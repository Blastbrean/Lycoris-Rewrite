---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.InstanceWrapper
local InstanceWrapper = require("Utility/InstanceWrapper")

---@class Defender
---@field tasks Task[]
local Defender = {}
Defender.__index = Defender
Defender.__type = "Defender"

-- Services.
local stats = game:GetService("Stats")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Check if we're in a valid state to proceed with action handling. Extend me.
---@param timing Timing
---@param action Action
---@return boolean
function Defender:valid(timing, action)
	return true
end

---Run hitbox check. Returns wheter if the hitbox is being touched.
---@note: This check can fail when players suddenly look...
---@param cframe CFrame
---@param size Vector3
---@param filter Instance[]
---@return boolean
function Defender:hitbox(cframe, size, filter)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = filter
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	---@todo: Make the visualizations better. This is just for debugging. Right now, they don't clear up properly.
	if Configuration.expectToggleValue("EnableVisualizations") then
		local visualizationPart = InstanceWrapper.create(self.maid, "VisualizationPart", "Part")
		visualizationPart.Size = size
		visualizationPart.CFrame = cframe
		visualizationPart.Transparency = 0.85
		visualizationPart.Color = Color3.fromRGB(0, 255, 0)
		visualizationPart.Parent = workspace
		visualizationPart.Anchored = true
		visualizationPart.CanCollide = false
		visualizationPart.Material = Enum.Material.SmoothPlastic
	end

	return #workspace:GetPartBoundsInBox(cframe, size, overlapParams) > 0
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

	self:notify(timing, "Action type '%s' is being executed.", action._type)

	if action._type == "Start Block" then
		return InputClient.bstart()
	end

	if action._type == "End Block" then
		return InputClient.bend()
	end

	if action._type == "Dodge" then
		return InputClient.dodge()
	end

	---@note: Okay, we'll assume that we're in the parry state. There's no other type.
	if effectReplicatorModule:FindEffect("ParryCool") and Configuration.expectToggleValue("RollOnParryCooldown") then
		self:notify(timing, "Action type 'Parry' overrided to 'Dodge' type.")
		return InputClient.dodge()
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
			Task.new(
				string.format("Action_%s", action._type),
				action:when() - ping,
				timing.punishable,
				timing.after,
				self.handle,
				self,
				timing,
				action
			)
		)

		-- Log.
		self:notify(timing, "Added action '%s' (%.2fs) with ping '%.2f' subtracted.", action.name, action:when(), ping)
	end
end

---Detach defender object.
function Defender:detach()
	self:clean()
	self.maid:clean()
	self = nil
end

---Create new Defender object.
function Defender.new()
	local self = setmetatable({}, Defender)
	self.tasks = {}
	self.maid = Maid.new()
	return self
end

-- Return Defender module.
return Defender
