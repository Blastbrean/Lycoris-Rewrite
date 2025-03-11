---@class Action
---@field _type string
---@field _when number When the action will occur in miliseconds. Never access directly.
---@field adelta number Animation delta if applicable.
---@field uad boolean Use animation delta.
---@field hitbox Vector3 The hitbox of the action.
local Action = {}
Action.__index = Action

---Getter for when in seconds.
---@return number
function Action:when()
	return self._when / 1000
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

	if typeof(values.adelta) == "number" then
		self.adelta = values.adelta
	end

	if typeof(values.uad) == "boolean" then
		self.uad = values.uad
	end
end

---Clone action.
---@return Action
function Action:clone()
	local clone = Action.new()

	clone._type = self._type
	clone._when = self._when
	clone.name = self.name
	clone.hitbox = self.hitbox
	clone.adelta = self.adelta
	clone.uad = self.uad

	return clone
end

---Return a serializable table.
---@return table
function Action:serialize()
	return {
		_type = self._type,
		when = self._when,
		name = self.name,
		adelta = self.adelta,
		uad = self.uad,
		hitbox = {
			X = self.hitbox.X,
			Y = self.hitbox.Y,
			Z = self.hitbox.Z,
		},
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
	self.adelta = 0
	self.uad = false

	if values then
		self:load(values)
	end

	return self
end

-- Return Action module.
return Action
