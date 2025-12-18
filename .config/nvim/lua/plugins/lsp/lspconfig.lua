return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import mason_lspconfig plugin
    local mason_lspconfig = require("mason-lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- for conciseness

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>ses", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>se", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "g[", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "g]", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "?", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- Configure diagnostics for better performance
    vim.diagnostic.config({
      virtual_text = {
        spacing = 4,
        prefix = "●",
      },
      signs = true,
      underline = true,
      update_in_insert = false, -- Don't update diagnostics while typing
      severity_sort = true,
    })

    mason_lspconfig.setup({
      -- default handler for installed servers
      function(server_name)
        -- Skip vtsls if ts_ls is being used (prevents duplicates)
        if server_name == "vtsls" then
          return
        end
        
        lspconfig[server_name].setup({
          capabilities = capabilities,
        })
      end,
      ["ts_ls"] = function()
        local util = require("lspconfig.util")
        lspconfig["ts_ls"].setup({
          capabilities = capabilities,
          -- CRITICAL FIX: In monorepos, find the NEAREST package.json (not root!)
          -- This prevents scanning the entire 5GB+ monorepo from the root
          root_dir = function(fname)
            -- First try to find tsconfig.json (most specific to the app)
            local tsconfig_root = util.root_pattern("tsconfig.json")(fname)
            if tsconfig_root then
              return tsconfig_root
            end
            -- Then look for package.json, but ONLY if it's not in a parent with pnpm-workspace.yaml
            local package_root = util.root_pattern("package.json")(fname)
            if package_root then
              -- Check if this is the monorepo root (has pnpm-workspace.yaml or lerna.json)
              local is_monorepo_root = util.root_pattern("pnpm-workspace.yaml", "lerna.json")(package_root)
              if not is_monorepo_root then
                return package_root
              end
            end
            return nil
          end,
          single_file_support = false, -- Don't attach to random TS files outside projects
          -- CRITICAL: Exclude symlinked workspace packages to prevent scanning entire monorepo
          on_new_config = function(config, root_dir)
            -- Ensure TypeScript doesn't follow symlinks in node_modules
            config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
              typescript = {
                tsserver = {
                  maxTsServerMemory = 4096,
                  watchOptions = {
                    excludeDirectories = {
                      "**/node_modules",
                      "**/.git",
                      "**/.next",
                      "**/.turbo",
                    },
                  },
                },
              },
            })
          end,
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "literal",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = false,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = false,
                includeInlayFunctionLikeReturnTypeHints = false,
                includeInlayEnumMemberValueHints = false,
              },
              tsserver = {
                maxTsServerMemory = 4096,
                useSyntaxServer = "auto",
              },
              diagnostics = {
                ignoredCodes = { 6133 },
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = false,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = false,
                includeInlayFunctionLikeReturnTypeHints = false,
                includeInlayEnumMemberValueHints = false,
              },
            },
          },
          init_options = {
            preferences = {
              -- Disable expensive features in large monorepos
              disableSuggestions = false,
              quotePreference = "auto",
              importModuleSpecifierPreference = "relative",
              importModuleSpecifierEnding = "auto",
              allowIncompleteCompletions = true,
              allowRenameOfImportPath = false, -- Disable for performance
            },
            hostInfo = "neovim",
          },
          flags = {
            debounce_text_changes = 300, -- Increased debounce for better performance
          },
          -- Disable semantic tokens for better performance and prevent duplicates
          on_attach = function(client, bufnr)
            client.server_capabilities.semanticTokensProvider = nil
            
            -- TypeScript handles completions, disable others if ts_ls is active
            local active_clients = vim.lsp.get_active_clients({ bufnr = bufnr })
            for _, c in ipairs(active_clients) do
              if c.name ~= "ts_ls" and c.name ~= "tailwindcss" then
                -- Disable completion for non-essential LSPs when TypeScript is active
                if c.name == "html" or c.name == "emmet_ls" or c.name == "cssls" then
                  c.server_capabilities.completionProvider = nil
                end
              end
            end
          end,
        })
      end,
      ["tailwindcss"] = function()
        local util = require("lspconfig.util")
        lspconfig["tailwindcss"].setup({
          capabilities = capabilities,
          root_dir = util.root_pattern("tailwind.config.js", "tailwind.config.ts", "postcss.config.js"),
          settings = {
            tailwindCSS = {
              experimental = {
                classRegex = {
                  { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                  { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
                },
              },
            },
          },
        })
      end,
      ["intelephense"] = function()
        lspconfig["intelephense"].setup({
          capabilities = capabilities,
          settings = {
            intelephense = {
              stubs = require("plugins.lsp.configs.intelephense-stubs"),
            },
          },
          filetypes = { "php", "blade" },
          root_dir = function()
            return vim.loop.cwd()
          end,
        })
      end,
      ["emmet_ls"] = function()
        -- configure emmet language server
        local emmet_capabilities = vim.deepcopy(capabilities)
        -- Reduce emmet priority to prevent duplicates with other LSPs
        emmet_capabilities.textDocument.completion.completionItem.snippetSupport = true
        
        lspconfig["emmet_ls"].setup({
          capabilities = emmet_capabilities,
          filetypes = {
            "html",
            "typescriptreact",
            "javascriptreact",
            "css",
            "sass",
            "scss",
            "less",
            "svelte",
            "php",
            "blade",
          },
          init_options = {
            showExpandedAbbreviation = "inMarkupAndStylesheetFilesOnly",
            showSuggestionsAsSnippets = true,
          },
        })
      end,
      ["html"] = function()
        -- configure html language server with reduced completions
        local html_capabilities = vim.deepcopy(capabilities)
        html_capabilities.textDocument.completion.completionItem.snippetSupport = true
        
        lspconfig["html"].setup({
          capabilities = html_capabilities,
          init_options = {
            provideFormatter = false, -- Use prettier instead
          },
        })
      end,
      ["cssls"] = function()
        -- configure css language server
        lspconfig["cssls"].setup({
          capabilities = capabilities,
          settings = {
            css = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
            scss = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
            less = {
              validate = true,
              lint = {
                unknownAtRules = "ignore",
              },
            },
          },
        })
      end,
      ["lua_ls"] = function()
        -- configure lua server (with special settings)
        lspconfig["lua_ls"].setup({
          capabilities = capabilities,
          settings = {
            Lua = {
              -- make the language server recognize "vim" global
              diagnostics = {
                globals = { "vim" },
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        })
      end,
      -- Explicitly disable vtsls to prevent conflicts with ts_ls
      ["vtsls"] = function()
        -- Do nothing - we're using ts_ls instead
      end,
    })
    
    -- Disable vtsls globally to prevent auto-attachment
    vim.g.vtsls_disable = true
  end,
}
