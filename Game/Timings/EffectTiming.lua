---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class EffectTiming: Timing
---@field ename string Effect name.
---@field rpue boolean Repeat parry until end.
---@field _rsd number Repeat start delay in miliseconds. Never access directly.
---@field _rpd number Delay between each repeat parry in miliseconds. Never access directly.
local EffectTiming = setmetatable({}, { __index = Timing })
EffectTiming.__index = EffectTiming

---Timing ID.
---@return string
function EffectTiming:id()
	return self.ename
end

---Equals check.
---@param other EffectTiming
---@return boolean
function EffectTiming:equals(other)
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

	if self.ename ~= other.ename then
		return false
	end

	return true
end

---Getter for repeat start delay in seconds.
---@return number
function EffectTiming:rsd()
	return PP_SCRAMBLE_NUM(self._rsd) / 1000
end

---Getter for repeat start delay in seconds.
---@return number
function EffectTiming:rpd()
	return PP_SCRAMBLE_NUM(self._rpd) / 1000
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
	clone._rsd = self._rsd
	clone.rpue = self.rpue

	return clone
end

---Return a serializable table.
---@return EffectTiming
function EffectTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable.ename = self.ename
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
