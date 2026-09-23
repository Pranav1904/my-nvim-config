-- gitinspect.lua
--
-- "Who wrote this line, why, and which merge request brought it in?"
--
-- One call (<leader>gm) blames the line under the cursor, resolves the commit
-- to the merge commit that pulled it into the branch, pulls the "See merge
-- request <project>!<n>" trailer out of that merge commit, and shows the whole
-- story in a floating window you can act on:
--
--   o  open the merge request in the browser
--   O  open the commit in the browser
--   d  open the commit's diff in diffview
--   y  yank the commit hash
--   q  close
--
-- Nothing here needs a plugin; it shells out to git.

local M = {}

----------------------------------------------------------------------
-- git plumbing
----------------------------------------------------------------------

local function git(dir, args, stdin)
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local out = stdin and vim.fn.system(cmd, stdin) or vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, out
  end
  return out
end

local function buf_dir(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    return nil
  end
  return vim.fs.dirname(file), file
end

-- host + project path of the remote we should build URLs against.
-- Prefers a gitlab remote, then origin, then whatever is first.
local function remote_info(dir)
  local function url_of(name)
    local out = git(dir, { "config", "--get", "remote." .. name .. ".url" })
    return out and vim.trim(out) or nil
  end

  local url = url_of("gitlab") or url_of("origin")
  if not url then
    local names = git(dir, { "remote" })
    if names then
      local first = vim.split(vim.trim(names), "\n")[1]
      if first and first ~= "" then
        url = url_of(first)
      end
    end
  end
  if not url or url == "" then
    return nil
  end

  -- ssh://git@host:27227/group/repo.git | git@host:group/repo.git | https://host/group/repo.git
  local host = url:match("^%w+://[^@/]*@?([^:/]+)") or url:match("^[^@]+@([^:/]+)")
  local path = url:match("^%w+://[^/]+/(.+)$") or url:match("^[^@]+@[^:]+:(.+)$")
  if not host or not path then
    return nil
  end
  path = path:gsub("%.git$", "")
  return { host = host, path = path }
end

----------------------------------------------------------------------
-- blame
----------------------------------------------------------------------

-- Blames one line. Unsaved edits are handled by feeding the buffer to git on
-- stdin, so the answer matches what you see on screen.
local function blame_line(bufnr, lnum)
  local dir, file = buf_dir(bufnr)
  if not dir then
    return nil, "this buffer is not a file on disk"
  end

  local contents = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"
  local out, err = git(dir, {
    "blame",
    "--porcelain",
    "-L",
    lnum .. "," .. lnum,
    "--contents",
    "-",
    "--",
    file,
  }, contents)
  if not out then
    return nil, vim.trim(err or "git blame failed")
  end

  local sha = out:match("^(%x+)")
  if not sha then
    return nil, "could not parse git blame output"
  end
  if sha:match("^0+$") then
    return nil, "this line is not committed yet"
  end

  return {
    dir = dir,
    file = file,
    sha = sha,
    author = out:match("\nauthor (.-)\n") or "?",
    time = tonumber(out:match("\nauthor%-time (%d+)")),
    summary = out:match("\nsummary (.-)\n") or "",
  }
end

----------------------------------------------------------------------
-- commit -> merge request
----------------------------------------------------------------------

local function parse_request(text)
  -- GitLab: "See merge request espressif/esp-idf!52460"
  local project, number = text:match("[Ss]ee merge request%s+([%w%._%-/]+)!(%d+)")
  if number then
    return { kind = "mr", project = project, number = number }
  end
  number = text:match("[Ss]ee merge request%s+!(%d+)")
  if number then
    return { kind = "mr", number = number }
  end
  -- GitHub: "Merge pull request #1234 from fork/branch"
  number = text:match("Merge pull request #(%d+)")
  if number then
    return { kind = "pr", number = number }
  end
  return nil
end

-- Walks forward from the commit to the first merge commit that contains it,
-- which is the merge commit carrying the merge request trailer.
local function find_request(dir, sha)
  local own = git(dir, { "show", "-s", "--format=%B", sha })
  if own then
    local req = parse_request(own)
    if req then
      return req, sha
    end
  end

  for _, tip in ipairs({ "HEAD", "origin/master", "gitlab/master", "origin/main" }) do
    local out = git(dir, {
      "log",
      "--merges",
      "--ancestry-path",
      "--reverse",
      "--format=%H%x1f%B%x1e",
      sha .. ".." .. tip,
    })
    if out and out ~= "" then
      for record in out:gmatch("(.-)\30") do
        local msha, body = record:match("^%s*(%x+)\31(.*)$")
        if msha then
          local req = parse_request(body)
          if req then
            return req, msha
          end
        end
      end
    end
  end
  return nil
end

local function request_url(dir, req, sha)
  local remote = remote_info(dir)
  if not remote then
    return nil
  end
  local project = req.project or remote.path
  if req.kind == "pr" then
    return "https://" .. remote.host .. "/" .. project .. "/pull/" .. req.number
  end
  return "https://" .. remote.host .. "/" .. project .. "/-/merge_requests/" .. req.number
end

local function commit_url(dir, sha)
  local remote = remote_info(dir)
  if not remote then
    return nil
  end
  local sep = remote.host:match("github") and "/commit/" or "/-/commit/"
  return "https://" .. remote.host .. "/" .. remote.path .. sep .. sha
end

----------------------------------------------------------------------
-- float
----------------------------------------------------------------------

local function open_float(lines, actions)
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(math.max(width + 2, 40), math.floor(vim.o.columns * 0.9))
  local height = math.min(#lines, math.floor(vim.o.lines * 0.8))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "git"
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "single",
  })
  vim.wo[win].wrap = true

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true })
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  map("q", close)
  map("<Esc>", close)
  for lhs, fn in pairs(actions or {}) do
    map(lhs, function()
      close()
      fn()
    end)
  end

  return win, buf
end

local function open_url(url)
  if not url then
    vim.notify("no URL for this commit (no usable git remote)", vim.log.levels.WARN)
    return
  end
  if vim.ui.open then
    vim.ui.open(url)
  else
    vim.fn.jobstart({ "open", url }, { detach = true })
  end
end

----------------------------------------------------------------------
-- public
----------------------------------------------------------------------

--- Blame the current line and show commit + merge request in a float.
function M.line_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]

  local info, err = blame_line(bufnr, lnum)
  if not info then
    vim.notify(err, vim.log.levels.WARN)
    return
  end

  local show = git(info.dir, {
    "show",
    "-s",
    "--date=format:%Y-%m-%d %H:%M",
    "--format=%h%n%an <%ae>%n%ad%n%B",
    info.sha,
  }) or ""
  local parts = vim.split(show, "\n")
  local short, author, date = parts[1], parts[2], parts[3]
  local message = vim.list_slice(parts, 4)

  local req, merge_sha = find_request(info.dir, info.sha)
  local url = req and request_url(info.dir, req, info.sha) or nil

  local lines = {
    "commit  " .. short .. "  (" .. info.sha:sub(1, 12) .. ")",
    "author  " .. author,
    "date    " .. date,
  }
  if req then
    local mark = req.kind == "pr" and "pr      #" or "mr      !"
    table.insert(lines, mark .. req.number .. (url and ("  " .. url) or ""))
    if merge_sha ~= info.sha then
      table.insert(lines, "merged  " .. merge_sha:sub(1, 12))
    end
  else
    table.insert(lines, "mr      not found on this branch")
  end
  table.insert(lines, "")
  for _, l in ipairs(message) do
    table.insert(lines, l)
  end
  while #lines > 0 and lines[#lines] == "" do
    table.remove(lines)
  end
  table.insert(lines, "")
  table.insert(lines, "[o] merge request  [O] commit page  [d] diff  [y] yank sha  [q] close")

  open_float(lines, {
    o = function()
      open_url(url)
    end,
    O = function()
      open_url(commit_url(info.dir, info.sha))
    end,
    y = function()
      vim.fn.setreg("+", info.sha)
      vim.notify(info.sha .. " yanked")
    end,
    d = function()
      vim.cmd("DiffviewOpen " .. info.sha .. "^!")
    end,
  })
end

--- Open the merge request for the current line straight away.
function M.open_request()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local info, err = blame_line(bufnr, lnum)
  if not info then
    vim.notify(err, vim.log.levels.WARN)
    return
  end
  local req = find_request(info.dir, info.sha)
  if not req then
    vim.notify("no merge request found for " .. info.sha:sub(1, 12), vim.log.levels.WARN)
    return
  end
  open_url(request_url(info.dir, req, info.sha))
end

--- Open the diff of the commit that last touched the current line.
function M.diff_commit()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local info, err = blame_line(bufnr, lnum)
  if not info then
    vim.notify(err, vim.log.levels.WARN)
    return
  end
  vim.cmd("DiffviewOpen " .. info.sha .. "^!")
end

--- Commit list for this file. Enter opens that commit's diff for the file,
--- <C-a> opens the merge request that brought the commit in.
function M.file_commits()
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    vim.cmd("DiffviewFileHistory %")
    return
  end

  local actions = require("telescope.actions")
  local state = require("telescope.actions.state")
  local file = vim.fn.expand("%")
  local dir = buf_dir(vim.api.nvim_get_current_buf())

  builtin.git_bcommits({
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd("DiffviewOpen " .. entry.value .. "^! -- " .. vim.fn.fnameescape(file))
      end)
      map({ "i", "n" }, "<C-a>", function()
        local entry = state.get_selected_entry()
        actions.close(prompt_bufnr)
        local req = dir and find_request(dir, entry.value)
        if req then
          open_url(request_url(dir, req, entry.value))
        else
          vim.notify("no merge request found for that commit", vim.log.levels.WARN)
        end
      end)
      return true
    end,
  })
end

--- History of the visually selected lines only.
function M.range_history()
  vim.cmd("'<,'>DiffviewFileHistory")
end

function M.setup_commands()
  vim.api.nvim_create_user_command("GitLineInfo", M.line_info, { desc = "Blame line: commit + merge request" })
  vim.api.nvim_create_user_command("GitOpenMR", M.open_request, { desc = "Open merge request for this line" })
end

return M
