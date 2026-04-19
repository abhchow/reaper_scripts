dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")

local daw_state = {}

function daw_state.get_current_pans(n)
  -- read pans of all parts and store them
  local pans = {}
  for i = 0, n-1, 1 do
    local track = reaper.GetTrack(0, i)
    pans[i+1] = reaper.GetMediaTrackInfo_Value(track, "D_PAN")
  end
  return pans
end

function daw_state.set_pans(pans)
  -- set pans of all parts
  for i = 0, #pans-1 do
    local track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_PAN", pans[i+1])
  end
end

function daw_state.get_current_volumes(n)
  -- read volumes of all parts and store them
  local volumes = {}
  for i = 0, n-1, 1 do
    local track = reaper.GetTrack(0, i)
    volumes[i+1] = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
  end
  return volumes
end

function daw_state.set_volumes(volumes)
  -- set volumes of all parts
  for i = 0, #volumes-1 do
    local track = reaper.GetTrack(0, i)
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", volumes[i+1])
  end
end

return daw_state
