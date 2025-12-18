return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
      python = { "pylint" },
    }

    -- Function to check if there's an eslint config
    local function has_eslint_config()
      -- Cache the result to avoid repeated file system checks
      if vim.b.has_eslint_config ~= nil then
        return vim.b.has_eslint_config
      end

      local files = {
        ".eslintrc.js",
        ".eslintrc.json",
        ".eslintrc.yml",
        ".eslintrc.yaml",
        ".eslintrc.cjs",
        "eslint.config.js",
        "eslint.config.mjs",
        "eslint.config.cjs",
      }

      -- Look in current directory and parent directories
      local current_dir = vim.fn.expand("%:p:h")
      local root = vim.fn.getcwd()

      while current_dir and current_dir ~= "/" and current_dir:find(root, 1, true) == 1 do
        for _, file in ipairs(files) do
          if vim.fn.filereadable(current_dir .. "/" .. file) == 1 then
            vim.b.has_eslint_config = true
            return true
          end
        end
        current_dir = vim.fn.fnamemodify(current_dir, ":h")
      end

      -- Check for eslintConfig in package.json
      local package_json = vim.fn.findfile("package.json", current_dir .. ";")
      if package_json ~= "" then
        local ok, content = pcall(vim.fn.readfile, package_json)
        if ok then
          local json_str = table.concat(content, "\n")
          if json_str:find('"eslintConfig"') then
            vim.b.has_eslint_config = true
            return true
          end
        end
      end

      vim.b.has_eslint_config = false
      return false
    end

    -- Configure eslint_d for better performance
    lint.linters.eslint_d.args = {
      "--no-warn-ignored",
      "--format",
      "json",
      "--stdin",
      "--stdin-filename",
      function()
        return vim.api.nvim_buf_get_name(0)
      end,
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    -- Only lint on save for smaller files
    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = lint_augroup,
      callback = function()
        -- Only lint if file is not too large (>200KB)
        local file_size = vim.fn.getfsize(vim.fn.expand("%"))
        if file_size > 200000 then
          return
        end

        local ft = vim.bo.filetype
        if ft == "python" then
          lint.try_lint("pylint")
        elseif
          (ft == "javascript" or ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact" or ft == "svelte")
          and has_eslint_config()
        then
          lint.try_lint("eslint_d")
        end
      end,
    })

    -- Removed InsertLeave linting - too aggressive for large files
    -- You can manually trigger linting with <leader>l

    vim.keymap.set("n", "<leader>l", function()
      local file_size = vim.fn.getfsize(vim.fn.expand("%"))
      if file_size > 200000 then
        vim.notify("File too large to lint (>200KB)", vim.log.levels.WARN)
        return
      end

      local ft = vim.bo.filetype
      if ft == "python" then
        lint.try_lint("pylint")
      elseif
        (ft == "javascript" or ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact" or ft == "svelte")
        and has_eslint_config()
      then
        lint.try_lint("eslint_d")
      else
        vim.notify("No linter configured for this filetype", vim.log.levels.INFO)
      end
    end, { desc = "Trigger linting for current file" })

    -- Add command to toggle linting
    vim.api.nvim_create_user_command("LintToggle", function()
      if vim.g.disable_lint then
        vim.g.disable_lint = false
        vim.notify("Linting enabled", vim.log.levels.INFO)
      else
        vim.g.disable_lint = true
        vim.notify("Linting disabled", vim.log.levels.WARN)
      end
    end, {})
  end,
}
