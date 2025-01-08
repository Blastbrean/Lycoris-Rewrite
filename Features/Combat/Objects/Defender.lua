---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@class Defender
---@field maid Maid
local Defender = {}
Defender.__index = Defender

-- Services.
local players = game:GetService("Players")

---Check if we're in a valid state to proceed with action handling. Extend me.
---@param action Action
---@return boolean
function Defender:valid(action)
	return true
end

---Handle action.
---@param action Action
function Defender:handle(action)
	if not self:valid(action) then
		return
	end

	Logger.notify("Action type '%s' is being executed.", action._type)

	if action._type == "Parry" then
		InputClient.parry()
	end

	if action._type == "Start Block" then
		InputClient.bstart()
	end

	if action._type == "End Block" then
		InputClient.bend()
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	if action._type == "Dodge" then
		InputClient.dodge(root, humanoid)
	end
end

---Create new Defender object.
function Defender.new()
	return setmetatable({}, Defender)
end

-- Return Defender module.
return Defender
