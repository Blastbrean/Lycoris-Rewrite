---@module Game.Timings.TimingSave
local TimingSave = require("Game/Timings/TimingSave")

---@module Game.Timings.TimingContainerPair
local TimingContainerPair = require("Game/Timings/TimingContainerPair")

---@module Game.Timings.TimingContainer
local TimingContainer = require("Game/Timings/TimingContainer")

---@module Game.Timings.AnimationTiming
local AnimationTiming = require("Game/Timings/AnimationTiming")

---@module Game.Timings.EffectTiming
local EffectTiming = require("Game/Timings/EffectTiming")

---@module Game.Timings.PartTiming
local PartTiming = require("Game/Timings/PartTiming")

---@module Game.Timings.SoundTiming
local SoundTiming = require("Game/Timings/SoundTiming")

---@module Game.Timings.EmitterTiming
local EmitterTiming = require("Game/Timings/EmitterTiming")

-- SaveManager module.
local SaveManager = {
	-- Last loaded config name.
	llcn = nil,
}

---@module Utility.Filesystem
local Filesystem = require("Utility/Filesystem")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Deserializer
local Deserializer = require("Utility/Deserializer")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.Serializer
local Serializer = require("Utility/Serializer")

---@module Utility.Signal
local Signal = require("Utility/Signal")

-- Manager filesystem.
local fs = Filesystem.new("Lycoris-Rewrite-Timings")

-- Current timing save.
local config = TimingSave.new()

-- Services.
local players = game:GetService("Players")

-- Generate mapping.
local charByteMap = {}

for idx = 0, 255 do
	charByteMap[string.char(idx)] = idx
end

---String to byte array.
---@param str string
---@return string
local function stringToByteArray(str)
	local chars = {}
	local idx = 1

	repeat
		chars[idx] = charByteMap[str:sub(idx, idx)]
		idx = idx + 1
	until idx == #str + 1

	return chars
end

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
	if not name or #name <= 0 then
		return Logger.longNotify("Config name cannot be empty.")
	end

	local success, result = pcall(fs.read, fs, name .. ".bin")

	if not success then
		Logger.longNotify("Failed to read config file %s.", name)

		return Logger.warn("Timing manager ran into the error '%s' while attempting to read config %s.", result, name)
	end

	success, result = pcall(Deserializer.unmarshal_one, stringToByteArray(result))

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

	config:merge(TimingSave.new(result), type)

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
	if not name or #name <= 0 then
		return Logger.longNotify("Config name cannot be empty.")
	end

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
	if not name or #name <= 0 then
		return Logger.longNotify("Config name cannot be empty.")
	end

	if fs:file(name .. ".bin") then
		return Logger.longNotify("Config file %s already exists.", name)
	end

	SaveManager.write(name)
end

---Save timing as config name.
---@param name string
function SaveManager.save(name)
	if not name or #name <= 0 then
		return Logger.longNotify("Config name cannot be empty.")
	end

	if not fs:file(name .. ".bin") then
		return Logger.longNotify("Config file %s does not exist.", name)
	end

	SaveManager.write(name)
end

---Write timing as config name.
---@param name string
function SaveManager.write(name)
	if not name or #name <= 0 then
		return Logger.longNotify("Config name cannot be empty.")
	end

	local success, result = pcall(Serializer.marshal, config:serialize())

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
	local timestamp = os.clock()

	if not name or #name <= 0 then
		return Logger.longNotify("Config name cannot be empty.")
	end

	local success, result = pcall(fs.read, fs, name .. ".bin")

	if not success then
		Logger.longNotify("Failed to read config file %s.", name)

		return Logger.warn("Timing manager ran into the error '%s' while attempting to read config %s.", result, name)
	end

	success, result = pcall(Deserializer.unmarshal_one, stringToByteArray(result))

	if not success then
		Logger.longNotify("Failed to deserialize config file %s.", name)

		return Logger.warn(
			"Timing manager ran into the error '%s' while attempting to deserialize config %s.",
			result,
			name
		)
	end

	if typeof(result) ~= "table" then
		Logger.longNotify("Failed to process config file %s.", name)

		return Logger.warn("Timing manager failed to process config %s with result %s.", name, tostring(result))
	end

	config:clear()

	success, result = pcall(config.load, config, result)

	if not success then
		Logger.longNotify("Failed to load config file %s.", name)

		return Logger.warn("Timing manager ran into the error '%s' while attempting to load config %s.", result, name)
	end

	Logger.notify(
		"Config file %s has loaded with %i timings in %.2f seconds.",
		name,
		config:count(),
		os.clock() - timestamp
	)

	SaveManager.llcn = name
end

---Auto-save timings.
function SaveManager.autosave()
	if not SaveManager.llcn then
		return
	end

	if not Configuration.expectToggleValue("AutoSaveOnLeave") then
		return
	end

	SaveManager.write(SaveManager.llcn)
end

---Initialize SaveManager.
function SaveManager.init()
	local timestamp = os.clock()

	-- Create internal timing containers.
	local internalAnimationContainer = TimingContainer.new(AnimationTiming.new())
	local internalEffectContainer = TimingContainer.new(EffectTiming.new())
	local internalPartContainer = TimingContainer.new(PartTiming.new())
	local internalSoundContainer = TimingContainer.new(SoundTiming.new())
	local internalEmitterContainer = TimingContainer.new(EmitterTiming.new())

	---@todo: Load internal timings from server.
	internalAnimationContainer:load({})
	internalEffectContainer:load({})
	internalPartContainer:load({})
	internalSoundContainer:load({})
	internalEmitterContainer:load({})

	-- Count up internal timings.
	local internalCount = internalAnimationContainer:count()
		+ internalEffectContainer:count()
		+ internalPartContainer:count()
		+ internalSoundContainer:count()
		+ internalEmitterContainer:count()

	Logger.notify(
		"Internal timings have loaded with %i timings in %.2f seconds.",
		internalCount,
		os.clock() - timestamp
	)

	-- Attempt to read auto-load config.
	local success, result = pcall(fs.read, fs, "autoload.txt")

	-- Load auto-load config if it exists.
	if success and result then
		SaveManager.load(result)
	end

	-- Animation stack.
	SaveManager.as = TimingContainerPair.new(internalAnimationContainer, config:get().animation)

	-- Effect stack.
	SaveManager.es = TimingContainerPair.new(internalEffectContainer, config:get().effect)

	-- Part stack.
	SaveManager.ps = TimingContainerPair.new(internalPartContainer, config:get().part)

	-- Sound stack.
	SaveManager.ss = TimingContainerPair.new(internalSoundContainer, config:get().sound)

	-- Emitter stack.
	SaveManager.ems = TimingContainerPair.new(internalEmitterContainer, config:get().emitter)

	-- Signals.
	local playerRemoving = Signal.new(players.PlayerRemoving)

	-- Auto-saving.
	playerRemoving:connect(function(player)
		if player ~= players.LocalPlayer then
			return
		end

		SaveManager.autosave()
	end)
end

-- Return SaveManager module.
return SaveManager
