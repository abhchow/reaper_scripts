dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local arr_utils = dofile(reaper.GetResourcePath().."/Scripts/src/utils/arr_utils.lua")
local daw_state = dofile(reaper.GetResourcePath().."/Scripts/src/utils/daw_state.lua")
local export = dofile(reaper.GetResourcePath().."/Scripts/src/commands/export.lua")

local make_track = {}

function make_track.part_only(n, project_name, path, original_volumes, part_number, file_number)
  local track = reaper.GetTrack(0, part_number)
  local retval, track_name = reaper.GetTrackName(track)
  
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

  local export_successful = export.export_track(project_name, track_name, path, file_number)

  daw_state.set_pans(zeros)
  daw_state.set_volumes(original_volumes)

  return export_successful
end

function make_track.part_predominant_panned(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, file_number)
  local track = reaper.GetTrack(0, part_number)
  local retval, track_name = reaper.GetTrackName(track)

  return make_track.part_predominant(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, track_name .. " Panned", file_number)
end

function make_track.part_predominant_mono(n, project_name, path, volume_diff, original_volumes, part_number, file_number)
  local track = reaper.GetTrack(0, part_number)
  local retval, track_name = reaper.GetTrackName(track)

  return make_track.part_predominant(n, project_name, path, 0, volume_diff, original_volumes, part_number, track_name .. " Predominant", file_number)
end

function make_track.part_predominant(n, project_name, path, pan_position, volume_diff, original_volumes, part_number, track_name, file_number)
  -- do not use directly, use part_predominant_panned or part_predominant_mono instead
  
  local volumes = arr_utils.copy_table(original_volumes)

  local pans = arr_utils.get_filled_array(n, -pan_position)
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

  local export_successful = export.export_track(project_name, track_name, path, file_number)

  local zeros = arr_utils.get_filled_array(n, 0)
  daw_state.set_pans(zeros)
  daw_state.set_volumes(original_volumes)

  return export_successful
end

function make_track.part_missing(n, project_name, path, pans, original_volumes, part_number, file_number)
  local part_exists = arr_utils.get_filled_array(n, 1)
  part_exists[part_number+1] = 0

  local track = reaper.GetTrack(0, part_number)
  local retval, track_name = reaper.GetTrackName(track)

  return make_track.full_mix(n, project_name, path, pans, original_volumes, part_exists, track_name .. " Missing", file_number)
end

function make_track.full_mix(n, project_name, path, pans, original_volumes, part_exists, track_name, file_number)
  local volumes = arr_utils.get_filled_array(n, 0)

  for i=1, #volumes do
    volumes[i] = original_volumes[i]*part_exists[i]
  end

  daw_state.set_pans(pans)
  daw_state.set_volumes(volumes)

  local export_successful = export.export_track(project_name, track_name, path, file_number)

  local zeros = arr_utils.get_filled_array(n, 0)
  daw_state.set_pans(zeros)
  daw_state.set_volumes(original_volumes)

  return export_successful
end

return make_track
