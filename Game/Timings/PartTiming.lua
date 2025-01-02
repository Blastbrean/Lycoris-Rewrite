---@module Game.Timings.Timing
local Timing = require("Game/Timings/Timing")

---@class PartTiming: Timing
---@field pname string Part name.
---@field td number Timing delay.
---@field filter string[] Part names to look for.
---@field imdd number Initial minimum distance.
---@field imxd number Initial maximum distance.
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

	if typeof(values.td) == "number" then
		self.td = values.td
	end

	if typeof(values.filter) == "table" then
		self.filter = values.filter
	end

	if typeof(values.imdd) == "number" then
		self.imdd = values.imdd
	end

	if typeof(values.imxd) == "number" then
		self.imxd = values.imxd
	end
end

---Clone timing.
---@return PartTiming
function PartTiming:clone()
	local clone = setmetatable(Timing.clone(self), PartTiming)

	clone.pname = self.pname
	clone.td = self.td
	clone.filter = self.filter
	clone.imdd = self.imdd
	clone.imxd = self.imxd

	return clone
end

---Return a serializable table.
---@return PartTiming
function PartTiming:serialize()
	local serializable = Timing.serialize(self)

	serializable.pname = self.pname
	serializable.td = self.td
	serializable.filter = self.filter
	serializable.imdd = self.imdd
	serializable.imxd = self.imxd

	return serializable
end

---Create a new part timing.
---@param values table?
---@return PartTiming
function PartTiming.new(values)
	local self = setmetatable(Timing.new(), PartTiming)

	self.pname = ""
	self.filter = {}
	self.td = 0
	self.imdd = 0
	self.imxd = 0

	if values then
		self:load(values)
	end

	return self
end

-- Return PartTiming module.
return PartTiming
