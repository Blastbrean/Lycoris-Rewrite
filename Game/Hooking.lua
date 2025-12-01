-- Hooking related stuff is handled here.
local Hooking = {}

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.StateListener
local StateListener = require("Features/Combat/StateListener")

---@module Game.LeaderboardClient
local LeaderboardClient = require("Game/LeaderboardClient")

---@module Features.Game.Spoofing
local Spoofing = require("Features/Game/Spoofing")

---@module Game.Objects.DodgeOptions
local DodgeOptions = require("Game/Objects/DodgeOptions")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

-- Services.
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

-- Cached IsA.
local isA = game.IsA

-- Old hooked functions.
local oldFireServer = nil
local oldUnreliableFireServer = nil
local oldNameCall = nil
local oldNewIndex = nil
local oldTick = nil
local oldToString = nil
local oldIndex = nil
local oldPrint = nil
local oldWarn = nil
local oldHasEffect = nil

-- InputClient caching.
local lastCallingFunction = nil
local lastFunctionCacheAttempt = 0

-- Action rolling.
local lastActionRoll = nil

-- Ban remotes table.
local banRemotes = {}

-- Input types.
local INPUT_LEFT_CLICK = 1
local INPUT_RIGHT_CLICK = 2
local INPUT_CRITICAL = 3
local INPUT_CAST = 4
local INPUT_BLOCK = 5

-- Input types two.
local INPUT_TYPE_BEFORE = 1
local INPUT_TYPE_AFTER = 2

---Handle flow state.
---@param type number
local handleFlowState = LPH_NO_VIRTUALIZE(function(type)
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	local localPlayer = playersService.LocalPlayer
	if not localPlayer then
		return
	end

	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	local flowStateTool = backpack:FindFirstChild("Talent:Flow State")
	if not flowStateTool then
		return
	end

	local flowStateRemote = flowStateTool:FindFirstChild("ActivateRt")
	if not flowStateRemote then
		return
	end

	local flowStateCooldown = false
	local shUpperCooldown = false
	local shDashCooldown = false
	local shGapCloserCooldown = false

	for _, effect in next, effectReplicatorModule.Effects do
		local index = rawget(effect, "index")
		if not index then
			continue
		end

		if index.Class == "ToolCD" and index.Value == "Talent: Flow State" then
			flowStateCooldown = true
		end

		if index.Class:match("SHUpper") and index.Class:match("CD") then
			shUpperCooldown = true
		end

		if index.Class:match("SHDash") and index.Class:match("CD") then
			shDashCooldown = true
		end

		if index.Class:match("SHGap") and index.Class:match("CD") then
			shGapCloserCooldown = true
		end
	end

	Logger.warn(
		"(%s, %s, %s, %s, %s) Current cooldown state...",
		shUpperCooldown and "SHUpperCD" or "SHUpperReady",
		shDashCooldown and "SHDashCD" or "SHDashReady",
		shGapCloserCooldown and "SHGapCloserCD" or "SHGapCloserReady",
		effectReplicatorModule:FindEffect("SlideAttackCD") and "SlideAttackCD" or "SlideAttackReady",
		flowStateCooldown and "FlowStateCD" or "FlowStateReady"
	)

	if flowStateCooldown then
		return Logger.warn("Flow state is on cooldown.")
	end

	Logger.warn("(%i) Attempting to detect Silentheart moves for input type.", type)

	if
		effectReplicatorModule:FindEffect("Sliding")
		and not effectReplicatorModule:FindEffect("SlideAttackCD")
		and type == INPUT_LEFT_CLICK
	then
		Logger.warn("Detected 'Ankle Cutter' move.")

		flowStateRemote:FireServer()
	end

	if effectReplicatorModule:FindEffect("SHDash") and not shDashCooldown and type == INPUT_LEFT_CLICK then
		Logger.warn("Detected 'Mayhem' move.")

		flowStateRemote:FireServer()
	end

	-- If we've done an aerial attack -- (aerial cooldown effect)
	-- If we've attacked also -- (light attack effect)
	if
		effectReplicatorModule:FindEffect("AerialCD")
		and effectReplicatorModule:FindEffect("LightAttack")
		and not shGapCloserCooldown
		and type == INPUT_LEFT_CLICK
	then
		Logger.warn("Detected 'Relentless Hunt' move.")

		flowStateRemote:FireServer()
	end

	if
		(
			effectReplicatorModule:FindEffect("Sliding")
			or effectReplicatorModule:FindEffect("ClientCrouch")
			or effectReplicatorModule:FindEffect("Crouching")
		)
		and not shUpperCooldown
		and type == INPUT_RIGHT_CLICK
	then
		Logger.warn("Detected 'Rising Star' move.")

		flowStateRemote:FireServer()
	end
end)

---Handle action rolling.
---@param type number
local handleActionRolling = LPH_NO_VIRTUALIZE(function(type)
	local actionRollTypes = Configuration.expectOptionValue("ActionRollingActions") or {}
	local actionRollInputs = {
		[INPUT_LEFT_CLICK] = actionRollTypes["Roll On M1"],
		[INPUT_CRITICAL] = actionRollTypes["Roll On Critical"],
		[INPUT_CAST] = actionRollTypes["Roll On Cast"],
		[INPUT_BLOCK] = actionRollTypes["Roll On Parry"],
	}

	if not actionRollInputs[type] then
		return
	end

	if type ~= INPUT_CAST then
		local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
		if not effectReplicator then
			return
		end

		local effectReplicatorModule = require(effectReplicator)
		if not effectReplicatorModule then
			return
		end

		if not effectReplicatorModule:HasEffect("Equipped") then
			return
		end
	end

	if type == INPUT_CAST then
		local lMantraActivated = StateListener.lMantraActivated
		if not lMantraActivated then
			return
		end

		if lMantraActivated.Name:match("Wisp") then
			return
		end
	end

	if
		lastActionRoll
		and os.clock() - lastActionRoll < (Configuration.expectOptionValue("ActionRollCooldown") or 2.0)
	then
		return
	end

	-- Timestamp it.
	lastActionRoll = os.clock()

	-- Wait.
	if type ~= INPUT_BLOCK then
		task.wait(0.1)
	end

	-- Perform options.
	local options = DodgeOptions.new()
	options.rollCancel = true
	options.rollCancelDelay = Configuration.expectOptionValue("ActionRollCancelDelay") or 0.1
	options.actionRolling = true

	-- Dodge.
	Logger.warn("(%i) Performing action roll dodge.", type)

	if type == INPUT_CAST then
		TaskSpawner.spawn("ActionRolling_CastDodge", InputClient.dodge, options)
	else
		InputClient.dodge(options)
	end
end)

---Handle delayed feints.
local handleDelayedFeints = LPH_NO_VIRTUALIZE(function()
	local lAnimTrack = StateListener.lAnimationValidTrack
	if not lAnimTrack then
		return Logger.warn("No valid animation track for delayed feint.")
	end

	local lAnimFaction = StateListener.lAnimFaction
	if not lAnimFaction then
		return Logger.warn("No animation faction for delayed feint.")
	end

	if not lAnimTrack.IsPlaying then
		return Logger.warn("Non playing animation track for delayed feint.")
	end

	if not StateListener.cfeint() then
		return Logger.warn("Unable to feint for delayed feint.")
	end

	local laTimestamp = StateListener.lAnimTimestamp
	if not laTimestamp then
		return Logger.warn("No animation timestamp for delayed feint.")
	end

	local laLatency = StateListener.lAnimLatency
	if not laLatency then
		return Logger.warn("No animation latency for delayed feint.")
	end

	local delayed = (lAnimFaction:when() - (os.clock() - laTimestamp)) - laLatency

	Logger.warn("Delaying for %.2f seconds before sending the feint remote.", delayed)

	task.wait(delayed)
end)

---On intercepted input.
---@param type number
---@param state number
local onInterceptedInput = LPH_NO_VIRTUALIZE(function(type, state)
	if Configuration.expectToggleValue("AutoFlowState") and state == INPUT_TYPE_BEFORE and type ~= INPUT_CAST then
		handleFlowState(type)
	end

	if Configuration.expectToggleValue("ActionRolling") and state == INPUT_TYPE_AFTER then
		handleActionRolling(type)
	end

	if
		Configuration.expectToggleValue("DelayedFeints")
		and state == INPUT_TYPE_BEFORE
		and type == INPUT_RIGHT_CLICK
		and StateListener.lAnimationValidTrack
	then
		handleDelayedFeints()
	end
end)

---Recursively find first valid InputClient stack.
---@return table?
local findInputClientStack = LPH_NO_VIRTUALIZE(function()
	for level = 1, math.huge do
		-- Get info.
		local success, info = pcall(debug.getinfo, level)
		if not success or not info then
			break
		end

		-- Check source.
		if not info.source:match("InputClient") then
			continue
		end

		-- Check if CClosure.
		if iscclosure(info.func) then
			continue
		end

		-- Fetch alternative stack - on Wave, this will fail. You cannot wrap debug.getstack(...) in pcall.
		local ssuccess, stack = pcall(debug.getstack, level)

		-- Return stack.
		return ssuccess and stack or debug.getstack(level - 1)
	end
end)

---Find function level of InputClient.
---@return number?, table?
local findInputClientLevel = LPH_NO_VIRTUALIZE(function()
	for level = 1, math.huge do
		-- Get info.
		local success, info = pcall(debug.getinfo, level)
		if not success or not info then
			break
		end

		-- Check source.
		if not info.source:match("InputClient") then
			continue
		end

		-- Return level, debug information.
		return level, info
	end
end)

---Stop gesture animations.
---@param animator Animator
local stopGestureAnimations = LPH_NO_VIRTUALIZE(function(animator)
	for _, animationTrack in pairs(animator:GetPlayingAnimationTracks()) do
		if not animationTrack.Animation or animationTrack.Animation.Parent.Name ~= "Gestures" then
			continue
		end

		animationTrack:Stop()
	end
end)

---Replicate gesture.
---@param gestureName string
local replicateGesture = LPH_NO_VIRTUALIZE(function(gestureName)
	local assets = replicatedStorage:FindFirstChild("Assets")
	local anims = assets and assets:FindFirstChild("Anims")
	local gestures = anims and anims:FindFirstChild("Gestures")
	local gesture = gestures and gestures:FindFirstChild(gestureName)
	if not gesture then
		return
	end

	local localPlayer = playersService.LocalPlayer
	if not localPlayer then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildWhichIsA("Animator")
	if not animator then
		return
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	local effectReplicatorModule = effectReplicator and require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if effectReplicatorModule:FindEffect("Gesturing") then
		return
	end

	-- Create animation objects.
	local actionEffect = effectReplicatorModule:CreateEffect("Action")
	local gesturingEffect = effectReplicatorModule:CreateEffect("Gesturing")
	local mobileActionEffect = effectReplicatorModule:CreateEffect("MobileAction")
	local gestureAnimation = animator:LoadAnimation(gesture)

	-- Play animation.
	stopGestureAnimations(animator)
	gestureAnimation:Play()

	-- Wait for movement to cancel.
	repeat
		task.wait()
	until humanoid.MoveDirection.Magnitude > 0

	-- Wait a bit...
	task.wait(0.5)

	-- Remove effects.
	actionEffect:Remove()
	gesturingEffect:Remove()
	mobileActionEffect:Remove()

	-- Stop animations.
	stopGestureAnimations(animator)
end)

---Modify ambience color.
---@param value Color3
local modifyAmbienceColor = LPH_NO_VIRTUALIZE(function(value)
	local ambienceColor = Configuration.expectOptionValue("AmbienceColor")
	local shouldUseOriginalAmbienceColor = Configuration.expectToggleValue("OriginalAmbienceColor")

	if not shouldUseOriginalAmbienceColor and ambienceColor then
		return ambienceColor
	end

	local brightness = Configuration.expectOptionValue("OriginalAmbienceColorBrightness") or 0.0
	local red, green, blue = value.R, value.G, value.B

	red = math.min(red + brightness, 255)
	green = math.min(green + brightness, 255)
	blue = math.min(blue + brightness, 255)

	return Color3.fromRGB(red, green, blue)
end)

---On print.
---@return any
local onPrint = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldPrint(...)
	end

	if Configuration.expectToggleValue("StopGameLogging") then
		return
	end

	return oldPrint(...)
end)

---On warn.
---@return any
local onWarn = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldWarn(...)
	end

	if Configuration.expectToggleValue("StopGameLogging") then
		return
	end

	return oldWarn(...)
end)

---On tick.
---@return any
local onTick = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldTick(...)
	end

	if not Configuration.expectToggleValue("AutoSprint") then
		return oldTick(...)
	end

	local level, info = findInputClientLevel()
	if not level or not info then
		return oldTick(...)
	end

	local stack = findInputClientStack()
	if not stack then
		return error("Stack is nil.")
	end

	local firstConstantSuccess, firstConstant = pcall(debug.getconstant, info.func, 1)
	if not firstConstantSuccess then
		return oldTick(...)
	end

	if firstConstant ~= "UserInputType" then
		return oldTick(...)
	end

	---@note: Filter for any other spots that might be using tick() through the stack.
	if
		not table.find(stack, "W")
		and not table.find(stack, "A")
		and not table.find(stack, "S")
		and not table.find(stack, "D")
	then
		return oldTick(...)
	end

	---@note: We can indeed set a delay in here. The active thread is InputClient.
	if Configuration.expectToggleValue("AutoSprintDelay") then
		task.wait(Configuration.expectOptionValue("AutoSprintDelayTime"))
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if
		not Configuration.expectToggleValue("AutoSprintOnCrouch") and effectReplicatorModule:HasEffect("ClientCrouch")
	then
		return oldTick(...)
	end

	---@note: Set the timestamp set by sprinting to -math.huge so it's always over 0.25s.
	return -math.huge
end)

---On index.
---@return any
local onIndex = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldIndex(...)
	end

	local args = { ... }
	local index = args[2]

	---@note: Patch out InputClient detection for __index hooking to prevent annoying errors.
	if typeof(args[2]) == "table" then
		return error("InputClient - Lycoris On Top")
	end

	if Spoofing.force or not Configuration.expectToggleValue("InfoSpoofing") then
		return oldIndex(...)
	end

	local self = args[1]

	if typeof(self) == "Instance" and typeof(index) == "string" then
		if index == "Value" then
			if self.Name == "SERVER_NAME" then
				return Configuration.expectOptionValue("SpoofedServerName")
			end

			if self.Name == "SERVER_REGION" then
				return Configuration.expectOptionValue("SpoofedServerRegion")
			end

			if self.Name == "SERVER_AGE" then
				return Configuration.expectOptionValue("SpoofedServerAge")
			end
		end

		if isA(self, "Player") then
			if index == "DisplayName" then
				return "Linoria V2 On Top"
			end

			if index == "Name" then
				return "Linoria V2 On Top"
			end

			if index == "UserId" then
				return 000000000
			end
		end
	end

	return oldIndex(...)
end)

---On name call.
---@return any
local onNameCall = LPH_NO_VIRTUALIZE(function(...)
	if not LeaderboardClient.calling and checkcaller() then
		return oldNameCall(...)
	end

	local args = { ... }
	local self = args[1]

	if banRemotes[self] then
		return Logger.warn("(%s) Anticheat is referencing a ban remote.", self.Name)
	end

	if typeof(self) ~= "Instance" then
		return oldNameCall(...)
	end

	local method = getnamecallmethod()
	local name = self.Name

	if method == "Create" then
		---@note: Fix object if we're using a lighting template.
		local lightingTemplate = args[4]

		if typeof(lightingTemplate) == "table" then
			if
				lightingTemplate["FogStart"]
				and lightingTemplate["FogEnd"]
				and Configuration.expectToggleValue("NoFog")
			then
				lightingTemplate["FogStart"] = 9e9
				lightingTemplate["FogEnd"] = 9e9
			end

			if lightingTemplate["Ambient"] and Configuration.expectToggleValue("ModifyAmbience") then
				lightingTemplate["Ambient"] = modifyAmbienceColor(lightingTemplate["Ambient"])
			end

			if lightingTemplate["Density"] and Configuration.expectToggleValue("NoFog") then
				lightingTemplate["Density"] = 0
			end

			return oldNameCall(unpack(args))
		end
	end

	if Configuration.expectToggleValue("InfoSpoofing") then
		if typeof(args[2]) == "string" and method == "GetAttribute" and not Spoofing.force then
			local character = playersService.LocalPlayer.Character
			local humanoid = game.FindFirstChild(character, "Humanoid")
			local foreign = true

			if character and humanoid and (self.Parent == character or self.Parent == humanoid) then
				foreign = false
			end

			if foreign and not Configuration.expectToggleValue("SpoofOtherPlayers") then
				return oldNameCall(...)
			end

			if args[2] == "FirstName" then
				return foreign and "Linoria V2" or Configuration.expectOptionValue("SpoofedFirstName")
			end

			if args[2] == "LastName" then
				return foreign and "On Top" or Configuration.expectOptionValue("SpoofedLastName")
			end

			if args[2] == "CharacterName" then
				local characterName = Configuration.expectOptionValue("SpoofedFirstName")
					.. " "
					.. Configuration.expectOptionValue("SpoofedLastName")

				return foreign and "Linoria V2 On Top" or characterName
			end

			if args[2] == "Guild" then
				return foreign and "discord.gg/lyc" or Configuration.expectOptionValue("SpoofedGuild")
			end

			if args[2] == "GuildRich" then
				return foreign and "discord.gg/lyc" or Configuration.expectOptionValue("SpoofedGuildName")
			end
		end
	end

	if name == "ActivateMantra" and getnamecallmethod() == "FireServer" then
		-- State.
		StateListener.lMantraActivated = args[2]

		-- Before.
		onInterceptedInput(INPUT_CAST, INPUT_TYPE_BEFORE)

		-- Now.
		local result = oldNameCall(...)

		-- After.
		onInterceptedInput(INPUT_CAST, INPUT_TYPE_AFTER)

		-- Return.
		return result
	end

	if name == "Gesture" and Configuration.expectToggleValue("EmoteSpoofer") and typeof(args[2]) == "string" then
		return replicateGesture(args[2])
	end

	return oldNameCall(...)
end)

---On unreliable fire server.
---@return any
local onUnreliableFireServer = LPH_NO_VIRTUALIZE(function(...)
	local args = { ... }
	local self = args[1]

	if banRemotes[self] then
		return Logger.warn("(%s) Anticheat is calling a unreliable ban remote.", self.Name)
	end

	local leftClickRemote = KeyHandling.getRemote("LeftClick")
	local criticalRemote = KeyHandling.getRemote("CriticalClick")
	local feintClickRemote = KeyHandling.getRemote("FeintClick")
	local offhandAttackRemote = KeyHandling.getRemote("OffhandAttack")

	local inputType = nil

	if criticalRemote and self == criticalRemote then
		inputType = INPUT_CRITICAL
	end

	if leftClickRemote and self == leftClickRemote then
		inputType = INPUT_LEFT_CLICK
	end

	if (feintClickRemote and self == feintClickRemote) or (offhandAttackRemote and self == offhandAttackRemote) then
		inputType = INPUT_RIGHT_CLICK
	end

	if inputType then
		-- Before.
		onInterceptedInput(inputType, INPUT_TYPE_BEFORE)

		-- Now.
		local result = oldUnreliableFireServer(...)

		-- After.
		onInterceptedInput(inputType, INPUT_TYPE_AFTER)

		-- Return.
		return result
	end

	if checkcaller() then
		return oldUnreliableFireServer(...)
	end

	return oldUnreliableFireServer(...)
end)

---On fire server.
---@return any
local onFireServer = LPH_NO_VIRTUALIZE(function(...)
	local args = { ... }
	local self = args[1]

	if banRemotes[self] then
		return Logger.warn("(%s) Anticheat is calling a ban remote.", self.Name)
	end

	local blockRemote = KeyHandling.getRemote("Block")

	local inputType = nil

	if blockRemote and self == blockRemote then
		inputType = INPUT_BLOCK
	end

	if inputType then
		-- Before.
		onInterceptedInput(inputType, INPUT_TYPE_BEFORE)

		-- Now.
		local result = oldFireServer(...)

		-- After.
		onInterceptedInput(inputType, INPUT_TYPE_AFTER)

		-- Return.
		return result
	end

	return oldFireServer(...)
end)

---On new index.
---@return any
local onNewIndex = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldNewIndex(...)
	end

	local args = { ... }
	local self = args[1]
	local index = args[2]
	local value = args[3]

	if typeof(self) ~= "Instance" then
		return oldNewIndex(...)
	end

	if Configuration.expectToggleValue("InfoSpoofing") then
		if game.IsA(self, "TextLabel") and index == "Text" and not Spoofing.force then
			if self.Name == "Slot" and self.Parent.Name == "CharacterInfo" then
				return oldNewIndex(self, index, Configuration.expectOptionValue("SpoofedSlotString"))
			end

			if self.Name == "GameVersion" then
				return oldNewIndex(self, index, Configuration.expectOptionValue("SpoofedGameVersion"))
			end

			if self.Name == "Date" then
				return oldNewIndex(self, index, Configuration.expectOptionValue("SpoofedDateString"))
			end
		end
	end

	if Configuration.expectToggleValue("NoClip") and Configuration.expectToggleValue("Fly") then
		if index == "ActiveController" then
			if self.Parent then
				local airController = self.Parent:FindFirstChild("AirController")
				return oldNewIndex(self, index, airController or value)
			end
		end
	end

	if index == "MouseIconEnabled" then
		return oldNewIndex(self, index, true)
	end

	if index == "Ambient" then
		if self == lighting and Configuration.expectToggleValue("ModifyAmbience") then
			return oldNewIndex(self, index, modifyAmbienceColor(value))
		end
	end

	return oldNewIndex(...)
end)

---On to string.
---@return any
local onToString = LPH_NO_VIRTUALIZE(function(...)
	if os.clock() - lastFunctionCacheAttempt <= 0.5 then
		return oldToString(...)
	end

	local level, info = findInputClientLevel()
	if not level or not info then
		return oldToString(...)
	end

	if info.func == lastCallingFunction then
		return oldToString(...)
	end

	lastFunctionCacheAttempt = os.clock()

	-- Cache InputClient data.
	local success = InputClient.cache()

	-- Update last calling function. Only do this if we successfully cached; else we need to wait for the next frame.
	if success then
		lastCallingFunction = info.func
	end

	-- Continue.
	return oldToString(...)
end)

---On has effect.
---@return any
local onHasEffect = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldHasEffect(...)
	end

	local args = { ... }
	local class = args[2]

	local attackEffects = {
		"LightAttack",
		"HeavyAttack",
		"OffhandAttack",
		"UsingAbility",
		"CastingSpell",
	}

	if Configuration.expectToggleValue("NoAttackingClientChecks") and table.find(attackEffects, class) then
		return false
	end

	if Configuration.expectToggleValue("NoFallDamage") and class == "NoFall" then
		return true
	end

	return oldHasEffect(...)
end)

---Hooking initialization.
function Hooking.init()
	local localPlayer = playersService.LocalPlayer

	---@improvement: Add a listener for this script.
	local playerScripts = localPlayer:WaitForChild("PlayerScripts")
	local clientActor = playerScripts:WaitForChild("ClientActor")
	local clientManager = clientActor:WaitForChild("ClientManager")
	local requests = replicatedStorage:WaitForChild("Requests")

	---@note: Crucial part because of the actor and the error detection.
	clientManager.Enabled = false

	---@note: Dynamically get the ban remotes.
	local banRemoteCount = 0

	for _, request in next, requests:GetChildren() do
		local hasChangedConnection = #getconnections(request.Changed)
		if hasChangedConnection <= 0 then
			continue
		end

		banRemoteCount = banRemoteCount + 1
		banRemotes[request] = true
	end

	if banRemoteCount ~= 2 then
		return error("Anticheat has less or more than two ban remotes.")
	end

	oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, onFireServer)
	oldUnreliableFireServer = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, onUnreliableFireServer)
	oldToString = hookfunction(tostring, onToString)
	oldIndex = hookfunction(getrawmetatable(game).__index, onIndex)
	oldNameCall = hookfunction(getrawmetatable(game).__namecall, onNameCall)
	oldNewIndex = hookfunction(getrawmetatable(game).__newindex, onNewIndex)
	oldTick = hookfunction(tick, onTick)
	oldWarn = hookfunction(warn, onWarn)
	oldPrint = hookfunction(print, onPrint)

	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)

	oldHasEffect = effectReplicatorModule.HasEffect

	effectReplicatorModule.HasEffect = onHasEffect

	-- Okay, we're done.
	Logger.warn("Client-side anticheat has been penetrated.")
end

---Hooking detach.
function Hooking.detach()
	local localPlayer = playersService.LocalPlayer

	if oldPrint then
		hookfunction(print, oldPrint)
	end

	if oldWarn then
		hookfunction(warn, oldWarn)
	end

	if oldTick then
		hookfunction(tick, oldTick)
	end

	if oldToString then
		hookfunction(tostring, oldToString)
	end

	if oldIndex then
		hookfunction(getrawmetatable(game).__index, oldIndex)
	end

	if oldNameCall then
		hookfunction(getrawmetatable(game).__namecall, oldNameCall)
	end

	if oldNewIndex then
		hookfunction(getrawmetatable(game).__newindex, oldNewIndex)
	end

	if oldFireServer then
		hookfunction(Instance.new("RemoteEvent").FireServer, oldFireServer)
	end

	if oldUnreliableFireServer then
		hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, oldUnreliableFireServer)
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	local effectReplicatorModule = effectReplicator and require(effectReplicator)

	if oldHasEffect and effectReplicatorModule then
		effectReplicatorModule.HasEffect = oldHasEffect
		oldHasEffect = nil
	end

	local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
	local clientActor = playerScripts and playerScripts:FindFirstChild("ClientActor")
	local clientManager = clientActor and clientActor:FindFirstChild("ClientManager")

	if clientManager then
		clientManager.Enabled = true
	end

	Logger.warn("Pulled out of client-side anticheat.")
end

-- Return Hooking module.
return Hooking
