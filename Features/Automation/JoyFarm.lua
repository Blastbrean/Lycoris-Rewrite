-- JoyFarm module.
local JoyFarm = {}

---@module Game.AntiAFK
local AntiAFK = require("Game/AntiAFK")

---@module Features.Game.Tweening
local Tweening = require("Features/Game/Tweening")

---@module Utility.FiniteState
local FiniteState = require("Utility/FiniteState")

---@module Utility.FiniteStateMachine
local FiniteStateMachine = require("Utility/FiniteStateMachine")

---@module Utility.Finder
local Finder = require("Utility/Finder")

---@module Utility.Table
local Table = require("Utility/Table")

---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

-- Maid.
local joyFarmMaid = Maid.new()

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Hooks.
local oldGetMouseInvoke = nil

-- Cached target.
local cachedTarget = nil

-- Tweening offset.
local offsetCFrame = CFrame.new(0.0, 30.0, 0.0)

-- Attack valid targets.
local function attackValidTargets()
	local targets = Finder.geir(300, true)
	if not targets then
		return true
	end

	local activeTarget = cachedTarget or targets[1]
	if not activeTarget then
		return true
	end

	if not activeTarget.Parent then
		return false
	end

	local targetHrp = activeTarget:FindFirstChild("HumanoidRootPart")
	if not targetHrp then
		return false
	end

	local targetHumanoid = activeTarget:FindFirstChild("Humanoid")
	if not targetHumanoid then
		return false
	end

	if targetHumanoid.Health <= 0 then
		return false
	end

	cachedTarget = activeTarget

	-- Tween to target.
	local targetPosition = (targetHrp.CFrame * offsetCFrame).Position
	local goalCFrame = CFrame.lookAt(targetPosition, targetHrp.Position)

	Tweening.stop("JoyFarm_TweenAboveShrine")
	Tweening.goal("JoyFarm_TweenToTarget", goalCFrame, false)

	-- Spoof OnClientEvent too.
	local requests = replicatedStorage:WaitForChild("Requests")
	local getMouse = requests:WaitForChild("GetMouse")
	local inputData = InputClient.getInputData()
	if not inputData then
		return warn("Failed to get InputData for JoyFarm mouse spoofing.")
	end

	if not oldGetMouseInvoke then
		oldGetMouseInvoke = getcallbackvalue(getMouse, "OnClientInvoke")
	end

	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return warn("Failed to get EffectReplicator module for JoyFarm mouse spoofing.")
	end

	---@note: Add some prediction to prevent mobs from running in a straight line.
	local at = targetHrp.CFrame + (targetHrp.AssemblyLinearVelocity * (0.1 + Defender.rtt()))
	local pos = workspace.CurrentCamera:WorldToViewportPoint(at.Position)
	local ray = workspace.CurrentCamera:ViewportPointToRay(pos.X, pos.Y)

	-- Override OnClientInvoke with new data.
	getMouse.OnClientInvoke = function()
		return {
			["Hit"] = at,
			["Target"] = targetHrp,
			["UnitRay"] = ray,
			["X"] = pos.X,
			["Y"] = pos.Y,
		}
	end

	-- Start attacking the target.
	InputClient.left(targetHrp.CFrame, true)

	-- Return true indicating we attacked a valid target.
	return true
end

-- States.
local jfIdleState = FiniteState.new("Idle", function(_, machine)
	-- Activate shrine.
	local shrine = Finder.wshrine()
	local interactPrompt = shrine:WaitForChild("InteractPrompt")

	Tweening.goal("JoyFarm_TweenToShrine", shrine:GetPivot(), false)

	while task.wait() do
		-- Fire prompt.
		fireproximityprompt(interactPrompt)

		-- Check if "Wave 1" was detected.
		local prompts = Finder.sprompts()
		local detected = Table.find(prompts, function(value, _)
			return value:lower():match("wave 1")
		end)

		-- Break out of loop, if so.
		if detected then
			break
		end
	end

	-- Break out of idle state.
	return machine:transition("Attack")
end, function()
	-- Stop tweens.
	Tweening.stop("JoyFarm_TweenToShrine")
end)

local jfAttackState = FiniteState.new("Attack", function(_, machine)
	-- Attack loop.
	while task.wait() do
		-- Check if "Final Wave Cleared" was detected.
		local prompts = Finder.sprompts()
		local detected = Table.find(prompts, function(value, _)
			return value:lower():match("final wave cleared")
		end)

		-- Transition us to idle state, if so.
		if detected then
			return machine:transition("Idle")
		end

		-- Tween us above the shrine. If we're attempting to attack a valid target, this will be overriden!
		local shrine = Finder.wshrine()
		Tweening.goal("JoyFarm_TweenAboveShrine", shrine:GetPivot() * CFrame.new(0.0, 30.0, 0.0), false)
		Tweening.stop("JoyFarm_TweenToTarget")

		-- Attack valid targets.
		if attackValidTargets() then
			continue
		end

		-- We must clear the cached target if we failed to attack valid targets!
		cachedTarget = nil
	end
end, function()
	-- Stop tweens.
	Tweening.stop("JoyFarm_TweenAboveShrine")
	Tweening.stop("JoyFarm_TweenToTarget")

	-- Reset "OnClientInvoke" spoof.
	---@todo: Make this more perfect later and add a silent aim.

	local requests = replicatedStorage:WaitForChild("Requests")
	local getMouse = requests:WaitForChild("GetMouse")

	if oldGetMouseInvoke then
		getMouse.OnClientInvoke = oldGetMouseInvoke
	end
end)

-- State machine.
local jfStateMachine = FiniteStateMachine.new({ jfIdleState, jfAttackState }, "Idle")

---Start JoyFarm module.
function JoyFarm.start()
	AntiAFK.start("JoyFarm")
	joyFarmMaid:add(TaskSpawner.spawn("JoyFarm_StateMachineStart", jfStateMachine.start, jfStateMachine))
end

---Stop JoyFarm module.
function JoyFarm.stop()
	AntiAFK.stop("JoyFarm")
	jfStateMachine:stop()
	joyFarmMaid:clean()
end

return JoyFarm
