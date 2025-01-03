---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

---@class Defender
local Defender = {}
Defender.__index = Defender

---Detach function. Override me.
function Defender:detach() end

---Parry action.
---@note: Re-created InputClient parry. We can't access the main proto or the input handler.
function Defender:parry()
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	local blockRemote = KeyHandling.getRemote("Block")
	local unblockRemote = KeyHandling.getRemote("Unblock")

	if not blockRemote or not unblockRemote then
		return
	end

	local sprintFunction = InputClient.sprintFunctionCache
	local inputData = InputClient.getInputData()

	if not sprintFunction or not inputData then
		return
	end

	local bufferEffect = effectReplicatorModule:FindEffect("M1Buffering")
	if bufferEffect then
		bufferEffect:Remove()
	end

	if effectReplicatorModule:HasEffect("CastingSpell") then
		return
	end

	blockRemote:FireServer()

	inputData["f"] = true

	sprintFunction(false)

	while not effectReplicatorModule:HasEffect("Blocking") do
		if effectReplicatorModule:FindEffect("Action") or effectReplicatorModule:FindEffect("Knocked") then
			continue
		end

		blockRemote:FireServer()

		task.wait()
	end

	unblockRemote:FireServer()

	inputData["f"] = false

	sprintFunction(false)
end

---Dodge action.
---@note: Re-created InputClient dodge. We can't access the main proto or input handler.
---@param hrp Part
---@param humanoid Humanoid
function Defender:dodge(hrp, humanoid)
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	local rollFunction = InputClient.rollFunctionCache
	if not rollFunction then
		return
	end

	local lastRollMoveDirection = debug.getupvalue(rollFunction, 14)
	if not lastRollMoveDirection or typeof(lastRollMoveDirection) ~= "Vector3" then
		return
	end

	effectReplicatorModule:CreateEffect("DodgeInputted"):Debris(0.35)

	local bufferEffect = effectReplicatorModule:FindEffect("M1Buffering")
	if bufferEffect then
		bufferEffect:Remove()
	end

	local pivotVelocity = effectReplicatorModule:FindEffect("PivotVelocity")
	local usePivotVelocityRoll = false

	local lookVector = hrp.CFrame.LookVector
	local moveDirection = humanoid.MoveDirection

	if moveDirection.Magnitude < 0.1 then
		moveDirection = -lookVector
	end

	if pivotVelocity and lastRollMoveDirection:Dot(moveDirection) < 0 then
		if effectReplicatorModule:FindEffect("NoRoll") then
			effectReplicatorModule:FindEffect("NoRoll"):Remove()
		end

		if effectReplicatorModule:FindEffect("PivotStepRESET") then
			effectReplicatorModule:FindEffect("PivotStepRESET"):Remove()
		end

		pivotVelocity.Value:Destroy()
		pivotVelocity:Remove()
		usePivotVelocityRoll = true
	end

	rollFunction(usePivotVelocityRoll and true or nil)
end

---Create new Defender object.
function Defender.new()
	return setmetatable({}, Defender)
end

-- Return Defender module.
return Defender
