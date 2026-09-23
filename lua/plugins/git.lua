-- Git integration: inline hunk marks + blame (gitsigns) and a real
-- side-by-side review UI (diffview).
--
-- NOTE on "[" vs "]": this config uses "[" for FORWARD and "]" for BACKWARD
-- (see the [s/]s and [f/]f swaps elsewhere), so hunk navigation follows suit.
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      -- off by default; <leader>gB toggles it when you want it
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text_pos = "eol",
        delay = 300,
      },
      current_line_blame_formatter = "   <author>, <author_time:%Y-%m-%d> :: <summary>",
      preview_config = { border = "single" },

      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- navigation ("[" forward, "]" back, per this config's convention)
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next git hunk")

        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev git hunk")

        -- staging
        map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("v", "<leader>gs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Stage selected lines")
        map("v", "<leader>gr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Reset selected lines")
        map("n", "<leader>gS", gs.stage_buffer, "Stage whole buffer")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")

        -- inspection
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, "Blame line (full)")
        map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle inline blame")
        map("n", "<leader>gd", gs.diffthis, "Diff this file")
        map("n", "<leader>gq", gs.setqflist, "All hunks -> quickfix")

        -- text object: a hunk. "vih" selects it, "dih" deletes it.
        map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
      end,
    },
  },

  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    keys = {
      {
        "<leader>gv",
        function()
          -- toggle: if a diffview tab is already open, close it
          local ok, lib = pcall(require, "diffview.lib")
          if ok and lib.get_current_view() then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Diffview: working tree",
      },
      { "<leader>gV", "<cmd>DiffviewOpen master...HEAD<cr>", desc = "Diffview: branch vs master" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: this file's history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: branch history" },
      { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        -- side-by-side for review; 3-way only when actually merging
        default = { layout = "diff2_horizontal" },
        merge_tool = { layout = "diff3_horizontal", disable_diagnostics = true },
      },
      file_panel = {
        listing_style = "tree",
        win_config = { width = 32 },
      },
    },
  },
}
