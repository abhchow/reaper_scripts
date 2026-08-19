dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local arr_utils = dofile(reaper.GetResourcePath().."/Scripts/src/utils/arr_utils.lua")
local file_io = dofile(reaper.GetResourcePath().."/Scripts/src/utils/file_io.lua")

local pan = {}

local ARRANGEMENTS_PATH = reaper.GetResourcePath().."/Scripts/src/pan_arrangements.yaml"

local function get_arrangement(arrangements, n, top_track_name, vp)
  -- Most specific key first, falling back to the other voicing so that a part
  -- count only defined for one of them is still panned
  local voicing = vp and "_including_vp" or "_voices"
  local other_voicing = vp and "_voices" or "_including_vp"

  local keys = {}
  if top_track_name == "Tenor" then --barbershop
    table.insert(keys, n .. voicing .. "_barbershop")
    table.insert(keys, n .. other_voicing .. "_barbershop")
  end
  table.insert(keys, n .. voicing)
  table.insert(keys, n .. other_voicing)

  for i = 1, #keys do
    local arrangement = arrangements[keys[i]]
    if arrangement and arrangement.positions then
      return arrangement
    end
  end

  return nil
end

function pan.get_positions(n, top_track_name, vp, print_console_msg)
  -- Full mix. Arrangements are defined in pan_arrangements.yaml
  local arrangements, err = file_io.read_yaml_file(ARRANGEMENTS_PATH)
  if not arrangements then
    error(err)
  end

  local arrangement = get_arrangement(arrangements, n, top_track_name, vp)
  if not arrangement then
    return arr_utils.get_filled_array(n, 0)
  end

  if print_console_msg then
    reaper.ShowConsoleMsg("Panning arrangement: " .. (arrangement.name or n .. " part") .. "\n\n")
  end

  return file_io.read_number_list(arrangement.positions)
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
