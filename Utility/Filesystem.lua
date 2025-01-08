---@class Filesystem
---@field _path string
local Filesystem = {}
Filesystem.__index = Filesystem

---Create and get the current path.
---@return string
function Filesystem:path()
	if not isfolder(self._path) then
		makefolder(self._path)
	end

	return self._path
end

---Append path to current path.
---@param path string
---@return string
function Filesystem:append(path)
	return self:path() .. "\\" .. path
end

---Check if filename is a file.
---@param filename string
---@return boolean
function Filesystem:file(filename)
	return isfile(self:append(filename))
end

---Read file from path.
---@param filename string
---@return string
function Filesystem:read(filename)
	if not self:file(filename) then
		return error("File does not exist or is a folder.", 2)
	end

	return readfile(self:append(filename))
end

---Delete file.
---@param filename string
---@return string
function Filesystem:delete(filename)
	if not self:file(filename) then
		return error("File does not exist or is a folder.", 2)
	end

	return delfile(self:append(filename))
end

---Write file to workspace folder.
---@param filename string
---@param contents string?
function Filesystem:write(filename, contents)
	writefile(self:append(filename), contents and contents or "")
end

---List files.
---@return table
function Filesystem:list()
	local list = listfiles(self:path())
	if not list then
		return error("File list does not exist.", 2)
	end

	for idx, path in next, list do
		list[idx] = string.gsub(path, self:path() .. "\\", "")
	end

	return list
end

---Create new Filesystem object.
---@param path string
---@return Filesystem
function Filesystem.new(path)
	local self = setmetatable({}, Filesystem)
	self._path = path
	return self
end

-- Return Filesystem module.
return Filesystem
