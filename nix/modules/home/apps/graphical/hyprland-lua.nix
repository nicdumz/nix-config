{ desktopshell }:
''
  hl.monitor({
      output   = "",
      mode     = "highres",
      position = "auto",
      scale    = 1.25,
  })

  local ipc = "noctalia-shell ipc call"

  hl.config({
      xwayland = {
          force_zero_scaling = true,
      },
  })

  hl.env("XCURSOR_SIZE",    "24")
  hl.env("HYPRCURSOR_SIZE", "24")

  hl.config({
      input = {
          kb_options   = "caps:super",
          follow_mouse = 1,
      },
  })

  -- https://wiki.hypr.land/Configuring/Variables/#general
  hl.config({
      general = {
          gaps_in     = 5,
          -- top,right,bottom,left
          gaps_out    = { 10,15,15,15 },
          border_size = 2,

          -- Catppuccin Mocha Colors
          -- blue to green
          col = {
              active_border   = { colors = { "rgba(89b4faee)", "rgba(a6e3a1ee)" }, angle = 45 },
              -- lavender
              inactive_border = "rgba(b4befeaa)",
          },

          resize_on_border = true,
          allow_tearing    = false,
          layout           = "dwindle",
      },
  })

  -- https://wiki.hypr.land/Configuring/Variables/#decoration
  hl.config({
      decoration = {
          rounding       = 10,
          rounding_power = 2,

          active_opacity   = 1.0,
          inactive_opacity = 1.0,

          shadow = {
              enabled      = true,
              range        = 8,
              render_power = 3,
              color        = "rgba(313244ee)",
          },

          blur = {
              enabled  = true,
              size     = 3,
              passes   = 1,
              vibrancy = 0.1696,
          },
      },
  })

  -- https://wiki.hypr.land/Configuring/Variables/#animations
  hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 }    } })
  hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 }    } })
  hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 }       } })
  hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 }    } })
  hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 }     } })

  hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default"       })
  hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint"  })
  hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint"  })
  hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint",  style = "popin 87%" })
  hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",        style = "popin 87%" })
  hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear"  })
  hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear"  })
  hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick"         })
  hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint"  })
  hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint",  style = "fade" })
  hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",        style = "fade" })
  hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear"  })
  hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear"  })
  hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick"         })
  hl.animation({ leaf = "workspaces",    enabled = true, speed = 2,    bezier = "default",       style = "slide" })

  -- https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
  hl.config({
      dwindle = {
          preserve_split = true,
      },
  })

  -- https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
  hl.config({
      master = {
          new_status = "master",
      },
  })

  hl.config({
      misc = {
          disable_hyprland_logo = true,
      },
  })

  -- Prevents the wallpaper/background layer from flickering during workspace changes
  hl.layer_rule({
      name        = "rofi-solid",
      ignore_alpha = 0,
      match       = { namespace = "rofi|rofi-theme-selector" },
  })
  hl.layer_rule({
      name    = "no-flickering",
      no_anim = true,
      match   = { namespace = "selection|overview|anylayer" },
  })

  local mod = "SUPER"

  hl.bind(mod .. " + C",       hl.dsp.window.close())
  hl.bind(mod .. " + RETURN",  hl.dsp.exec_cmd("kitty"))
  hl.bind(mod .. " + R",       hl.dsp.exec_cmd("rofi -show drun"))
  hl.bind(mod .. " + F",       hl.dsp.window.fullscreen({ type = "fullscreen" }))
  hl.bind(mod .. " + V",       hl.dsp.window.fullscreen({ type = "maximize" }))
  hl.bind(mod .. " + left",    hl.dsp.focus({ workspace = "e-1" }))
  hl.bind(mod .. " + right",   hl.dsp.focus({ workspace = "e+1" }))
  hl.bind(mod .. " + j",       hl.dsp.focus({ direction = "up" }))
  hl.bind(mod .. " + k",       hl.dsp.focus({ direction = "down" }))

  -- Switch workspaces and move windows with mainMod + [0-9]
  for i = 1, 10 do
      local key = i % 10
      hl.bind(mod .. " + "         .. key, hl.dsp.focus({ workspace = i }))
      hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
  end

  -- Scroll through workspaces with mainMod + scroll
  hl.bind(mod .. " + mouse_down",         hl.dsp.focus({ workspace = "e-1" }))
  hl.bind(mod .. " + mouse_up",           hl.dsp.focus({ workspace = "e+1" }))
  hl.bind(mod .. " + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e-1", silent = true }))
  hl.bind(mod .. " + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "e+1", silent = true }))

  hl.bind(mod .. " + TAB",         hl.dsp.focus({ urgent_or_last = true }))
  hl.bind(mod .. " + S",           hl.dsp.workspace.toggle_special())
  hl.bind(mod .. " + SHIFT + S",   hl.dsp.window.move({ workspace = "special" }))

  -- Move/resize windows with mainMod + LMB/RMB and dragging
  hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
  hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

  hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(ipc .. " launcher toggle"))
  hl.bind(mod .. " + comma", hl.dsp.exec_cmd(ipc .. " settings toggle"))

  -- Media keys
  hl.bind("XF86AudioRaiseVolume",   hl.dsp.exec_cmd(ipc .. " volume increase"),   { locked = true, repeating = true })
  hl.bind("XF86AudioLowerVolume",   hl.dsp.exec_cmd(ipc .. " volume decrease"),   { locked = true, repeating = true })
  hl.bind("XF86AudioMute",          hl.dsp.exec_cmd(ipc .. " volume muteOutput"), { locked = true })
  hl.bind("XF86MonBrightnessUp",    hl.dsp.exec_cmd(ipc .. " brightness increase"), { locked = true, repeating = true })
  hl.bind("XF86MonBrightnessDown",  hl.dsp.exec_cmd(ipc .. " brightness decrease"), { locked = true, repeating = true })

  hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))

  -- Dynamic per-machine config (must be a lua file, not hyprlang)
  pcall(dofile, os.getenv("HOME") .. "/.config/hypr/dynamic.lua")

  -- Google Meet popup
  hl.window_rule({
      match = { class = "^(google-chrome)$", initial_title = "^Meet - .*" },
      float = true,
      pin   = true,
      size  = "900 700",
      move  = "((monitor_w*1)-920) ((monitor_h*1)-720)",
  })

  -- Catppuccin Mocha: Red to Peach gradient for remote SSH connections in kitty
  hl.window_rule({
      match        = { class = "^(kitty)$", title = "^.*%[.*%].*" },
      border_color = { colors = { "rgb(f38ba8)", "rgb(fab387)" }, angle = 45 },
  })

  ${
    if desktopshell == "noctalia" then
      ''
        hl.on("hyprland.start", function()
            hl.exec_cmd("noctalia-shell")
        end)''
    else
      ""
  }
''
