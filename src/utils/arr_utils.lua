local arr_utils = {}

function arr_utils.print_array(arr, msg)
  if msg then
    reaper.ShowConsoleMsg(msg .. ": ")
  else
    reaper.ShowConsoleMsg("Array values: ")
  end
  for i = 1, #arr do
    reaper.ShowConsoleMsg(arr[i] .. " ")
  end
  reaper.ShowConsoleMsg("\n")
end


function arr_utils.copy_table(table)
  local new_table = {}
  for i = 1, #table do
    new_table[i] = table[i]
  end
  return new_table
end


function arr_utils.has_value(table, val)
  for index, value in ipairs(table) do
    if value == val then
        return true
    end
  end

  return false
end


function arr_utils.get_filled_array(n, value)
  local arr = {}
  for i = 0, n-1, 1 do
    arr[i+1] = value
  end
  return arr
end

return arr_utils