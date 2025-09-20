---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class PartTiming: Timing
---@field pname string Part name.
---@field uhc boolean Use hitbox CFrame.
local PartTiming = setmetatable({}, { __index = Timing })
PartTiming.__index = PartTiming

---Timing ID.
---@return string
function PartTiming:id()
	return self.pname
end

---Load from partial values.
---@param values table
function PartTiming:load(values)
	Timing.load(self, values)

	if typeof(values.pname) == "string" then
		self.pname = values.pname
	end

	if typeof(values.uhc) == "boolean" then
		self.uhc = values.uhc
	end
end

---Equals check.
---@param other PartTiming
---@return boolean
function PartTiming:equals(other)
	if not Timing.equals(self, other) then
		return false
	end

	if self.pname ~= other.pname then
		return false
	end

	if self.uhc ~= other.uhc then
		return false
	end

	return true
end

---Clone timing.
---@return PartTiming
function PartTiming:clone()
	local clone = setmetatable(Timing.clone(self), PartTiming)

	clone.pname = self.pname
	clone.uhc = self.uhc

	return clone
end

---Return a serializable table.
---@return PartTiming
function PartTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable.pname = self.pname
	serializable.uhc = self.uhc

	return serializable
end

---Create a new part timing.
---@param values table?
---@return PartTiming
function PartTiming.new(values)
	local self = setmetatable(Timing.new(), PartTiming)

	self.pname = ""
	self.uhc = false

	if values then
		self:load(values)
	end

	return self
end

-- Return PartTiming module.
return PartTiming
