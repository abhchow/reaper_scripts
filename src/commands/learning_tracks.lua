dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local pan = dofile(reaper.GetResourcePath().."/Scripts/src/utils/pan.lua")
local file_io = dofile(reaper.GetResourcePath().."/Scripts/src/utils/file_io.lua")
local make_track = dofile(reaper.GetResourcePath().."/Scripts/src/commands/make_track.lua")
local arr_utils = dofile(reaper.GetResourcePath().."/Scripts/src/utils/arr_utils.lua")
local daw_state = dofile(reaper.GetResourcePath().."/Scripts/src/utils/daw_state.lua")

local learning_tracks = {}

function learning_tracks.export_all(n, project_name, path, vp, original_volumes)
  local settings = file_io.read_yaml_file(reaper.GetResourcePath().."/Scripts/src/settings.yaml")
  
  local hard_pan_volume = tonumber(settings.hard_pan_volume)
  local predominant_volume = tonumber(settings.predominant_volume)
  local default_pan_width = tonumber(settings.default_pan_width)
  local panned_track_position = tonumber(settings.panned_track_position)

  local export_full_mix = file_io.read_bool(settings.export_full_mix)
  local export_individual_tracks = file_io.read_bool(settings.export_individual_tracks)
  local export_part_missing_tracks = file_io.read_bool(settings.export_part_missing_tracks)
  local export_part_panned_tracks = file_io.read_bool(settings.export_part_panned_tracks)
  local export_part_predominant_tracks = file_io.read_bool(settings.export_part_predominant_tracks)
  local cancel_exports_after_failure = file_io.read_bool(settings.cancel_exports_after_failure)

  local top_track = reaper.GetTrack(0,0)
  local retval, top_track_name = reaper.GetTrackName(top_track)
  local positions = pan.get_positions(n, top_track_name, vp)
  local pans = pan.positions_to_pans(positions, default_pan_width)
  local file_number = 1

  local export_queue = {}
  
  if export_full_mix then
    table.insert(export_queue, {make_track.full_mix, table.pack(n, project_name, path, pans, original_volumes, arr_utils.get_filled_array(n, 1), "Full mix")})
  end

  for part_number=0, n-1, 1 do
    if export_individual_tracks then
      table.insert(export_queue, {make_track.part_only, table.pack(n, project_name, path, original_volumes, part_number)})
    end
    if export_part_panned_tracks then
      table.insert(export_queue, {make_track.part_predominant_panned, table.pack(n, project_name, path, panned_track_position, hard_pan_volume, original_volumes, part_number)})
    end
    if export_part_predominant_tracks then
      table.insert(export_queue, {make_track.part_predominant_mono, table.pack(n, project_name, path, predominant_volume, original_volumes, part_number)})
    end
    if export_part_missing_tracks then
      table.insert(export_queue, {make_track.part_missing, table.pack(n, project_name, path, pans, original_volumes, part_number)})
    end
  end
  
  if vp then
    if export_individual_tracks then
      table.insert(export_queue, {make_track.part_only, table.pack(n, project_name, path, original_volumes, {n-1, n-2}, "Rhythm")})
    end
    if export_part_panned_tracks then
      table.insert(export_queue, {make_track.part_predominant_panned, table.pack(n, project_name, path, -1, hard_pan_volume, original_volumes, {n-1, n-2}, "Rhythm")})
    end
    if export_part_predominant_tracks then
      table.insert(export_queue, {make_track.part_predominant_mono, table.pack(n, project_name, path, predominant_volume, original_volumes, {n-1, n-2}, "Rhythm")})
    end
  end

  for export_number=1, #export_queue, 1 do
    local export_function = export_queue[export_number][1]
    local export_args = export_queue[export_number][2]
    table.insert(export_args, export_number)  

    local export_successful = export_function(table.unpack(export_args, 1, export_args.n+1))
    if not export_successful and cancel_exports_after_failure then
      reaper.ShowConsoleMsg("Export failed. Cancelling remaining exports.\n")
      break
    end
  end
end

function learning_tracks.main()
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

  local original_pans = daw_state.get_current_pans(n)
  local original_volumes = daw_state.get_current_volumes(n)
  arr_utils.print_array(original_pans, "Original pans")
  arr_utils.print_array(original_volumes, "Original volumes")

  if metronome then
    if second_bottom_track_name == "VP" then
      vp = true
    end
    reaper.SetMediaTrackInfo_Value(bottom_track, "D_PAN", 0); -- no need to set metronome volume because we never touch it elsewhere
    learning_tracks.export_all(n-1, project_name, path, vp, original_volumes)
  else
    if bottom_track_name == "VP" then
      vp = true
    end
    learning_tracks.export_all(n, project_name, path, vp, original_volumes)
  end

  daw_state.set_pans(original_pans)
  daw_state.set_volumes(original_volumes)
end

learning_tracks.main()

-- return learning_tracks


