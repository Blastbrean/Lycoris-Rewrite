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

---@module GUI.Library
local Library = require("GUI/Library")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@class Defender
---@field tasks Task[]
---@field tmaid Maid Cleaned up every clean cycle.
---@field rhook table<string, function> Hooked functions that we can restore on clean-up.
---@field markers table<string, boolean> Blocking markers for unknown length timings. If the entry exists and is true, then we're blocking.
---@field maid Maid
---@field vpart Part?
---@field ppart Part?
local Defender = {}
Defender.__index = Defender
Defender.__type = "Defender"

-- Services.
local stats = game:GetService("Stats")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local textChatService = game:GetService("TextChatService")

-- Constants.
local MAX_VISUALIZATION_TIME = 5.0
local MAX_DUIH_WAIT = 10.0

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

---Call RPUE function.
---@param entity Model
---@param track AnimationTrack?
---@param timing Timing
---@param index number
---@param start number
Defender.crpue = LPH_NO_VIRTUALIZE(function(self, entity, track, timing, index, start)
	-- Check if we're in the initial condition.
	local initial = index == 0

	-- Fetch delay depending on if we're on the initial condition or not.
	local tdelay = initial and timing:rsd() or timing:rpd()

	-- Spawn task.
	self:mark(
		Task.new(
			string.format("RPUE_%s_%i", timing.name, index),
			tdelay - self:ping(),
			timing.punishable,
			timing.after,
			self.rpue,
			self,
			entity,
			track,
			timing,
			index,
			start
		)
	)

	-- Don't notify if we're not on the initial condition.
	if not initial then
		return
	end

	-- Notify.
	self:notify(
		timing,
		"Added RPUE '%s' (%.2fs, then every %.2fs) with relevant ping subtracted.",
		timing.name,
		timing:rsd(),
		timing:rpd()
	)
end)

---Repeat until parry end.
---@param entity Model
---@param track AnimationTrack?
---@param timing Timing
---@param index number
---@param start number
Defender.rpue = LPH_NO_VIRTUALIZE(function(self, entity, track, timing, index, start)
	local distance = self:distance(entity)
	if not distance then
		return Logger.warn("Stopping RPUE '%s' because the distance is not valid.", timing.name)
	end

	if timing and (distance < timing.imdd or distance > timing.imxd) then
		return self:notify(timing, "Distance is out of range.")
	end

	if not self:rc(timing, start, track) then
		return Logger.warn("Stopping RPUE '%s' because the repeat condition is not valid.", timing.name)
	end

	self:crpue(entity, track, timing, index + 1, start)

	local target = Targeting.find(entity)
	if not target then
		return Logger.warn("Skipping RPUE '%s' because the target is not valid.", timing.name)
	end

	if not self:hc(target.root.CFrame, timing, nil, { players.LocalPlayer.Character }) then
		return Logger.warn("Skipping RPUE '%s' because we are not in the hitbox.", timing.name)
	end

	self:notify(timing, "(%i) Action 'RPUE Parry' is being executed.", index)

	InputClient.parry()
end)

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
		Configuration.expectToggleValue("CheckTextboxFocused")
		and (userInputService:GetFocusedTextBox() or chatInputBarConfiguration.IsFocused)
	then
		return self:notify(timing, "User is typing in a text box.")
	end

	if Configuration.expectToggleValue("CheckWindowActive") and not iswindowactive() then
		return self:notify(timing, "Window is not active.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return self:notify(timing, "No effect replicator found.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return self:notify(timing, "No effect replicator module found.")
	end

	if
		effectReplicatorModule:FindEffect("LightAttack")
		or effectReplicatorModule:FindEffect("CriticalAttack")
		or effectReplicatorModule:FindEffect("Followup")
		or effectReplicatorModule:FindEffect("CastingSpell")
	then
		return self:notify(timing, "User is in a state where they are attacking.")
	end

	if effectReplicatorModule:FindEffect("HitAnim") and effectReplicatorModule:FindEffect("Stun") then
		return self:notify(timing, "User is stunned.")
	end

	if effectReplicatorModule:FindEffect("Knocked") then
		return self:notify(timing, "User is knocked.")
	end

	if timing.tag == "M1" and Configuration.expectToggleValue("CheckM1Attack") then
		return self:notify(timing, "Attacker is using a 'M1' attack.")
	end

	if timing.tag == "Mantra" and Configuration.expectToggleValue("CheckMantra") then
		return self:notify(timing, "Attacker is using a 'Mantra' attack.")
	end

	if timing.tag == "Critical" and Configuration.expectToggleValue("CheckCritical") then
		return self:notify(timing, "Attacker is using a 'Critical' attack.")
	end

	if timing.tag == "Undefined" and Configuration.expectToggleValue("CheckUndefined") then
		return self:notify(timing, "Attacker is using an 'Undefined' attack.")
	end

	return true
end)

---Update visualizations.
Defender.vupdate = LPH_NO_VIRTUALIZE(function(self)
	-- Calculate whether or not we should be showing visualizations.
	local showVisualizations = Configuration.expectToggleValue("EnableVisualizations")
		and os.clock() - self.lvisualization <= MAX_VISUALIZATION_TIME

	-- Set transparency.
	if self.vpart then
		self.vpart.Transparency = showVisualizations and 0.85 or 1.0
	end

	if self.ppart then
		self.ppart.Transparency = showVisualizations and 0.85 or 1.0
	end
end)

---Run hitbox check. Returns wheter if the hitbox is being touched.
---@todo: Add backtracking to the player to compensate for lag on the server and extrapolation for the other player to compensate for their next position in the future.
---@todo: Add a check to see if the player was looking at us in the last 0.25 seconds aswell.
---@todo: An issue is that the player's current look vector will not be the same as when they attack due to a parry timing being seperate from the attack; causing this check to fail.
---@param cframe CFrame
---@param fd boolean
---@param size Vector3
---@param filter Instance[]
---@return boolean
Defender.hitbox = LPH_NO_VIRTUALIZE(function(self, cframe, fd, size, filter)
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

	-- Real CFrame.
	local realCFrame = cframe

	-- Add facing depth if we need to.
	if fd then
		realCFrame = realCFrame * CFrame.new(0, 0, -(size.Z / 2))
	end

	-- Check in bounds.
	local inBounds = #workspace:GetPartBoundsInBox(realCFrame, size, overlapParams) > 0

	-- Visualize color.
	local visColor = inBounds and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

	-- Create visualization part if it doesn't exist.
	if not self.vpart then
		-- Create part.
		local vpart = Instance.new("Part")
		vpart.Parent = workspace
		vpart.Anchored = true
		vpart.CanCollide = false
		vpart.Material = Enum.Material.SmoothPlastic

		-- Set part.
		self.vpart = vpart
	end

	-- Create player part if it doesn't exist.
	if not self.ppart then
		-- Create part.
		local ppart = Instance.new("Part")
		ppart.Parent = workspace
		ppart.Anchored = true
		ppart.CanCollide = false
		ppart.Material = Enum.Material.Plastic

		-- Set part.
		self.ppart = ppart
	end

	-- Visual part.
	self.vpart.Size = size
	self.vpart.CFrame = realCFrame
	self.vpart.Color = visColor

	-- Player part.
	self.ppart.Size = root.Size
	self.ppart.CFrame = root.CFrame
	self.ppart.Color = visColor

	-- Set timestamp.
	self.lvisualization = os.clock()

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
---@note: https://devforum.roblox.com/t/in-depth-information-about-robloxs-remoteevents-instance-replication-and-physics-replication-w-sources/1847340
---@note: The forum post above is misleading, not only is it the RTT time, please note that this also takes into account all delays like frame time.
---@note: This is our round-trip time (e.g double the ping) since we have a receiving delay (replication) and a sending delay when we send the input to the server.
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

	return (dataPingItem:GetValue() / 1000)
end

---Repeat conditional.
---@param timing AnimationTiming
---@param start number
---@param track AnimationTrack?
---@return boolean
Defender.rc = LPH_NO_VIRTUALIZE(function(_, timing, start, track)
	if os.clock() - start >= MAX_DUIH_WAIT then
		return false
	end

	return true
end)

---Handle hitbox check and delay until in hitbox.
---@param cframe CFrame
---@param timing Timing|EffectTiming|AnimationTiming
---@param action Action?
---@param filter Instance[]
---@return boolean
Defender.hc = LPH_NO_VIRTUALIZE(function(self, cframe, timing, action, filter)
	local start = os.clock()

	---@note: We check for 'fhb' here even though the base timing may not have it.
	while timing.duih and not timing.rpue and not self:hitbox(cframe, timing.fhb, timing.hitbox, filter) do
		if not self:rc(timing, start, nil) then
			return false
		end

		task.wait()
	end

	local uh = action and action.hitbox or timing.hitbox
	if not uh then
		return false
	end

	if not timing.duih and not self:hitbox(cframe, timing.fhb, uh, filter) then
		return false
	end

	return true
end)

---Handle end block.
Defender.bend = LPH_NO_VIRTUALIZE(function(self)
	-- Iterate for start block tasks.
	for idx, task in next, self.tasks do
		-- Check if task is a start block.
		if task.identifier ~= "Start Block" then
			continue
		end

		-- End start block tasks.
		task:cancel()

		-- Clear in table.
		self.tasks[idx] = nil
	end

	-- End block.
	InputClient.bend(false)
end)

---Handle action.
---@param timing Timing
---@param action Action
Defender.handle = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if not self:valid(timing, action) then
		return
	end

	self:notify(timing, "Action type '%s' is being executed.", action._type)

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if action._type == "Start Block" then
		return InputClient.bstart()
	end

	if action._type == "End Block" then
		return self:bend()
	end

	if action._type == "Dodge" then
		return InputClient.dodge(false)
	end

	if action._type == "Forced Full Dodge" then
		return InputClient.dodge(true)
	end

	if action._type == "Jump" then
		local character = players.LocalPlayer.Character
		if not character then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			return
		end

		return humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	if action._type == "Teleport Up" then
		local character = players.LocalPlayer.Character
		if not character then
			return
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end

		if Entitites.isNear(humanoidRootPart.Position) then
			return self:notify(timing, "Action 'Teleport Up' blocked because there are players nearby.")
		end

		humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0, 50, 0))
	end

	---@note: Okay, we'll assume that we're in the parry state. There's no other type.
	if
		(not effectReplicatorModule:FindEffect("Equipped") or effectReplicatorModule:FindEffect("ParryCool"))
		and Configuration.expectToggleValue("RollOnParryCooldown")
	then
		self:notify(timing, "Action type 'Parry' overrided to 'Dodge' type.")
		return InputClient.dodge()
	end

	InputClient.parry()
end)

---Check if we have input blocking tasks.
---@return boolean
Defender.blocking = LPH_NO_VIRTUALIZE(function(self)
	for _, marker in next, self.markers do
		if not marker then
			continue
		end

		return true
	end

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

---Clean up hooks.
function Defender:clhook()
	for key, old in next, self.rhook do
		if not self[key] then
			continue
		end

		self[key] = old
	end
end

---Clean up all tasks.
Defender.clean = LPH_NO_VIRTUALIZE(function(self)
	-- Clean-up hooks.
	self:clhook()

	-- Clear temporary maid.
	self.tmaid:clean()

	-- Clear markers.
	self.markers = {}

	-- Teleport visualizations away.
	if self.vpart then
		self.vpart.CFrame = CFrame.new(math.huge, math.huge, math.huge)
	end

	if self.ppart then
		self.ppart.CFrame = CFrame.new(math.huge, math.huge, math.huge)
	end

	-- Was there a start block, end block, or parry?
	local blocking = false

	for idx, task in next, self.tasks do
		-- Cancel task.
		task:cancel()

		-- Clear in table.
		self.tasks[idx] = nil

		-- Check.
		blocking = blocking
			or (task.identifier == "Start Block" or task.identifier == "End Block" or task.identifier == "Parry")
	end

	-- Run end block, just in case we get stuck.
	if blocking then
		InputClient.bend(true)
	end
end)

---Process module.
---@param timing Timing
---@varargs any
Defender.module = LPH_NO_VIRTUALIZE(function(self, timing, ...)
	-- Get loaded function.
	local lf = ModuleManager.modules[timing.smod]
	if not lf then
		return self:notify(timing, "No module '%s' found.", timing.smod)
	end

	-- Create identifier.
	local identifier = string.format("Defender_RunModule_%s", timing.smod)

	-- Notify.
	if not timing.smn then
		self:notify(timing, "Running module '%s' on timing.", timing.smod)
	end

	-- Run module.
	self.tmaid:mark(TaskSpawner.spawn(identifier, lf, self, timing, ...))
end)

---Add a action to the defender object.
---@param timing Timing
---@param action Action
Defender.action = LPH_NO_VIRTUALIZE(function(self, timing, action)
	-- Get ping.
	local ping = self:ping()

	-- Add action.
	self:mark(
		Task.new(action._type, action:when() - ping, timing.punishable, timing.after, self.handle, self, timing, action)
	)

	-- Log.
	self:notify(timing, "Added action '%s' (%.2fs) with ping '%.2f' subtracted.", action.name, action:when(), ping)
end)

---Add actions from timing to defender object.
---@param timing Timing
Defender.actions = LPH_NO_VIRTUALIZE(function(self, timing)
	for _, action in next, timing.actions:get() do
		self:action(timing, action, false)
	end
end)

---Safely replace a function in the defender object.
---@param key string
---@param new function
---@return boolean, function
function Defender:hook(key, new)
	-- Check if we're already hooked.
	if self.rhook[key] then
		return false, nil
	end

	-- Get our assumed old / target function.
	local old = self[key]

	-- Check if function.
	if typeof(old) ~= "function" then
		return false, nil
	end

	-- Create hook.
	self[key] = new

	-- Add to hook table with the old function so we can restore it on clean-up.
	self.rhook[key] = old

	return true, old
end

---Detach defender object.
function Defender:detach()
	-- Clean self.
	self:clean()
	self.maid:clean()

	-- Destroy parts.
	if self.vpart then
		self.vpart:Destroy()
	end

	if self.ppart then
		self.ppart:Destroy()
	end

	-- Set object nil.
	self = nil
end

---Create new Defender object.
function Defender.new()
	local self = setmetatable({}, Defender)
	self.tasks = {}
	self.rhook = {}
	self.tmaid = Maid.new()
	self.maid = Maid.new()
	self.ppart = nil
	self.vpart = nil
	self.markers = {}
	self.lvisualization = os.clock()
	return self
end

-- Return Defender module.
return Defender
