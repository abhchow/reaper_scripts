local pan = dofile(reaper.GetResourcePath().."/Scripts/src/utils/pan.lua")

function main()
  local retval, width = reaper.GetUserInputs("Input Panning Width", 1, "Panning width (between 0-1)", "1")
  width = tonumber(width)
  pan.set_pan_arrangement(width)
end

main()
