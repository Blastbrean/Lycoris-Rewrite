---@class FiniteStateMachine
---@field states FiniteState[]
---@field current string Current identifier.
---@field initial string Initial identifier.
---@field started boolean
local FiniteStateMachine = {}
FiniteStateMachine.__index = FiniteStateMachine

---Create a new finite state machine.
---@param states FiniteState[]
---@param initial string
---@return FiniteStateMachine
function FiniteStateMachine.new(states, initial)
	local self = setmetatable({}, FiniteStateMachine)
	self.states = states
	self.current = initial
	self.initial = initial
	self.started = false

	-- Validate initial state.
	self:get(self.current)

	return self
end

---Get the current state. Non-failable.
---@param identifier string
---@return FiniteState
function FiniteStateMachine:get(identifier)
	for _, state in next, self.states do
		if state.identifier ~= identifier then
			continue
		end

		return state
	end

	return warn(string.format("(%s) State does not exist in states table.", identifier))
end

---Get a state
---@param identifier string
---@return boolean
function FiniteStateMachine:has(identifier)
	for _, state in next, self.states do
		if state.identifier ~= identifier then
			continue
		end

		return true
	end

	return false
end

---Stop the state machine.
function FiniteStateMachine:stop()
	-- Check if already stopped.
	if not self.started then
		return warn("Finite state machine has not been started.")
	end

	-- Detach current state.
	local current = self:get(self.current)
	current:detach()

	-- Reset state machine.
	self.started = false
	self.current = self.initial
end

---Start the state machine.
function FiniteStateMachine:start()
	-- Check if already started.
	if self.started then
		return warn("Finite state machine has already been started.")
	end

	-- Set initial state.
	self.started = true
	self.current = self.initial

	-- Start current state.
	local current = self:get(self.current)
	current:start(self)
end

---Transition to a new state identifier.
---@param identifier string
function FiniteStateMachine:transition(identifier)
	if not self.started then
		return warn("Finite state machine has not been started.")
	end

	-- Detach old state.
	local old = self:get(self.current)
	old:detach()

	-- Set new state.
	self.current = identifier

	-- Start new state.
	local new = self:get(identifier)
	new:start(self)
end

-- Return FiniteStateMachine module.
return FiniteStateMachine
