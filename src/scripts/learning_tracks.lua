dofile(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua")
local pan = dofile(reaper.GetResourcePath().."/Scripts/src/utils/pan.lua")
local arr_utils = dofile(reaper.GetResourcePath().."/Scripts/src/utils/arr_utils.lua")
local daw_state = dofile(reaper.GetResourcePath().."/Scripts/src/utils/daw_state.lua")
local file_io = dofile(reaper.GetResourcePath().."/Scripts/src/utils/file_io.lua")
local make_all_tracks = dofile(reaper.GetResourcePath().."/Scripts/src/commands/make_all_tracks.lua")

function main()
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
    make_all_tracks.export_all(n-1, project_name, path, vp, original_volumes)
  else
    if bottom_track_name == "VP" then
      vp = true
    end
    make_all_tracks.export_all(n, project_name, path, vp, original_volumes)
  end

  daw_state.set_pans(original_pans)
  daw_state.set_volumes(original_volumes)
end

main()
