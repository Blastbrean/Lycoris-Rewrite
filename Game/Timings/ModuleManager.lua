-- Module manager.
local ModuleManager = { modules = {} }

---@module Utility.Filesystem
local Filesystem = require("Utility/Filesystem")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Module filesystem.
local fs = Filesystem.new("Lycoris-Rewrite-Modules")

---List loaded modules.
---@return string[]
function ModuleManager.loaded()
	local out = {}

	for file, _ in next, ModuleManager.modules do
		table.insert(out, file)
	end

	return out
end

---Get module files list.
---@return table
function ModuleManager.list()
	local list = fs:list()
	local out = {}

	for idx = 1, #list do
		local file = list[idx]

		if file:sub(-4) ~= ".lua" then
			continue
		end

		local pos = file:find(".lua", 1, true)
		local char = file:sub(pos, pos)
		local start = pos

		while char ~= "/" and char ~= "\\" and char ~= "" do
			pos = pos - 1
			char = file:sub(pos, pos)
		end

		if char == "/" or char == "\\" then
			table.insert(out, file:sub(pos + 1, start - 1))
		end
	end

	return out
end

---Refresh ModuleManager.
function ModuleManager.refresh()
	-- Reset current list.
	ModuleManager.modules = {}

	-- Load all modules in our filesystem.
	for _, file in next, ModuleManager.list() do
		-- Get string to load.
		local ls = fs:read(file)

		-- Get function that we can execute.
		local lf, lr = loadstring(ls)
		if not lf then
			Logger.warn("Module file '%s' failed to load due to error '%s' while loading.", file, lr)
			continue
		end

		-- Run executable function to initialize it.
		local success, result = pcall(lf)
		if not success then
			Logger.warn("Module file '%s' failed to load due to error '%s' while executing.", file, result)
			continue
		end

		if typeof(result) ~= "function" then
			Logger.warn("Module file '%s' is invalid because it does not return a function.")
			continue
		end

		-- Get the result as a function.
		ModuleManager.modules[file] = result
	end
end

-- Return ModuleManager module.
return ModuleManager
