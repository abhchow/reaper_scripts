dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

-- functions that should really be built into lua
function print_array(arr)
  reaper.ShowConsoleMsg("Array values: ")
  for i = 1, #arr do
    reaper.ShowConsoleMsg(arr[i] .. " ")
  end
  reaper.ShowConsoleMsg("\n")
end


function copy_table(table)
  local new_table = {}
  for i = 1, #table do
    new_table[i] = table[i]
  end
  return new_table
end


function has_value(table, val)
  for index, value in ipairs(table) do
    if value == val then
        return true
    end
  end

  return false
end


function get_filled_array(n, value)
  local arr = {}
  for i = 0, n-1, 1 do
    arr[i+1] = value
  end
  return arr
end


-- Functions for exporting each configuration of learning tracks
function part_only_singles(n, project_name, path, original_volumes, part_number, track_name)
  local zeros = get_filled_array(n, 0)
  set_pans(zeros)

  if track_name == nil then
    local retval
    local track = reaper.GetTrack(0, part_number)
    retval, track_name = reaper.GetTrackName(track)
  end

  local volumes = get_filled_array(n, 0)
  if type(part_number) == "table" then
    for i = 1, #part_number do
      volumes[part_number[i]+1] = original_volumes[part_number[i]+1]
    end
  else
    volumes[part_number+1] = original_volumes[part_number+1]
  end
  set_volumes(volumes)

  local export_file_name = "\\" .. project_name .. " - " .. track_name .. ".mp3"
  export_track(export_file_name, path)

  reaper.ShowConsoleMsg("\n")

  set_volumes(original_volumes)
  set_pans(zeros)
end


function part_predominant_panned_singles(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, track_name)
  if track_name == nil then
    local retval
    local track = reaper.GetTrack(0, part_number)
    retval, track_name = reaper.GetTrackName(track)
  end
  part_predominant_singles(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, track_name .. " Panned")
end


function part_predominant_mono_singles(n, project_name, path, volume_diff, original_volumes, part_number, track_name)
  if track_name == nil then
    local retval
    local track = reaper.GetTrack(0, part_number)
    retval, track_name = reaper.GetTrackName(track)
  end
  part_predominant_singles(n, project_name, path, 0, volume_diff, original_volumes, part_number, track_name .. " Predominant")
end

function part_predominant_singles(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, track_name)
  -- do not use directly, use part_predominant_panned_singles or part_predominant_mono_singles instead
  local volumes = copy_table(original_volumes)

  pans = get_filled_array(n, -pan_position)
  if type(part_number) == "table" then
    for i = 1, #part_number do
      pans[part_number[i]+1] = pan_position
    end
    for i = 1, n do
      if not has_value(part_number, i-1) then
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




  set_volumes(volumes)
  set_pans(pans)

  local export_file_name = "\\" .. project_name .. " - " .. track_name .. ".mp3"
  export_track(export_file_name, path)

  reaper.ShowConsoleMsg("\n")

  set_volumes(original_volumes)
  local zeros = get_filled_array(n, 0)
  set_pans(zeros)
end


function part_missing_singles(n, project_name, path, pans, original_volumes, part_number)
  local part_exists = get_filled_array(n, 1)
  part_exists[part_number+1] = 0

  local track = reaper.GetTrack(0, part_number)
  local retval, track_name = reaper.GetTrackName(track)

  full_mix_singles(n, project_name, path, pans, original_volumes, part_exists, track_name .. " Missing")
end


function full_mix_singles(n, project_name, path, pans, original_volumes, part_exists, track_name)
  local volumes = get_filled_array(n, 0)
  
  for i=1, #volumes do
    volumes[i] = original_volumes[i]*part_exists[i]
  end

  set_volumes(volumes)
  set_pans(pans)

  local export_file_name = "\\" .. project_name .. " - " .. track_name .. ".mp3"
  export_track(export_file_name, path)

  reaper.ShowConsoleMsg("\n")

  set_volumes(original_volumes)
  local zeros = get_filled_array(n, 0)
  set_pans(zeros)
end


function part_missing_all(n, project_name, path, pans, original_volumes)
  for i = 0, n-1, 1 do
    part_missing_singles(n, project_name, path, pans, original_volumes, i)
  end
end


-- Helper functions for exporting learning tracks
function get_positions(n, top_track_name, vp)
  -- Full mix
    -- Pan in a way that makes sure adjacent parts are separate (except for barbershop)
    -- For 6 part SATBB+VP: Alto, Bass, Tenor/VP, Sop, Bari
    -- For 5 part SATB+VP: Alto, Bass, VP, Sop, Tenor
    -- For 5 part SATBB: Alto, Bass, Tenor, Sop, Bari
    -- For 4 part SATB: Alto, Bass, Sop, Tenor
    -- For barbershop: Bari, Bass, Lead, Tenor
    -- For 3 part (assuming SAT): Tenor, Sop, Alto
    -- For 2 part: Alto, Sop
  local pans

  if n == 6 then
    reaper.ShowConsoleMsg("Panning arrangement: 6 part SATBB+VP\n\n")
    pans = {4,1,3,5,2,3}
  elseif n == 5 then
    if vp then
      reaper.ShowConsoleMsg("Panning arrangement: 5 part SATB+VP\n\n")
      pans = {4,1,5,2,3}
    else
      reaper.ShowConsoleMsg("Panning arrangement: 5 part SATBB\n\n")
      pans = {4,1,3,5,2}
    end
  elseif n == 4 then
    if top_track_name == "Tenor" then --barbershop
      reaper.ShowConsoleMsg("Panning arrangement: 4 part barbershop\n\n")
      pans = {4,3,1,2}
    else
      reaper.ShowConsoleMsg("Panning arrangement: 4 part SATB\n\n")
      pans = {3,1,4,2}
    end
  elseif n == 3 then
    reaper.ShowConsoleMsg("Panning arrangement: 3 part\n\n")
    pans = {3,1,2}
  elseif n == 2 then
    reaper.ShowConsoleMsg("Panning arrangement: 2 part\n\n")
    pans = {2,1}
  else
    for i = 1, n do
      pans[i] = 0
    end
  end

  return pans
end


function positions_to_pans(positions, width)
  -- width is a minimum of 0 (mono) and a maximum of 1 (furthest parts are hard panned)

  local pans = {}

  local positions_max = math.max(table.unpack(positions))
  local positions_min = math.min(table.unpack(positions))
  local diff = positions_max - positions_min

  for i = 1, #positions do
    pans[i] = ((positions[i] - positions_min) / diff * 2 - 1) * width
  end

  return pans  
end


function export_track(export_file_name, path)
  local retval = ultraschall.SetProject_RenderFilename(nil, path .. export_file_name)
  local render_cfg_string = ultraschall.CreateRenderCFG_MP3MaxQuality()
  
  local retval, renderfilecount, MediaItemStateChunkArray, Filearray
    = ultraschall.RenderProject(nil, path .. export_file_name, 0, -1, false, false, false, render_cfg_string, nil)
    
  local displayMessage
  if retval == 0 then
    displayMessage = "Successfully exported " .. path .. export_file_name .. "\n"
  else
    displayMessage = "Failed to export " .. path .. export_file_name .. "\n"
  end
  reaper.ShowConsoleMsg(displayMessage)
end


function export_all(n, project_name, path, second_bottom_track, export_parts_only, vp, hard_pan_position, hard_pan_volume, original_volumes)
  local top_track = reaper.GetTrack(0,0)
  local retval, top_track_name = reaper.GetTrackName(top_track)
  local positions = get_positions(n, top_track_name, vp)
  local pans = positions_to_pans(positions, 0.6) -- overwrite this to customise

  -- for i = 0, n-1, 1 do
  --   -- part_only_singles(n, project_name, path, original_volumes, i)
  --   -- part_missing_singles(n, project_name, path, pans, original_volumes, i)
  --   -- part_panned_singles(n, project_name, path, hard_pan_position, hard_pan_volume, original_volumes, i)
  -- end

  -- if export_parts_only then
  --   parts_only(n, project_name, path, original_volumes)
  -- end
  -- panned_learning_tracks(n, project_name, path, hard_pan_position, hard_pan_volume, original_volumes)
  -- part_missing_learning_tracks(n, project_name, path, pans, original_volumes)
  -- if vp then
  --   rhythm_learning_tracks(n, project_name, path, original_volumes)
  -- end
  -- full_mix_learning_track(n, project_name, path, pans, original_volumes, 0.7)

    for part_number=0, n-1, 1 do
      -- part_only_singles(n, project_name, path, original_volumes, part_number)
      -- part_predominant_panned_singles(n, project_name, path, -1, 2, original_volumes, part_number) -- hard panned
      part_predominant_mono_singles(n, project_name, path, 3, original_volumes, part_number) -- mono predominant
      -- part_missing_singles(n, project_name, path, pans, original_volumes, part_number)
    end
    
    -- part_only_singles(n, project_name, path, original_volumes, {4,5}, "Rhythm")
    -- part_predominant_panned_singles(n, project_name, path, -1, 2, original_volumes, {4,5}, "Rhythm")
    part_predominant_mono_singles(n, project_name, path, 2, original_volumes, {4,5}, "Rhythm")

    -- full_mix_singles(n, project_name, path, pans, original_volumes, get_filled_array(n, 1), "Full mix")
end




function get_current_pans(n)
  -- read pans of all parts and store them
  local pans = {}
  for i = 0, n-1, 1 do
    local track = reaper.GetTrack(0, i)
    pans[i+1] = reaper.GetMediaTrackInfo_Value(track, "D_PAN")
  end
  return pans
end


function set_pans(pans)
  -- set pans of all parts
  for i = 0, #pans-1 do
    local track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", pans[i+1])
  end
end


function get_current_volumes(n)
  -- read volumes of all parts and store them
  local volumes = {}
  for i = 0, n-1, 1 do
    local track = reaper.GetTrack(0, i)
    volumes[i+1] = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
  end
  return volumes
end


function set_volumes(volumes)
  -- set volumes of all parts
  for i = 0, #volumes-1 do
    local track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", volumes[i+1])
  end
end



function main()
  local export_parts_only = true
  local n = reaper.GetNumTracks()
  local project_name_ext = reaper.GetProjectName()
  local project_name = string.sub(project_name_ext, 0, string.len(project_name_ext) - 4) -- stripping .rpp file extension
  local path = reaper.GetProjectPath() .. "\\Learning Track Exports"

  local bottom_track = reaper.GetTrack(0,n-1)
  local retval, bottom_track_name = reaper.GetTrackName(bottom_track)
  local second_bottom_track = reaper.GetTrack(0,n-2)
  local retval, second_bottom_track_name = reaper.GetTrackName(second_bottom_track)
  local vp = false
  local hard_pan_position = -1
  local hard_pan_volume = 2

  local original_pans = get_current_pans(n)
  local original_volumes = get_current_volumes(n)
  reaper.ShowConsoleMsg("Original pans: ") 
  for i = 1, n do
    reaper.ShowConsoleMsg(original_pans[i] .. " ")
  end
  reaper.ShowConsoleMsg("\n")
  reaper.ShowConsoleMsg("Original volumes: ")
  for i = 1, n do
    reaper.ShowConsoleMsg(original_volumes[i] .. " ")
  end
  reaper.ShowConsoleMsg("\n")

  if bottom_track_name == "Metronome" or bottom_track_name == "Click" then
    if second_bottom_track_name == "VP" then
      vp = true
    end
    reaper.SetMediaTrackInfo_Value(bottom_track, "D_PAN", 0); -- no need to set metronome volume because we never touch it elsewhere
    export_all(n-1, project_name, path, second_bottom_track, export_parts_only, vp, hard_pan_position, hard_pan_volume, original_volumes)
  else
    if bottom_track_name == "VP" then
      vp = true
    end
    export_all(n, project_name, path, second_bottom_track, export_parts_only, vp, hard_pan_position, hard_pan_volume, original_volumes)
  end

  set_pans(original_pans)
  set_volumes(original_volumes)
end

main()

--  TODO: Change export_track to export to a lower quality mp3
--  TODO: Clean up the README, make sure all features are documented, make it easy to read for someone who doesn't know programming
--  TODO: Clean up the code and refactor things
--    TODO: Check for places to use set_pans and set_volumes
--    TODO: Put all of the customisable values in one spot
--  TODO: Add optional numbers to the start of the file names
--    TODO: Refactoring the code to export all the tracks for each part might make this easier, and help with custom combinations
--  TODO: Detect clipping in export, delete the clipped track and re-export at a lower volume
--  TODO: Build a GUI to turn this into a rehearsal tool
--    TODO: Options to select a custom panning arrangement for full mix and part missing tracks
--    TODO: Options to select custom combinations of different parts present, not just Bass and VP
--      TODO: Refactoring the code to export all the tracks for each part might make this easier
--            ie, export all  tracks for Sop, then all tracks for Alto etc, then all combinations, Bass+VP, plus whatever else is custom defined
