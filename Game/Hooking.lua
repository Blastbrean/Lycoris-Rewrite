-- Hooking related stuff is handled here.
local Hooking = {}

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Features.Game.Monitoring
local Monitoring = require("Features/Game/Monitoring")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.Defense
local Defense = require("Features/Combat/Defense")

---@module Game.LeaderboardClient
local LeaderboardClient = require("Game/LeaderboardClient")

-- Services.
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

-- Old hooked functions.
local oldFireServer = nil
local oldUnreliableFireServer = nil
local oldNameCall = nil
local oldNewIndex = nil
local oldTick = nil
local oldCoroutineWrap = nil
local oldTaskSpawn = nil
local oldIndex = nil

-- Ban remotes table.
local banRemotes = {}

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
		local stack_success, stack = pcall(debug.getstack, level)

		-- Return stack.
		return stack_success and stack or debug.getstack(level - 1)
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

	-- Stop animation.
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
	local self = args[1]
	local index = args[2]

	---@note: Patch out InputClient detection for __index hooking to prevent annoying errors.
	if typeof(index) == "table" and findInputClientLevel() then
		return error("InputClient - Lycoris On Top")
	end

	if not Configuration.expectToggleValue("InfoSpoofing") then
		return oldIndex(...)
	end

	if typeof(self) == "Instance" and typeof(index) == "string" and index == "Value" then
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

	if
		typeof(self) == "Instance"
		and typeof(args[2]) == "string"
		and getnamecallmethod() == "GetAttribute"
		and Configuration.expectToggleValue("InfoSpoofing")
	then
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

	if banRemotes[self] then
		return Logger.warn("(%s) Anticheat is referencing a ban remote.", self.Name)
	end

	local isActivatingMantra = self.Name == "ActivateMantra"

	if typeof(args[2]) == "Instance" and isActivatingMantra then
		Defense.lastMantraActivate = args[2]
	end

	if isActivatingMantra and Configuration.expectToggleValue("BlockPunishableMantras") and Defense.blocking() then
		return
	end

	---@note: Fix object if we're using a lighting template.
	local lightingTemplate = args[3]

	if
		getnamecallmethod() == "Create"
		and typeof(lightingTemplate) == "table"
		and lightingTemplate["FogStart"]
		and lightingTemplate["FogEnd"]
	then
		if Configuration.expectToggleValue("NoFog") then
			lightingTemplate["FogStart"] = 9e9
			lightingTemplate["FogEnd"] = 9e9
			args[2] = TweenInfo.new(0.0)
		end

		if Configuration.expectToggleValue("ModifyAmbience") then
			lightingTemplate["Ambient"] = modifyAmbienceColor(lightingTemplate["Ambient"])
			args[2] = TweenInfo.new(0.0)
		end

		return oldNameCall(unpack(args))
	end

	if self.Name == "AcidCheck" and Configuration.expectToggleValue("NoAcidWater") then
		return
	end

	if self.Name == "Gesture" and Configuration.expectToggleValue("EmoteSpoofer") and typeof(args[2]) == "string" then
		return replicateGesture(args[2])
	end

	local fallDamageRemote = KeyHandling.getRemote("FallDamage")

	if self == fallDamageRemote and Configuration.expectToggleValue("NoFallDamage") then
		return
	end

	if
		self.Name == "ServerSprint"
		and (self.ClassName == "UnreliableRemoteEvent" or self.ClassName == "RemoteEvent")
		and Configuration.expectToggleValue("RunAttack")
	then
		return oldNameCall(self, true)
	end

	return oldNameCall(...)
end)

---On unreliable fire server.
---@return any
local onUnreliableFireServer = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldUnreliableFireServer(...)
	end

	local args = { ... }
	local self = args[1]

	if banRemotes[self] then
		return Logger.warn("(%s) Anticheat is calling a unreliable ban remote.", self.Name)
	end

	local leftClickRemote = KeyHandling.getRemote("LeftClick")
	local criticalClickRemote = KeyHandling.getRemote("CriticalClick")

	if leftClickRemote and self == leftClickRemote then
		local block = (Configuration.expectToggleValue("BlockPunishableM1s") and Defense.blocking())
		return (not block) and oldUnreliableFireServer(...)
	end

	if criticalClickRemote and self == criticalClickRemote then
		local block = (Configuration.expectToggleValue("BlockPunishableCriticals") and Defense.blocking())
		return (not block) and oldUnreliableFireServer(...)
	end

	return oldUnreliableFireServer(...)
end)

---On fire server.
---@return any
local onFireServer = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldFireServer(...)
	end

	local args = { ... }
	local self = args[1]

	if banRemotes[self] then
		return Logger.warn("(%s) Anticheat is calling a ban remote.", self.Name)
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

	if
		typeof(self) == "Instance"
		and (self.Name == "InputClient" or self.Name == "CharacterHandler")
		and index:lower():match("parent")
	then
		return Logger.warn(
			"(%s) Caller attempted to set the parent of InputClient or CharacterHandler",
			debug.getinfo(3).short_src
		)
	end

	if
		Configuration.expectToggleValue("InfoSpoofing")
		and typeof(self) == "Instance"
		and game.IsA(self, "TextLabel")
		and index == "Text"
	then
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

	if self == lighting and (index == "FogStart" or index == "FogEnd") and Configuration.expectToggleValue("NoFog") then
		return
	end

	if self:IsA("Atmosphere") and index == "Density" and Configuration.expectToggleValue("NoFog") then
		return
	end

	if self == lighting and index == "Ambient" and Configuration.expectToggleValue("ModifyAmbience") then
		return oldNewIndex(self, index, modifyAmbienceColor(value))
	end

	if self == workspace.CurrentCamera then
		if index == "FieldOfView" and Configuration.expectToggleValue("ModifyFieldOfView") then
			return
		end

		if index == "CameraSubject" and Monitoring.subject then
			return
		end
	end

	return oldNewIndex(...)
end)

---On coroutine call.
---@return any
local onCoroutineCall = LPH_NO_VIRTUALIZE(function(arg)
	if arg == "" then
		return ""
	else
		return "LYCORIS_ON_TOP"
	end
end)

---On coroutine wrap.
---@return any
local onCoroutineWrap = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldCoroutineWrap(...)
	end

	local level, info = findInputClientLevel()
	if not level or not info then
		return oldCoroutineWrap(...)
	end

	-- Fetch arguments.
	local args = { ... }

	---@note: Prevent InputClient detection 16.2 from happening so the Disconnect call never happens.
	args[1] = onCoroutineCall

	-- Return with modified arguments.
	return oldCoroutineWrap(unpack(args))
end)

---On task spawn.
---@return any
local onTaskSpawn = LPH_NO_VIRTUALIZE(function(...)
	if checkcaller() then
		return oldTaskSpawn(...)
	end

	local level, info = findInputClientLevel()
	if not level or not info then
		return oldTaskSpawn(...)
	end

	local stack = findInputClientStack()
	if not stack then
		Logger.warn("Task stack is nil.")
	end

	-- Arguments.
	local args = { ... }
	local func = args[1]

	-- Constants.
	local consts = debug.getconstants(func)

	-- Check for anticheat task.
	local isAnticheatTask = (#consts == 0 or consts[2] == "Parent" or table.find(consts, "RenderStepped"))
		and not table.find(consts, "LightAttack")

	-- Okay, replace arguments.
	if isAnticheatTask then
		args[1] = function() end
	end

	-- Check if this is something where we would want to update the InputClient cache.
	if not isAnticheatTask and stack and stack[2] ~= Enum.HumanoidStateType.Landed then
		InputClient.update(consts)
	end

	-- Return.
	return oldTaskSpawn(unpack(args))
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

	---@todo: Optimize hooks - preferably filter out calls slowing performance.
	oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, onFireServer)
	oldUnreliableFireServer = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, onUnreliableFireServer)
	oldCoroutineWrap = hookfunction(coroutine.wrap, onCoroutineWrap)
	oldTaskSpawn = hookfunction(task.spawn, onTaskSpawn)
	oldIndex = hookfunction(getrawmetatable(game).__index, onIndex)
	oldNameCall = hookfunction(getrawmetatable(game).__namecall, onNameCall)
	oldNewIndex = hookfunction(getrawmetatable(game).__newindex, onNewIndex)
	oldTick = hookfunction(tick, onTick)

	-- Okay, we're done.
	Logger.warn("Client-side anticheat has been penetrated.")
end

---Hooking detach.
function Hooking.detach()
	local localPlayer = playersService.LocalPlayer

	if oldTick then
		hookfunction(tick, oldTick)
	end

	if oldTaskSpawn then
		hookfunction(task.spawn, oldTaskSpawn)
	end

	if oldCoroutineWrap then
		hookfunction(coroutine.wrap, oldCoroutineWrap)
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
