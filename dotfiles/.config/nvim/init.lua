
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "mason-org/mason.nvim", opts = {} },

  {
    "mason-org/mason-lspconfig.nvim",
    opts = { ensure_installed = { "basedpyright" } },
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.enable("basedpyright")
    end,
  },

  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = {
      	preset = "default",
	["<CR>"] = { "accept", "fallback" },
	["<Tab>"] = { "accept", "fallback" }
      },
      completion = {
        documentation = { auto_show = true },
      },
    },
  },
})
