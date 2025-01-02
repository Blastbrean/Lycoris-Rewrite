---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class SoundTiming: Timing
---@field id string Sound ID.
---@field rpue boolean Repeat parry until end.
---@field rpd number Delay between each repeat parry.
local SoundTiming = setmetatable({}, { __index = Timing })
SoundTiming.__index = SoundTiming

---Timing ID.
---@return string
function SoundTiming:id()
	return self._id
end

---Load from partial values.
---@param values table
function SoundTiming:load(values)
	Timing.load(self, values)

	if typeof(values._id) == "string" then
		self._id = values._id
	end

	if typeof(values.rpue) == "boolean" then
		self.rpue = values.rpue
	end

	if typeof(values.rpd) == "number" then
		self.rpd = values.rpd
	end
end

---Clone timing.
---@return SoundTiming
function SoundTiming:clone()
	local clone = setmetatable(Timing.clone(self), SoundTiming)

	clone.rpd = self.rpd
	clone.rpue = self.rpue
	clone.id = self.id

	return clone
end

---Return a serializable table.
---@return SoundTiming
function SoundTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable._id = self._id
	serializable.rpue = self.rpue
	serializable.rpd = self.rpd

	return serializable
end

---Create a new sound timing.
---@param values table?
---@return SoundTiming
function SoundTiming.new(values)
	local self = setmetatable(Timing.new(), SoundTiming)

	self._id = ""
	self.rpue = false
	self.rpd = 0

	if values then
		self:load(values)
	end

	return self
end

-- Return SoundTiming module.
return SoundTiming
