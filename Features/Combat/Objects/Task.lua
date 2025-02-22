---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@class Task
---@field thread thread
---@field identifier string
---@field when number A timestamp when the task will be executed.
---@field punishable number A window in seconds where the task can be punished.
---@field after number A window in seconds where the task can be executed.
local Task = {}
Task.__index = Task

---Check if task should block the input.
---@return boolean
function Task:blocking()
	if not (coroutine.status(self.thread) ~= "dead") then
		return false
	end

	-- We've exceeded the execution time. Block if we're within the after window.
	if os.clock() >= self.when then
		return os.clock() <= self.when + self.after
	end

	---@note: Allow us to do inputs up until a certain amount of time before the task happens.
	return os.clock() >= self.when - self.punishable
end

---Cancel task.
function Task:cancel()
	if coroutine.status(self.thread) ~= "suspended" then
		return
	end

	task.cancel(self.thread)
end

---Create new Task object.
---@param identifier string
---@param delay number
---@param punishable number
---@param after number
---@param callback function
---@vararg any
---@return Task
function Task.new(identifier, delay, punishable, after, callback, ...)
	local self = setmetatable({}, Task)
	self.thread = TaskSpawner.delay("Action_" .. identifier, delay, callback, ...)
	self.identifier = identifier
	self.when = os.clock() + delay
	self.punishable = punishable
	self.after = after

	if not self.punishable or self.punishable <= 0 then
		self.punishable = Configuration.expectOptionValue("DefaultPunishableWindow") or 0.7
	end

	if not self.after or self.after <= 0 then
		self.after = Configuration.expectOptionValue("DefaultAfterWindow") or 0.1
	end

	return self
end

-- Return Task module.
return Task
