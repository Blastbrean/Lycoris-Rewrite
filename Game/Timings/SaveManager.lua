---@module Game.Timings.TimingSave
local TimingSave = require("Game/Timings/TimingSave")

---@module Game.Timings.TimingContainerPair
local TimingContainerPair = require("Game/Timings/TimingContainerPair")

-- SaveManager module.
local SaveManager = {
	default = TimingSave.new(),
	config = TimingSave.new(),
}

---@module Utility.Filesystem
local Filesystem = require("Utility/Filesystem")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Deserializer
local Deserializer = require("Utility/Deserializer")

---@module Utility.Serializer
local Serializer = require("Utility/Serializer")

-- Manager filesystem.
local fs = Filesystem.new("Lycoris-Rewrite-Timings")

---Get save files list.
---@return table
function SaveManager.list()
	local list = fs:list()
	local out = {}

	for idx = 1, #list do
		local file = list[idx]

		if file:sub(-4) ~= ".bin" then
			continue
		end

		local pos = file:find(".bin", 1, true)
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

---Merge with current config.
---@param name string
---@param type MergeType
function SaveManager.merge(name, type)
	local success, result = pcall(fs.read, fs, name .. ".bin")

	if not success then
		Logger.longNotify("Failed to read config file %s.", name)

		return Logger.warn("Timing manager ran into the error '%s' while attempting to read config %s.", result, name)
	end

	success, result = pcall(Deserializer.at, result)

	if not success then
		Logger.longNotify("Failed to deserialize config file %s.", name)

		return Logger.warn(
			"Timing manager ran into the error '%s' while attempting to deserialize config %s.",
			result,
			name
		)
	end

	if typeof(result) ~= "table" then
		Logger.longNotify("Failed to load config file %s.", name)

		return Logger.warn("Timing manager failed to load config %s with result %s.", name, tostring(result))
	end

	SaveManager.config:merge(TimingSave.new(result), type)

	Logger.notify("Config file %s has merged with the loaded one.", name)
end

---Refresh dropdown values with timing data.
---@param dropdown table
function SaveManager.refresh(dropdown)
	dropdown:SetValues(SaveManager.list())
end

---Set config name as auto-load.
---@param name string
function SaveManager.autoload(name)
	local success, result = pcall(fs.write, fs, "autoload.txt", name)

	if not success then
		Logger.longNotify("Failed to write autoload file %s.", name)

		return Logger.warn(
			"Timing manager ran into the error '%s' while attempting to write autoload file %s.",
			result,
			name
		)
	end

	Logger.notify("Config file %s has set to auto-load.", name)
end

---Create timing as config name.
---@param name string
function SaveManager.create(name)
	if fs:file(name .. ".bin") then
		return Logger.longNotify("Config file %s already exists.", name)
	end

	SaveManager.write(name)
end

---Save timing as config name.
---@param name string
function SaveManager.save(name)
	if not fs:file(name .. ".bin") then
		return Logger.longNotify("Config file %s does not exist.", name)
	end

	SaveManager.write(name)
end

---Write timing as config name.
---@param name string
function SaveManager.write(name)
	if #name <= 0 then
		return Logger.longNotify("Config name cannot be empty.")
	end

	local success, result = pcall(Serializer.marshal, SaveManager.config:serialize())

	if not success then
		Logger.longNotify("Failed to serialize config file %s.", name)

		return Logger.warn(
			"Timing manager ran into the error '%s' while attempting to serialize config %s.",
			result,
			name
		)
	end

	success, result = pcall(fs.write, fs, name .. ".bin", result)

	if not success then
		Logger.longNotify("Failed to write config file %s.", name)

		return Logger.warn("Timing manager ran into the error '%s' while attempting to write config %s.", result, name)
	end

	Logger.notify("Config file %s has written to.", name)
end

---Load timing from config name.
---@param name string
function SaveManager.load(name)
	local success, result = pcall(fs.read, fs, name .. ".bin")

	if not success then
		Logger.longNotify("Failed to read config file %s.", name)

		return Logger.warn("Timing manager ran into the error '%s' while attempting to read config %s.", result, name)
	end

	success, result = pcall(Deserializer.at, result)

	if not success then
		Logger.longNotify("Failed to deserialize config file %s.", name)

		return Logger.warn(
			"Timing manager ran into the error '%s' while attempting to deserialize config %s.",
			result,
			name
		)
	end

	if typeof(result) ~= "table" then
		Logger.longNotify("Failed to load config file %s.", name)

		return Logger.warn("Timing manager failed to load config %s with result %s.", name, tostring(result))
	end

	SaveManager.config:load(result)

	Logger.notify("Config file %s has loaded.", name)
end

---Initialize SaveManager.
function SaveManager.init()
	---@todo: Load default timings from server.
	SaveManager.default:load({})

	-- Attempt to read auto-load config.
	local success, result = pcall(fs.read, fs, "autoload.txt")

	-- Load auto-load config if it exists.
	if success and result then
		SaveManager.load(result)
	end

	-- Animation stack.
	SaveManager.as = TimingContainerPair.new(SaveManager.default:get().animation, SaveManager.config:get().animation)

	-- Effect stack.
	SaveManager.es = TimingContainerPair.new(SaveManager.default:get().effect, SaveManager.config:get().effect)

	-- Part stack.
	SaveManager.ps = TimingContainerPair.new(SaveManager.default:get().part, SaveManager.config:get().part)

	-- Sound stack.
	SaveManager.ss = TimingContainerPair.new(SaveManager.default:get().sound, SaveManager.config:get().sound)
end

-- Return SaveManager module.
return SaveManager
