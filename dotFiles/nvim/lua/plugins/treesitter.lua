return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({
			ensure_installed = { "lua", "javascript", "vim", "vimdoc", "regex", "bash", "css", "html", "yuck" },
			indent = {enable = true},
			autotage = {enable = true },
			auto_install = true,
		})
	end,
}
