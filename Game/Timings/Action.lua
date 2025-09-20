---@class Action
---@field _type string
---@field _when number When the action will occur in miliseconds. Never access directly.
---@field hitbox Vector3 The hitbox of the action.
---@field ihbc boolean Ignore hitbox check.
---@field name string The name of the action.
---@field tp number Time position. Never accessible unless inside of a module or inside of real code. This is never serialized.
local Action = {}
Action.__index = Action

---Getter for when in seconds.
---@return number
function Action:when()
	return PP_SCRAMBLE_NUM(self._when) / 1000
end

---Load from partial values.
---@param values table
function Action:load(values)
	if typeof(values._type) == "string" then
		self._type = values._type
	end

	if typeof(values.when) == "number" then
		self._when = values.when
	end

	if typeof(values.name) == "string" then
		self.name = values.name
	end

	if typeof(values.hitbox) == "table" then
		self.hitbox = Vector3.new(values.hitbox.X, values.hitbox.Y, values.hitbox.Z)
	end

	if typeof(values.ihbc) == "boolean" then
		self.ihbc = values.ihbc
	end
end

---Equals check.
---@param other Action
---@return boolean
function Action:equals(other)
	if self._type ~= other._type then
		return false
	end

	if self._when ~= other._when then
		return false
	end

	if self.name ~= other.name then
		return false
	end

	if self.hitbox ~= other.hitbox then
		return false
	end

	if self.ihbc ~= other.ihbc then
		return false
	end

	return true
end

---Clone action.
---@return Action
function Action:clone()
	local clone = Action.new()

	clone._type = self._type
	clone._when = self._when
	clone.name = self.name
	clone.hitbox = self.hitbox
	clone.ihbc = self.ihbc

	return clone
end

---Return a serializable table.
---@return table
function Action:serialize()
	return {
		_type = self._type,
		when = self._when,
		name = self.name,
		hitbox = {
			X = self.hitbox.X,
			Y = self.hitbox.Y,
			Z = self.hitbox.Z,
		},
		ihbc = self.ihbc,
	}
end

---Create new Action object.
---@param values table?
---@return Action
function Action.new(values)
	local self = setmetatable({}, Action)

	self._type = "N/A"
	self._when = 0
	self.name = ""
	self.hitbox = Vector3.zero
	self.ihbc = false
	self.tp = 0

	if values then
		self:load(values)
	end

	return self
end

-- Return Action module.
return Action
