return {
  -- ══════════════════════════════════════════════════════════
  --  bufferline.nvim  ·  tokyonight  ·  underline style
  -- ══════════════════════════════════════════════════════════
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "folke/tokyonight.nvim",
    },
    event = "VeryLazy",

    opts = function()
      -- ┌─ tokyonight palette ──────────────────────────────┐
      local tn_ok, tn = pcall(require, "tokyonight.colors")
      local p = tn_ok and tn.setup({ style = "storm" }) or {}

      local bg      = p.bg      or "#1e1e2e"
      local bg_dark = p.bg_dark or "#1e1e2e"
      local fg      = p.fg      or "#c0caf5"
      local fg_dark = p.fg_dark or "#a9b1d6"
      local blue    = p.blue    or "#7aa2f7"
      local cyan    = p.cyan    or "#7dcfff"
      local red     = p.red     or "#f7768e"
      local orange  = p.orange  or "#ff9e64"
      local yellow  = p.yellow  or "#e0af68"
      local green   = p.green   or "#9ece6a"
      local comment = p.comment or "#565f89"
      local border  = p.border  or "#29a4bd"

      -- ┌─ highlights ──────────────────────────────────────┐
      -- All tabs share the same bg — active tab is shown
      -- only via a blue underline (sp). No bg/fg colour shift.
      local highlights = {
        fill = {
          fg = comment,
          bg = bg_dark,
        },

        -- ── inactive ──────────────────────────────────────
        background = {
          fg = comment,
          bg = bg,
        },
        tab = {
          fg = comment,
          bg = bg_dark,
        },
        tab_close = {
          fg = red,
          bg = bg_dark,
        },
        close_button = {
          fg = comment,
          bg = bg,
        },
        close_button_visible = {
          fg = comment,
          bg = bg,
        },
        separator = {
          fg = bg_dark,
          bg = bg,
        },
        duplicate = {
          fg = comment,
          bg = bg,
          italic = true,
        },
        modified = {
          fg = orange,
          bg = bg,
        },
        diagnostic        = { fg = comment, bg = bg },
        hint              = { fg = comment, bg = bg },
        hint_diagnostic   = { fg = comment, bg = bg },
        info              = { fg = comment, bg = bg },
        info_diagnostic   = { fg = comment, bg = bg },
        warning           = { fg = yellow,  bg = bg },
        warning_diagnostic= { fg = yellow,  bg = bg },
        error             = { fg = red,     bg = bg },
        error_diagnostic  = { fg = red,     bg = bg },

        -- ── visible (split open, not focused) ─────────────
        buffer_visible          = { fg = comment, bg = bg },
        separator_visible       = { fg = bg_dark, bg = bg },
        duplicate_visible       = { fg = comment, bg = bg, italic = true },
        modified_visible        = { fg = orange,  bg = bg },
        diagnostic_visible      = { fg = comment, bg = bg },
        hint_visible            = { fg = comment, bg = bg },
        hint_diagnostic_visible = { fg = comment, bg = bg },
        info_visible            = { fg = comment, bg = bg },
        info_diagnostic_visible = { fg = comment, bg = bg },
        warning_visible         = { fg = yellow,  bg = bg },
        warning_diagnostic_visible = { fg = yellow, bg = bg },
        error_visible           = { fg = red,     bg = bg },
        error_diagnostic_visible= { fg = red,     bg = bg },

        -- ── selected / active  ────────────────────────────
        -- bg stays the same; underline (sp = blue) is the
        -- only visual cue for the active buffer.
        buffer_selected = {
          fg = fg,
          bg = bg,
          bold = true,
          underline = true,
          sp = blue,
        },
        -- hide the left-edge icon; underline does the job
        indicator_selected = {
          fg = bg,
          bg = bg,
          underline = true,
          sp = blue,
        },
        separator_selected = {
          fg = bg_dark,
          bg = bg,
          underline = true,
          sp = blue,
        },
        close_button_selected = {
          fg = red,
          bg = bg,
          underline = true,
          sp = blue,
        },
        duplicate_selected = {
          fg = comment,
          bg = bg,
          italic = true,
          underline = true,
          sp = blue,
        },
        modified_selected = {
          fg = orange,
          bg = bg,
          underline = true,
          sp = blue,
        },
        diagnostic_selected       = { fg = fg_dark, bg = bg, underline = true, sp = blue },
        hint_selected             = { fg = cyan,    bg = bg, underline = true, sp = blue },
        hint_diagnostic_selected  = { fg = cyan,    bg = bg, underline = true, sp = blue },
        info_selected             = { fg = fg_dark, bg = bg, underline = true, sp = blue },
        info_diagnostic_selected  = { fg = fg_dark, bg = bg, underline = true, sp = blue },
        warning_selected          = { fg = yellow,  bg = bg, underline = true, sp = blue },
        warning_diagnostic_selected={ fg = yellow,  bg = bg, underline = true, sp = blue },
        error_selected            = { fg = red,     bg = bg, underline = true, sp = blue },
        error_diagnostic_selected = { fg = red,     bg = bg, underline = true, sp = blue },

        -- ── pick mode ──────────────────────────────────────
        pick_selected = { fg = green, bg = bg, bold = true, italic = true, underline = true, sp = blue },
        pick_visible  = { fg = green, bg = bg, italic = true },
        pick          = { fg = green, bg = bg_dark, italic = true },

        -- ── misc ───────────────────────────────────────────
        offset_separator = { fg = border,  bg = bg_dark },
        trunc_marker     = { fg = comment, bg = bg_dark },
      }

      -- ┌─ main config ─────────────────────────────────────┐
      return {
        options = {
          mode = "buffers",
          style_preset = require("bufferline").style_preset.default,
          themable = true,
          numbers = "none",              -- no numbers
          close_command = "bdelete! %d",
          right_mouse_command = "vertical sbuffer %d",
          left_mouse_command = "buffer %d",
          middle_mouse_command = nil,
          indicator = {
            style = "none",              -- no left-edge icon; underline via highlights only
          },
          buffer_close_icon = "󰅖",
          modified_icon = "●",
          close_icon = "",
          left_trunc_marker = "",
          right_trunc_marker = "",
          max_name_length = 30,
          max_prefix_length = 15,
          truncate_names = true,
          tab_size = 20,
          diagnostics = "nvim_lsp",
          diagnostics_update_in_insert = false,
          diagnostics_indicator = function(count, level)
            local icons = {
              error   = " ",
              warning = " ",
              hint    = " ",
              info    = " ",
            }
            return (icons[level] or "") .. count
          end,
          offsets = {
            {
              filetype   = "NvimTree",
              text       = "  File Explorer",
              text_align = "left",
              separator  = true,
            },
            {
              filetype   = "neo-tree",
              text       = "  Neo-tree",
              text_align = "left",
              separator  = true,
            },
          },
          color_icons          = true,
          show_buffer_icons    = true,
          show_buffer_close_icons = true,
          show_close_icon      = true,
          show_tab_indicators  = true,
          show_duplicate_prefix= true,
          persist_buffer_sort  = true,
          move_wraps_at_ends   = false,
          separator_style      = "thin",
          enforce_regular_tabs = false,
          always_show_bufferline = true,
          hover = {
            enabled = true,
            delay   = 150,
            reveal  = { "close" },
          },
          sort_by = "insert_after_current",
        },

        highlights = highlights,
      }
    end,
  },
}
