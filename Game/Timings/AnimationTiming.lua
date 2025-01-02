---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class AnimationTiming: Timing
---@field id string Animation ID.
---@field rpue boolean Repeat parry until end.
---@field rpd number Delay between each repeat parry.
local AnimationTiming = setmetatable({}, { __index = Timing })
AnimationTiming.__index = AnimationTiming

---Timing ID.
---@return string
function AnimationTiming:id()
	return self._id
end

---Load from partial values.
---@param values table
function AnimationTiming:load(values)
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
---@return AnimationTiming
function AnimationTiming:clone()
	local clone = setmetatable(Timing.clone(self), AnimationTiming)

	clone.rpd = self.rpd
	clone.rpue = self.rpue
	clone.id = self.id

	return clone
end

---Return a serializable table.
---@return AnimationTiming
function AnimationTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable._id = self._id
	serializable.rpue = self.rpue
	serializable.rpd = self.rpd

	return serializable
end

---Create a new animation timing.
---@param values table?
---@return AnimationTiming
function AnimationTiming.new(values)
	local self = setmetatable(Timing.new(), AnimationTiming)

	self._id = ""
	self.rpue = false
	self.rpd = 0

	if values then
		self:load(values)
	end

	return self
end

-- Return AnimationTiming module.
return AnimationTiming
