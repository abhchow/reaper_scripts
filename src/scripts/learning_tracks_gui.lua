local learning_tracks = dofile(reaper.GetResourcePath().."/Scripts/src/commands/learning_tracks.lua")

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Button.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

GUI.name = "Export Learning Tracks"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 360, 440
GUI.anchor, GUI.corner = "mouse", "C"

GUI.New("Options", "Checklist", {
    z = 11,
    x = 48,
    y = 48,
    w = 256,
    h = 168,
    caption = "Options",
    optarray = {"Export Full Mix", "Export Individual Parts", "Export Part Panned Tracks", "Export Part Predominant Tracks", "Export Part Missing Tracks", "Cancel Exports After Failure"},
    dir = "v",
    pad = 4,
    font_a = 2,
    font_b = 3,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = nil,
    opt_size = 20
})


GUI.New("Panned Part Volume", "Slider", {
    z = 11,
    x = 64,
    y = 256,
    w = 96,
    caption = "Panned Part Volume",
    min = 1,
    max = 20,
    defaults = {10},
    inc = 0.1,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0
})


GUI.New("Panned Part Position", "Slider", {
    z = 11,
    x = 64,
    y = 320,
    w = 96,
    caption = "Panned Part Position",
    min = -1,
    max = 1,
    defaults = {0},
    inc = 0.05,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0
})


GUI.New("Predominant Part Volume", "Slider", {
    z = 11,
    x = 208,
    y = 256,
    w = 96,
    caption = "Predominant Part Volume",
    min = 1,
    max = 20,
    defaults = {20},
    inc = 0.1,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0
})


GUI.New("Full Mix Width", "Slider", {
    z = 11,
    x = 208,
    y = 320,
    w = 96,
    caption = "Full Mix Width",
    min = 0,
    max = 1,
    defaults = {12},
    inc = 0.05,
    dir = "h",
    font_a = 3,
    font_b = 4,
    col_txt = "txt",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0
})


GUI.New("Save Settings", "Button", {
    z = 11,
    x = 64,
    y = 368,
    w = 96,
    h = 24,
    caption = "Save Settings",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame"
})


GUI.New("Export Tracks", "Button", {
    z = 11,
    x = 208,
    y = 368,
    w = 96,
    h = 24,
    caption = "Export Tracks",
    font = 3,
    col_txt = "txt",
    col_fill = "elm_frame",
    func=learning_tracks.main
})


GUI.Init()
GUI.Main()
