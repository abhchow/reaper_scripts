local file_io = {}

function file_io.read_yaml_file(filename)
  -- Supports flat keys, plus one level of nesting: a key with no value on its
  -- line collects the indented keys below it into a table.
  local file = io.open(filename, "r")
  if not file then
    return nil, "Failed to open file: " .. filename
  end

  local data = {}
  local parent = nil
  for line in file:lines() do
    local content = line:gsub("%s*#.*$", "") -- strip comments
    local indent, key, value = content:match("^(%s*)([%w_%+]+):%s*(.-)%s*$")
    if key then
      if indent == "" then
        if value == "" then
          data[key] = {}
          parent = data[key]
        else
          data[key] = value
          parent = nil
        end
      elseif parent then
        parent[key] = value
      end
    end
  end

  file:close()
  return data
end

function file_io.read_number_list(str)
  -- Reads a yaml inline list of numbers, e.g. "[4, 1, 5, 2, 3]"
  local numbers = {}
  for number in str:gmatch("-?%d+%.?%d*") do
    table.insert(numbers, tonumber(number))
  end
  return numbers
end

function file_io.read_bool(str)
  if str == "true" then
    return true
  elseif str == "false" then
    return false
  else
    -- throw error
    error("Invalid setting value: " .. str .. ". Please only use true or false.")
  end
end

return file_io
