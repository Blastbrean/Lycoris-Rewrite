-- Task spawner module.
local TaskSpawner = {}

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---Spawn delayed task. Tasks will be killed upon execution.
---@param label string
---@param delay number
---@param callback function
---@vararg any
function TaskSpawner.delay(label, delay, callback, ...)
	---Log task errors.
	---@param error string
	local function onTaskFunctionError(error)
		Logger.trace("onTaskFunctionError - (%s) - %s", label, error)
	end

	-- Store task reference.
	local taskReference = nil

	-- Wrap callback in profiler and error handling.
	local taskFunction = Profiler.wrap(label, function(...)
		return xpcall(function(...)
			-- Run callback.
			callback(...)

			-- Kill task.
			task.cancel(taskReference)
		end, onTaskFunctionError, ...)
	end)

	-- Spawn delayed task.
	taskReference = task.delay(delay, taskFunction, ...)

	-- Return reference.
	return taskReference
end

---Spawn task. Tasks will be killed upon execution.
---@param label string
---@param callback function
---@vararg any
function TaskSpawner.spawn(label, callback, ...)
	---Log task errors.
	---@param error string
	local function onTaskFunctionError(error)
		Logger.trace("onTaskFunctionError - (%s) - %s", label, error)
	end

	-- Store task reference.
	local taskReference = nil

	-- Wrap callback in profiler and error handling.
	local taskFunction = Profiler.wrap(label, function(...)
		return xpcall(function(...)
			-- Run callback.
			callback(...)

			-- Kill task.
			task.cancel(taskReference)
		end, onTaskFunctionError, ...)
	end)

	-- Spawn delayed task.
	taskReference = task.spawn(taskFunction, ...)

	-- Return reference.
	return taskReference
end

-- Return TaskSpawner module.
return TaskSpawner
