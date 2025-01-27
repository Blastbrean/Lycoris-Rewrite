---@module Game.Timings.ActionContainer
local ActionContainer = require("Game/Timings/ActionContainer")

---@class Timing
---@field name string
---@field tag string
---@field imdd number Initial minimum distance from position.
---@field imxd number Initial maximum distance from position.
---@field punishable number Punishable window in seconds.
---@field after number After window in seconds.
---@field duih boolean Delay until in hitbox.
---@field actions ActionContainer
local Timing = {}
Timing.__index = Timing

---Timing ID. Override me.
---@return string
function Timing:id()
	return self.name
end

---Set timing ID. Override me.
---@param id string
function Timing:set(id)
	self.name = id
end

---Load from partial values.
---@param values table
function Timing:load(values)
	if typeof(values.name) == "string" then
		self.name = values.name
	end

	if typeof(values.tag) == "string" then
		self.tag = values.tag
	end

	if typeof(values.imdd) == "number" then
		self.imdd = values.imdd
	end

	if typeof(values.imxd) == "number" then
		self.imxd = values.imxd
	end

	if typeof(values.duih) == "boolean" then
		self.duih = values.duih
	end

	if typeof(values.punishable) == "number" then
		self.punishable = values.punishable
	end

	if typeof(values.after) == "number" then
		self.after = values.after
	end

	if typeof(values.actions) == "table" then
		self.actions:load(values.actions)
	end
end

---Clone timing.
---@return Timing
function Timing:clone()
	local clone = Timing.new()

	clone.name = self.name
	clone.tag = self.tag
	clone.duih = self.duih
	clone.imdd = self.imdd
	clone.imxd = self.imxd
	clone.punishable = self.punishable
	clone.after = self.after
	clone.actions = self.actions:clone()

	return clone
end

---Return a serializable table.
---@return table
function Timing:serialize()
	return {
		name = self.name,
		tag = self.tag,
		imdd = self.imdd,
		imxd = self.imxd,
		duih = self.duih,
		punishable = self.punishable,
		after = self.after,
		actions = self.actions:serialize(),
	}
end

---Create new Timing object.
---@param values table?
---@return Timing
function Timing.new(values)
	local self = setmetatable({}, Timing)

	self.tag = "Undefined"
	self.name = "N/A"
	self.imdd = 0
	self.imxd = 0
	self.punishable = 0
	self.after = 0
	self.duih = false
	self.actions = ActionContainer.new()

	if values then
		self:load(values)
	end

	return self
end

-- Return Timing module.
return Timing
