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

-- Services.
local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")

-- Old hooked functions.
local oldFireServer = nil
local oldUnreliableFireServer = nil
local oldNameCall = nil
local oldGetFenv = nil
local oldIndex = nil
local oldNewIndex = nil
local oldTick = nil
local oldCoroutineWrap = nil
local oldTaskSpawn = nil
local oldProtectedCall = nil
local oldError = nil
local oldToString = nil

-- Last state.
local lastErrorResult = nil
local lastErrorLevel = nil

---Replicate gesture.
---@param gestureName string
local function replicateGesture(gestureName)
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

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	local effectReplicatorModule = effectReplicator and require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if effectReplicatorModule:FindEffect("Gesturing") then
		return
	end

	local actionEffect = effectReplicatorModule:CreateEffect("Action")
	local gesturingEffect = effectReplicatorModule:CreateEffect("Gesturing")
	local mobileActionEffect = effectReplicatorModule:CreateEffect("MobileAction")

	---Stop gesture animations.
	local function stopGestureAnimations()
		for _, animationTrack in pairs(humanoid:GetPlayingAnimationTracks()) do
			if not animationTrack.Animation or animationTrack.Animation.Parent ~= gestures then
				continue
			end

			animationTrack:Stop()
		end
	end

	stopGestureAnimations()

	humanoid:LoadAnimation(gesture):Play()

	repeat
		task.wait()
	until humanoid.MoveDirection.Magnitude > 0

	task.wait(0.5)

	actionEffect:Remove()
	gesturingEffect:Remove()
	mobileActionEffect:Remove()

	stopGestureAnimations()
end

---On tick.
---@return any
local function onTick(...)
	if checkcaller() then
		return oldTick(...)
	end

	if not Configuration.expectToggleValue("AutoSprint") then
		return oldTick(...)
	end

	local debugInfoResult = debug.getinfo(3)
	if not debugInfoResult.source:match("InputClient") then
		return oldTick(...)
	end

	local firstConstantSuccess, firstConstant = pcall(debug.getconstant, debugInfoResult.func, 1)
	if not firstConstantSuccess then
		return oldTick(...)
	end

	if firstConstant ~= "UserInputType" then
		return oldTick(...)
	end

	local tickStack = debug.getstack(3)

	---@note: Filter for any other spots that might be using tick() through the stack.
	local tickStackValue = tickStack[6]
	if tickStackValue ~= "W" and tickStackValue ~= "A" and tickStackValue ~= "S" and tickStackValue ~= "D" then
		return oldTick(...)
	end

	---@note: We can indeed set a delay in here. The active thread is InputClient.
	if Configuration.expectToggleValue("AutoSprintDelay") then
		task.wait(Configuration.expectOptionValue("AutoSprintDelayTime"))
	end

	---@note: Set the timestamp set by sprinting to -math.huge so it's always over 0.25s.
	return -math.huge
end

---On name call.
---@return any
local function onNameCall(...)
	local args = { ... }
	local self = args[1]

	local heavenRemote, hellRemote = KeyHandling.getAntiCheatRemotes()
	local method = getnamecallmethod()

	if self == heavenRemote or self == hellRemote then
		return
	end

	if self.Name == "AcidCheck" and Configuration.expectToggleValue("NoAcidWater") then
		return
	end

	if
		typeof(args[2]) == "number"
		and typeof(args[3]) == "boolean"
		and Configuration.expectToggleValue("NoFallDamage")
	then
		return
	end

	if self == runService and method == "IsStudio" then
		return true
	end

	if self.Name == "Gesture" and Configuration.expectToggleValue("EmoteSpoofer") and typeof(args[2]) == "string" then
		return replicateGesture(args[2])
	end

	if
		self.Name == "ServerSprint"
		and (self.ClassName == "UnreliableRemoteEvent" or self.ClassName == "RemoteEvent")
		and Configuration.expectToggleValue("RunAttack")
	then
		return oldNameCall(self, true)
	end

	return oldNameCall(...)
end

---On unreliable fire server.
---@return any
local function onUnreliFireServer(...)
	local args = { ... }
	local self = args[1]

	local heavenRemote, hellRemote = KeyHandling.getAntiCheatRemotes()

	if heavenRemote and self == heavenRemote then
		return
	end

	if hellRemote and self == hellRemote then
		return
	end

	return oldUnreliableFireServer(...)
end

---On fire server.
---@return any
local function onFireServer(...)
	local args = { ... }
	local self = args[1]

	local heavenRemote, hellRemote = KeyHandling.getAntiCheatRemotes()

	if heavenRemote and self == heavenRemote then
		return
	end

	if hellRemote and self == hellRemote then
		return
	end

	return oldFireServer(...)
end

---On get function environment.
---@return any
local function onGetFunctionEnvironment(...)
	---@note: Virtualize this part. Unleaked KH Bypass.
	local functionEnvironment = oldGetFenv(...)

	if not functionEnvironment then
		return nil
	end

	return getrenv()
end

---On index.
---@return any
local function onIndex(...)
	local args = { ... }
	local self = args[1]
	local index = args[2]

	local stripped_index = index:sub(1, 7)

	---@note: Virtualize this part. Unleaked KH Bypass.
	if self == game and (stripped_index == "HttpGet" or stripped_index == "httpGet") then
		return oldIndex(self, "HttpGet\255")
	end

	if self == game and index == "Demiurge" then
		return true
	end

	return oldIndex(...)
end

---Modify ambience color.
---@param value Color3
local function modifyAmbienceColor(value)
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
end

---On new index.
---@return any
local function onNewIndex(...)
	local args = { ... }
	local self = args[1]
	local index = args[2]
	local value = args[3]

	if self == lighting and index == "Ambient" and Configuration.expectToggleValue("ModifyAmbience") then
		return oldNewIndex(self, index, modifyAmbienceColor(value))
	end

	if not checkcaller() and self == workspace.CurrentCamera then
		if index == "FieldOfView" and Configuration.expectToggleValue("ModifyFieldOfView") then
			return
		end

		if index == "CameraSubject" and Monitoring.subject then
			return
		end
	end

	return oldNewIndex(...)
end

---On coroutine wrap.
---@return any
local function onCoroutineWrap(...)
	local args = { ... }

	---@note: Prevent InputClient detection 16.2 from happening so the Disconnect call never happens.
	if debug.getinfo(3).source:match("InputClient") then
		local function onCoroutineCall(arg1)
			if arg1 == "" then
				return ""
			else
				return "LYCORIS_ON_TOP"
			end
		end

		args[1] = onCoroutineCall
	end

	return oldCoroutineWrap(unpack(args))
end

---On task spawn.
---@return any
local function onTaskSpawn(...)
	local args = { ... }

	local func = args[1]
	local consts = debug.getconstants(func)

	if debug.getinfo(3).source:match("InputClient") then
		if #consts == 0 or consts[2] == "Parent" then
			args[1] = function() end
		else
			InputClient.update(consts)
		end
	end

	return oldTaskSpawn(unpack(args))
end

---On pcall.
---@return any
local function onProtectedCall(...)
	local callSuccess, callResult = oldProtectedCall(...)

	---@note: Virtualize this part. Unleaked KH Bypass.
	if lastErrorLevel == 4 then
		callSuccess, callResult = false, "LYCORIS_ON_TOP"
	end

	if lastErrorLevel == 9 then
		callSuccess, callResult = false, lastErrorResult
	end

	if lastErrorLevel == 10 then
		callSuccess, callResult = false, lastErrorResult
	end

	lastErrorLevel = nil
	lastErrorResult = nil

	return callSuccess, callResult
end

---On error.
---@return any
local function onError(...)
	local args = { ... }

	---@note: Virtualize this part. Unleaked KH Bypass.
	lastErrorResult = args[1]
	lastErrorLevel = args[2]

	return oldError(...)
end

---On tostring.
---@return any
local function onToString(...)
	local args = { ... }
	local variable = args[1]

	---@note: Don't virtualize this part. Unleaked KH Bypass.
	if typeof(variable) == "string" and variable:match("EEKE") and checkcaller() then
		Logger.longNotify("[1] Screenshot this message, send it to the developers, and leave the game when possible.")
		return error("LYCORIS_ON_TOP")
	end

	return oldToString(...)
end

---Hooking initialization.
---@note: Careful with checkcaller() on hooks where it is called from us during KeyHandling phase.
function Hooking.init()
	local localPlayer = playersService.LocalPlayer
	local playerScripts = localPlayer.PlayerScripts

	---@todo: Optimize hooks - preferably filter out calls slowing performance.
	oldToString = hookfunction(tostring, onToString)
	oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, onFireServer)
	oldUnreliableFireServer = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, onUnreliFireServer)
	oldGetFenv = hookfunction(getfenv, onGetFunctionEnvironment)
	oldProtectedCall = hookfunction(pcall, onProtectedCall)
	oldError = hookfunction(error, onError)
	oldCoroutineWrap = hookfunction(coroutine.wrap, onCoroutineWrap)
	oldTaskSpawn = hookfunction(task.spawn, onTaskSpawn)
	oldIndex = hookfunction(getrawmetatable(game).__index, onIndex)
	oldNameCall = hookfunction(getrawmetatable(game).__namecall, onNameCall)
	oldNewIndex = hookfunction(getrawmetatable(game).__newindex, onNewIndex)
	oldTick = hookfunction(tick, onTick)

	---@note: This is longer for lower-end devices.
	---@note: This part is crucial because of the Actor and the error detection.
	---@improvement: Add a listener for this script.
	local clientActor = playerScripts and playerScripts:WaitForChild("ClientActor", 25)
	local clientManager = clientActor and clientActor:WaitForChild("ClientManager", 25)

	if clientManager then
		clientManager.Enabled = false
	end

	Logger.warn("Client-side anticheat has been penetrated.")
end

---Hooking detach.
function Hooking.detach()
	local localPlayer = playersService.LocalPlayer

	hookfunction(tostring, oldToString)
	hookfunction(tick, oldTick)
	hookfunction(task.spawn, oldTaskSpawn)
	hookfunction(pcall, oldProtectedCall)
	hookfunction(coroutine.wrap, oldCoroutineWrap)
	hookfunction(error, oldError)
	hookfunction(getfenv, oldGetFenv)
	hookfunction(getrawmetatable(game).__namecall, oldNameCall)
	hookfunction(getrawmetatable(game).__index, oldIndex)
	hookfunction(getrawmetatable(game).__newindex, oldNewIndex)
	hookfunction(Instance.new("RemoteEvent").FireServer, oldFireServer)
	hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, oldUnreliableFireServer)

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
