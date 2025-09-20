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

---@module Features.Combat.PositionHistory
local PositionHistory = require("Features/Combat/PositionHistory")

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@module Utility.OriginalStore
local OriginalStore = require("Utility/OriginalStore")

---@module Features.Combat.EffectListener
local EffectListener = require("Features/Combat/EffectListener")

---@class Defender
---@field tasks Task[]
---@field tmaid Maid Cleaned up every clean cycle.
---@field rhook table<string, function> Hooked functions that we can restore on clean-up.
---@field markers table<string, boolean> Blocking markers for unknown length timings. If the entry exists and is true, then we're blocking.
---@field maid Maid
---@field hmaid Maid Maid for hitbox visualizations.
local Defender = {}
Defender.__index = Defender
Defender.__type = "Defender"

-- Services.
local stats = game:GetService("Stats")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local textChatService = game:GetService("TextChatService")
local debrisService = game:GetService("Debris")

-- Constants.
local MAX_VISUALIZATION_TIME = 5.0
local MAX_REPEAT_WAIT = 10.0
local PREDICTION_LENIENCY_MULTI = 5.0

---Log a miss to the UI library with distance check.
---@param type string
---@param key string
---@param name string?
---@param distance number
---@param parent string? If provided, will be shown in the log.
---@return boolean
function Defender:miss(type, key, name, distance, parent)
	if not Configuration.expectToggleValue("ShowLoggerWindow") then
		return false
	end

	if
		distance < (Configuration.expectOptionValue("MinimumLoggerDistance") or 0)
		or distance > (Configuration.expectOptionValue("MaximumLoggerDistance") or 0)
	then
		return false
	end

	Library:AddMissEntry(type, key, name, distance, parent)

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

---Find target - hookable function.
---@param self Defender
---@param entity Model
---@return Target?
Defender.target = LPH_NO_VIRTUALIZE(function(self, entity)
	return Targeting.find(entity)
end)

---Get extrapolated seconds.
---@param self Defender
---@param timing AnimationTiming
---@return number
Defender.fsecs = LPH_NO_VIRTUALIZE(function(self, timing)
	local player = players:GetPlayerFromCharacter(self.entity)
	local sd = (player and player:GetAttribute("AveragePing") or 50.0) / 2000
	return (timing.pfht or 0.15) + (sd + Defender.rdelay())
end)

---Repeat until parry end.
---@param self Defender
---@param entity Model
---@param timing Timing
---@param info RepeatInfo
Defender.rpue = LPH_NO_VIRTUALIZE(function(self, entity, timing, info)
	local distance = self:distance(entity)
	if not distance then
		return Logger.warn("Stopping RPUE '%s' because the distance is not valid.", PP_SCRAMBLE_STR(timing.name))
	end

	if timing and (distance < PP_SCRAMBLE_NUM(timing.imdd) or distance > PP_SCRAMBLE_NUM(timing.imxd)) then
		return self:notify(timing, "Distance is out of range.")
	end

	if not self:rc(info) then
		return Logger.warn(
			"Stopping RPUE '%s' because the repeat condition is not valid.",
			PP_SCRAMBLE_STR(timing.name)
		)
	end

	local target = self:target(entity)

	local options = HitboxOptions.new(target and target.root or CFrame.new(), timing)
	options.spredict = not timing.duih
	options.ptime = self:fsecs(timing)
	options.entity = entity
	options.hmid = info.hmid

	local success = target and self:hc(options, timing.duih and info or nil)

	info.index = info.index + 1

	self:mark(Task.new(string.format("RPUE_%s_%i", PP_SCRAMBLE_STR(timing.name), info.index), function()
		return timing:rpd() - info.irdelay - self.sdelay()
	end, timing.punishable, timing.after, self.rpue, self, self.entity, timing, info))

	if not target then
		return Logger.warn("Skipping RPUE '%s' because the target is not valid.", PP_SCRAMBLE_STR(timing.name))
	end

	if not success then
		return Logger.warn("Skipping RPUE '%s' because we are not in the hitbox.", PP_SCRAMBLE_STR(timing.name))
	end

	if not timing.srpn then
		self:notify(timing, "(%i) Action 'RPUE Parry' is being executed.", info.index)
	end

	InputClient.deflect()
end)

---Check if we're in a valid state to proceed with action handling. Extend me.
---@param self Defender
---@param timing Timing
---@param action Action
---@return boolean
Defender.valid = LPH_NO_VIRTUALIZE(function(self, timing, action)
	local integer = Random.new():NextNumber(1.0, 100.0)
	local rate = Configuration.expectOptionValue("FailureRate") or 0.0

	if Configuration.expectToggleValue("AllowFailure") and integer <= rate then
		return self:notify(timing, "(%i <= %i) Intentionally did not run.", integer, rate)
	end

	local keybinds = replicatedStorage:FindFirstChild("KeyBinds")
	if not keybinds then
		return self:notify(timing, "No keybinds instance found.")
	end

	local keybindsModule = require(keybinds)
	if not keybindsModule or not keybindsModule.Current then
		return self:notify(timing, "No keybinds module found.")
	end

	local selectedFilters = Configuration.expectOptionValue("AutoDefenseFilters") or {}

	for _, keybind in next, keybindsModule.Current["Block"] or {} do
		local success, keyCode = pcall(function()
			return Enum.KeyCode[tostring(keybind)]
		end)

		if not success or not keyCode then
			continue
		end

		if not userInputService:IsKeyDown(keyCode) then
			continue
		end

		if not selectedFilters["Disable While Holding Block"] then
			continue
		end

		return self:notify(timing, "User is pressing down on a key binded to Block.")
	end

	local chatInputBarConfiguration = textChatService:FindFirstChildOfClass("ChatInputBarConfiguration")

	if
		selectedFilters["Disable When Textbox Focused"]
		and (userInputService:GetFocusedTextBox() or chatInputBarConfiguration.IsFocused)
	then
		return self:notify(timing, "User is typing in a text box.")
	end

	if selectedFilters["Disable When Window Not Active"] and not iswindowactive() then
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

	if EffectListener.sstun() then
		return self:notify(timing, "User has the 'LightAttack' effect.")
	end

	if effectReplicatorModule:FindEffect("Knocked") then
		return self:notify(timing, "User is knocked.")
	end

	if timing.tag == "M1" and selectedFilters["Filter Out M1s"] then
		return self:notify(timing, "Attacker is using a 'M1' attack.")
	end

	if timing.tag == "Mantra" and selectedFilters["Filter Out Mantras"] then
		return self:notify(timing, "Attacker is using a 'Mantra' attack.")
	end

	if timing.tag == "Critical" and selectedFilters["Filter Out Criticals"] then
		return self:notify(timing, "Attacker is using a 'Critical' attack.")
	end

	if timing.tag == "Undefined" and selectedFilters["Filter Out Undefined"] then
		return self:notify(timing, "Attacker is using an 'Undefined' attack.")
	end

	return true
end)

---Check if any parts that are in our filter were hit.
---@note: Solara fallback.
local function checkParts(parts, filter)
	for _, part in next, parts do
		for _, fpart in next, filter do
			if part ~= fpart and not part:IsDescendantOf(fpart) then
				continue
			end

			return true
		end
	end

	return false
end

---Get a unique ID for hitboxes.
---@param spaces number Determines how many spaces that one UID can occupy.
---@return number
function Defender:uid(spaces)
	-- Increment.
	self.uids = self.uids + spaces

	-- Return.
	return self.uids
end

---Visualize a position and size.
---@param self Defender
---@param identifier number? If the identifier is nil, then we will auto-generate one for each visualization.
---@param cframe CFrame
---@param size Vector3
---@param color Color3
Defender.visualize = LPH_NO_VIRTUALIZE(function(self, identifier, cframe, size, color)
	local id = identifier or self:uid(10)
	local vpart = self.hmaid[id] or Instance.new("Part")

	vpart.Parent = workspace
	vpart.Anchored = true
	vpart.CanCollide = false
	vpart.CanQuery = false
	vpart.CanTouch = false
	vpart.Material = Enum.Material.ForceField
	vpart.CastShadow = false
	vpart.Size = size
	vpart.CFrame = cframe
	vpart.Color = color
	vpart.Name = string.format("RW_Visualization_%i", id)
	vpart.Transparency = Configuration.expectToggleValue("EnableVisualizations") and 0.2 or 1.0

	if self.hmaid[id] then
		return
	end

	self.hmaid[id] = vpart

	debrisService:AddItem(vpart, MAX_VISUALIZATION_TIME)
end)

---Run hitbox check. Returns wheter if the hitbox is being touched.
---@todo: An issue is that the player's current look vector will not be the same as when they attack due to a parry timing being seperate from the attack causing this check to fail.
---@param self Defender
---@param cframe CFrame
---@param fd boolean
---@param size Vector3
---@param filter Instance[]
---@return boolean?, CFrame?
Defender.hitbox = LPH_NO_VIRTUALIZE(function(self, cframe, fd, size, filter)
	local shouldManualFilter = getexecutorname
		and (getexecutorname():match("Solara") or getexecutorname():match("Xeno"))

	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = shouldManualFilter and {} or filter
	overlapParams.FilterType = shouldManualFilter and Enum.RaycastFilterType.Exclude or Enum.RaycastFilterType.Include

	local character = players.LocalPlayer.Character
	if not character then
		return nil, nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, nil
	end

	-- Used CFrame.
	local usedCFrame = cframe

	if fd then
		usedCFrame = usedCFrame * CFrame.new(0, 0, -(size.Z / 2))
	end

	-- Parts in bounds.
	local parts = workspace:GetPartBoundsInBox(usedCFrame, size, overlapParams)

	-- Return result.
	return shouldManualFilter and checkParts(parts, filter) or #parts > 0, usedCFrame
end)

---Check initial state.
---@param self Defender
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
	if timing and (distance < PP_SCRAMBLE_NUM(timing.imdd) or distance > PP_SCRAMBLE_NUM(timing.imxd)) then
		return nil
	end

	-- Check for no timing. If so, let's log a miss.
	---@note: Ignore return value.
	if not timing then
		self:miss(self.__type, key, name, distance, from and tostring(from.Parent) or nil)
		return nil
	end

	-- Return timing.
	return timing
end)

---Logger notify.
---@param self Defender
---@param timing Timing
---@param str string
Defender.notify = LPH_NO_VIRTUALIZE(function(self, timing, str, ...)
	if not Configuration.expectToggleValue("EnableNotifications") then
		return
	end

	Logger.notify("[%s] (%s) %s", PP_SCRAMBLE_STR(timing.name), self.__type, string.format(str, ...))
end)

---@note: Perhaps one day, we can get better approximations for these.
--- These used to rely on GetNetworkPing which we assumed would be sending or atleast receiving delay.
--- That is incorrect, it is RakNet ping thereby being RTT.

---Get receiving delay.
---@return number
function Defender.rdelay()
	return math.max(Defender.rtt() / 2, 0.0)
end

---Get sending delay.
---@return number
function Defender.sdelay()
	return math.max(Defender.rtt() / 2, 0.0)
end

---Get data ping.
---@note: https://devforum.roblox.com/t/in-depth-information-about-robloxs-remoteevents-instance-replication-and-physics-replication-w-sources/1847340
---@note: The forum post above is misleading, not only is it the RTT time, please note that this also takes into account all delays like frame time.
---@note: This is our round-trip time (e.g double the ping) since we have a receiving delay (replication) and a sending delay when we send the input to the server.
---@todo: For every usage, the sending delay needs to be continously updated. The receiving one must be calculated once at initial send for AP ping compensation.
---@return number
function Defender.rtt()
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
---@param self Defender
---@param info RepeatInfo
---@return boolean
Defender.rc = LPH_NO_VIRTUALIZE(function(self, info)
	if os.clock() - info.start >= MAX_REPEAT_WAIT then
		return false
	end

	return true
end)

---Handle delay until in hitbox.
---@param self Defender
---@param options HitboxOptions
---@param info RepeatInfo
---@return boolean
Defender.duih = LPH_NO_VIRTUALIZE(function(self, options, info)
	local clone = options:clone()
	clone.hmid = info.hmid

	while task.wait() do
		if not self:rc(info) then
			return false
		end

		if not self:hc(clone, nil) then
			continue
		end

		return true
	end
end)

---Handle hitbox check options.
---@param self Defender
---@param options HitboxOptions
---@param info RepeatInfo? Pass this in if you want to use the delay until in hitbox.
---@return boolean
Defender.hc = LPH_NO_VIRTUALIZE(function(self, options, info)
	local action = options.action
	local timing = options.timing

	-- Run basic validation.
	local character = players.LocalPlayer.Character
	if not character then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	if action and action.ihbc then
		return true
	end

	-- If we have info, then we want to delay until in hitbox.
	if info then
		return self:duih(options, info)
	end

	-- Fetch the data that we need.
	local hitbox = options:hitbox()
	local eposition = options.spredict and options:extrapolate() or nil
	local position = options:pos()

	-- Run hitbox check.
	local result, usedCFrame = self:hitbox(position, timing.fhb, hitbox, options.filter)

	if usedCFrame then
		self:visualize(options.hmid, usedCFrame, hitbox, options:ghcolor(result))
		self:visualize(options.hmid and options.hmid + 1 or nil, root.CFrame, root.Size, options:ghcolor(result))
	end

	if not options.spredict or result then
		return result
	end

	-- Run prediction check.
	local closest = PositionHistory.closest(players.LocalPlayer, tick() - (self.sdelay() * PREDICTION_LENIENCY_MULTI))
	if not closest then
		return false
	end

	local store = OriginalStore.new()

	-- Run check.
	store:run(root, "CFrame", closest, function()
		result, usedCFrame = self:hitbox(eposition, timing.fhb, hitbox, options.filter)
	end)

	-- Visualize predicted hitbox.
	if usedCFrame then
		self:visualize(options.hmid and options.hmid + 1 or nil, usedCFrame, hitbox, options:gphcolor(result))
		self:visualize(options.hmid and options.hmid + 1 or nil, root.CFrame, root.Size, options:gphcolor(result))
	end

	-- Return result.
	return result
end)

---Handle end block.
---@param self Defender
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
---@param self Defender
---@param timing Timing
---@param action Action
---@param notify boolean
Defender.handle = LPH_NO_VIRTUALIZE(function(self, timing, action, notify)
	if not self:valid(timing, action) then
		return
	end

	if not notify then
		self:notify(timing, "Action type '%s' is being executed.", PP_SCRAMBLE_STR(action._type))
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	-- Dash instead of parry.
	local dashReplacement = Random.new():NextNumber(1.0, 100.0)
		<= (Configuration.expectOptionValue("DashInsteadOfParryRate") or 0.0)

	if PP_SCRAMBLE_STR(action._type) ~= "Parry" then
		dashReplacement = false
	end

	if not Configuration.expectToggleValue("AllowFailure") then
		dashReplacement = false
	end

	if timing.umoa or timing.actions:count() ~= 1 then
		dashReplacement = false
	end

	if PP_SCRAMBLE_STR(action._type) == "Start Block" then
		return InputClient.bstart()
	end

	if PP_SCRAMBLE_STR(action._type) == "End Block" then
		return self:bend()
	end

	if PP_SCRAMBLE_STR(action._type) == "Dodge" then
		return InputClient.dodge(false)
	end

	if PP_SCRAMBLE_STR(action._type) == "Forced Full Dodge" then
		return InputClient.dodge(true)
	end

	if PP_SCRAMBLE_STR(action._type) == "Jump" then
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

	if PP_SCRAMBLE_STR(action._type) == "Teleport Up" then
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

		humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0, 25, 0))
	end

	-- Parry if possible.
	-- We'll assume that we're in the parry state. There's no other type.
	if EffectListener.cparry() then
		if timing.nfdb or not EffectListener.cdodge() or not dashReplacement then
			return InputClient.deflect()
		end

		self:notify(timing, "Action type 'Parry' replaced to 'Dodge' type.")

		return InputClient.dodge()
	end

	---Block fallback function. Returns whether the fallback was successful.
	---@return boolean
	local function blockFallback()
		if not Configuration.expectToggleValue("DeflectBlockFallback") then
			return false
		end

		Defender:notify(timing, "Action fallback 'Parry' is using block frames.")
		InputClient.deflect()

		return true
	end

	-- Dodge fallback.
	if not Configuration.expectToggleValue("RollOnParryCooldown") then
		return blockFallback()
	end

	if timing.ndfb then
		return self:notify(timing, "Action fallback 'Dodge' is disabled for this timing.")
	end

	if not EffectListener.cdodge() then
		return blockFallback() or self:notify(timing, "Action fallback 'Dodge' blocked because we are unable to dash.")
	end

	self:notify(timing, "Action type 'Parry' overrided to 'Dodge' type.")

	return InputClient.dodge()
end)

---Check if we have input blocking tasks.
---@param self Defender
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

	self.rhook = {}
end

---Clean up all tasks.
---@param self Defender
Defender.clean = LPH_NO_VIRTUALIZE(function(self)
	-- Clean-up hooks.
	self:clhook()

	-- Clear temporary maid.
	self.tmaid:clean()

	-- Clear markers.
	self.markers = {}

	-- Clean up hitboxes.
	self.hmaid:clean()

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
---@param self Defender
---@param timing Timing
---@varargs any
Defender.module = LPH_NO_VIRTUALIZE(function(self, timing, ...)
	-- Get loaded function.
	local lf = ModuleManager.modules[PP_SCRAMBLE_STR(timing.smod)]
	if not lf then
		return self:notify(timing, "No module '%s' found.", PP_SCRAMBLE_STR(timing.smod))
	end

	-- Create identifier.
	local identifier = string.format("Defender_RunModule_%s", PP_SCRAMBLE_STR(timing.smod))

	-- Notify.
	if not timing.smn then
		self:notify(timing, "Running module '%s' on timing.", PP_SCRAMBLE_STR(timing.smod))
	end

	-- Run module.
	self.tmaid:mark(TaskSpawner.spawn(identifier, lf, self, timing, ...))
end)

---Add a action to the defender object.
---@param self Defender
---@param timing Timing
---@param action Action
Defender.action = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if timing.umoa then
		action["_type"] = PP_SCRAMBLE_STR(action["_type"])
		action["name"] = PP_SCRAMBLE_STR(action["name"])
		action["_when"] = PP_SCRAMBLE_RE_NUM(action["_when"])
		action["hitbox"] = Vector3.new(
			PP_SCRAMBLE_RE_NUM(action["hitbox"].X),
			PP_SCRAMBLE_RE_NUM(action["hitbox"].Y),
			PP_SCRAMBLE_RE_NUM(action["hitbox"].Z)
		)
	end

	-- Get initial receive delay.
	local rdelay = self.rdelay()

	-- Add action.
	self:mark(Task.new(PP_SCRAMBLE_STR(action._type), function()
		return action:when() - rdelay - self.sdelay()
	end, timing.punishable, timing.after, self.handle, self, timing, action))

	-- Log.
	if not LRM_UserNote or LRM_UserNote == "tester" then
		self:notify(
			timing,
			"Added action '%s' (%.2fs) with ping '%.2f' (changing) subtracted.",
			PP_SCRAMBLE_STR(action.name),
			action:when(),
			self.rtt()
		)
	else
		self:notify(
			timing,
			"Added action '%s' ([redacted]) with ping '%.2f' (changing) subtracted.",
			PP_SCRAMBLE_STR(action.name),
			self.rtt()
		)
	end
end)

---Add actions from timing to defender object.
---@param self Defender
---@param timing Timing
Defender.actions = LPH_NO_VIRTUALIZE(function(self, timing)
	for _, action in next, timing.actions:get() do
		self:action(timing, action)
	end
end)

---Safely replace a function in the defender object.
---@param key string
---@param new function
---@return boolean, function
function Defender:hook(key, new)
	-- Check if we're already hooked.
	if self.rhook[key] then
		Logger.warn("Cannot hook '%s' because it is already hooked.", key)
		return false, nil
	end

	-- Get our assumed old / target function.
	local old = self[key]

	-- Check if function.
	if typeof(old) ~= "function" then
		Logger.warn("Cannot hook '%s' because it is not a function.", key)
		return false, nil
	end

	-- Create hook.
	self[key] = new

	-- Add to hook table with the old function so we can restore it on clean-up.
	self.rhook[key] = old

	-- Log.
	Logger.warn("Hooked '%s' with new function.", key)

	return true, old
end

---Detach defender object.
function Defender:detach()
	-- Clean self.
	self:clean()
	self.maid:clean()

	-- Clean up hitboxes.
	self.hmaid:clean()

	-- Set object nil.
	self = nil
end

---Create new Defender object.
---@return Defender
function Defender.new()
	local self = setmetatable({}, Defender)
	self.tasks = {}
	self.rhook = {}
	self.tmaid = Maid.new()
	self.maid = Maid.new()
	self.hmaid = Maid.new()
	self.uids = 0
	self.markers = {}
	self.lvisualization = os.clock()
	return self
end

-- Return Defender module.
return Defender
