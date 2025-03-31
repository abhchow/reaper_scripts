dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

function parts_only(n, project_name, path, volume, original_volumes)
  zeros = get_zeros(n)
  set_pans(zeros)

  for i = 0, n-1, 1 do
    set_volumes(get_zeros(n))
    track = reaper.GetTrack(0, i)
    retval, track_name = reaper.GetTrackName(track)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", volume*original_volumes[i+1]);
    
    export_file_name = "\\" .. project_name .. " - " .. track_name .. ".mp3"
    export_track(export_file_name, path)
  end
  reaper.ShowConsoleMsg("\n")
end


function panned_learning_tracks(n, project_name, path, part_position, volume_diff, original_volumes)
  -- part position should be either -1 (left) or 1 (right)

  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    retval, track_name = reaper.GetTrackName(track)
    
    for j = 0, n-1, 1 do
      track = reaper.GetTrack(0, j)
      
      if i == j then -- double volume and hard pan target track
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", volume_diff*original_volumes[j+1]);
        reaper.SetMediaTrackInfo_Value(track, "D_PAN", part_position);
      else -- reset volume and hard pan in the other direction for all other tracks
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", original_volumes[j+1]);
        reaper.SetMediaTrackInfo_Value(track, "D_PAN", -part_position);
      end
    end
    
    export_file_name = "\\" .. project_name .. " - " .. track_name .. " Panned.mp3"
    export_track(export_file_name, path)
  end
  reaper.ShowConsoleMsg("\n")
end


function part_missing_learning_tracks(n, project_name, path, pans, original_volumes)
  set_pans(pans)
  set_volumes(original_volumes)

  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    retval, track_name = reaper.GetTrackName(track)
    
    set_volumes(original_volumes)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", 0);
    
    export_file_name = "\\" .. project_name .. " - " .. track_name .. " Missing.mp3"
    export_track(export_file_name, path)
  end
  reaper.ShowConsoleMsg("\n")
end


function rhythm_learning_tracks(n, project_name, path, original_volumes)
  -- vp is n-1
  -- bass is n-2
  bass_track = reaper.GetTrack(0,n-2)
  vp_track = reaper.GetTrack(0,n-1)
  retval, bt_name = reaper.GetTrackName(bass_track)
  retval, vpt_name = reaper.GetTrackName(vp_track)
  
  -- rhythm only track
  reaper.SetMediaTrackInfo_Value(bass_track, "D_VOL", original_volumes[n-1]);
  reaper.SetMediaTrackInfo_Value(vp_track, "D_VOL", original_volumes[n]);
  reaper.SetMediaTrackInfo_Value(bass_track, "D_PAN", 0);
  reaper.SetMediaTrackInfo_Value(vp_track, "D_PAN", 0);
  for i = 0, n-3, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", 0);
  end
  
  export_file_name = "\\" .. project_name .. " - Rhythm.mp3"
  retval = ultraschall.SetProject_RenderFilename(nil, path .. export_file_name)
  render_cfg_string = ultraschall.CreateRenderCFG_MP3MaxQuality()
  
  retval, renderfilecount, MediaItemStateChunkArray, Filearray
    = ultraschall.RenderProject(nil, path .. export_file_name, 0, -1, false, false, false, render_cfg_string, nil)
    
  if retval == 0 then
    displayMessage = "Successfully exported " .. path .. export_file_name .. "\n"
  else
    displayMessage = "Failed to export " .. path .. export_file_name .. "\n"
  end
  reaper.ShowConsoleMsg(displayMessage)

  -- rhythm panned
  reaper.SetMediaTrackInfo_Value(bass_track, "D_VOL", 1.5*original_volumes[n-1]);
  reaper.SetMediaTrackInfo_Value(vp_track, "D_VOL", 1.5*original_volumes[n]);
  reaper.SetMediaTrackInfo_Value(bass_track, "D_PAN", -1);
  reaper.SetMediaTrackInfo_Value(vp_track, "D_PAN", -1);
  for i = 0, n-3, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", original_volumes[i+1]);
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", 1);
  end
  
  export_file_name = "\\" .. project_name .. " - Rhythm Panned.mp3"
  export_track(export_file_name, path)
  reaper.ShowConsoleMsg("\n")
end


function full_mix_learning_track(n, project_name, path, pans, original_volumes)
  set_pans(pans)
  set_volumes(original_volumes)
  
  export_file_name = "\\" .. project_name .. " - Full Mix.mp3"
  export_track(export_file_name, path)
  reaper.ShowConsoleMsg("\n")
end


function get_positions(n, top_track_name, vp)
  -- Full mix
    -- Pan in a way that makes sure adjacent parts are separate (except for barbershop)
    -- For 6 part SATBB+VP: Alto, Bass, Tenor/VP, Sop, Bari
    -- For 5 part SATB+VP: Alto, Bass, VP, Sop, Tenor
    -- For 5 part SATBB: Alto, Bass, Tenor, Sop, Bari
    -- For 4 part SATB: Alto, Bass, Sop, Tenor
    -- For barbershop: Bari, Bass, Lead, Tenor

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
  else
    for i = 1, n do
      pans[i] = 0
    end
  end

  return pans
end


function positions_to_pans(positions, width)
  -- width is a minimum of 0 (mono) and a maximum of 1 (furthest parts are hard panned)

  pans = {}

  positions_max = math.max(table.unpack(positions))
  positions_min = math.min(table.unpack(positions))
  diff = positions_max - positions_min

  for i = 1, #positions do
    pans[i] = ((positions[i] - positions_min) / diff * 2 - 1) * width
  end

  return pans  
end


function export_track(export_file_name, path)
  retval = ultraschall.SetProject_RenderFilename(nil, path .. export_file_name)
  render_cfg_string = ultraschall.CreateRenderCFG_MP3MaxQuality()
  
  retval, renderfilecount, MediaItemStateChunkArray, Filearray
    = ultraschall.RenderProject(nil, path .. export_file_name, 0, -1, false, false, false, render_cfg_string, nil)
    
  if retval == 0 then
    displayMessage = "Successfully exported " .. path .. export_file_name .. "\n"
  else
    displayMessage = "Failed to export " .. path .. export_file_name .. "\n"
  end
  reaper.ShowConsoleMsg(displayMessage)
end


function export_all(n, project_name, path, second_bottom_track, export_parts_only, vp, hard_pan_position, hard_pan_volume, original_volumes)
  top_track = reaper.GetTrack(0,0)
  retval, top_track_name = reaper.GetTrackName(top_track)
  positions = get_positions(n, top_track_name, vp)
  pans = positions_to_pans(positions, 0.6) -- overwrite this to customise

  if export_parts_only then
    parts_only(n, project_name, path, 2, original_volumes)
  end
  panned_learning_tracks(n, project_name, path, hard_pan_position, hard_pan_volume, original_volumes)
  part_missing_learning_tracks(n, project_name, path, pans, original_volumes)
  if vp then
    rhythm_learning_tracks(n, project_name, path, original_volumes)
  end
  full_mix_learning_track(n, project_name, path, pans, original_volumes)

end


function get_zeros(n)
  arr = {}
  for i = 0, n-1, 1 do
    arr[i+1] = 0
  end
  return arr
end


function get_pans(n)
  -- read pans of all parts and store them
  pans = {}
  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    pans[i+1] = reaper.GetMediaTrackInfo_Value(track, "D_PAN")
  end
  return pans
end


function set_pans(pans)
  -- set pans of all parts
  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", pans[i+1])
  end
end


function get_volumes(n)
  -- read volumes of all parts and store them
  volumes = {}
  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    volumes[i+1] = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
  end
  return volumes
end


function set_volumes(volumes)
  -- set volumes of all parts
  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", volumes[i+1])
  end
end


function print_volumes(volumes)
  reaper.ShowConsoleMsg("Volumes: ")
  for i = 1, n do
    reaper.ShowConsoleMsg(volumes[i] .. " ")
  end
  reaper.ShowConsoleMsg("\n")
end


function main()
  export_parts_only = true
  n = reaper.GetNumTracks()
  project_name_ext = reaper.GetProjectName()
  project_name = string.sub(project_name_ext, 0, string.len(project_name_ext) - 4) -- stripping .rpp file extension
  path = reaper.GetProjectPath() .. "\\Learning Track Exports"

  bottom_track = reaper.GetTrack(0,n-1)
  retval, bottom_track_name = reaper.GetTrackName(bottom_track)
  second_bottom_track = reaper.GetTrack(0,n-2)
  retval, second_bottom_track_name = reaper.GetTrackName(second_bottom_track)
  vp = false
  hard_pan_position = -1
  hard_pan_volume = 2

  original_pans = get_pans(n)
  original_volumes = get_volumes(n)
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

--  TODO: Make sure all variables are local instead of global
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
