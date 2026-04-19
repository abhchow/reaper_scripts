dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

local export = {}

function export.export_track(project_name, track_name, path, file_number)
  local export_file_name = project_name .. " - " .. track_name .. ".mp3"
  local retval = ultraschall.SetProject_RenderFilename(nil, path .. export_file_name)
  local render_cfg_string = ultraschall.CreateRenderCFG_MP3MaxQuality()
  
  local export_file_name = project_name .. " - " .. track_name .. ".mp3"

  local export_file_name_with_number = ""
  if not (file_number == nil) then
    export_file_name_with_number = file_number .. ". " .. export_file_name
  end

  local retval, renderfilecount, MediaItemStateChunkArray, Filearray
    = ultraschall.RenderProject(nil, path .. export_file_name_with_number, 0, -1, false, false, false, render_cfg_string, nil)
    
  local displayMessage
  if retval == 0 then
    displayMessage = "Successfully exported " .. path .. export_file_name_with_number .. "\n"
  else
    displayMessage = "Failed to export " .. path .. export_file_name_with_number .. "\n"
  end
  reaper.ShowConsoleMsg(displayMessage .. "\n")

  return retval == 0
end

return export
