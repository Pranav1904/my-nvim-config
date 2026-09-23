local M = {}

local km = vim.keymap.set

-- remaps
vim.g.mapleader = " "
vim.g.maplocalleader = ","

km("n", "<C-h>", "<C-w>h")
km("n", "<C-j>", "<C-w>j")
km("n", "<C-k>", "<C-w>k")
km("n", "<C-l>", "<C-w>l")

-- because [e goes to the next error
-- for consistency
km("n", "[s", "]s")
km("n", "]s", "[s")

-- window manips
km("n", "=", [[<cmd>vertical resize +5<cr>]])
km("n", "-", [[<cmd>vertical resize -5<cr>]])
km("n", "+", [[<cmd>horizontal resize +5<cr>]])
km("n", "^", [[<cmd>horizontal resize +5<cr>]])
km("n", "<leader>vs", ":vsplit<CR>")
km("n", "<leader>hs", ":split<CR>")
km("n", "<leader>wc", ":clo<CR>")

-- move selections
km("v", "J", ":m '>+1<CR>gv=gv") -- Shift visual selected line down
km("v", "K", ":m '<-2<CR>gv=gv") -- Shift visual selected line up
km("n", "<leader>t", "bv~")

-- colorscheme picker
km("n", "<C-n>", ":Telescope colorscheme<CR>")

km("n", "<C-d>", "<C-d>zz")
km("n", "<C-u>", "<C-u>zz")
km("n", "<C-f>", "<C-f>zz")
km("n", "<C-b>", "<C-b>zz")
km("n", "Y", "yy")

-- autocomplete in normal text
km("i", "<C-f>", "<C-x><C-f>", { noremap = true, silent = true })
km("i", "<C-n>", "<C-x><C-n>", { noremap = true, silent = true })
km("i", "<C-l>", "<C-x><C-l>", { noremap = true, silent = true })

-- spell check
km("n", "<leader>ll", ":setlocal spell spelllang=en_us<CR>")

-- lsp setup
km("n", "K", vim.lsp.buf.hover)
km("n", "gd", vim.lsp.buf.definition)
km("n", "gD", vim.lsp.buf.declaration)
km("n", "gr", function()
  -- Trigger the LSP references function and populate the quickfix list
  vim.lsp.buf.references()

  vim.defer_fn(function()
    -- Set up an autocmd to remap keys in the quickfix window
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "qf", -- Only apply this mapping in quickfix windows
      callback = function()
        -- Remap <Enter> to jump to the location and close the quickfix window
        vim.api.nvim_buf_set_keymap(0, "n", "<CR>", "<CR>:cclose<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(0, "n", "q", ":cclose<CR>", { noremap = true, silent = true })

        -- Set up <Tab> to cycle through quickfix list entries
        km("n", "<Tab>", function()
          local current_idx = vim.fn.getqflist({ idx = 0 }).idx
          local qflist = vim.fn.getqflist() -- Get the current quickfix list
          if current_idx >= #qflist then
            vim.cmd("cfirst")
            vim.cmd("wincmd p")
          else
            vim.cmd("cnext")
            vim.cmd("wincmd p")
          end
        end, { noremap = true, silent = true, buffer = 0 })

        km("n", "<S-Tab>", function()
          local current_idx = vim.fn.getqflist({ idx = 0 }).idx
          if current_idx < 2 then
            vim.cmd("clast")
            vim.cmd("wincmd p")
          else
            vim.cmd("cprev")
            vim.cmd("wincmd p")
          end
        end, { noremap = true, silent = true, buffer = 0 })
      end,
    })
  end, 0)
end)

km({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})

km({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})

-- see error
km("n", "<leader>e", vim.diagnostic.open_float)

-- go to errors. keeping this config's convention: "[" goes FORWARD, "]" back
-- (same reason [s/]s and [f/]f are swapped). "]e" used to also jump forward.
km("n", "[e", function() vim.diagnostic.jump({ count = 1, float = true }) end)
km("n", "]e", function() vim.diagnostic.jump({ count = -1, float = true }) end)

-- more lsp: things that had no bindings at all
km("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP rename" })
km("n", "gi", vim.lsp.buf.implementation, { desc = "LSP implementation" })
km("n", "gy", vim.lsp.buf.type_definition, { desc = "LSP type definition" })
km("n", "<leader>ci", vim.lsp.buf.incoming_calls, { desc = "LSP incoming calls" })
km("n", "<leader>co", vim.lsp.buf.outgoing_calls, { desc = "LSP outgoing calls" })
km("n", "<leader>fm", function()
  require("conform").format({ lsp_format = "fallback" })
end, { desc = "Format buffer (manual)" })

-- quickfix walking, using the same "[" = forward convention
km("n", "[q", "<cmd>cnext<cr>zz", { desc = "Next quickfix" })
km("n", "]q", "<cmd>cprev<cr>zz", { desc = "Prev quickfix" })
km("n", "<leader>qo", "<cmd>copen<cr>", { desc = "Open quickfix" })
km("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })

-- Fill the quickfix list with every file under review, then walk it with [q/]q.
-- Prefers the branch's own commits (base...HEAD); if you are sitting on the
-- base branch with uncommitted work, falls back to the working tree.
vim.api.nvim_create_user_command("ReviewFiles", function(opts)
  local base = opts.args ~= "" and opts.args or "master"

  local function run(cmd)
    local out = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 then
      return {}
    end
    return out
  end

  local origin, files = "vs " .. base, run({ "git", "diff", "--name-only", base .. "...HEAD" })

  if #files == 0 then
    -- tracked edits + untracked files, straight from status
    origin = "working tree"
    for _, line in ipairs(run({ "git", "status", "--porcelain" })) do
      local path = line:sub(4)
      -- renames come through as "old -> new"; keep the new name
      files[#files + 1] = path:match("%s%->%s(.+)$") or path
    end
  end

  if #files == 0 then
    vim.notify("nothing to review (" .. base .. " and working tree are clean)", vim.log.levels.WARN)
    return
  end

  vim.fn.setqflist(vim.tbl_map(function(f)
    return { filename = f, lnum = 1, text = "changed: " .. origin }
  end, files))
  vim.cmd("copen")
end, { nargs = "?", desc = "Quickfix list of files under review (default base: master)" })

----------------------------------------------------------------------
-- git archaeology: who changed this, why, and in which merge request
-- (see lua/utils/gitinspect.lua)
----------------------------------------------------------------------
local gitinspect = require("utils.gitinspect")
gitinspect.setup_commands()

km("n", "<leader>gm", gitinspect.line_info, { desc = "Git: line -> commit + merge request" })
km("n", "<leader>go", gitinspect.open_request, { desc = "Git: open merge request in browser" })
km("n", "<leader>gC", gitinspect.diff_commit, { desc = "Git: diff the commit behind this line" })
km("n", "<leader>gf", gitinspect.file_commits, { desc = "Git: commits touching this file" })
km("v", "<leader>gh", gitinspect.range_history, { desc = "Git: history of selected lines" })
km("n", "<leader>gL", function()
  local ok, gs = pcall(require, "gitsigns")
  if ok and gs.blame then
    gs.blame()
  else
    vim.cmd("Gitsigns blame")
  end
end, { desc = "Git: full-file blame pane" })

----------------------------------------------------------------------
-- buffers: move between files and close one without wrecking the layout
----------------------------------------------------------------------

-- Close the current buffer but keep every window and split alive: each window
-- showing it falls back to the alternate buffer, then the previous one, then a
-- scratch buffer. This is what :bd does not do.
local function close_buffer(force)
  local cur = vim.api.nvim_get_current_buf()

  if vim.bo[cur].modified and not force then
    vim.notify("buffer has unsaved changes (:w, or <leader>bD to force)", vim.log.levels.WARN)
    return
  end

  local alt = vim.fn.bufnr("#")
  local usable_alt = alt ~= -1 and alt ~= cur and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == cur then
      vim.api.nvim_win_call(win, function()
        if usable_alt then
          vim.cmd("buffer " .. alt)
        else
          vim.cmd("bprevious")
        end
        if vim.api.nvim_win_get_buf(win) == cur then
          vim.cmd("enew")
        end
      end)
    end
  end

  pcall(vim.api.nvim_buf_delete, cur, { force = force })
end

km("n", "[b", "<cmd>bnext<cr>", { desc = "Next buffer" })
km("n", "]b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
km("n", "<leader>bb", function()
  require("telescope.builtin").buffers({ sort_mru = true, ignore_current_buffer = true })
end, { desc = "Buffer picker" })
km("n", "<leader>bd", function()
  close_buffer(false)
end, { desc = "Close buffer, keep layout" })
km("n", "<leader>bD", function()
  close_buffer(true)
end, { desc = "Close buffer, discard changes" })
km("n", "<leader>bo", function()
  local cur = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= cur and vim.bo[b].buflisted and not vim.bo[b].modified then
      pcall(vim.api.nvim_buf_delete, b, {})
    end
  end
end, { desc = "Close all other buffers" })
km("n", "<leader>bl", "<cmd>buffers<cr>", { desc = "List buffers (:b <n> to jump)" })

----------------------------------------------------------------------
-- cheatsheet
----------------------------------------------------------------------
vim.api.nvim_create_user_command("Cheatsheet", function()
  vim.cmd("tabedit " .. vim.fn.stdpath("config") .. "/CHEATSHEET.md")
  vim.opt_local.conceallevel = 0
  vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = 0, nowait = true })
end, { desc = "Open the nvim cheatsheet" })
km("n", "<leader>ch", "<cmd>Cheatsheet<cr>", { desc = "Cheatsheet" })

M.after_lazy_keymaps = function()
  -- notes and related
  km("n", "<leader>lc", ":LinkConvertAll<CR>") -- make all links in markdown refs
end

return M
