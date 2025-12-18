return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        javascript = { "prettierd" },
        typescript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescriptreact = { "prettierd" },
        svelte = { "prettierd" },
        css = { "prettierd" },
        html = { "prettierd" },
        json = { "prettierd" },
        yaml = { "prettierd" },
        markdown = { "prettierd" },
        graphql = { "prettierd" },
        liquid = { "prettierd" },
        lua = { "stylua" },
        python = { "isort", "black" },
        php = { "php-cs-fixer" },
        blade = { "php-cs-fixer" },
      },
      -- Disable format_on_save by default for large files
      format_on_save = function(bufnr)
        -- Disable for large files
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
        if ok and stats and stats.size > max_filesize then
          return nil
        end

        -- Disable if no formatter configured
        local ft = vim.bo[bufnr].filetype
        if not conform.formatters_by_ft[ft] then
          return nil
        end

        return {
          timeout_ms = 500, -- Reduced from 1000
          lsp_fallback = true,
          async = false,
        }
      end,
      formatters = {
        -- Configure prettierd for better performance
        prettierd = {
          env = {
            PRETTIERD_DEFAULT_CONFIG = vim.fn.expand("~/.config/nvim/.prettierrc.json"),
          },
        },
      },
    })

    -- Manual format command with better performance
    vim.keymap.set({ "n", "v" }, "<leader>mp", function()
      -- Check file size before formatting
      local file_size = vim.fn.getfsize(vim.fn.expand("%"))
      if file_size > 100000 then
        vim.notify("File too large to format (>100KB)", vim.log.levels.WARN)
        return
      end

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

    -- Add command to toggle format on save
    vim.api.nvim_create_user_command("FormatToggle", function()
      if vim.g.disable_autoformat then
        vim.g.disable_autoformat = false
        vim.notify("Format on save enabled", vim.log.levels.INFO)
      else
        vim.g.disable_autoformat = true
        vim.notify("Format on save disabled", vim.log.levels.WARN)
      end
    end, {})
  end,
}
