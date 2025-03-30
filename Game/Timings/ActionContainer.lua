---@module Game.Timings.Action
local Action = require("Game/Timings/Action")

---@class ActionContainer
---@field _data table<string, Action>
local ActionContainer = {}
ActionContainer.__index = ActionContainer

---Clone action container.
---@return ActionContainer
function ActionContainer:clone()
	local clone = ActionContainer.new()

	for _, action in next, self._data do
		clone:push(action:clone())
	end

	return clone
end

---Find a action from name.
---@param name string
---@return Action?
function ActionContainer:find(name)
	return self._data[name]
end

---Remove a action from the list.
---@param action Action
function ActionContainer:remove(action)
	self._data[action.name] = nil
end

---Push a action to the list.
---@param action Action
function ActionContainer:push(action)
	local name = action.name

	---@note: Action array keys must all be unique.
	if self._data[name] then
		return error(string.format("Action name '%s' already exists in container.", name))
	end

	self._data[name] = action
end

---Load from partial values.
---@param values table
function ActionContainer:load(values)
	for _, data in next, values do
		self:push(Action.new(data))
	end
end

---List all action names.
---@return string[]
function ActionContainer:names()
	local names = {}

	for name, _ in next, self._data do
		table.insert(names, name)
	end

	return names
end

---Get action count.
---@return number
function ActionContainer:count()
	local count = 0

	for _, _ in next, self._data do
		count = count + 1
	end

	return count
end

---Get action data.
---@return table<string, Action>
function ActionContainer:get()
	return self._data
end

---Return a serializable table.
---@return table
function ActionContainer:serialize()
	local data = {}

	for _, action in next, self._data do
		table.insert(data, action:serialize())
	end

	return data
end

---Create new ActionContainer object.
---@param values table?
---@return ActionContainer
function ActionContainer.new(values)
	local self = setmetatable({}, ActionContainer)

	self._data = {}

	if values then
		self:load(values)
	end

	return self
end

-- Return ActionContainer module.
return ActionContainer
