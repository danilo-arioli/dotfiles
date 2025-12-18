return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    {
      "L3MON4D3/LuaSnip",
      -- follow latest release.
      version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      -- install jsregexp (optional!).
      build = "make install_jsregexp",
    },
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    "onsails/lspkind.nvim", -- vs-code like pictograms
  },
  config = function()
    local cmp = require("cmp")

    local luasnip = require("luasnip")

    local lspkind = require("lspkind")

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    cmp.setup({
      window = {
        completion = { border = "single", scrollbar = false },
        documentation = { border = "single", scrollbar = false },
      },
      completion = {
        completeopt = "menu,menuone,preview,noselect",
        keyword_length = 2, -- Only show completions after 2 characters
      },
      performance = {
        debounce = 150, -- Debounce completion requests
        throttle = 50, -- Throttle completion requests
        fetching_timeout = 200, -- Timeout for fetching completions
        max_view_entries = 50, -- Maximum number of items to show
      },
      sorting = {
        priority_weight = 2,
        comparators = {
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          cmp.config.compare.score,
          cmp.config.compare.recently_used,
          cmp.config.compare.locality,
          cmp.config.compare.kind,
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      },
      experimental = {
        ghost_text = false, -- Disable ghost text to reduce visual clutter
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-n>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-s>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      }),
      -- sources for autocompletion - prioritize LSP, then snippets
      sources = cmp.config.sources({
        {
          name = "nvim_lsp",
          priority = 1000,
          max_item_count = 20, -- Limit number of LSP suggestions
          -- Disable LSP completions for very large buffers
          entry_filter = function(entry, ctx)
            local bufnr = ctx.bufnr
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            if line_count > 10000 then
              return false
            end
            return true
          end,
        },
        { name = "luasnip", priority = 750, max_item_count = 10 }, -- snippets
        {
          name = "buffer",
          priority = 500,
          max_item_count = 10,
          option = {
            get_bufnrs = function()
              -- Only use current buffer for completion to reduce memory usage
              return { vim.api.nvim_get_current_buf() }
            end,
          },
        },
        { name = "path", priority = 250, max_item_count = 10 }, -- file system paths
      }),

      -- configure lspkind for vs-code like pictograms in completion menu
      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = lspkind.cmp_format({
          mode = "symbol_text",
          maxwidth = 50,
          ellipsis_char = "...",
        }),
      },
    })
  end,
}
