dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
dofile(reaper.GetResourcePath().."/Scripts/pan.lua")

function main()
  local n = reaper.GetNumTracks()

  local bottom_track = reaper.GetTrack(0,n-1)
  local retval, bottom_track_name = reaper.GetTrackName(bottom_track)
  local second_bottom_track = reaper.GetTrack(0,n-2)
  local retval, second_bottom_track_name = reaper.GetTrackName(second_bottom_track)
  local vp = false
  local metronome = false
  if bottom_track_name == "Metronome" or bottom_track_name == "Click" then
    metronome = true
  end


  local top_track = reaper.GetTrack(0,0)
  local retval, top_track_name = reaper.GetTrackName(top_track)  
  
  local n_to_pan = n
  if metronome then
    n_to_pan = n-1
  end

  local positions = get_positions(n_to_pan, top_track_name, vp)
  local retval, width = reaper.GetUserInputs("Input Panning Width", 1, "Panning width (between 0-1)", "1")
  width = tonumber(width)
  local pans = positions_to_pans(positions, width) -- overwrite this to customise
  set_pans(pans)
end

main()
