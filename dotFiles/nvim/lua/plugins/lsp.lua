-- ~/.config/nvim/lua/plugins/lsp.lua
-- Requires Neovim 0.11+ (uses vim.lsp.config / vim.lsp.enable)

-- Map: filetype -> { lsp servers, mason tools (formatters/linters) }
local ft_config = {
	lua = { servers = { "lua_ls" }, tools = { "stylua" } },
	python = { servers = { "pyright" }, tools = { "black", "isort", "flake8" } },
	javascript = { servers = { "ts_ls" }, tools = { "prettier", "eslint_d" } },
	typescript = { servers = { "ts_ls" }, tools = { "prettier", "eslint_d" } },
	javascriptreact = { servers = { "ts_ls" }, tools = { "prettier", "eslint_d" } },
	typescriptreact = { servers = { "ts_ls" }, tools = { "prettier", "eslint_d" } },
	go = { servers = { "gopls" }, tools = { "gofumpt", "golangci-lint" } },
	rust = { servers = { "rust_analyzer" }, tools = {} },
	c = { servers = { "clangd" }, tools = {} },
	cpp = { servers = { "clangd" }, tools = {} },
	sh = { servers = { "bashls" }, tools = { "shfmt" } },
	bash = { servers = { "bashls" }, tools = { "shfmt" } },
	json = { servers = { "jsonls" }, tools = { "prettier" } },
	yaml = { servers = { "yamlls" }, tools = { "prettier" } },
	toml = { servers = { "taplo" }, tools = {} },
	html = { servers = { "html" }, tools = { "prettier" } },
	css = { servers = { "cssls" }, tools = { "prettier" } },
	markdown = { servers = { "marksman" }, tools = { "prettier" } },
	dockerfile = { servers = { "dockerls" }, tools = {} },
	terraform = { servers = { "terraformls" }, tools = { "tflint" } },
	php = { servers = { "intelephense" }, tools = {} },
	ruby = { servers = { "ruby_lsp" }, tools = {} },
	java = { servers = { "jdtls" }, tools = {} },
	kotlin = { servers = { "kotlin_language_server" }, tools = {} },
	zig = { servers = { "zls" }, tools = {} },
	elixir = { servers = { "elixirls" }, tools = {} },
	haskell = { servers = { "hls" }, tools = {} },
	vue = { servers = { "volar" }, tools = { "prettier" } },
	svelte = { servers = { "svelte" }, tools = { "prettier" } },
	nix = { servers = { "nixd" }, tools = {} },
}

-- lspconfig server name -> mason package name (only where they differ)
local lsp_to_mason = {
	ts_ls = "typescript-language-server",
	lua_ls = "lua-language-server",
	bashls = "bash-language-server",
	jsonls = "json-lsp",
	yamlls = "yaml-language-server",
	html = "html-lsp",
	cssls = "css-lsp",
	dockerls = "dockerfile-language-server",
	terraformls = "terraform-ls",
	ruby_lsp = "ruby-lsp",
	kotlin_language_server = "kotlin-language-server",
	elixirls = "elixir-ls",
	hls = "haskell-language-server",
	volar = "vue-language-server",
	svelte = "svelte-language-server",
	rust_analyzer = "rust-analyzer",
}

local installed_fts = {}

-- Called after everything for a filetype is installed.
-- Uses the new native vim.lsp.config / vim.lsp.enable API (Nvim 0.11+).
local function enable_servers(ft)
	local cfg = ft_config[ft]
	if not cfg then
		return
	end

	for _, server in ipairs(cfg.servers) do
		-- vim.lsp.config() merges into whatever nvim-lspconfig already shipped
		-- in its lsp/<server>.lua; we only override what we need.
		vim.lsp.config(server, {
			-- Global capabilities are injected via the '*' wildcard below.
			-- Per-server overrides go here if needed.
		})
		vim.lsp.enable(server)
	end
end

local function ensure_ft(ft)
	if installed_fts[ft] then
		return
	end
	installed_fts[ft] = true

	local cfg = ft_config[ft]
	if not cfg then
		return
	end

	local registry = require("mason-registry")
	local to_install = {}

	for _, server in ipairs(cfg.servers) do
		local pkg = lsp_to_mason[server] or server
		if pkg and not registry.is_installed(pkg) then
			table.insert(to_install, pkg)
		end
	end

	for _, tool in ipairs(cfg.tools) do
		if not registry.is_installed(tool) then
			table.insert(to_install, tool)
		end
	end

	if #to_install == 0 then
		enable_servers(ft)
		return
	end

	vim.notify("[LSP] Installing: " .. table.concat(to_install, ", "), vim.log.levels.INFO)

	local remaining = #to_install
	for _, pkg_name in ipairs(to_install) do
		local ok, pkg = pcall(registry.get_package, pkg_name)
		if ok then
			pkg:install():once(
				"closed",
				vim.schedule_wrap(function()
					vim.notify("[LSP] ✓ " .. pkg_name, vim.log.levels.INFO)
					remaining = remaining - 1
					if remaining == 0 then
						enable_servers(ft)
					end
				end)
			)
		else
			vim.notify("[LSP] Unknown package: " .. pkg_name, vim.log.levels.WARN)
			remaining = remaining - 1
			if remaining == 0 then
				enable_servers(ft)
			end
		end
	end
end

return {
	-- Mason: installs binaries
	{
		"williamboman/mason.nvim",
		opts = {},
	},

	-- mason <-> lspconfig bridge (provides lsp/*.lua server definitions)
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = { automatic_installation = false },
	},

	-- nvim-lspconfig: only used for its bundled lsp/<server>.lua definitions,
	-- NOT for require('lspconfig')[server].setup() anymore.
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			-- Inject cmp capabilities globally so every server gets them.
			vim.lsp.config("*", {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
			})

			-- Keymaps on attach (fires for every server that connects)
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
					end
					map("gd", vim.lsp.buf.definition, "Go to Definition")
					map("gD", vim.lsp.buf.declaration, "Go to Declaration")
					map("gr", vim.lsp.buf.references, "Go to References")
					map("gi", vim.lsp.buf.implementation, "Go to Implementation")
					map("K", vim.lsp.buf.hover, "Hover Docs")
					map("<leader>rn", vim.lsp.buf.rename, "Rename")
					map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
					map("<leader>f", function()
						vim.lsp.buf.format({ async = true })
					end, "Format")
					map("[d", vim.diagnostic.goto_prev, "Prev Diagnostic")
					map("]d", vim.diagnostic.goto_next, "Next Diagnostic")
				end,
			})

			-- Diagnostics UI
			vim.diagnostic.config({
				virtual_text = true,
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = { border = "rounded", source = "always" },
			})

			-- Auto-install + enable on FileType
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				callback = function(args)
					vim.schedule(function()
						ensure_ft(args.match)
					end)
				end,
			})
		end,
	},

	-- Completion
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
			})
		end,
	},
}
