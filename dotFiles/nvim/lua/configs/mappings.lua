vim.g.mapleader = " "

local keymap = vim.keymap
-- telescope
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
--neo-tree
vim.keymap.set("n", "<leader>nt", "<cmd>Neotree toggle<CR>", { desc = "Toggle Neotree" })
--conform
vim.keymap.set("n", "<leader>fm", function()
	require("conform").format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 500,
	})
end, { desc = "Format file" })
--opencode
local opencode = require("opencode")
vim.keymap.set({ "n", "x" }, "<C-a>", function()
	opencode.ask("@this: ", { submit = true })
end, { desc = "Ask opencode…" })
vim.keymap.set({ "n", "x" }, "<C-x>", function()
	opencode.select()
end, { desc = "Execute opencode action…" })
vim.keymap.set({ "n", "t" }, "<C-.>", function()
	opencode.toggle()
end, { desc = "Toggle opencode" })
vim.keymap.set({ "n", "x" }, "go", function()
	return opencode.operator("@this ")
end, { desc = "Add range to opencode", expr = true })
vim.keymap.set("n", "goo", function()
	return opencode.operator("@this ") .. "_"
end, { desc = "Add line to opencode", expr = true })
vim.keymap.set("n", "<S-C-u>", function()
	opencode.command("session.half.page.up")
end, { desc = "Scroll opencode up" })
vim.keymap.set("n", "<S-C-d>", function()
	opencode.command("session.half.page.down")
end, { desc = "Scroll opencode down" })
--bufferline
for i = 1, 9 do
	keymap.set("n", "<leader>" .. i, "<cmd>BufferLineGoToBuffer " .. i .. "<cr>", { 
		desc = "Go to buffer " .. i, 
		silent = true 
	})
end
keymap.set("n", "<leader>$", "<cmd>BufferLineGoToBuffer -1<cr>", { 
	desc = "Go to last buffer", 
	silent = true 
})
