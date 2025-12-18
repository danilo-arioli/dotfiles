return {
  "sindrets/diffview.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local keymap = vim.keymap

    keymap.set("n", "<leader>dvo", "<cmd>DiffviewOpen<cr>", {
      desc = "Open diff view",
    })

    keymap.set("n", "<leader>dvm", "<cmd>DiffviewOpen origin/main...HEAD<cr>", {
      desc = "Open diff view with main branch",
    })

    keymap.set("n", "<leader>dvc", "<cmd>DiffviewClose<cr>", {
      desc = "Close diff view",
    })
  end,
}
