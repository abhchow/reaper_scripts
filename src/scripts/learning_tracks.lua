dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local pan = dofile(reaper.GetResourcePath().."/Scripts/src/utils/pan.lua")
local arr_utils = dofile(reaper.GetResourcePath().."/Scripts/src/utils/arr_utils.lua")
local daw_state = dofile(reaper.GetResourcePath().."/Scripts/src/utils/daw_state.lua")

-- Functions for exporting each configuration of learning tracks
function part_only_singles(n, project_name, path, original_volumes, part_number, track_name, file_number)
  if track_name == nil then
    local retval
    local track = reaper.GetTrack(0, part_number)
    retval, track_name = reaper.GetTrackName(track)
  end
  
  local volumes = arr_utils.get_filled_array(n, 0)
  if type(part_number) == "table" then
    for i = 1, #part_number do
      volumes[part_number[i]+1] = original_volumes[part_number[i]+1]
    end
  else
    volumes[part_number+1] = original_volumes[part_number+1]
  end
  
  local zeros = arr_utils.get_filled_array(n, 0)
  daw_state.set_pans(zeros)
  daw_state.set_volumes(volumes)
  
  export_track(project_name, track_name, path, file_number)

  daw_state.set_pans(zeros)
  daw_state.set_volumes(original_volumes)

  if file_number == nil then
    return nil
  else
    return file_number + 1
  end
end


function part_predominant_panned_singles(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, track_name, file_number)
  if track_name == nil then
    local retval
    local track = reaper.GetTrack(0, part_number)
    retval, track_name = reaper.GetTrackName(track)
  end
  return part_predominant_singles(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, track_name .. " Panned", file_number)
end


function part_predominant_mono_singles(n, project_name, path, volume_diff, original_volumes, part_number, track_name, file_number)
  if track_name == nil then
    local retval
    local track = reaper.GetTrack(0, part_number)
    retval, track_name = reaper.GetTrackName(track)
  end
  return part_predominant_singles(n, project_name, path, 0, volume_diff, original_volumes, part_number, track_name .. " Predominant", file_number)
end


function part_predominant_singles(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, track_name, file_number)
  -- do not use directly, use part_predominant_panned_singles or part_predominant_mono_singles instead
  
  local volumes = arr_utils.copy_table(original_volumes)

  pans = arr_utils.get_filled_array(n, -pan_position)
  if type(part_number) == "table" then
    for i = 1, #part_number do
      pans[part_number[i]+1] = pan_position
    end
    for i = 1, n do
      if not arr_utils.has_value(part_number, i-1) then
        volumes[i] = original_volumes[i]/volume_diff
      end
    end
  else
    pans[part_number+1] = pan_position
    for i = 1, n do
      if not (i-1 == part_number) then
        volumes[i] = original_volumes[i]/volume_diff
      end
    end
  end

  daw_state.set_pans(pans)
  daw_state.set_volumes(volumes)

  export_track(project_name, track_name, path, file_number)

  local zeros = arr_utils.get_filled_array(n, 0)
  daw_state.set_pans(zeros)
  daw_state.set_volumes(original_volumes)

  if file_number == nil then
    return nil
  else
    return file_number + 1
  end
end


function part_missing_singles(n, project_name, path, pans, original_volumes, part_number, file_number)
  local part_exists = arr_utils.get_filled_array(n, 1)
  part_exists[part_number+1] = 0

  local track = reaper.GetTrack(0, part_number)
  local retval, track_name = reaper.GetTrackName(track)

  return full_mix_singles(n, project_name, path, pans, original_volumes, part_exists, track_name .. " Missing", file_number)
end


function full_mix_singles(n, project_name, path, pans, original_volumes, part_exists, track_name, file_number)
  local volumes = arr_utils.get_filled_array(n, 0)

  for i=1, #volumes do
    volumes[i] = original_volumes[i]*part_exists[i]
  end

  daw_state.set_pans(pans)
  daw_state.set_volumes(volumes)

  export_track(project_name, track_name, path, file_number)

  local zeros = arr_utils.get_filled_array(n, 0)
  daw_state.set_pans(zeros)
  daw_state.set_volumes(original_volumes)

  if file_number == nil then
    return nil
  else
    return file_number + 1
  end
end


function export_track(project_name, track_name, path, file_number)
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
end


function export_all(n, project_name, path, export_parts_only, vp, hard_pan_volume, predominant_volume, original_volumes)
  local top_track = reaper.GetTrack(0,0)
  local retval, top_track_name = reaper.GetTrackName(top_track)
  local positions = pan.get_positions(n, top_track_name, vp)
  local pans = pan.positions_to_pans(positions, 0.6) -- overwrite this to customise
  local file_number = 1

  file_number = full_mix_singles(n, project_name, path, pans, original_volumes, arr_utils.get_filled_array(n, 1), "Full mix", file_number)

  for part_number=0, n-1, 1 do
    file_number = part_only_singles(n, project_name, path, original_volumes, part_number, nil, file_number)
    file_number = part_predominant_panned_singles(n, project_name, path, -1, hard_pan_volume, original_volumes, part_number, nil, file_number) -- hard panned
    file_number = part_predominant_mono_singles(n, project_name, path, predominant_volume, original_volumes, part_number, nil, file_number) -- mono predominant
    file_number = part_missing_singles(n, project_name, path, pans, original_volumes, part_number, file_number)
  end
  
  if vp then
    file_number = part_only_singles(n, project_name, path, original_volumes, {n-1, n-2}, "Rhythm", file_number)
    file_number = part_predominant_panned_singles(n, project_name, path, -1, hard_pan_volume, original_volumes, {n-1, n-2}, "Rhythm", file_number)
    file_number = part_predominant_mono_singles(n, project_name, path, predominant_volume, original_volumes, {n-1, n-2}, "Rhythm", file_number)
  end
end


function main()
  local export_parts_only = true
  local n = reaper.GetNumTracks()
  local project_name_ext = reaper.GetProjectName()
  local project_name = string.sub(project_name_ext, 0, string.len(project_name_ext) - 4) -- stripping .rpp file extension
  local path = reaper.GetProjectPath() .. "\\Learning Track Exports\\"

  local bottom_track = reaper.GetTrack(0,n-1)
  local retval, bottom_track_name = reaper.GetTrackName(bottom_track)
  local second_bottom_track = reaper.GetTrack(0,n-2)
  local retval, second_bottom_track_name = reaper.GetTrackName(second_bottom_track)
  local vp = false
  local metronome = false
  if bottom_track_name == "Metronome" or bottom_track_name == "Click" then
    metronome = true
  end

  local hard_pan_position = -1
  local hard_pan_volume = 2
  local predominant_volume = 3

  local original_pans = daw_state.get_current_pans(n)
  local original_volumes = daw_state.get_current_volumes(n)
  arr_utils.print_array(original_pans, "Original pans")
  arr_utils.print_array(original_volumes, "Original volumes")

  if metronome then
    if second_bottom_track_name == "VP" then
      vp = true
    end
    reaper.SetMediaTrackInfo_Value(bottom_track, "D_PAN", 0); -- no need to set metronome volume because we never touch it elsewhere
    export_all(n-1, project_name, path, export_parts_only, vp, hard_pan_volume, predominant_volume, original_volumes)
  else
    if bottom_track_name == "VP" then
      vp = true
    end
    export_all(n, project_name, path, export_parts_only, vp, hard_pan_volume, predominant_volume, original_volumes)
  end

  daw_state.set_pans(original_pans)
  daw_state.set_volumes(original_volumes)
end

main()

