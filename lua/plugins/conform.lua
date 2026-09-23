return {
  "stevearc/conform.nvim",
  config = function()
    vim.g.disable_autoformat = false
    require("conform").setup({
      formatters_by_ft = {
        purescript = { "purstidy", stop_after_first = true },
        lua = { "stylua", stop_after_first = true },
        ocaml = { "ocamlformat", stop_after_first = true },
        python = { "black" },
        rust = { "rustfmt" },
        javascript = { "prettier", stop_after_first = true },
        javascriptreact = { "prettier", stop_after_first = true },
        typescript = { "prettier", stop_after_first = true },
        typescriptreact = { "prettier", stop_after_first = true },
        astro = { "astro", stop_after_first = true },
        go = { "gofumpt", "golines", "goimports-reviser" },
        c = { "clang_format" },
        cpp = { "clang_format" },
        haskell = { "fourmolu" },
        yaml = { "yamlfmt" },
        html = { "prettier" },
        json = { "prettier" },
        markdown = { "prettier" },
        gleam = { "gleam" },
        asm = { "asmfmt" },
        css = { "prettier", stop_after_first = true },
        fennel = { "fnlfmt" }
      },
      formatters = {
        clang_format = {
          prepend_args = { "--style={BasedOnStyle: LLVM, SortIncludes: false}" },
        },
      },
      format_on_save = function(_)
        if vim.g.disable_autoformat then
          return
        end
        return {
          timeout_ms = 500,
          lsp_format = "fallback",
        }
      end,
    })

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function(args)
        if vim.g.disable_autoformat then
          return
        end
        require("conform").format({ bufnr = args.buf })
      end,
    })

    -- Some repos use their own code style and do NOT run our formatters in CI:
    --   * esp-emulator does not use rustfmt (no rustfmt.toml).
    --   * esp-idf uses its own C style (Allman braces, aligned params), which
    --     does not match clang-format's LLVM style forced above.
    -- Format-on-save would reformat whole files and create huge noise diffs, so
    -- auto-disable autoformat for any file inside these repos and re-enable it
    -- everywhere else.
    local no_autoformat_repos = { "esp%-emulator", "esp%-idf" }
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter" }, {
      pattern = "*",
      callback = function(args)
        local path = vim.api.nvim_buf_get_name(args.buf)
        local disable = false
        for _, repo in ipairs(no_autoformat_repos) do
          if path:find(repo, 1, false) ~= nil then
            disable = true
            break
          end
        end
        vim.g.disable_autoformat = disable
      end,
    })
  end,
}
