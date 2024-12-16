---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

---@class Defender
local Defender = {}
Defender.__index = Defender

---Check if table has non-boolean values.
---@param tbl table
---@return boolean
local function hasNonBooleans(tbl)
	for _, value in next, tbl do
		if typeof(value) == "boolean" then
			continue
		end

		return false
	end

	return true
end

---Fetch InputClient data.
---@return table?, table?
local function fetchInputClientData()
	for _, connection in next, getconnections(runService.RenderStepped) do
		local func = connection.Function
		if not func then
			continue
		end

		local consts = debug.getconstants(func)
		if consts[241] ~= ".lastHBCheck" then
			continue
		end

		local upvalues = debug.getupvalues(func)
		local inputs = nil

		---@note: Only table with boolean values is the input table. Find a better way to filter this?
		for _, upvalue in next, upvalues do
			if typeof(upvalue) ~= "table" or getrawmetatable(upvalue) then
				continue
			end

			if not hasNonBooleans(upvalues) then
				continue
			end

			inputs = upvalue
			break
		end

		local env = getfenv(func)
		if not env or getrawmetatable(env) then
			continue
		end

		return env, inputs
	end
end

---Detach defender.
function Defender:detach()
	self.maid:clean()
end

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

	local environment, inputs = fetchInputClientData()
	local sprintFunction = environment.Sprint

	if not environment or not inputs or not sprintFunction then
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

	inputs["f"] = true

	sprintFunction(false)

	while not effectReplicatorModule:HasEffect("Blocking") do
		if effectReplicatorModule:FindEffect("Action") or effectReplicatorModule:FindEffect("Knocked") then
			continue
		end

		blockRemote:FireServer()

		task.wait()
	end

	unblockRemote:FireServer()

	inputs["f"] = false

	sprintFunction(false)
end

---Dodge action.
---@note: Re-created InputClient dodge. We can't access the main proto or input handler.
---@param hrp Instance
---@param humanoid Instance
function Defender:dodge(hrp, humanoid)
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	local environment, inputs = fetchInputClientData()
	local rollFunction = environment.Roll

	if not environment or not inputs or not rollFunction then
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
	return setmetatable({}, { __index = Defender })
end

-- Return Defender module.
return Defender
