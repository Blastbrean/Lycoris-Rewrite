---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@class Defender
---@field tasks Task[]
local Defender = {}
Defender.__index = Defender

-- Services.
local players = game:GetService("Players")
local stats = game:GetService("Stats")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Check if we're in a valid state to proceed with action handling. Extend me.
---@param timing Timing
---@param action Action
---@return boolean
function Defender:valid(timing, action)
	return true
end

---Logger notify.
---@param timing Timing
---@param str string
function Defender:notify(timing, str, ...)
	if not Configuration.expectToggleValue("EnableNotifications") then
		return
	end

	Logger.notify("[%s] %s", timing.name, string.format(str, ...))
end

---Get ping.
---@return number
function Defender:ping()
	local network = stats:FindFirstChild("Network")
	if not network then
		return
	end

	local serverStatsItem = network:FindFirstChild("ServerStatsItem")
	if not serverStatsItem then
		return
	end

	local dataPingItem = serverStatsItem:FindFirstChild("Data Ping")
	if not dataPingItem then
		return
	end

	return dataPingItem:GetValue() / 1000
end

---Handle action.
---@param timing Timing
---@param action Action
function Defender:handle(timing, action)
	if not self:valid(timing, action) then
		return
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
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

	Logger.notify("Action type '%s' is being executed.", action._type)

	if action._type == "Start Block" then
		return InputClient.bstart()
	end

	if action._type == "End Block" then
		return InputClient.bend()
	end

	if action._type == "Dodge" then
		return InputClient.dodge(root, humanoid)
	end

	---@note: Okay, we'll assume that we're in the parry state. There's no other type.
	if effectReplicatorModule:FindEffect("ParryCool") and Configuration.expectToggleValue("RollOnParryCooldown") then
		return InputClient.dodge(root, humanoid)
	end

	InputClient.parry()
end

---Check if we have input blocking tasks.
---@return boolean
function Defender:blocking()
	for _, task in next, self.tasks do
		if not task:blocking() then
			continue
		end

		return true
	end
end

---Mark task.
---@param task Task
function Defender:mark(task)
	self.tasks[#self.tasks + 1] = task
end

---Clean up all tasks.
function Defender:clean()
	for idx, task in next, self.tasks do
		-- Cancel task.
		task:cancel()

		-- Clear in table.
		self.tasks[idx] = nil
	end
end

---Add actions from timing to defender object.
---@param timing Timing
function Defender:actions(timing)
	for _, action in next, timing.actions:get() do
		-- Get ping.
		local ping = self:ping()

		-- Add action.
		self:mark(
			Task.new(string.format("Action_%s", action._type), action:when() - ping, self.handle, self, timing, action)
		)

		-- Log.
		self:log(timing, "Added action '%s' (%.2fs) with ping '%.2f' subtracted.", action.name, action:when(), ping)
	end
end

---Create new Defender object.
function Defender.new()
	local self = setmetatable({}, Defender)
	self.tasks = {}
	return self
end

-- Return Defender module.
return Defender
