function print_array(arr)
  reaper.ShowConsoleMsg("Array values: ")
  for i = 1, #arr do
    reaper.ShowConsoleMsg(arr[i] .. " ")
  end
  reaper.ShowConsoleMsg("\n")
end


function copy_table(table)
  local new_table = {}
  for i = 1, #table do
    new_table[i] = table[i]
  end
  return new_table
end


function has_value(table, val)
  for index, value in ipairs(table) do
    if value == val then
        return true
    end
  end

  return false
end


function get_filled_array(n, value)
  local arr = {}
  for i = 0, n-1, 1 do
    arr[i+1] = value
  end
  return arr
end