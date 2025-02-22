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

---@module GUI.Library
local Library = require("GUI/Library")

---@class Defender
---@field tasks Task[]
local Defender = {}
Defender.__index = Defender
Defender.__type = "Defender"

-- Services.
local stats = game:GetService("Stats")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local textChatService = game:GetService("TextChatService")

---Log a miss to the UI library with distance check.
---@param type string
---@param key string
---@param name string?
---@param distance number
---@return boolean
function Defender:miss(type, key, name, distance)
	if not Configuration.expectToggleValue("ShowLoggerWindow") then
		return false
	end

	if
		distance < (Configuration.expectOptionValue("MinimumLoggerDistance") or 0)
		or distance > (Configuration.expectOptionValue("MaximumLoggerDistance") or 0)
	then
		return false
	end

	Library:AddMissEntry(type, key, name, distance)

	return true
end

---Fetch distance.
---@param from Model? | BasePart?
---@return number?
function Defender:distance(from)
	if not from then
		return
	end

	local entRootPart = from

	if from:IsA("Model") then
		entRootPart = from:FindFirstChild("HumanoidRootPart")
	end

	if not entRootPart then
		return
	end

	local localCharacter = players.LocalPlayer.Character
	if not localCharacter then
		return
	end

	local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return
	end

	return (entRootPart.Position - localRootPart.Position).Magnitude
end

---Check if we're in a valid state to proceed with action handling. Extend me.
---@param timing Timing
---@param action Action
---@return boolean
Defender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
	local keybinds = replicatedStorage:FindFirstChild("KeyBinds")
	if not keybinds then
		return self:notify(timing, "No keybinds instance found.")
	end

	local keybindsModule = require(keybinds)
	if not keybindsModule or not keybindsModule.Current then
		return self:notify(timing, "No keybinds module found.")
	end

	for _, keybind in next, keybindsModule.Current["Block"] or {} do
		if not userInputService:IsKeyDown(Enum.KeyCode[tostring(keybind)]) then
			continue
		end

		if not Configuration.expectToggleValue("CheckHoldingBlockInput") then
			continue
		end

		return self:notify(timing, "User is pressing down on a key binded to Block.")
	end

	local chatInputBarConfiguration = textChatService:FindFirstChildOfClass("ChatInputBarConfiguration")

	if
		Configuration.expectToggleValue("CheckTextboxFocus")
		and (userInputService:GetFocusedTextBox() or chatInputBarConfiguration.IsFocused)
	then
		return self:notify(timing, "User is typing in a text box.")
	end

	if Configuration.expectToggleValue("CheckWindowActive") and not iswindowactive() then
		return self:notify(timing, "Window is not active.")
	end

	return true
end)

---Run hitbox check. Returns wheter if the hitbox is being touched.
---@note: This check can fail when players suddenly look...
---@param position Vector3
---@param depth number
---@param size Vector3
---@param filter Instance[]
---@return boolean
Defender.hitbox = LPH_NO_VIRTUALIZE(function(self, position, depth, size, filter)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = filter
	overlapParams.FilterType = Enum.RaycastFilterType.Include

	local character = players.LocalPlayer.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	---@todo: Bad fix. The issue is that the player's current look vector will not be the same as when they attack due to a parry timing being seperate from the attack.
	local realCFrame = CFrame.lookAt(position, root.Position)

	-- Add depth.
	if depth > 0 then
		realCFrame = realCFrame * CFrame.new(0, 0, -depth)
	end

	-- Check in bounds.
	local inBounds = #workspace:GetPartBoundsInBox(realCFrame, size, overlapParams) > 0

	-- Visualize color.
	local visColor = inBounds and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

	---@todo: Make the visualizations better. This is just for debugging. Right now, they don't clear up properly.
	if Configuration.expectToggleValue("EnableVisualizations") then
		local visualizationPart = InstanceWrapper.create(self.maid, "VisualizationPart", "Part")
		visualizationPart.Size = size
		visualizationPart.CFrame = realCFrame
		visualizationPart.Transparency = 0.85
		visualizationPart.Color = visColor
		visualizationPart.Parent = workspace
		visualizationPart.Anchored = true
		visualizationPart.CanCollide = false
		visualizationPart.Material = Enum.Material.SmoothPlastic

		local playerVisPart = InstanceWrapper.create(self.maid, "PlayerVisualizationPart", "Part")
		playerVisPart.Size = root.Size
		playerVisPart.CFrame = root.CFrame
		playerVisPart.Transparency = 0.85
		playerVisPart.Color = visColor
		playerVisPart.Parent = workspace
		playerVisPart.Anchored = true
		playerVisPart.CanCollide = false
		playerVisPart.Material = Enum.Material.Plastic
	end

	return inBounds
end)

---Check initial state.
---@param from Model? | BasePart?
---@param pair TimingContainerPair
---@param name string
---@param key string
---@return Timing?
Defender.initial = LPH_NO_VIRTUALIZE(function(self, from, pair, name, key)
	-- Find timing.
	local timing = pair:index(key)

	-- Fetch distance.
	local distance = self:distance(from)
	if not distance then
		return nil
	end

	-- Check for distance; if we have a timing.
	if timing and (distance < timing.imdd or distance > timing.imxd) then
		return nil
	end

	-- Check for no timing. If so, let's log a miss.
	---@note: Ignore return value.
	if not timing then
		self:miss(self.__type, key, name, distance)
		return nil
	end

	-- Return timing.
	return timing
end)

---Logger notify.
---@param timing Timing
---@param str string
Defender.notify = LPH_NO_VIRTUALIZE(function(self, timing, str, ...)
	if not Configuration.expectToggleValue("EnableNotifications") then
		return
	end

	Logger.notify("[%s] (%s) %s", timing.name, self.__type, string.format(str, ...))
end)

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
Defender.handle = LPH_NO_VIRTUALIZE(function(self, timing, action)
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
end)

---Check if we have input blocking tasks.
---@return boolean
Defender.blocking = LPH_NO_VIRTUALIZE(function(self)
	for _, task in next, self.tasks do
		if not task:blocking() then
			continue
		end

		return true
	end
end)

---Mark task.
---@param task Task
function Defender:mark(task)
	self.tasks[#self.tasks + 1] = task
end

---Clean up all tasks.
Defender.clean = LPH_NO_VIRTUALIZE(function(self)
	-- Was there a start block?
	local blocking = false

	for idx, task in next, self.tasks do
		-- Cancel task.
		task:cancel()

		-- Clear in table.
		self.tasks[idx] = nil

		-- Check.
		blocking = blocking or task.identifier == "Start Block"
	end

	-- End block if we're blocking.
	if blocking then
		InputClient.bend()
	end
end)

---Add actions from timing to defender object.
---@param timing Timing
---@param multiplier number
Defender.actions = LPH_NO_VIRTUALIZE(function(self, timing, multiplier)
	for _, action in next, timing.actions:get() do
		-- Get ping.
		local ping = self:ping()

		-- Add action.
		self:mark(
			Task.new(
				action._type,
				(action:when() - ping) * (multiplier or 1),
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
end)

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
