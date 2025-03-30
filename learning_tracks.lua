dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")


function panned_learning_tracks(n, project_name, path)
  for i = 0, n-1, 1 do
    track_main = reaper.GetTrack(0, i)
    retval, track_name = reaper.GetTrackName(track_main)
    
    for j = 0, n-1, 1 do
      track = reaper.GetTrack(0, j)
      
      if i == j then -- double volume and hard pan left target track
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", 2);
        reaper.SetMediaTrackInfo_Value(track, "D_PAN", -1);
      else -- set volumes to 0dB and hard pan right all other tracks
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1);
        reaper.SetMediaTrackInfo_Value(track, "D_PAN", 1);
      end
    end
    
    export_file_name = "\\" .. project_name .. " - " .. track_name .. " Panned.mp3"
    export_track(export_file_name, path)
  end
  reaper.ShowConsoleMsg("\n")
end


function full_mix_learning_track(n, project_name, path, pans)
  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1);
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", pans[i+1]);
  end
  
  export_file_name = "\\" .. project_name .. " - Full Mix.mp3"
  export_track(export_file_name, path)
  reaper.ShowConsoleMsg("\n")
end


function part_missing_learning_tracks(n, project_name, path, pans)
  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1);
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", pans[i+1]);
  end

  for i = 0, n-1, 1 do
    track_main = reaper.GetTrack(0, i)
    retval, track_name = reaper.GetTrackName(track_main)
    
    for j = 0, n-1, 1 do
      track = reaper.GetTrack(0, j)
      
      if i == j then -- double volume and hard pan left target track
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", 0);
      else -- set volumes to 0dB and hard pan right all other tracks
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1);
      end
    end
    
    export_file_name = "\\" .. project_name .. " - " .. track_name .. " Missing.mp3"
    export_track(export_file_name, path)
  end
  reaper.ShowConsoleMsg("\n")
end


function parts_only(n, project_name, path)
  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", 0);
  end

  for i = 0, n-1, 1 do
    track_main = reaper.GetTrack(0, i)
    retval, track_name = reaper.GetTrackName(track_main)
    
    for j = 0, n-1, 1 do
      track = reaper.GetTrack(0, j)
      
      if i == j then 
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1);
      else
        reaper.SetMediaTrackInfo_Value(track, "D_VOL", 0);
      end
    end
    
    export_file_name = "\\" .. project_name .. " - " .. track_name .. ".mp3"
    export_track(export_file_name, path)
  end
  reaper.ShowConsoleMsg("\n")
end


function rhythm_learning_tracks(n, project_name, path)
  -- vp is n-1
  -- bass is n-2
  bass_track = reaper.GetTrack(0,n-2)
  vp_track = reaper.GetTrack(0,n-1)
  retval, bt_name = reaper.GetTrackName(bass_track)
  retval, vpt_name = reaper.GetTrackName(vp_track)
  
  -- rhythm only track
  reaper.SetMediaTrackInfo_Value(bass_track, "D_VOL", 1);
  reaper.SetMediaTrackInfo_Value(vp_track, "D_VOL", 1);
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
  reaper.SetMediaTrackInfo_Value(bass_track, "D_VOL", 1.5);
  reaper.SetMediaTrackInfo_Value(vp_track, "D_VOL", 1.5);
  reaper.SetMediaTrackInfo_Value(bass_track, "D_PAN", -1);
  reaper.SetMediaTrackInfo_Value(vp_track, "D_PAN", -1);
  for i = 0, n-3, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1);
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", 1);
  end
  
  export_file_name = "\\" .. project_name .. " - Rhythm Panned.mp3"
  export_track(export_file_name, path)
  reaper.ShowConsoleMsg("\n")
end


function get_pans(n, top_track_name, vp)
  -- Full mix
    -- Pan in a way that makes sure adjacent parts are separate (except for barbershop)
    -- For 6 part: Alto, Bass, Tenor/VP, Sop, Bari
    -- For 5 part: Alto, Bass, VP, Sop, Tenor
    -- For 4 part: Alto, Bass, Sop, Tenor
    -- For barbershop: Bari, Bass, Lead, Tenor

  if n == 6 then
    reaper.ShowConsoleMsg("Panning arrangement: 6 part SATBB+VP\n\n")
    pans = {0.5, -1, 0, 1, -0.5, 0}
  elseif n == 5 then
    if vp then
      reaper.ShowConsoleMsg("Panning arrangement: 5 part SATB+VP\n\n")
      pans = {0.5, -1, 1, -0.5, 0}
    else
      reaper.ShowConsoleMsg("Panning arrangement: 5 part SATBB\n\n")
      pans = {0.5, -1, 0, 1, -0.5}
    end
  elseif n == 4 then
    if top_track_name == "Tenor" then --barbershop
      reaper.ShowConsoleMsg("Panning arrangement: 4 part barbershop\n\n")
      pans = {1, 1/3, -1, -1/3}
    else
      reaper.ShowConsoleMsg("Panning arrangement: 4 part SATB\n\n")
      pans = {1/3, -1, 1, -1/3} 
    end
  else
    for i = 1, n do
      pans[i] = 0
    end
  end

  return pans
end


function reset(n)
  for i = 0, n-1, 1 do
    track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1);
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", 0);
  end
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


function export_all(n, project_name, path, second_bottom_track, export_parts_only, vp)
  top_track = reaper.GetTrack(0,0)
  retval, top_track_name = reaper.GetTrackName(top_track)
  pans = get_pans(n, top_track_name, vp)

  if export_parts_only then
    parts_only(n, project_name, path)
  end
  panned_learning_tracks(n, project_name, path)
  part_missing_learning_tracks(n, project_name, path, pans)
  if vp then
    rhythm_learning_tracks(n, project_name, path)
  end
  full_mix_learning_track(n, project_name, path, pans)

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

  if bottom_track_name == "Metronome" or bottom_track_name == "Click" then
    if second_bottom_track_name == "VP" then
      vp = true
    end
    reaper.SetMediaTrackInfo_Value(bottom_track, "D_PAN", 0);
    --reaper.SetMediaTrackInfo_Value(bottom_track, "D_VOL", 1);
    export_all(n-1, project_name, path, second_bottom_track, export_parts_only, vp)
  else
    if bottom_track_name == "VP" then
      vp = true
    end
    export_all(n, project_name, path, second_bottom_track, export_parts_only, vp)
  end

  reset(n)
end

-- main()

-- TODO: Add optional numbers to the start of the file names
-- TODO: Parameterise everything
  -- TODO: Parameterise volume for all tracks (make it so that you can drop the volume of all parts the same amount)
  -- TODO: Parameterise hard panning so that you can choose left or right
-- TODO: Map a sequence of integers to panning
  -- ie, 3, 1, 2, 4, 5 => 0, -1, -0.5, 0.5, 1
  -- extension: add a width parameter such that maximum width is 1 (furthest parts are hard panned) and minimum is 0 (all parts are centred)
-- TODO: Set pans function for convenience
-- TODO: Restore function (putting volume and pan back where they were)
  -- TODO: Get original state function (store volume and pan values before running the script)
-- TODO: Detect clipping in export, delete the clipped track and re-export at a lower volume
-- TODO: Build a GUI to turn this into a rehearsal tool
  -- TODO: Options to select a custom panning arrangement for full mix and part missing tracks
  -- TODO: Options to select custom combinations of different parts present, not just Bass and VP
