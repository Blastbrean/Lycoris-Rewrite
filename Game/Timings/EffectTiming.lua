---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class EffectTiming: Timing
---@field ename string Effect name.
---@field rpue boolean Repeat parry until end.
---@field rpd number Delay between each repeat parry.
local EffectTiming = setmetatable({}, { __index = Timing })
EffectTiming.__index = EffectTiming

---Timing ID.
---@return string
function EffectTiming:id()
	return self.ename
end

---Load from partial values.
---@param values table
function EffectTiming:load(values)
	Timing.load(self, values)

	if typeof(values.ename) == "string" then
		self.ename = values.ename
	end

	if typeof(values.rpue) == "boolean" then
		self.rpue = values.rpue
	end

	if typeof(values.rpd) == "number" then
		self.rpd = values.rpd
	end
end

---Clone timing.
---@return EffectTiming
function EffectTiming:clone()
	local clone = setmetatable(Timing.clone(self), EffectTiming)

	clone.id = self.id
	clone.rpd = self.rpd
	clone.rpue = self.rpue

	return clone
end

---Return a serializable table.
---@return EffectTiming
function EffectTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable.id = self.id
	serializable.rpue = self.rpue
	serializable.rpd = self.rpd

	return serializable
end

---Create a new effect timing.
---@param values table?
---@return EffectTiming
function EffectTiming.new(values)
	local self = setmetatable(Timing.new(), EffectTiming)

	self.id = ""
	self.rpue = false
	self.rpd = 0

	if values then
		self:load(values)
	end

	return self
end

-- Return EffectTiming module.
return EffectTiming
