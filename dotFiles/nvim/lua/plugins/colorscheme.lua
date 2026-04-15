local function enable_transparency()
   vim.api.nvim_set_hl(0, "Normal", { bg = "none" })	
end

return {
    {
	"folke/tokyonight.nvim",
	lazy = false,
	config = function ()
	   vim.cmd.colorscheme "tokyonight"
	   enable_transparency()

	   vim.api.nvim_create_autocmd("Colorscheme", {
	       callback = function()
	           vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = "none" })
	           vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { bg = "none" })
	       end,
	   })
	end
    },
}
