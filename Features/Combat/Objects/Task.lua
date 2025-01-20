---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@class Task
---@field thread thread
---@field when number A timestamp when the task will be executed.
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
		return os.clock() <= self.when + Configuration.expectOptionValue("AfterWindow")
	end

	---@note: Allow us to do inputs up until a certain amount of time before the task happens.
	return os.clock() >= self.when - Configuration.expectOptionValue("PunishableWindow")
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
---@param callback function
---@vararg any
---@return Task
function Task.new(identifier, delay, callback, ...)
	local self = setmetatable({}, Task)
	self.thread = TaskSpawner.delay(identifier, delay, callback, ...)
	self.when = os.clock() + delay
	return self
end

-- Return Task module.
return Task
