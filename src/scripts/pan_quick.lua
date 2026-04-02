local pan = dofile(reaper.GetResourcePath().."/Scripts/src/utils/pan.lua")

function main()
  pan.set_pan_arrangement(0.6)
end

main()
