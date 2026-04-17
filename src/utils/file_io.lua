local file_io = {}

function file_io.read_yaml_file(filename)
  local file = io.open(filename, "r")
  if not file then
    return nil, "Failed to open file: " .. filename
  end

  local data = {}
  for line in file:lines() do
    local key, value = line:match("([%w_]+):%s*(.+)")
    if key and value then
      data[key] = value
    end
  end

  file:close()
  return data
end

return file_io