local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    -- Clone the plugin
    local cmd = {
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    }

    -- Run the command and check for errors
    local result = vim.loop.system(cmd)
    if result ~= 0 then
        vim.notify("Failed to clone lazy.nvim", vim.log.levels.ERROR)
        return
    end
end

-- Add the lazy.nvim to the runtime path
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
    { import = "plugins" },
    { import = "plugins.lsp" }
}, {
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        notify = false,
    },
})
