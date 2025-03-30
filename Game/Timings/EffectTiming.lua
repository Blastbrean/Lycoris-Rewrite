---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class EffectTiming: Timing
---@field ename string Effect name.
---@field rpue boolean Repeat parry until end.
---@param fhb boolean Flag to see whether or not this timing should offset facing.
---@field _rsd number Repeat start delay in miliseconds. Never access directly.
---@field _rpd number Delay between each repeat parry in miliseconds. Never access directly.
local EffectTiming = setmetatable({}, { __index = Timing })
EffectTiming.__index = EffectTiming

---Timing ID.
---@return string
function EffectTiming:id()
	return self.ename
end

---Getter for repeat start delay in seconds.
---@return number
function EffectTiming:rsd()
	return self._rsd / 1000
end

---Getter for repeat start delay in seconds.
---@return number
function EffectTiming:rpd()
	return self._rpd / 1000
end

---Load from partial values.
---@param values table
function EffectTiming:load(values)
	Timing.load(self, values)

	if typeof(values.ename) == "string" then
		self.ename = values.ename
	end

	if typeof(values.rsd) == "number" then
		self._rsd = values.rsd
	end

	if typeof(values.fhb) == "boolean" then
		self.fhb = values.fhb
	end

	if typeof(values.rpue) == "boolean" then
		self.rpue = values.rpue
	end

	if typeof(values.rpd) == "number" then
		self._rpd = values.rpd
	end
end

---Clone timing.
---@return EffectTiming
function EffectTiming:clone()
	local clone = setmetatable(Timing.clone(self), EffectTiming)

	clone.ename = self.ename
	clone._rpd = self._rpd
	clone.fhb = self.fhb
	clone._rsd = self._rsd
	clone.rpue = self.rpue

	return clone
end

---Return a serializable table.
---@return EffectTiming
function EffectTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable.ename = self.ename
	serializable.fhb = self.fhb
	serializable.rpue = self.rpue
	serializable.rsd = self._rsd
	serializable.rpd = self._rpd

	return serializable
end

---Create a new effect timing.
---@param values table?
---@return EffectTiming
function EffectTiming.new(values)
	local self = setmetatable(Timing.new(), EffectTiming)

	self.fhb = false
	self.ename = ""
	self.rpue = false
	self._rsd = 0
	self._rpd = 0

	if values then
		self:load(values)
	end

	return self
end

-- Return EffectTiming module.
return EffectTiming
