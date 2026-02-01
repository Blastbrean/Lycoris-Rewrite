---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Objects.Task
local Task = require("Features/Combat/Objects/Task")

---@module Game.QueuedBlocking
local QueuedBlocking = require("Game/QueuedBlocking")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Game.Timings.ModuleManager
local ModuleManager = require("Game/Timings/ModuleManager")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Features.Combat.Targeting
local Targeting = require("Features/Combat/Targeting")

---@module Features.Combat.Objects.ValidationOptions
local ValidationOptions = require("Features/Combat/Objects/ValidationOptions")

---@module Features.Combat.EntityHistory
local EntityHistory = require("Features/Combat/EntityHistory")

---@module Features.Combat.Objects.HitboxOptions
local HitboxOptions = require("Features/Combat/Objects/HitboxOptions")

---@module Utility.OriginalStore
local OriginalStore = require("Utility/OriginalStore")

---@module Features.Combat.StateListener
local StateListener = require("Features/Combat/StateListener")

---@module Utility.Finder
local Finder = require("Utility/Finder")

---@module Game.Latency
local Latency = require("Game/Latency")

---@module GUI.Library
local Library = require("GUI/Library")

---@class Defender
---@field tasks Task[]
---@field tmaid Maid Cleaned up every clean cycle.
---@field rhook table<string, function> Hooked functions that we can restore on clean-up.
---@field markers table<string, boolean> Blocking markers for unknown length timings. If the entry exists and is true, then we're blocking.
---@field maid Maid
---@field hmaid Maid Maid for hitbox visualizations.
---@field uids number Unique ID counter for hitbox visualizations.
---@field afeinted boolean Whether if we have auto-feinted this defense cycle.
---@field ifeinted boolean Whether if we have initial auto-feinted this defense cycle.
local Defender = {}
Defender.__index = Defender
Defender.__type = "Defender"

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local textChatService = game:GetService("TextChatService")
local debrisService = game:GetService("Debris")

-- Constants.
local MAX_VISUALIZATION_TIME = 5.0
local MAX_REPEAT_WAIT = 10.0
local PREDICTION_LENIENCY_MULTI = 10.0

---@module Game.Objects.DodgeOptions
local DodgeOptions = require("Game/Objects/DodgeOptions")

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
Defender.distance = LPH_NO_VIRTUALIZE(function(_, from)
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
end)

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
	return (timing.pfht or 0.15) + (sd + Latency.rdelay())
end)

---Start repeat until parry end.
---@param self Defender
---@param ref Model|Part
---@param timing Timing
---@param info RepeatInfo
Defender.srpue = LPH_NO_VIRTUALIZE(function(self, ref, timing, info)
	if timing.umoa or timing.cbm then
		timing["_rpd"] = PP_SCRAMBLE_RE_NUM(timing["_rpd"])
		timing["_rsd"] = PP_SCRAMBLE_RE_NUM(timing["_rsd"])
		timing["imdd"] = PP_SCRAMBLE_RE_NUM(timing["imdd"])
		timing["imxd"] = PP_SCRAMBLE_RE_NUM(timing["imxd"])
	end

	local cache = {
		["name"] = PP_SCRAMBLE_STR(timing.name),
		["imdd"] = PP_SCRAMBLE_NUM(timing.imdd),
		["imxd"] = PP_SCRAMBLE_NUM(timing.imxd),
		["rsd"] = timing:rsd(),
		["rpd"] = timing:rpd(),
	}

	local target = self:target(ref)
	local part = target and target.root or CFrame.new()

	if ref:IsA("Part") then
		part = ref
	end

	local options = HitboxOptions.new(part, timing)
	options.spredict = not timing.duih
	options.ptime = self:fsecs(timing)
	options.entity = ref:IsA("Model") and target or nil
	options.hmid = info.hmid
	options:ucache()

	-- Start RPUE.
	self:mark(Task.new(string.format("RPUE_%s_%i", timing.name, 0), function()
		return cache["rsd"] - info.irdelay - Latency.sdelay()
	end, timing.punishable, timing.after, self.rpue, self, ref, timing, info, cache, options))

	-- Notify.
	if not LRM_UserNote or LRM_UserNote == "tester" then
		self:notify(
			timing,
			"Added RPUE '%s' (%.2fs, then every %.2fs) with ping '%.2f' (changing) subtracted.",
			cache["name"],
			cache["rsd"],
			cache["rpd"],
			Latency.rtt()
		)
	else
		self:notify(
			timing,
			"Added RPUE '%s' ([redacted], then every [redacted]) with ping '%.2f' (changing) subtracted.",
			cache["name"],
			Latency.rtt()
		)
	end
end)

---Repeat until parry end.
---@param self Defender
---@param ref Model|Part
---@param timing Timing
---@param info RepeatInfo
---@param cache table Cache table for RPUE to prevent unnecessary recalculations.
---@param options HitboxOptions
Defender.rpue = LPH_NO_VIRTUALIZE(function(self, ref, timing, info, cache, options)
	local distance = self:distance(ref)
	if not distance then
		return Logger.warn("Stopping RPUE '%s' because the distance is not valid.", cache.name)
	end

	if not self:rc(info) then
		return Logger.warn("Stopping RPUE '%s' because the repeat condition is not valid.", cache.name)
	end

	local target = ref:IsA("Model") and self:target(ref) or true
	local success = false
	local reasons = {}

	options.part = ref:IsA("Part") and ref or (target and target.root)
	options.cframe = not options.part and CFrame.new()

	if timing.duih and target then
		success = self:hc(options, info)
		reasons[#reasons + 1] = string.format("hitbox (%s)", tostring(options:hitbox()))
	end

	local within = (distance >= cache.imdd and distance <= cache.imxd)

	if timing then
		success = within
	end

	if not within then
		reasons[#reasons + 1] = string.format("distance range (%.2f < %.2f > %.2f)", cache.imdd, distance, cache.imxd)
	end

	info.index = info.index + 1

	self:mark(Task.new(string.format("RPUE_%s_%i", timing.name, info.index), function()
		return cache.rpd - info.irdelay - Latency.sdelay()
	end, timing.punishable, timing.after, self.rpue, self, ref, timing, info, cache, options))

	if not target then
		return Logger.warn("Skipping RPUE '%s' because the target is not valid.", cache.name)
	end

	if not success then
		return Logger.warn("Skipping RPUE '%s' (%s)", cache.name, #reasons > 1 and table.concat(reasons, ", ") or "N/A")
	end

	self:notify(timing, "Action type 'RPUE Parry' is being executed.")

	self:parry(timing, nil)
end)

---Check if we're in a valid state to proceed with action handling. Extend me.
---@param self Defender
---@param options ValidationOptions
---@return boolean
Defender.valid = LPH_NO_VIRTUALIZE(function(self, options)
	local integer = Random.new():NextNumber(1.0, 100.0)
	local rate = Configuration.expectOptionValue("FailureRate") or 0.0
	local timing = options.timing

	local function internalNotifyFunction(...)
		if not options.notify then
			return
		end

		return self:notify(...)
	end

	local overrideData = Library:GetOverrideData(PP_SCRAMBLE_STR(timing.name))

	if overrideData then
		rate = overrideData.fr
	end

	if (Configuration.expectToggleValue("AllowFailure") or overrideData) and integer <= rate then
		return internalNotifyFunction(timing, "(%i <= %i) Intentionally did not run.", integer, rate)
	end

	local selectedFilters = Configuration.expectOptionValue("AutoDefenseFilters") or {}

	if selectedFilters["Disable While Holding Block"] and StateListener.hblock() then
		return internalNotifyFunction(timing, "User is pressing down on a key binded to Block.")
	end

	local chatInputBarConfiguration = textChatService:FindFirstChildOfClass("ChatInputBarConfiguration")

	if
		selectedFilters["Disable When Textbox Focused"]
		and (userInputService:GetFocusedTextBox() or chatInputBarConfiguration.IsFocused)
	then
		return internalNotifyFunction(timing, "User is typing in a text box.")
	end

	if selectedFilters["Disable While Using Sightless Beam"] and StateListener.csb() then
		return internalNotifyFunction(timing, "User is using the 'Sightless Beam' move.")
	end

	if selectedFilters["Disable When Window Not Active"] and not iswindowactive() then
		return internalNotifyFunction(timing, "Window is not active.")
	end

	if selectedFilters["Disable During Chime Countdown"] and StateListener.ccd() then
		return internalNotifyFunction(timing, "Chime countdown is active.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return internalNotifyFunction(timing, "No effect replicator found.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return internalNotifyFunction(timing, "No effect replicator module found.")
	end

	local actionType = options.action and options.action._type or "N/A"

	if
		not Configuration.expectToggleValue("BlatantRoll")
		or (actionType ~= PP_SCRAMBLE_STR("Dodge") and actionType ~= PP_SCRAMBLE_STR("Forced Full Dodge"))
	then
		if not self.afeinted and not options.sstun and StateListener.astun() then
			return internalNotifyFunction(timing, "User is in action stun.")
		end

		if effectReplicatorModule:FindEffect("Knocked") then
			return internalNotifyFunction(timing, "User is knocked.")
		end
	end

	if actionType == PP_SCRAMBLE_STR("Parry") then
		if effectReplicatorModule:FindEffect("AutoParry") then
			return internalNotifyFunction(timing, "User has auto parry frames.")
		end
	end

	if timing.tag == "M1" and selectedFilters["Filter Out M1s"] then
		return internalNotifyFunction(timing, "Attacker is using a 'M1' attack.")
	end

	if timing.tag == "Mantra" and selectedFilters["Filter Out Mantras"] then
		return internalNotifyFunction(timing, "Attacker is using a 'Mantra' attack.")
	end

	if timing.tag == "Critical" and selectedFilters["Filter Out Criticals"] then
		return internalNotifyFunction(timing, "Attacker is using a 'Critical' attack.")
	end

	if timing.tag == "Undefined" and selectedFilters["Filter Out Undefined"] then
		return internalNotifyFunction(timing, "Attacker is using an 'Undefined' attack.")
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
---@param shape Enum.PartType
Defender.visualize = LPH_NO_VIRTUALIZE(function(self, identifier, cframe, size, color, shape)
	local id = identifier or self:uid(10)
	local vpart = self.hmaid[id] or Instance.new("Part")

	pcall(function()
		vpart.Parent = workspace
	end)

	if vpart.Parent then
		vpart.Anchored = true
		vpart.CanCollide = false
		vpart.CanQuery = false
		vpart.CanTouch = false
		vpart.Material = Enum.Material.ForceField
		vpart.CastShadow = false
		vpart.Size = size
		vpart.CFrame = cframe
		vpart.Color = color
		vpart.Shape = shape
		vpart.Transparency = Configuration.expectToggleValue("EnableVisualizations") and 0.2 or 1.0
	end

	if self.hmaid[id] then
		return
	end

	self.hmaid[id] = vpart

	debrisService:AddItem(vpart, MAX_VISUALIZATION_TIME)
end)

---Run hitbox check. Returns wheter if the hitbox is being touched.
---@param self Defender
---@param cframe CFrame
---@param fd boolean
---@param soffset number
---@param size Vector3
---@param filter Instance[]
---@param shape Enum.PartType
---@return boolean?, CFrame?
Defender.hitbox = LPH_NO_VIRTUALIZE(function(self, cframe, fd, soffset, size, filter, shape)
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

	if soffset and soffset ~= 0 then
		usedCFrame = usedCFrame * CFrame.new(0, 0, soffset)
	end

	-- Create simulation part.
	local simulationPart = Instance.new("Part")
	simulationPart.Size = size
	simulationPart.Material = Enum.Material.ForceField
	simulationPart.Shape = shape
	simulationPart.CFrame = usedCFrame

	if shape == Enum.PartType.Cylinder then
		simulationPart.CFrame = usedCFrame * CFrame.Angles(0, 0, math.rad(90))
	end

	-- Parts in bounds.
	local parts = workspace:GetPartsInPart(simulationPart, overlapParams)

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
	if timing then
		local md = PP_SCRAMBLE_NUM(timing.imdd)

		if md <= 0.01 then
			md = 0.0
		end

		if distance < md or distance > PP_SCRAMBLE_NUM(timing.imxd) then
			return nil
		end
	end

	-- Check for no timing. If so, let's log a miss.
	---@note: Ignore return value.
	if not timing then
		self:miss(self.__type, key, name, distance, from and tostring(from.Parent) or nil)
		return false
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

	Logger.qnotify("[%s] (%s) %s", PP_SCRAMBLE_STR(timing.name), self.__type, string.format(str, ...))
end)

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
	clone:ucache()

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

	-- Inner visualization function.
	local function innerVisualize(...)
		if not options.visualize then
			return
		end

		return self:visualize(...)
	end

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
	local pt = timing.htype or Enum.PartType.Block

	-- Run hitbox check.
	local result, usedCFrame = self:hitbox(position, timing.fhb, timing.hso, hitbox, options.filter, pt)

	if usedCFrame then
		innerVisualize(options.hmid, usedCFrame, hitbox, options:ghcolor(result), pt)
		innerVisualize(options.hmid and options.hmid + 1 or nil, root.CFrame, root.Size, options:ghcolor(result), pt)
	end

	if not options.spredict or result then
		return result
	end

	-- Run prediction check.
	local closest = EntityHistory.pclosest(players.LocalPlayer, tick() - (Latency.rtt() * PREDICTION_LENIENCY_MULTI))
	if not closest then
		return false
	end

	local store = OriginalStore.new()

	-- Run check.
	store:run(root, "CFrame", closest, function()
		result, usedCFrame = self:hitbox(eposition, timing.fhb, timing.hso, hitbox, options.filter, pt)
	end)

	-- Visualize predicted hitbox.
	if usedCFrame then
		innerVisualize(options.hmid and options.hmid + 1 or nil, usedCFrame, hitbox, options:gphcolor(result), pt)
		innerVisualize(options.hmid and options.hmid + 1 or nil, closest, root.Size, options:gphcolor(result), pt)
	end

	-- Return result.
	return result
end)

---Handle action.
---@param self Defender
---@param timing Timing
---@param action Action
---@param started number
Defender.handle = LPH_NO_VIRTUALIZE(function(self, timing, action, started)
	local actionType = PP_SCRAMBLE_STR(action._type)

	if actionType == "End Block" then
		QueuedBlocking.stop("Defender_StartBlock")
	end

	-- Handle auto feint. We want to feint before the parry action gets sent out.
	-- We don't want to do this for any action that has:
	-- 1. Delay until in hitbox because we don't know the actual timing
	-- 2. A zero when time because it is instant
	-- 3. Is not an animation defender because it won't make sense to feint non-animation actions.
	if
		Configuration.expectToggleValue("AutoFeint")
		and not timing.duih
		and action._when > 0
		and self.__type == "Animation"
		and actionType ~= "End Block"
	then
		self:afeint(timing, action, started, false)
	end

	if actionType ~= "End Block" then
		if not self:valid(ValidationOptions.new(action, timing)) then
			return
		end
	end

	local redactedMap = {
		["Start Slide"] = "1",
		["End Slide"] = "2",
		["Teleport Up"] = "3",
		["Forced Full Dodge"] = "4",
		["Jump"] = "5",
		["Start Block"] = "6",
		["End Block"] = "7",
		["Parry"] = "8",
		["Dodge"] = "9",
		["Start Crouch"] = "10",
		["End Crouch"] = "11",
	}

	if LRM_UserNote then
		self:notify(timing, "Action type '%s' is being executed.", redactedMap[actionType] or actionType)
	else
		self:notify(timing, "Action type '%s' is being executed.", actionType)
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if actionType == "Start Block" then
		return QueuedBlocking.invoke(QueuedBlocking.BLOCK_TYPE_NORMAL, "Defender_StartBlock", 20.0)
	end

	local options = DodgeOptions.new()
	options.rollCancel = Configuration.expectToggleValue("RollCancel") and actionType ~= "Forced Full Dodge"
	options.rollCancelDelay = Configuration.expectOptionValue("RollCancelDelay") or 0.0
	options.direct = Configuration.expectToggleValue("BlatantRoll")

	local inIFrame = effectReplicatorModule:FindEffect("Immortal")
		or effectReplicatorModule:FindEffect("Dodge")
		or effectReplicatorModule:FindEffect("Ghost")
	
	if (actionType == "Dodge" or actionType == "Forced Full Dodge") and Configuration.expectToggleValue("ParryOnly") then
		actionType = "Parry"
		self:notify(timing, "Action 'Dodge' changed to 'Parry'")
	end

	if actionType == "Dodge" then
		if Configuration.expectToggleValue("UseIFrames") and inIFrame then
			return
		end

		return InputClient.dodge(options)
	end

	if actionType == "Forced Full Dodge" then
		return InputClient.dodge(options)
	end

	if actionType == "End Block" then
		return
	end

	if actionType == "Start Slide" then
		local serverSlide = KeyHandling.getRemote("ServerSlide")
		if not serverSlide then
			return
		end

		return serverSlide:FireServer(true)
	end

	if actionType == "End Slide" then
		local serverSlideStop = KeyHandling.getRemote("ServerSlideStop")
		if not serverSlideStop then
			return
		end

		return serverSlideStop:FireServer(false)
	end

	if actionType == "Start Crouch" then
		return InputClient.crouch(true)
	end

	if actionType == "End Crouch" then
		return InputClient.crouch(false)
	end

	if actionType == "Jump" then
		local humanController = InputClient.getHumanController()
		if not humanController then
			return
		end

		if effectReplicatorModule:HasAny("Swimming", "Jumped", "NoJump", "Landed") then
			return
		end

		if not humanController:Jump() then
			return
		end

		return InputClient.ejump()
	end

	if actionType == "Teleport Up" then
		local character = players.LocalPlayer.Character
		if not character then
			return
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			return
		end

		if Finder.pnear(humanoidRootPart.Position, 500) then
			return self:notify(timing, "Action 'Teleport Up' blocked because there are players nearby.")
		end

		humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0, 75, 0))
	end

	self:parry(timing, action)
end)

---Handle parry.
---@param self Defender
---@param timing Timing
---@param action Action
Defender.parry = LPH_NO_VIRTUALIZE(function(self, timing, action)
	-- Options.
	local options = DodgeOptions.new()
	options.rollCancel = Configuration.expectToggleValue("RollCancel")
	options.rollCancelDelay = Configuration.expectOptionValue("RollCancelDelay") or 0.0
	options.direct = Configuration.expectToggleValue("BlatantRoll")

	-- Rate.
	local rate = (Configuration.expectOptionValue("DashInsteadOfParryRate") or 0.0)
	local overrideData = Library:GetOverrideData(PP_SCRAMBLE_STR(timing.name))
	if overrideData then
		rate = overrideData.dipr
	end

	-- Effect Replicator.
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	local effectReplicatorModule = effectReplicator and require(effectReplicator)

	-- IFrame checks
	local inIFrame = effectReplicatorModule:FindEffect("Immortal")
		or effectReplicatorModule:FindEffect("DodgeFrame")
		or effectReplicatorModule:FindEffect("ParryFrame")
		or effectReplicatorModule:FindEffect("Ghost")

	-- Dash instead of parry.
	local dashReplacement = Random.new():NextNumber(1.0, 100.0) <= rate

	if action and PP_SCRAMBLE_STR(action._type) ~= "Parry" then
		dashReplacement = false
	end

	if not Configuration.expectToggleValue("AllowFailure") and not overrideData then
		dashReplacement = false
	end

	if timing.umoa or timing.actions:count() ~= 1 then
		dashReplacement = false
	end
	
	if Configuration.expectToggleValue("ParryOnly") then
		dashReplacement = false
	end

	local function internalNotify(...)
		if timing.rpue and timing.srpn then
			return
		end

		return self:notify(...)
	end

	if Configuration.expectToggleValue("UseIFrames") and inIFrame then
		return internalNotify(timing, "Action 'Parry' blocked because there are already existing IFrames.")
	end

	-- Parry if possible. Handles replacements.
	if StateListener.cparry() then
		-- Handle deflecting.
		if timing.nfdb or not StateListener.cdodge() or not dashReplacement then
			return QueuedBlocking.invoke(QueuedBlocking.BLOCK_TYPE_DEFLECT, "Defender_Deflect", nil)
		end

		-- Notify.
		internalNotify(timing, "Action type 'Parry' replaced to 'Dodge' type.")

		-- Dash replacement.
		return InputClient.dodge(options)
	end

	-- What fallbacks can we run?
	local canBlock = Configuration.expectToggleValue("DeflectBlockFallback")
		and not timing.nbfb
		and StateListener.cblock()

	local canVent = StateListener.cvent()
		and Configuration.expectToggleValue("VentFallback")
		and not timing.nvfb
		and not timing.rpue
		and self.__type ~= "Part"

	local canDodge = StateListener.cdodge()
		and Configuration.expectToggleValue("RollOnParryCooldown")
		and not timing.ndfb

	if canDodge then
		-- Dodge.
		InputClient.dodge(options)

		-- Notify.
		return internalNotify(timing, "Action type 'Parry' fallback to 'Dodge' type.")
	end

	if canVent then
		-- Vent.
		InputClient.vent()

		-- Notify.
		return internalNotify(timing, "Action type 'Parry' fallback to 'Vent' type.")
	end

	if canBlock then
		-- Block.
		QueuedBlocking.invoke(QueuedBlocking.BLOCK_TYPE_NORMAL, "Defender_BlockFallback", timing.bfht)

		-- Notify.
		return internalNotify(timing, "Action type 'Parry' fallback to 'Block' type.")
	end

	-- Cannot fallback.
	return internalNotify(timing, "Action 'Parry' blocked because no fallbacks are available.")
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
	-- Clean-up tasks.
	for idx, task in next, self.tasks do
		if task.forced then
			continue
		end

		-- Cancel task.
		task:cancel()

		-- Clear in table.
		self.tasks[idx] = nil

		-- If we are cancelling a stop block or start block, then we want to end the block.
		if task.identifier ~= "End Block" and task.identifier ~= "Start Block" then
			continue
		end

		QueuedBlocking.stop("Defender_StartBlock")
	end

	-- Clean-up hooks.
	self:clhook()

	-- Clear temporary maid.
	self.tmaid:clean()

	-- Clear markers.
	self.markers = {}

	-- Clean up hitboxes.
	self.hmaid:clean()

	-- Reset auto feint.
	self.afeinted = false
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

---Activate Prediction mantra instead of parrying.
---@param self Defender
---@param timing Timing
---@param action Action
Defender.prediction = LPH_NO_VIRTUALIZE(function(self, timing, action)
	-- Throw bypasses all counters.
	if PP_SCRAMBLE_STR(timing.smod) == "Throw" then
		return
	end

	-- Only use against players.
	if not players:GetPlayerFromCharacter(self.entity) then
		return
	end

	-- Windup delay.
	task.wait(0.1)

	local options = ValidationOptions.new(action, timing)
	options.skipFailureRate = true
	options.visualize = false
	if not self:valid(options) then
		return
	end

	-- Feint check.
	if self.__type == "Animation" and self.track and self:stopped(self.track, timing) then
		return
	end

	local localPlayer = players.LocalPlayer
	local character = localPlayer and localPlayer.Character
	local backpack = localPlayer and localPlayer:FindFirstChild("Backpack")
	local predictionMantra = backpack and backpack:FindFirstChild("Mantra:PredictionIntelligence{{Prediction}}")

	if not character then
		return
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	local effectReplicatorModule = effectReplicator and require(effectReplicator)

	if not effectReplicatorModule then
		return
	end

	-- IFrame check.
	local inIFrame = effectReplicatorModule:FindEffect("Immortal")
		or effectReplicatorModule:FindEffect("DodgeFrame")
		or effectReplicatorModule:FindEffect("ParryFrame")
		or effectReplicatorModule:FindEffect("Ghost")

	local isPlayer = self.entity and players:GetPlayerFromCharacter(self.entity)
	if Configuration.expectToggleValue("UseIFrames") and inIFrame and isPlayer then
		return
	end

	-- Hitbox check.
	if self.entity and self.__type == "Animation" then
		local root = self.entity:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end

		local hoptions = HitboxOptions.new(root, timing)
		hoptions.spredict = not timing.duih and not timing.dp
		hoptions.ptime = self:fsecs(timing)
		hoptions.action = action
		hoptions.entity = self.entity
		hoptions.visualize = false
		hoptions:ucache()

		if not self:hc(hoptions, nil) and not self:fpc(timing, hoptions) then
			return
		end
	end

	if not predictionMantra then
		return
	end

	local onCooldown = false
	for _, effect in next, effectReplicatorModule.Effects do
		if effect.Class == "ToolLockCD" and effect.index and effect.index.Value and tostring(effect.index.Value):find("PredictionIntelligence") then
			onCooldown = true
			break
		end
	end

	if onCooldown then
		return
	end

	local activateMantra = character:FindFirstChild("CharacterHandler")
		and character.CharacterHandler:FindFirstChild("Requests")
		and character.CharacterHandler.Requests:FindFirstChild("ActivateMantra")

	if not activateMantra then
		return
	end

	activateMantra:FireServer(predictionMantra)
	self:notify(timing, PP_SCRAMBLE_STR("Action 'Parry' replaced with 'Prediction' mantra."))
end)

---Activate Punishment mantra instead of parrying.
---@param self Defender
---@param timing Timing
---@param action Action
Defender.punishment = LPH_NO_VIRTUALIZE(function(self, timing, action)
	-- Throw bypasses all counters.
	if PP_SCRAMBLE_STR(timing.smod) == "Throw" then
		return
	end

	-- Only use against players.
	if not players:GetPlayerFromCharacter(self.entity) then
		return
	end

	-- Windup delay.
	task.wait(0.1)

	local options = ValidationOptions.new(action, timing)
	options.skipFailureRate = true
	options.visualize = false
	if not self:valid(options) then
		return
	end

	-- Feint check.
	if self.__type == "Animation" and self.track and self:stopped(self.track, timing) then
		return
	end

	local localPlayer = players.LocalPlayer
	local character = localPlayer and localPlayer.Character
	local backpack = localPlayer and localPlayer:FindFirstChild("Backpack")
	local punishmentMantra = backpack and backpack:FindFirstChild("Mantra:RevengeWeaponHeavy{{Punishment}}")

	if not character then
		return
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	local effectReplicatorModule = effectReplicator and require(effectReplicator)

	if not effectReplicatorModule then
		return
	end

	-- Defer to Prediction.
	if Configuration.expectToggleValue("UsePrediction") then
		local predictionMantra = backpack and backpack:FindFirstChild("Mantra:PredictionIntelligence{{Prediction}}")
		if predictionMantra then
			local predictionOnCooldown = false
			for _, effect in next, effectReplicatorModule.Effects do
				if effect.Class == "ToolLockCD" and effect.index and effect.index.Value and tostring(effect.index.Value):find("PredictionIntelligence") then
					predictionOnCooldown = true
					break
				end
			end

			if not predictionOnCooldown then
				return
			end
		end
	end

	-- Skip if already absorbing.
	if effectReplicatorModule:FindEffect("AbsorbCharge") then
		return
	end

	-- IFrame check.
	local inIFrame = effectReplicatorModule:FindEffect("Immortal")
		or effectReplicatorModule:FindEffect("DodgeFrame")
		or effectReplicatorModule:FindEffect("ParryFrame")
		or effectReplicatorModule:FindEffect("Ghost")

	local isPlayer = self.entity and players:GetPlayerFromCharacter(self.entity)
	if Configuration.expectToggleValue("UseIFrames") and inIFrame and isPlayer then
		return
	end

	-- Hitbox check.
	if self.entity and self.__type == "Animation" then
		local root = self.entity:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end

		local hoptions = HitboxOptions.new(root, timing)
		hoptions.spredict = not timing.duih and not timing.dp
		hoptions.ptime = self:fsecs(timing)
		hoptions.action = action
		hoptions.entity = self.entity
		hoptions.visualize = false
		hoptions:ucache()

		if not self:hc(hoptions, nil) and not self:fpc(timing, hoptions) then
			return
		end
	end

	if not punishmentMantra then
		return
	end

	local onCooldown = false
	for _, effect in next, effectReplicatorModule.Effects do
		if effect.Class == "ToolLockCD" and effect.index and effect.index.Value and tostring(effect.index.Value):find("RevengeWeaponHeavy") then
			onCooldown = true
			break
		end
	end

	if onCooldown then
		return
	end

	local activateMantra = character:FindFirstChild("CharacterHandler")
		and character.CharacterHandler:FindFirstChild("Requests")
		and character.CharacterHandler.Requests:FindFirstChild("ActivateMantra")

	if not activateMantra then
		return
	end

	activateMantra:FireServer(punishmentMantra)
	self:notify(timing, PP_SCRAMBLE_STR("Action 'Parry' replaced with 'Punishment' mantra."))
end)

---Handle auto feint.
---@param self Defender
---@param timing Timing
---@param action Action
---@param started number Timestamp of when the auto feint task started.
---@param initial boolean Whether this is the initial auto feint check.
Defender.afeint = LPH_NO_VIRTUALIZE(function(self, timing, action, started, initial)
	local function innerNotify(...)
		if initial then
			return
		end

		return self:notify(...)
	end

	local lfaction = StateListener.lAnimFaction
	if not lfaction then
		return innerNotify(timing, "Auto feint blocked because there is no local first action.")
	end

	local latimestamp = StateListener.lAnimTimestamp
	if not latimestamp then
		return innerNotify(timing, "Auto feint blocked because there is no last animation timestamp.")
	end

	if not StateListener.cfeint() then
		return innerNotify(timing, "Auto feint blocked because we are unable to feint.")
	end

	-- Our goal is to attempt to detect if this local timing will out-pace the animation timing that the enemey is doing.
	-- If it will out-pace it, then we don't want to feint as it will be useless, and not ideal.
	-- If not, then we did our goal, and prevented the user from getting hit.

	-- Time until our animation ends.
	local animTimeLeft = (lfaction:when() - (os.clock() - latimestamp)) + Latency.rtt()

	-- Time until the enemy's action hits us.
	local enemyTimeLeft = action:when() - (os.clock() - started)

	-- The local player will hit them before they do, so we don't want to feint.
	local autoFeintType = Configuration.expectOptionValue("AutoFeintType")

	if autoFeintType ~= "Aggressive" then
		if not timing.ha and enemyTimeLeft > animTimeLeft then
			return innerNotify(
				timing,
				"Auto feint blocked because enemy action (%.2fs, %.2fs) would not hit before local animation ends (%.2fs, %.2fs, %.2fs).",
				enemyTimeLeft,
				(os.clock() - started),
				animTimeLeft,
				lfaction:when(),
				(os.clock() - latimestamp)
			)
		end
	end

	local options = ValidationOptions.new(action, timing)
	options.sstun = true
	options.notify = false
	options.visualize = false

	if not self:valid(options) then
		return innerNotify(timing, "Auto feint failed because action is not valid.")
	end

	if not self.ifeinted then
		self:notify(timing, "Auto feint executed.")
	end

	if not initial then
		self.afeinted = true
	else
		self.ifeinted = true
	end

	InputClient.feint()
end)

---Add a action to the defender object.
---@param self Defender
---@param timing Timing
---@param action Action
Defender.action = LPH_NO_VIRTUALIZE(function(self, timing, action)
	if timing.umoa and self.__type == "Animation" then
		timing.et = action["_when"]
	end

	if timing.umoa or timing.cbm then
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
	local rdelay = Latency.rdelay()

	-- Add action.
	local atask = Task.new(PP_SCRAMBLE_STR(action._type), function()
		return action:when() - rdelay - Latency.sdelay()
	end, timing.punishable, timing.after, self.handle, self, timing, action, os.clock())

	if timing.forced then
		atask.forced = true
	end

	self:mark(atask)

	local actionType = PP_SCRAMBLE_STR(action._type)
	local isParryOrDodge = actionType == "Parry" or actionType == "Dodge"

	---@note: Schedule early Prediction task if enabled and action is Parry or Dodge.
	if Configuration.expectToggleValue("UsePrediction") and isParryOrDodge then
		self:mark(Task.new("Prediction", function()
			return action:when() - rdelay - Latency.sdelay() - 0.2
		end, timing.punishable, timing.after, self.prediction, self, timing, action, os.clock()))
	end

	---@note: Schedule early Punishment task if enabled and action is Parry or Dodge.
	if Configuration.expectToggleValue("UsePunishment") and isParryOrDodge then
		self:mark(Task.new("Punishment", function()
			return action:when() - rdelay - Latency.sdelay() - 0.2
		end, timing.punishable, timing.after, self.punishment, self, timing, action, os.clock()))
	end

	-- Add auto feint action.
	if
		Configuration.expectToggleValue("AutoFeint")
		and not timing.duih
		and action._when > 0
		and self.__type == "Animation"
		and action._type ~= PP_SCRAMBLE_STR("End Block")
	then
		self:mark(Task.new(PP_SCRAMBLE_STR(action._type), function()
			return (action:when() - rdelay - Latency.sdelay()) / 2
		end, timing.punishable, timing.after, self.afeint, self, timing, action, os.clock(), true))
	end

	-- Log.
	if not LRM_UserNote or LRM_UserNote == "tester" then
		self:notify(
			timing,
			"Added action '%s' (%.2fs) with ping '%.2f' (changing) subtracted.",
			PP_SCRAMBLE_STR(action.name),
			action:when(),
			Latency.rtt()
		)
	else
		self:notify(
			timing,
			"Added action '%s' ([redacted]) with ping '%.2f' (changing) subtracted.",
			PP_SCRAMBLE_STR(action.name),
			Latency.rtt()
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
	self.afeinted = false
	self.ifeinted = false
	return self
end

-- Return Defender module.
return Defender
