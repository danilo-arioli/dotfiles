return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
        php = { "php-cs-fixer" },
        blade = { "php-cs-fixer" },
      },
      format_on_save = {
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      },
    })

    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (in visual mode)" })

    -- Add the DebugFormatter command inside the config function
    vim.api.nvim_create_user_command("DebugFormatter", function(opts)
      local formatters_by_ft = conform.formatters_by_ft

      if not formatters_by_ft then
        vim.notify("No formatters configuration found", vim.log.levels.ERROR)
        return
      end

      -- If a filetype argument is provided, use that
      local filetype = opts.args

      -- If no filetype argument, use the current buffer's filetype
      if filetype == "" then
        filetype = vim.bo.filetype
      end

      if formatters_by_ft[filetype] then
        vim.notify("Formatters for " .. filetype .. ": " .. table.concat(formatters_by_ft[filetype], ", "))

        -- Check if each formatter is installed
        for _, formatter in ipairs(formatters_by_ft[filetype]) do
          local handle = io.popen("which " .. formatter)
          local result = handle:read("*a")
          handle:close()

          if result and result ~= "" then
            vim.notify(formatter .. " is installed at: " .. result:gsub("\n", ""))
          else
            vim.notify(formatter .. " is not installed or not in PATH", vim.log.levels.WARN)
          end
        end
      else
        vim.notify("No formatters found for " .. filetype .. " files", vim.log.levels.WARN)
      end
    end, { nargs = "?" })
  end,
}
