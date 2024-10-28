-- Wrapper for Roblox's signals for safe connections to signals.
-- Automatically profiles signals & wraps them in a safe alternative.
---@class Signal
---@field signal RBXScriptSignal Underlying roblox script signal
local Signal = {}
Signal.__index = Signal

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---Safely connect to Roblox's signal.
---@param label string
---@param eventFunction function
---@return RBXScriptConnection
function Signal:connect(label, eventFunction)
	---Log event errors.
	---@param error string
	local function onEventFunctionError(error)
		Logger.trace("onEventFunctionError - (%s) - %s", label, error)
	end

	-- Connect to signal. Wrap function with profiler and error handling.
	local connection = self.signal:Connect(Profiler.wrap(label, xpcall(eventFunction, onEventFunctionError)))

	-- Return connection.
	return connection
end

---Create new wrapper signal object.
---@param robloxSignal RBXScriptSignal
---@return Signal
function Signal.new(robloxSignal)
	-- Create new wrapper signal object.
	local self = setmetatable({}, Signal)
	self.signal = robloxSignal

	-- Return new wrapper signal object.
	return self
end

-- Return Signal module.
return Signal
