dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local arr_utils = dofile(reaper.GetResourcePath().."/Scripts/src/utils/arr_utils.lua")

local pan = {}

function pan.get_positions(n, top_track_name, vp, print_console_msg)
  -- Full mix
    -- Pan in a way that makes sure adjacent parts are separate (except for barbershop)
    -- For 7 part SATTBB+VP: idk i haven't worked this out
    -- For 6 part SATBB+VP: Alto, Bass, Tenor/VP, Sop, Bari
    -- For 5 part SATB+VP: Alto, Bass, VP, Sop, Tenor
    -- For 5 part SATBB: Alto, Bass, Tenor, Sop, Bari
    -- For 4 part SATB: Alto, Bass, Sop, Tenor
    -- For barbershop: Bari, Bass, Lead, Tenor
    -- For 3 part (assuming SAT): Tenor, Sop, Alto
    -- For 2 part: Alto, Sop
  local defaults = {
    print_console_msg = false
  }
  local positions = {}
  local msg = ""

  if n == 7 then
    msg = "Panning arrangement: 7 part SATBBB+VP\n\n"
    positions = {2,4,6,1,3,5,7}
  elseif n == 6 then
    msg = "Panning arrangement: 6 part SATBB+VP\n\n"
    positions = {4,1,3,5,2,3}
  elseif n == 5 then
    if vp then
      msg = "Panning arrangement: 5 part SATB+VP\n\n"
      positions = {4,1,5,2,3}
    else
      msg = "Panning arrangement: 5 part SATBB\n\n"
      positions = {4,1,3,5,2}
    end
  elseif n == 4 then
    if top_track_name == "Tenor" then --barbershop
      msg = "Panning arrangement: 4 part barbershop\n\n"
      positions = {4,3,1,2}
    else
      msg = "Panning arrangement: 4 part SATB\n\n"
      positions = {3,1,4,2}
    end
  elseif n == 3 then
    msg = "Panning arrangement: 3 part\n\n"
    positions = {3,1,2}
  elseif n == 2 then
    msg = "Panning arrangement: 2 part\n\n"
    positions = {2,1}
  else
    for i = 1, n do
      positions[i] = 0
    end
  end

  if print_console_msg then
    reaper.ShowConsoleMsg(msg)
  end

  return positions
end

function pan.positions_to_pans(positions, width)
  -- width is a minimum of 0 (mono) and a maximum of 1 (furthest parts are hard panned)

  local pans = {}

  local positions_max = math.max(table.unpack(positions))
  local positions_min = math.min(table.unpack(positions))
  local diff = positions_max - positions_min

  if diff == 0 then
    pans = arr_utils.get_filled_array(#positions, 0)    
  else
    for i = 1, #positions do
      pans[i] = ((positions[i] - positions_min) / diff * 2 - 1) * width
    end
  end

  return pans  
end


function pan.set_pan_arrangement(width)
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

  local positions = pan.get_positions(n_to_pan, top_track_name, vp)
  local pans = pan.positions_to_pans(positions, width) -- overwrite this to customise
  daw_state.set_pans(pans)
end

return pan
