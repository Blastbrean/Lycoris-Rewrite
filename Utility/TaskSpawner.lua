-- Task spawner module.
local TaskSpawner = {}

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---Spawn delayed task.
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

	-- Wrap callback in profiler and error handling.
	local taskFunction = Profiler.wrap(
		label,
		LPH_NO_VIRTUALIZE(function(...)
			return xpcall(callback, onTaskFunctionError, ...)
		end)
	)

	return task.delay(delay, taskFunction, ...)
end

---Spawn task.
---@param label string
---@param callback function
---@vararg any
function TaskSpawner.spawn(label, callback, ...)
	---Log task errors.
	---@param error string
	local function onTaskFunctionError(error)
		Logger.trace("onTaskFunctionError - (%s) - %s", label, error)
	end

	-- Wrap callback in profiler and error handling.
	local taskFunction = Profiler.wrap(
		label,
		LPH_NO_VIRTUALIZE(function(...)
			return xpcall(callback, onTaskFunctionError, ...)
		end)
	)

	-- Return reference.
	return task.spawn(taskFunction, ...)
end

-- Return TaskSpawner module.
return TaskSpawner
