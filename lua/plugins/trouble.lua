-- trouble.nvim: a persistent, navigable panel for diagnostics / references /
-- symbols, instead of the transient quickfix window.
--
-- The big win over "gr" -> quickfix is that the list stays open with a live
-- preview while you walk it, which is what you want when tracing every caller
-- of a register write across components.
return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "Trouble",
  opts = {
    focus = true,
    win = { size = 0.32 },
    modes = {
      -- a symbol outline that behaves like VSCode's outline pane
      symbols = {
        win = { position = "right", size = 0.25 },
        filter = {
          -- C/C++: only the things worth outlining
          any = {
            ft = { "c", "cpp" },
            kind = { "Function", "Struct", "Enum", "Constant", "Field", "Method", "Class" },
          },
        },
      },
    },
  },
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics: workspace" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics: this buffer" },
    { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbol outline" },
    { "<leader>xr", "<cmd>Trouble lsp_references toggle<cr>", desc = "References (panel)" },
    { "<leader>xi", "<cmd>Trouble lsp_incoming_calls toggle<cr>", desc = "Incoming calls" },
    { "<leader>xo", "<cmd>Trouble lsp_outgoing_calls toggle<cr>", desc = "Outgoing calls" },
    { "<leader>xd", "<cmd>Trouble lsp_definitions toggle<cr>", desc = "Definitions (panel)" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
  },
}
