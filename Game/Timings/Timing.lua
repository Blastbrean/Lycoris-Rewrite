---@module Game.Timings.ActionContainer
local ActionContainer = require("Game/Timings/ActionContainer")

---@class Timing
---@field name string
---@field tag string
---@field hitbox Vector3
---@field duih boolean Delay until in hitbox.
---@field actions ActionContainer
local Timing = {}
Timing.__index = Timing

---Timing ID. Override me.
---@return string
function Timing:id()
	return self.name
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

	if typeof(values.hitbox) == "table" then
		self.hitbox = Vector3.new(values.hitbox.X, values.hitbox.Y, values.hitbox.Z)
	end

	if typeof(values.duih) == "boolean" then
		self.duih = values.duih
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
	clone.hitbox = self.hitbox
	clone.duih = self.duih
	clone.actions = self.actions:clone()

	return clone
end

---Return a serializable table.
---@return table
function Timing:serialize()
	return {
		name = self.name,
		tag = self.tag,
		hitbox = {
			X = self.hitbox.X,
			Y = self.hitbox.Y,
			Z = self.hitbox.Z,
		},
		actions = self.actions,
	}
end

---Create new Timing object.
---@param values table?
---@return Timing
function Timing.new(values)
	local self = setmetatable({}, Timing)

	self.tag = "Undefined"
	self.name = "N/A"
	self.hitbox = Vector3.zero
	self.duih = false
	self.actions = ActionContainer.new()

	if values then
		self:load(values)
	end

	return self
end

-- Return Timing module.
return Timing
