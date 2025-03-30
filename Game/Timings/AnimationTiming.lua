---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class AnimationTiming: Timing
---@field id string Animation ID.
---@field rpue boolean Repeat parry until end.
---@field _rsd number Repeat start delay in miliseconds. Never access directly.
---@field _rpd number Delay between each repeat parry in miliseconds. Never access directly.
---@param ha boolean Flag to see whether or not this timing can be cancelled by a hit.
---@param fhb boolean Flag to see whether or not this timing should offset facing.
---@param iae boolean Flag to see whether or not this timing should ignore animation end.
local AnimationTiming = setmetatable({}, { __index = Timing })
AnimationTiming.__index = AnimationTiming

---Timing ID.
---@return string
function AnimationTiming:id()
	return self._id
end

-- Getter for repeat start delay in seconds
---@return number
function AnimationTiming:rsd()
	return self._rsd / 1000
end

-- Getter for repeat parry delay in seconds.
---@return number
function AnimationTiming:rpd()
	return self._rpd / 1000
end

---Load from partial values.
---@param values table
function AnimationTiming:load(values)
	Timing.load(self, values)

	if typeof(values._id) == "string" then
		self._id = values._id
	end

	if type(values.rsd) == "number" then
		self._rsd = values.rsd
	end

	if typeof(values.rpd) == "number" then
		self._rpd = values.rpd
	end

	if typeof(values.rpue) == "boolean" then
		self.rpue = values.rpue
	end

	if typeof(values.ha) == "boolean" then
		self.ha = values.ha
	end

	if typeof(values.fhb) == "boolean" then
		self.fhb = values.fhb
	end

	if typeof(values.iae) == "boolean" then
		self.iae = values.iae
	end
end

---Clone timing.
---@return AnimationTiming
function AnimationTiming:clone()
	local clone = setmetatable(Timing.clone(self), AnimationTiming)

	clone._rsd = self._rsd
	clone._rpd = self._rpd
	clone._id = self._id
	clone.rpue = self.rpue
	clone.ha = self.ha
	clone.fhb = self.fhb
	clone.iae = self.iae

	return clone
end

---Return a serializable table.
---@return AnimationTiming
function AnimationTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable._id = self._id
	serializable.rsd = self._rsd
	serializable.rpd = self._rpd
	serializable.rpue = self.rpue
	serializable.ha = self.ha
	serializable.fhb = self.fhb
	serializable.iae = self.iae

	return serializable
end

---Create a new animation timing.
---@param values table?
---@return AnimationTiming
function AnimationTiming.new(values)
	local self = setmetatable(Timing.new(), AnimationTiming)

	self._id = ""
	self._rsd = 0
	self._rpd = 0
	self.rpue = false
	self.ha = false
	self.fhb = true
	self.iae = false

	if values then
		self:load(values)
	end

	return self
end

-- Return AnimationTiming module.
return AnimationTiming
