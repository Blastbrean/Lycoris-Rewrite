-- This module is used for getting input values in a Vector3.
local ControlModule = {
	forwardValue = 0,
	backwardValue = 0,
	leftValue = 0,
	rightValue = 0,
}

ControlModule.__index = ControlModule

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Maid
local Maid = require("Utility/Maid")

-- Maids.
local controlMaid = Maid.new()

-- Services.
local ContextActionService = game:GetService("ContextActionService")

---Bind action safely with maid, error, and profiler handling.
---@param actionName string
---@param callback function
---@param createTouchButton boolean
local function bindActionWrapper(actionName, callback, createTouchButton, ...)
	---Log bind action errors.
	---@param error string
	local function onBindActionWrapperError(error)
		Logger.trace("onBindActionWrapperError - (%s) - %s", actionName, error)
	end

	local actionWrapperCallback = callback and Profiler.wrap(xpcall(callback, onBindActionWrapperError))

	controlMaid:add(ContextActionService:BindAction(actionName, actionWrapperCallback, createTouchButton, ...))
end

---Initialize control module.
function ControlModule.init()
	bindActionWrapper("ControlModule_ForwardValue", function(_, inputState, _)
		ControlModule.forwardValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.W)

	bindActionWrapper("ControlModule_LeftValue", function(_, inputState, _)
		ControlModule.leftValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.A)

	bindActionWrapper("ControlModule_BackwardValue", function(_, inputState, _)
		ControlModule.backwardValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.S)

	bindActionWrapper("ControlModule_RightValue", function(_, inputState, _)
		ControlModule.rightValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.D)
end

---Detach control module.
function ControlModule.detach()
	controlMaid:clean()
end

---Get move vector.
---@return Vector3
function ControlModule.getMoveVector()
	return Vector3.new(
		ControlModule.leftValue + ControlModule.rightValue,
		0,
		ControlModule.forwardValue + ControlModule.backwardValue
	)
end

-- Return control module.
return ControlModule
