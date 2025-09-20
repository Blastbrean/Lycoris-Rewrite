---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class SoundTiming: Timing
---@field id string Sound ID.
---@field rpue boolean Repeat parry until end.
---@field _rsd number Repeat start delay in miliseconds. Never access directly.
---@field _rpd number Delay between each repeat parry in miliseconds. Never access directly.
local SoundTiming = setmetatable({}, { __index = Timing })
SoundTiming.__index = SoundTiming

---Timing ID.
---@return string
function SoundTiming:id()
	return self._id
end

-- Getter for repeat start delay in seconds.
---@return number
function SoundTiming:rsd()
	return PP_SCRAMBLE_NUM(self._rsd) / 1000
end

-- Getter for repeat start delay in seconds.
---@return number
function SoundTiming:rpd()
	return PP_SCRAMBLE_NUM(self._rpd) / 1000
end

---Equals check.
---@param other SoundTiming
function SoundTiming:equals(other)
	if not Timing.equals(self, other) then
		return false
	end

	if self._rsd ~= other._rsd then
		return false
	end

	if self._rpd ~= other._rpd then
		return false
	end

	if self.rpue ~= other.rpue then
		return false
	end

	if self._id ~= other._id then
		return false
	end

	return true
end

---Load from partial values.
---@param values table
function SoundTiming:load(values)
	Timing.load(self, values)

	if typeof(values._id) == "string" then
		self._id = values._id
	end

	if type(values.rsd) == "number" then
		self._rsd = values.rsd
	end

	if typeof(values.rpue) == "boolean" then
		self.rpue = values.rpue
	end

	if typeof(values.rpd) == "number" then
		self._rpd = values.rpd
	end
end

---Clone timing.
---@return SoundTiming
function SoundTiming:clone()
	local clone = setmetatable(Timing.clone(self), SoundTiming)

	clone._rpd = self._rpd
	clone.rpue = self.rpue
	clone._rsd = self._rsd
	clone._id = self._id

	return clone
end

---Return a serializable table.
---@return SoundTiming
function SoundTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable._id = self._id
	serializable.rpue = self.rpue
	serializable.rsd = self._rsd
	serializable.rpd = self._rpd

	return serializable
end

---Create a new sound timing.
---@param values table?
---@return SoundTiming
function SoundTiming.new(values)
	local self = setmetatable(Timing.new(), SoundTiming)

	self._id = ""
	self.rpue = false
	self._rsd = 0
	self._rpd = 0

	if values then
		self:load(values)
	end

	return self
end

-- Return SoundTiming module.
return SoundTiming
