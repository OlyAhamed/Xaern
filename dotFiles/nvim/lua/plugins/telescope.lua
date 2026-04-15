return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim" },
	lazy = true,
	opts = {
		defaults = {
			preview = {
				treesitter = false,
			},
			find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
		},
		pickers = {
			find_files = {
				hidden = true,
			},
		},
	},
}
