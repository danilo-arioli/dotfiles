return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "ts_ls", -- Using ts_ls instead of vtsls
        "html",
        "cssls",
        "tailwindcss",
        "lua_ls",
        "graphql",
        "emmet_ls",
        "prismals",
        "intelephense",
      },
      -- Automatically install configured servers
      automatic_installation = { exclude = { "vtsls" } }, -- Exclude vtsls to prevent conflicts
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "prettierd", -- fast prettier formatter (daemon)
        "stylua", -- lua formatter
        "eslint_d", -- fast eslint (daemon)
        "php-cs-fixer",
        "pylint",
      },
    })
  end,
}
