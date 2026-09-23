return {
  {

    "nvim-neotest/nvim-nio",
  },
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      dap.adapters.codelldb = {
        type = "executable",
        port = "${port}",
        command = "codelldb",
        name = "codelldb",
        executable = {
          command = "$HOME/.local/share/nvim/mason/bin/codelldb",
          args = { "--port", "${port}" }
        }
      }

      dap.configurations.c = {
        {
          type = "codelldb",
          name = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("path to exe: ", vim.fn.getcwd() .. "/build", "file")
          end,
          cwd = function()
            return vim.fn.input("cwd: ", vim.fn.getcwd() .. "/build", "file")
          end,
          stopOnEntry = false
        }
      }

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      -- Breakpoints need a sign column to render in; options.lua now reserves
      -- one permanently so nothing shifts when they appear.
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◐", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

      -- This config had a full codelldb setup and zero keybindings, so the
      -- debugger was unreachable. F-keys for stepping, <leader>d* for the rest.
      local km = vim.keymap.set
      km("n", "<F5>", dap.continue, { desc = "DAP continue / start" })
      km("n", "<F10>", dap.step_over, { desc = "DAP step over" })
      km("n", "<F11>", dap.step_into, { desc = "DAP step into" })
      km("n", "<S-F11>", dap.step_out, { desc = "DAP step out" })

      km("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
      km("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "DAP conditional breakpoint" })
      km("n", "<leader>dl", function()
        dap.set_breakpoint(nil, nil, vim.fn.input("Log message: "))
      end, { desc = "DAP log point" })
      km("n", "<leader>dc", dap.continue, { desc = "DAP continue" })
      km("n", "<leader>dn", dap.step_over, { desc = "DAP step over (next)" })
      km("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
      km("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
      km("n", "<leader>dr", dap.run_last, { desc = "DAP re-run last" })
      km("n", "<leader>dR", dap.repl.toggle, { desc = "DAP repl" })
      km("n", "<leader>dt", dap.terminate, { desc = "DAP terminate" })
      km("n", "<leader>du", dapui.toggle, { desc = "DAP toggle UI" })
      km({ "n", "v" }, "<leader>dv", function()
        require("dapui").eval(nil, { enter = true })
      end, { desc = "DAP eval under cursor" })
      km("n", "<leader>dC", dap.clear_breakpoints, { desc = "DAP clear all breakpoints" })
    end
  },
  { "rcarriga/nvim-dap-ui" }
}
