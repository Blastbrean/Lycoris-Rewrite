-- Hooking related stuff is handled here.
local Hooking = {}
Hooking.__index = Hooking

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Services.
local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Old hooked functions.
local oldDestroy = nil
local oldFireServer = nil
local oldUnreliableFireServer = nil
local oldNameCall = nil
local oldGetFenv = nil
local oldIndex = nil
local oldNewIndex = nil

---Replicate gesture.
---@param gestureName string
local function replicateGesture(gestureName)
	local assets = replicatedStorage:FindFirstChild("Assets")
	if not assets then
		return
	end

	local anims = assets:FindFirstChild("Anims")
	if not anims then
		return
	end

	local gestures = anims:FindFirstChild("Gestures")
	if not gestures then
		return
	end

	local gesture = gestures:FindFirstChild(gestureName)
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
	if not effectReplicator then
		return
	end

	local effectHandler = require(effectReplicator)
	if not effectHandler.FindEffect or not effectHandler.CreateEffect or not effectHandler:FindEffect("Gesturing") then
		return
	end

	local actionEffect = effectHandler:CreateEffect("Action")
	local gesturingEffect = effectHandler:CreateEffect("Gesturing")
	local mobileActionEffect = effectHandler:CreateEffect("MobileAction")

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

---On name call.
---@return any
local function onNameCall(...)
	local args = { ... }
	local self = args[1]

	local method = getnamecallmethod()
	local heavenRemote, hellRemote = KeyHandling.getAntiCheatRemotes()

	if not checkcaller() then
		if self == runService and method == "IsStudio" then
			return true
		end

		if self == heavenRemote or self == hellRemote then
			return
		end

		if self.Name == "AcidCheck" and Toggles.NoAcid.Value then
			return
		end

		if typeof(args[2]) == "number" and typeof(args[3]) == "boolean" and Toggles.NoFallDamage.Value then
			return
		end

		if self.Name == "Gesture" and Toggles.UnlockEmotes.Value and typeof(args[2]) == "string" then
			replicateGesture(args[2])
		end

		if
			self.Name == "ServerSprint"
			and (self.ClassName == "UnreliableRemoteEvent" or self.ClassName == "RemoteEvent")
			and Toggles.RunAttack.Value
		then
			return oldNameCall(self, true)
		end
	else
		local leftClickRemote = KeyHandling.getRemote("LeftClick")
		if not leftClickRemote then
			return oldNameCall(...)
		end

		if self ~= leftClickRemote then
			return oldNameCall(...)
		end

		---@todo: Auto-parry busy check. We'll do this way later.
		if Toggles.BlockInput.Value then
			return
		end
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

---On destroy.
---@return any
local function onDestroy(...)
	local localPlayer = playersService.LocalPlayer
	if not localPlayer then
		return oldDestroy(...)
	end

	local character = localPlayer.Character
	if not character then
		return oldDestroy(...)
	end

	local characterHandler = character:FindFirstChild("CharacterHandler")
	if not characterHandler then
		return oldDestroy(...)
	end

	local args = { ... }
	local self = args[1]

	if self ~= characterHandler then
		return oldDestroy(...)
	end
end

---On get function environment.
---@return any
local function onGetFunctionEnvironment(...)
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

	if self == game and (index == "HttpGet" or index == "httpGet") then
		return oldIndex(self, index)
	end

	if self == game and index == "Demigure" then
		return true
	end

	return oldIndex(...)
end

---On new index.
---@return any
local function onNewIndex(...)
	local args = { ... }
	local self = args[1]
	local index = args[2]

	if self.Name == "CharacterHandler" and (index == "Parent" or index == "parent") then
		return
	end

	return oldNewIndex(...)
end

---Hooking initialization.
function Hooking.init()
	local localPlayer = playersService.LocalPlayer

	oldDestroy = hookfunction(game.Destroy, newcclosure(onDestroy))
	oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(onFireServer))
	oldUnreliableFireServer =
		hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, newcclosure(onUnreliFireServer))
	oldGetFenv = hookfunction(getfenv, newcclosure(onGetFunctionEnvironment))
	oldNameCall = hookmetamethod(game, "__namecall", newcclosure(onNameCall))
	oldIndex = hookmetamethod(game, "__index", newcclosure(onIndex))
	oldNewIndex = hookmetamethod(game, "__newindex", newcclosure(onNewIndex))

	local playerScripts = localPlayer:WaitForChild("PlayerScripts", 5)
	local clientActor = playerScripts and playerScripts:WaitForChild("ClientActor", 5)
	local clientManager = clientActor and clientActor:WaitForChild("ClientManager", 5)

	if clientManager then
		clientManager.Enabled = false
	end

	Logger.warn("Client-side anticheat has been penetrated.")
end

---Hooking detach.
function Hooking.detach()
	local localPlayer = playersService.LocalPlayer

	hookfunction(game.Destroy, oldDestroy)
	hookfunction(Instance.new("RemoteEvent").FireServer, oldFireServer)
	hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, oldUnreliableFireServer)
	hookfunction(getfenv, oldGetFenv)
	hookfunction(game, "__namecall", oldNameCall)
	hookfunction(game, "__index", oldIndex)
	hookfunction(game, "__newindex", oldNewIndex)

	local playerScripts = localPlayer:WaitForChild("PlayerScripts", 5)
	local clientActor = playerScripts and playerScripts:WaitForChild("ClientActor", 5)
	local clientManager = clientActor and clientActor:WaitForChild("ClientManager", 5)

	if clientManager then
		clientManager.Enabled = false
	end

	Logger.warn("Pulled out of client-side anticheat.")
end

-- Return Hooking module.
return Hooking
