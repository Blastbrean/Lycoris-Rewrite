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

---@class TimingSave
---@field _data TimingContainer[]
---@field _removals table<string, string[]> For every container, a list of timing IDs that we need to remove from the internal data.
local TimingSave = {}
TimingSave.__index = TimingSave

---Timing save version constant.
---@note: Increment me when the data structure changes and we need to add backwards compatibility.
local TIMING_SAVE_VERSION = 1

---@alias MergeType
---| '1' # Only add new timings
---| '2' # Overwrite and add everything

---Get timing save.
---@return TimingContainer[]
function TimingSave:get()
	return self._data
end

---Clear timing containers.
function TimingSave:clear()
	for _, container in next, self._data do
		container:clear()
	end
end

---Merge with another TimingSave object.
---@param save TimingSave The other save.
---@param type MergeType
function TimingSave:merge(save, type)
	for idx, other in next, save._data do
		local container = self._data[idx]
		if not container then
			continue
		end

		container:merge(other, type)
	end
end

---Load from partial values.
---@param values table
function TimingSave:load(values)
	local data = self._data

	if typeof(values.animation) == "table" then
		data.animation:load(values.animation)
	end

	if typeof(values.effect) == "table" then
		data.effect:load(values.effect)
	end

	if typeof(values.part) == "table" then
		data.part:load(values.part)
	end

	if typeof(values.sound) == "table" then
		data.sound:load(values.sound)
	end
end

---Get timing save count.
---@return number
function TimingSave:count()
	local count = 0

	for _, container in next, self._data do
		count = count + container:count()
	end

	return count
end

---Return a serializable table.
---@return table
function TimingSave:serialize()
	local data = self._data

	return {
		version = TIMING_SAVE_VERSION,
		animation = data.animation:serialize(),
		effect = data.effect:serialize(),
		part = data.part:serialize(),
		sound = data.sound:serialize(),
	}
end

---Create new TimingSave object.
---@param values table?
---@return TimingSave
function TimingSave.new(values)
	local self = setmetatable({}, TimingSave)

	self._data = {
		animation = TimingContainer.new(AnimationTiming),
		effect = TimingContainer.new(EffectTiming),
		part = TimingContainer.new(PartTiming),
		sound = TimingContainer.new(SoundTiming),
	}

	if values then
		self:load(values)
	end

	return self
end

-- Return TimingSave module.
return TimingSave
