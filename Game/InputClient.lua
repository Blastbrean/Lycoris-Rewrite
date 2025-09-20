-- InputClient module. Deals with everything related to that script. Re-created functions and all.
---@note: Never call the roll function from the cache. We only need this to get the last roll move direction.
local InputClient = {
	sprintFunctionCache = nil,
	rollFunctionCache = nil,
}

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Services.
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local debris = game:GetService("Debris")

-- Cache.
local inputDataCache = nil
local lastInputDataCache = os.clock()

---Re-created has talent.
---@param character Model
---@param talentName string
---@return boolean
local function hasTalent(character, talentName)
	if not talentName:match("Talent:") then
		talentName = "Talent:" .. talentName
	end

	local foundPlayer = players:GetPlayerFromCharacter(character)
	if not foundPlayer then
		return foundPlayer.Backpack:FindFirstChild(talentName) and true or false
	end

	return character:FindFirstChild(talentName) and true or false
end

---Check if we're in air.
---@param humanoid Model
---@param effectReplicatorModule table
---@return boolean
local function inAir(humanoid, effectReplicatorModule)
	if effectReplicatorModule:HasEffect("Swimming") then
		return false
	end

	local humanoidState = humanoid:GetState()

	if humanoidState == Enum.HumanoidStateType.Freefall or humanoidState == Enum.HumanoidStateType.Jumping then
		return true
	end

	return effectReplicatorModule:HasEffect("AirBorne") ~= nil
end

---Manual table find. Stupid Wave hotfix. Way slower to use this.
---@param tbl table
---@param value any
---@return boolean
local manualTableFind = LPH_NO_VIRTUALIZE(function(tbl, value)
	for _, val in next, tbl do
		if val ~= value then
			continue
		end

		return true
	end
end)

---Check if table has non-boolean values.
---@param tbl table
---@return boolean
local hasNonBooleans = LPH_NO_VIRTUALIZE(function(tbl)
	for _, value in next, tbl do
		if typeof(value) == "boolean" then
			continue
		end

		return false
	end

	return true
end)

---Get amount of entries in table.
---@param tbl table
local getTableLength = LPH_NO_VIRTUALIZE(function(tbl)
	local count = 0

	for _ in next, tbl do
		count = count + 1
	end

	return count
end)

---Validate keys.
---@param tbl table
local validateKeys = LPH_NO_VIRTUALIZE(function(tbl)
	local allowedKeys = {
		["Left"] = true,
		["Right"] = true,
		["W"] = true,
		["A"] = true,
		["S"] = true,
		["D"] = true,
		["Thumbstick1"] = true,
		["C"] = true,
		["f"] = true,
		["H"] = true,
		["Space"] = true,
		["ctrl"] = true,
	}

	for key, _ in next, tbl do
		if allowedKeys[key] then
			continue
		end

		return false
	end

	return true
end)

---Fetch last roll move direction.
---@return Vector3?
InputClient.getLastRollMoveDirection = LPH_NO_VIRTUALIZE(function()
	local rollFunction = InputClient.rollFunctionCache
	if not rollFunction then
		return nil
	end

	local lastRollMoveDirection = nil

	for _, upvalue in next, debug.getupvalues(rollFunction) do
		if typeof(upvalue) ~= "Vector3" then
			continue
		end

		lastRollMoveDirection = upvalue
		break
	end

	if not lastRollMoveDirection then
		lastRollMoveDirection = Vector3.zero
	end

	if lastRollMoveDirection and typeof(lastRollMoveDirection) ~= "Vector3" then
		return nil
	end

	return lastRollMoveDirection
end)

---Fetch input data.
---@return table?
InputClient.getInputData = LPH_NO_VIRTUALIZE(function()
	-- Get from cache if we can, this is particularly expensive.
	if inputDataCache and (os.clock() - lastInputDataCache) <= 2.0 then
		return inputDataCache
	end

	-- Store input data.
	local inputData = nil

	-- Get the input data from RenderStepped.
	for _, connection in next, getconnections(runService.RenderStepped) do
		local func = connection.Function
		if not func then
			continue
		end

		if iscclosure(func) then
			continue
		end

		local consts = debug.getconstants(func)
		if not table.find(consts, ".lastHBCheck") and not manualTableFind(consts, ".lastHBCheck") then
			continue
		end

		local upvalues = debug.getupvalues(func)

		---@note: Only table with boolean values is the input table. Find a better way to filter this?
		for _, upvalue in next, upvalues do
			if typeof(upvalue) ~= "table" or getrawmetatable(upvalue) then
				continue
			end

			if not hasNonBooleans(upvalue) then
				continue
			end

			if getTableLength(upvalue) >= 1 and not validateKeys(upvalue) then
				continue
			end

			inputData = upvalue
			break
		end
	end

	-- Add into cache.
	-- We want to attempt to re-cache again if it's missing.
	inputDataCache = inputData
	lastInputDataCache = inputData and os.clock() or lastInputDataCache

	-- Return input data.
	return inputData
end)

---End block function.
---@param noUnsprint boolean
InputClient.bend = LPH_NO_VIRTUALIZE(function(noUnsprint)
	local unblockRemote = KeyHandling.getRemote("Unblock")
	if not unblockRemote then
		return Logger.warn("Cannot end block without unblock remote.")
	end

	local sprintFunction = InputClient.sprintFunctionCache
	local inputData = InputClient.getInputData()

	if not sprintFunction or not inputData then
		return Logger.warn("Cannot end block without sprint function or input data.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return Logger.warn("Cannot end block without effect replicator.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return Logger.warn("Cannot end block without effect replicator module.")
	end

	while effectReplicatorModule:HasEffect("Blocking") do
		-- Unblock.
		unblockRemote:FireServer()

		-- Wait.
		task.wait()
	end

	inputData["f"] = false

	---@note: This can be undesired behavior if we were simply trying to unblock as a backup method.
	if noUnsprint then
		return
	end

	sprintFunction(false)
end)

---Start block function.
InputClient.bstart = LPH_NO_VIRTUALIZE(function()
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return Logger.warn("Cannot start block without effect replicator.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return Logger.warn("Cannot start block without effect replicator module.")
	end

	local blockRemote = KeyHandling.getRemote("Block")
	if not blockRemote then
		return Logger.warn("Cannot start block without block remote.")
	end

	local sprintFunction = InputClient.sprintFunctionCache
	local inputData = InputClient.getInputData()
	if not sprintFunction or not inputData then
		return Logger.warn("Cannot start block without sprint function or input data.")
	end

	local bufferEffect = effectReplicatorModule:FindEffect("M1Buffering")
	if bufferEffect then
		bufferEffect:Remove()
	end

	if effectReplicatorModule:HasEffect("CastingSpell") then
		return Logger.warn("Cannot start block while casting spell.")
	end

	blockRemote:FireServer()

	inputData["f"] = true

	sprintFunction(false)

	while not effectReplicatorModule:HasEffect("Blocking") do
		task.wait()

		if effectReplicatorModule:FindEffect("Action") or effectReplicatorModule:FindEffect("Knocked") then
			continue
		end

		blockRemote:FireServer()
	end
end)

---Left click function.
InputClient.left = LPH_NO_VIRTUALIZE(function()
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	if effectReplicatorModule:HasEffect("InDialogue") then
		return
	end

	local inputData = InputClient.getInputData()
	if not inputData then
		return Logger.warn("Cannot left click without input data.")
	end

	local leftClickRemote = KeyHandling.getRemote("LeftClick")
	if not leftClickRemote then
		return
	end

	if
		effectReplicatorModule:HasEffect("LightAttack")
		or effectReplicatorModule:HasEffect("CriticalAttack")
		or effectReplicatorModule:HasEffect("Followup")
		or effectReplicatorModule:HasEffect("Parried")
	then
		return
	end

	leftClickRemote:FireServer(inAir(humanoid, effectReplicatorModule), players.LocalPlayer:GetMouse().Hit, inputData)

	---@note: Missing M1-Hold and Input Buffering functionality but I don't think the caller cares about it.
end)

---Deflect. This is called this way because it can either give parry or block frames depending on whether or not parry is on cooldown.
InputClient.deflect = LPH_NO_VIRTUALIZE(function()
	InputClient.bstart()
	InputClient.bend()
end)

---Dodge function.
---@param skipRollCancel boolean
InputClient.dodge = LPH_NO_VIRTUALIZE(function(skipRollCancel)
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return Logger.warn("Cannot dodge without effect replicator.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return Logger.warn("Cannot dodge without effect replicator module.")
	end

	local lastRollMoveDirection = InputClient.getLastRollMoveDirection()
	if not lastRollMoveDirection then
		return Logger.warn("Cannot dodge without last roll move direction.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return Logger.warn("Cannot dodge without character.")
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return Logger.warn("Cannot dodge without root.")
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return Logger.warn("Cannot dodge without humanoid.")
	end

	effectReplicatorModule:CreateEffect("DodgeInputted"):Debris(0.35)

	local bufferEffect = effectReplicatorModule:FindEffect("M1Buffering")
	if bufferEffect then
		bufferEffect:Remove()
	end

	local pivotVelocity = effectReplicatorModule:FindEffect("PivotVelocity")
	local usePivotVelocityRoll = false

	local lookVector = root.CFrame.LookVector
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

	local rollCancelDelay = Configuration.expectOptionValue("RollCancelDelay") or 0.0

	if skipRollCancel or not Configuration.expectToggleValue("RollCancel") then
		rollCancelDelay = nil
	end

	---@note: Run this in a seperate task because the roll movement must still continue even when detached and destroyed. Else, it will behave wrong.
	--- This is OK. Before any yields occur, we fetch the remotes beforehand. Also, the clean up is done at the very end of the function.
	task.spawn(InputClient.roll, usePivotVelocityRoll and true or nil, rollCancelDelay)
end)

---Re-created feint function.
InputClient.feint = LPH_NO_VIRTUALIZE(function()
	local rightClickRemote = KeyHandling.getRemote("RightClick")
	if not rightClickRemote then
		return Logger.warn("Cannot feint without right click remote.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return Logger.warn("Cannot feint without effect replicator.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return Logger.warn("Cannot feint without effect replicator module.")
	end

	local inputDataTable = InputClient.getInputData()
	if not inputDataTable then
		return Logger.warn("Cannot feint without input data.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return Logger.warn("Cannot feint without character.")
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return Logger.warn("Cannot feint without root.")
	end

	inputDataTable.Right = true

	if effectReplicatorModule:HasEffect("ClientDodge") then
		effectReplicatorModule:CreateEffect("ClientFeint"):Debris(0.4)
	end

	if hrp:FindFirstChild("ClientRemove") then
		hrp.ClientRemove:Destroy()
	end

	if effectReplicatorModule:HasEffect("Feint") then
		return
	end

	rightClickRemote:FireServer(inputDataTable)
end)

---Re-created roll function for safety.
---@param pivotStep boolean
---@param rollCancelTime number?
InputClient.roll = LPH_NO_VIRTUALIZE(function(pivotStep, rollCancelTime)
	local unblockRemote = KeyHandling.getRemote("Unblock")
	local dodgeRemote = KeyHandling.getRemote("Dodge")
	local stopDodge = KeyHandling.getRemote("StopDodge")

	if not unblockRemote or not dodgeRemote or not stopDodge then
		return
	end

	local inputDataTable = InputClient.getInputData()
	if not inputDataTable then
		return
	end

	local character = players.LocalPlayer.Character
	local characterHandler = character and character:FindFirstChild("CharacterHandler")
	local inputClient = characterHandler and characterHandler:FindFirstChild("InputClient")
	if not inputClient then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	local assets = replicatedStorage:FindFirstChild("Assets")
	local anims = assets and assets:FindFirstChild("Anims")
	local movement = anims and anims:FindFirstChild("Movement")

	local waterDash = movement and movement:FindFirstChild("WaterDash")
	local roll = movement and movement:FindFirstChild("Roll")

	if not waterDash and not roll then
		return
	end

	local forwardRoll = roll:FindFirstChild("ForwardRoll")
	local backRoll = roll:FindFirstChild("BackRoll")
	local rightRoll = roll:FindFirstChild("RightRoll")
	local leftRoll = roll:FindFirstChild("LeftRoll")

	local cancelLeft = roll:FindFirstChild("CancelLeft")
	local cancelRight = roll:FindFirstChild("CancelRight")

	if not forwardRoll or not backRoll or not rightRoll or not leftRoll or not cancelLeft or not cancelRight then
		return
	end

	local forwardWaterDash = waterDash:FindFirstChild("ForwardWaterDash")
	local backWaterDash = waterDash:FindFirstChild("BackWaterDash")
	local rightWaterDash = waterDash:FindFirstChild("RightWaterDash")
	local leftWaterDash = waterDash:FindFirstChild("LeftWaterDash")

	if not forwardWaterDash or not backWaterDash or not rightWaterDash or not leftWaterDash then
		return
	end

	local rollToWaterDashMap = {
		[forwardRoll] = forwardWaterDash,
		[backRoll] = backWaterDash,
		[rightRoll] = rightWaterDash,
		[leftRoll] = leftWaterDash,
	}

	local freefallAnimation = inputClient:FindFirstChild("FreefallAnim")
	if not freefallAnimation then
		return
	end

	local landingAnim = inputClient:FindFirstChild("LandingAnim")
	if not landingAnim then
		return
	end

	local pressureSlideAnimation = inputClient:FindFirstChild("PressureSlide")
	if not pressureSlideAnimation then
		return
	end

	local airDashAnimation = inputClient:FindFirstChild("AirDash")
	if not airDashAnimation then
		return
	end

	local requests = replicatedStorage:FindFirstChild("Requests")
	local clientEffectDirect = requests and requests:FindFirstChild("ClientEffectDirect")

	if not clientEffectDirect then
		return
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	local replicatedDebris = replicatedStorage:FindFirstChild("Debris")
	if not replicatedDebris then
		return
	end

	local clientSwimEffect = effectReplicatorModule:FindEffect("ClientSwim")

	---@note: Inlined movement check.
	if
		effectReplicatorModule:HasEffect("Action")
		or effectReplicatorModule:HasEffect("NoParkour")
		or effectReplicatorModule:HasEffect("Knocked")
		or effectReplicatorModule:HasEffect("Unconscious")
		or effectReplicatorModule:HasEffect("Pinned")
		or effectReplicatorModule:HasEffect("Carried")
	then
		return
	end

	if effectReplicatorModule:HasEffect("CarryObject") and not clientSwimEffect then
		return
	end

	if
		effectReplicatorModule:HasEffect("UsingSpell")
		or effectReplicatorModule:HasEffect("CastingSpell")
		or (effectReplicatorModule:HasEffect("NoAttack") and not effectReplicatorModule:HasEffect("CanRoll"))
		or effectReplicatorModule:HasEffect("Dodged")
		or effectReplicatorModule:HasEffect("Dodge")
		or effectReplicatorModule:HasEffect("NoRoll")
		or effectReplicatorModule:HasEffect("PreventRoll")
		or effectReplicatorModule:HasEffect("Stun")
		or effectReplicatorModule:HasEffect("Action")
		or effectReplicatorModule:HasEffect("MobileAction")
		or effectReplicatorModule:HasEffect("PreventAction")
		or effectReplicatorModule:HasEffect("Carried")
	then
		return
	end

	local pressureForwardEffect = effectReplicatorModule:FindEffect("PressureForward")
	if effectReplicatorModule:HasEffect("LightAttack") and not pressureForwardEffect then
		return
	end

	if effectReplicatorModule:HasEffect("Blocking") then
		unblockRemote:FireServer()
	end

	if effectReplicatorModule:HasEffect("ClientSlide") then
		return
	end

	if hrp:FindFirstChild("GravBV") then
		return
	end

	if hrp:FindFirstChild("Mover") then
		hrp.Mover:Destroy()
	end

	local loadedFreefallAnimation = humanoid:LoadAnimation(freefallAnimation)
	loadedFreefallAnimation:Stop(0.3)

	local loadedCancelLeftAnimation = humanoid:LoadAnimation(cancelLeft)
	local loadedCancelRightAnimation = humanoid:LoadAnimation(cancelRight)

	local rollType = clientSwimEffect and "waterdash" or "roll"
	local isPressureForwarding = false

	if
		effectReplicatorModule:HasEffect("PressureForward")
		or effectReplicatorModule:HasEffect("GaleDash")
		or (
			effectReplicatorModule:HasEffect("PhantomStep")
			and not effectReplicatorModule:HasEffect("PhantomStepDashCD")
		)
	then
		isPressureForwarding = true
		effectReplicatorModule:CreateEffect("PressureForwarding"):Debris(0.5)
	end

	local healthPercentage = humanoid.Health / humanoid.MaxHealth

	if players.LocalPlayer.Backpack:FindFirstChild("Talent:Endurance Runner") then
		healthPercentage = 0.25 + healthPercentage * 0.75
	end

	local rollMoveDirectionMulti = 60 + character.PassiveAgility.Value * 0.5 * healthPercentage
	local rushOfAncientsBoost = false

	if hasTalent(character, "Lowstride") and effectReplicatorModule:FindEffect("ClientCrouch") then
		rollMoveDirectionMulti = rollMoveDirectionMulti + 10
	end

	local sprintSpeedEffect = effectReplicatorModule:FindEffect("SprintSpeed")

	if
		hasTalent(character, "Rush of Ancients")
		and sprintSpeedEffect
		and sprintSpeedEffect.Disabled == false
		and sprintSpeedEffect.Value >= 10
	then
		rushOfAncientsBoost = true
		rollMoveDirectionMulti = rollMoveDirectionMulti + (20 + 15 * healthPercentage)
	end

	local aerialAssaultBoolean = false
	local airDashBoolean = false

	if
		inAir(humanoid, effectReplicatorModule)
		and not inputDataTable["S"]
		and not effectReplicatorModule:HasEffect("ClientSwim")
		and (game.PlaceId == 5614144350 or players.LocalPlayer.Backpack:FindFirstChild("Talent:Aerial Assault") or game.PlaceId == 13891478131)
		and not effectReplicatorModule:HasEffect("GravityField")
	then
		aerialAssaultBoolean = true
		rollMoveDirectionMulti = 35
		airDashBoolean = true
	end

	if effectReplicatorModule:HasEffect("SpinAttack") then
		dodgeRemote:FireServer("SpinAttack", rollType, true)
	else
		dodgeRemote:FireServer("Dodge", rollType, nil, nil, rushOfAncientsBoost, pivotStep)
	end

	effectReplicatorModule:CreateEffect("ClientDodge"):Debris(0.3)

	local noRollEffect = effectReplicatorModule:CreateEffect("NoRoll")
	noRollEffect:Debris(2.3)

	local rollTimeSeconds = 0.2

	if
		(effectReplicatorModule:HasEffect("GodSpeed") or effectReplicatorModule:HasEffect("Overcharged"))
		and not effectReplicatorModule:HasEffect("ClientSwim")
	then
		rollTimeSeconds = 0.5
	end

	local lookVector = hrp.CFrame.LookVector
	local moveDirection = humanoid.MoveDirection
	local rollAnimation = nil

	if moveDirection.Magnitude < 0.1 then
		moveDirection = -lookVector
	end

	local rollAngle = math.deg((math.acos((math.clamp(moveDirection:Dot(lookVector), -1, 1)))))
	local rollSideAngle =
		math.deg((math.acos((math.clamp(moveDirection:Dot((Vector3.new(-lookVector.z, 0, lookVector.x))), -1, 1)))))

	if rollAngle <= 45 then
		rollAnimation = forwardRoll
	elseif rollAngle > 45 and rollAngle < 135 then
		if rollSideAngle <= 45 then
			rollAnimation = rightRoll
		elseif rollSideAngle > 135 then
			rollAnimation = leftRoll
		else
			rollAnimation = backRoll
		end
	else
		rollAnimation = backRoll
	end

	if clientSwimEffect then
		rollMoveDirectionMulti = 30 + 10 * healthPercentage
		aerialAssaultBoolean = true
		rollAnimation = rollToWaterDashMap[rollAnimation] or rollAnimation
	end

	if rollAnimation == backRoll then
		rollMoveDirectionMulti = rollMoveDirectionMulti - 10
	end

	if isPressureForwarding then
		rollAnimation = pressureSlideAnimation
		rollTimeSeconds = 0.5
	end

	local arcSuitEffect = effectReplicatorModule:HasEffect("ArcSuit") and hasTalent(character, "Arc Module: Dash")
	if arcSuitEffect then
		rollMoveDirectionMulti = rollMoveDirectionMulti - 5
		rollAnimation = pressureSlideAnimation
		rollTimeSeconds = 0.3
		clientEffectDirect:Fire("WindTrails", {
			char = character,
			Duration = 0.3,
		})
	end

	if effectReplicatorModule:HasEffect("ReducedRoll") and not arcSuitEffect then
		rollMoveDirectionMulti = rollMoveDirectionMulti - 10
	end

	if effectReplicatorModule:HasEffect("GravityField") then
		aerialAssaultBoolean = true
		rollMoveDirectionMulti = rollMoveDirectionMulti * 0.2
	end

	if airDashBoolean then
		rollAnimation = airDashAnimation
	end

	local loadedRollAnimation = humanoid:LoadAnimation(rollAnimation)
	if isPressureForwarding then
		loadedRollAnimation.Priority = Enum.AnimationPriority.Movement
	end

	if not effectReplicatorModule:HasEffect("GodSpeed") and not effectReplicatorModule:HasEffect("ClientSwim") then
		if isPressureForwarding then
			loadedRollAnimation:Play(0.1, 0.5, 1)
		else
			loadedRollAnimation:Play(0.1)
		end
	end

	if effectReplicatorModule:HasEffect("SlowTime") then
		rollTimeSeconds = 1
		rollMoveDirectionMulti = 10
		loadedRollAnimation:Play()
	end

	if effectReplicatorModule:HasEffect("SlowDodge") then
		rollTimeSeconds = 0.5
		rollMoveDirectionMulti = 15
		loadedRollAnimation:Play()
	end

	---@todo: guyz this doesn't work .Sound
	local robloxGlobalEnvironment = getrenv()._G

	local arcSuitDash = effectReplicatorModule:HasEffect("ArcSuit") and hasTalent(character, "Arc Module: Dash")
	local dashItEffect = effectReplicatorModule:CreateEffect("DashIt")

	if rollType == "waterdash" then
		robloxGlobalEnvironment.Sound(replicatedStorage.Sounds.WaterDash, hrp)
	elseif airDashBoolean then
		if effectReplicatorModule:HasEffect("Wings") then
			robloxGlobalEnvironment.Sound(replicatedStorage.Sounds.Flap2, hrp)
		else
			robloxGlobalEnvironment.Sound(replicatedStorage.Sounds.AirDodge, hrp)
		end
	elseif not arcSuitDash then
		robloxGlobalEnvironment.Sound(replicatedStorage.Sounds.Roll, hrp)
	end

	local rollBodyVelocity = Instance.new("BodyVelocity")
	rollBodyVelocity:AddTag("AllowedBM")
	rollBodyVelocity.MaxForce = Vector3.new(50000, 0, 50000, 0)

	---@note: Exempt crouch boolean flag.

	if pivotStep then
		rollMoveDirectionMulti = rollMoveDirectionMulti + 10
	end

	rollBodyVelocity.Velocity = moveDirection * rollMoveDirectionMulti

	local newMoveDirectionMulti = 50 + healthPercentage * 20
	local airDashVertMulti = newMoveDirectionMulti
	local currentDuration = 1.3

	local info = replicatedStorage:FindFirstChild("Info")
	local realmInfo = info and info:FindFirstChild("RealmInfo")

	if realmInfo and airDashBoolean then
		rollBodyVelocity.MaxForce = Vector3.new(50000, 50000, 50000, 0)
		moveDirection = workspace.CurrentCamera.CFrame.LookVector

		if effectReplicatorModule:HasEffect("Wings") then
			local increaseMobilityFlag = effectReplicatorModule:HasEffect("HorMobilityChain")
				or game.ReplicatedStorage:FindFirstChild("DUNGEON")

			newMoveDirectionMulti = increaseMobilityFlag and 50 + healthPercentage * 30 or 55 + healthPercentage * 35

			airDashVertMulti = 50 + healthPercentage * 30
		end

		local realmInfoModule = require(realmInfo)

		if realmInfoModule.CurrentWorld == "Depths" then
			newMoveDirectionMulti = newMoveDirectionMulti * 0.8
			airDashVertMulti = airDashVertMulti * 0.8
		end

		if effectReplicatorModule:HasEffect("Carrying") then
			newMoveDirectionMulti = newMoveDirectionMulti * 0.75
			airDashVertMulti = airDashVertMulti * 0.75
		end

		if effectReplicatorModule:HasEffect("GravityField") then
			newMoveDirectionMulti = newMoveDirectionMulti * 0.5
			airDashVertMulti = airDashVertMulti * 0.5
			currentDuration = currentDuration * 0.5
			rollBodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
		end

		moveDirection = Vector3.new(
			moveDirection.X * newMoveDirectionMulti,
			moveDirection.Y * airDashVertMulti,
			moveDirection.Z * newMoveDirectionMulti
		)

		rollBodyVelocity.Velocity = moveDirection

		clientEffectDirect:Fire("WindTrails", {
			char = character,
			Duration = currentDuration + 0.4,
		})
	end

	rollBodyVelocity.Parent = hrp
	rollBodyVelocity.Name = "Mover"

	if hasTalent(character, "Pivot Step") and not effectReplicatorModule:HasEffect("PivotCD") and not pivotStep then
		effectReplicatorModule
			:CreateEffect("PivotVelocity", {
				Value = rollBodyVelocity,
			})
			:Debris(0.45)

		effectReplicatorModule:CreateEffect("PivotCD"):Debris(1)
	end

	if isPressureForwarding then
		rollBodyVelocity.Name = "EasyCancel"
	end

	debris:AddItem(rollBodyVelocity, currentDuration)

	local rollTimestamp = tick()

	clientEffectDirect:Fire("footprintCheck", {
		char = character,
		strength = 1.8,
	})

	local freeDodgeBoolean = false
	local rollCancelStart = os.clock()

	if
		airDashBoolean
		and (
			game.PlaceId == 5614144350
			or players.LocalPlayer.Backpack:FindFirstChild("Talent:Aerial Assault")
			or game.PlaceId == 13891478131
		)
	then
		if not arcSuitDash then
			clientEffectDirect:Fire("GaleLeap15", {
				char = character,
			})
		else
			clientEffectDirect:Fire("ArcExhaust", {
				char = character,
				dur = 0.6,
			})
		end

		local clientAirDodgeEffect = effectReplicatorModule:CreateEffect("ClientAirDodge")

		while game:GetService("RunService").RenderStepped:Wait() do
			if effectReplicatorModule:HasEffect("MantraCasted") and loadedRollAnimation.IsPlaying then
				loadedRollAnimation:Stop()
			end

			if
				(
						effectReplicatorModule:HasEffect("LightAttack")
						or effectReplicatorModule:HasEffect("CriticalActive")
					)
					and not isPressureForwarding
				or effectReplicatorModule:HasEffect("CastingSpell")
				or effectReplicatorModule:HasEffect("UsingSpell")
				or effectReplicatorModule:HasEffect("Feint")
				or effectReplicatorModule:HasEffect("ClientFeint")
				or effectReplicatorModule:HasEffect("Parry")
				or effectReplicatorModule:HasEffect("DodgedFrame")
				or rollCancelTime and os.clock() - rollCancelStart > rollCancelTime
			then
				stopDodge:FireServer(inputDataTable, effectReplicatorModule:HasEffect("LightAttack"), airDashBoolean)

				if
					players.LocalPlayer.Backpack:FindFirstChild("Talent:Death from Above")
					or effectReplicatorModule:HasEffect("RevealBleeding")
						and players.LocalPlayer.Backpack:FindFirstChild("Talent:Float Like a Butterfly")
				then
					pcall(function() --[[ Line: 1147 ]]
						requests.ServerAirDashCancel:FireServer()
					end)
				end

				loadedRollAnimation:Stop()

				if inputDataTable["A"] then
					cancelLeft:Play(0.1)
				else
					cancelRight:Play(0.1)
				end

				replicatedDebris:Fire(rollBodyVelocity, 0.1)
				rollBodyVelocity.MaxForce = Vector3.new(100, 0, 100)
				rollBodyVelocity.Velocity = Vector3.zero
				freeDodgeBoolean = true
				break
			else
				if rollBodyVelocity and rollBodyVelocity.Parent then
					moveDirection = workspace.CurrentCamera.CFrame.LookVector
					moveDirection = Vector3.new(
						moveDirection.X * newMoveDirectionMulti,
						moveDirection.Y * airDashVertMulti,
						moveDirection.Z * newMoveDirectionMulti
					)

					if effectReplicatorModule:HasEffect("Wings") and not isPressureForwarding then
						rollBodyVelocity.Velocity = moveDirection
					else
						rollBodyVelocity.Velocity = moveDirection
						if rollBodyVelocity.Velocity.Y > 0 then
							rollBodyVelocity.Velocity = rollBodyVelocity.Velocity / Vector3.new(1, 2, 1)
						end
					end
				end
				if
					rollTimeSeconds < tick() - rollTimestamp
					or not rollBodyVelocity
					or not rollBodyVelocity.Parent
					or not inAir(humanoid, effectReplicatorModule)
					or hrp:FindFirstChild("GravBV")
				then
					break
				end
			end
		end

		clientAirDodgeEffect:Remove()
		loadedRollAnimation:Stop()

		if tick() - rollTimestamp < rollTimeSeconds then
			---@note: Again, exempt crouch boolean flag.
			humanoid:LoadAnimation(landingAnim):Play()

			local airDashBodyVelocity = Instance.new("BodyVelocity")
			airDashBodyVelocity:AddTag("AllowedBM")
			airDashBodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
			airDashBodyVelocity.Velocity = hrp.CFrame.LookVector * 60
			airDashBodyVelocity.Parent = hrp

			replicatedDebris:Fire(airDashBodyVelocity, 0.2)

			repeat
				task.wait(0.01)
				airDashBodyVelocity.Velocity = hrp.CFrame.LookVector * 60
			until not airDashBodyVelocity or not airDashBodyVelocity.Parent
		end
	else
		repeat
			if effectReplicatorModule:HasEffect("MantraCasted") and loadedRollAnimation.IsPlaying then
				loadedRollAnimation:Stop(0)
			end

			if not aerialAssaultBoolean and inAir(humanoid, effectReplicatorModule) then
				aerialAssaultBoolean = true
				rollMoveDirectionMulti = rollMoveDirectionMulti - 10
			end

			local combatActionEffects = effectReplicatorModule:FindEffect("Feint")
				or effectReplicatorModule:HasEffect("ClientFeint")
				or effectReplicatorModule:HasEffect("Parry")
				or effectReplicatorModule:HasEffect("DodgedFrame")

			if
				combatActionEffects
				or (effectReplicatorModule:HasEffect("LightAttack") or effectReplicatorModule:HasEffect(
					"CriticalActive"
				)) and not effectReplicatorModule:HasEffect("PressureForwarding")
				or effectReplicatorModule:HasEffect("CastingSpell")
				or effectReplicatorModule:HasEffect("UsingSpell")
				or rollCancelTime and os.clock() - rollCancelStart > rollCancelTime
			then
				stopDodge:FireServer(inputDataTable, effectReplicatorModule:HasEffect("LightAttack"))

				if loadedRollAnimation.IsPlaying then
					loadedRollAnimation:Stop(0)
				end

				if
					(effectReplicatorModule:FindEffect("Feint") or effectReplicatorModule:HasEffect("ClientFeint"))
					and not loadedCancelLeftAnimation.IsPlaying
					and not loadedCancelRightAnimation.IsPlaying
				then
					if inputDataTable["A"] then
						loadedCancelLeftAnimation:Play(0.1)
					else
						loadedCancelRightAnimation:Play(0.1)
					end
				end

				if combatActionEffects then
					freeDodgeBoolean = true
				else
					freeDodgeBoolean = "mantra"
					break
				end
			end

			if rollBodyVelocity and rollBodyVelocity.Parent then
				local currentMoveDirection = humanoid.MoveDirection
				if currentMoveDirection.Magnitude < 0.1 then
					currentMoveDirection = moveDirection
				end

				if not pivotStep then
					moveDirection = currentMoveDirection
				end

				if freeDodgeBoolean == true and rollMoveDirectionMulti >= 30 then
					rollMoveDirectionMulti = rollMoveDirectionMulti - 10
				end

				rollBodyVelocity.Velocity = moveDirection * rollMoveDirectionMulti
			end

			runService.RenderStepped:Wait()
		until rollTimeSeconds < tick() - rollTimestamp
			or not rollBodyVelocity
			or not rollBodyVelocity.Parent
			or hrp:FindFirstChild("GravBV")
			or effectReplicatorModule:HasEffect("CancelDodge")
	end

	clientEffectDirect:Fire("footprintCheck", {
		char = character,
		strength = 1.5,
	})

	if isPressureForwarding or arcSuitDash then
		loadedRollAnimation:Stop()
	end

	if rollBodyVelocity then
		rollBodyVelocity:Destroy()
	end

	local dodgeCooldown = 1.3

	if
		effectReplicatorModule:HasEffect("RollCancelFatigue")
		and (
			effectReplicatorModule:HasEffect("DownComesTheClaw")
			or not players.LocalPlayer.Backpack:FindFirstChild("Talent:Tap Dancer")
		)
	then
		dodgeCooldown = 1.8
	end

	if
		freeDodgeBoolean
		and not effectReplicatorModule:HasEffect("RollCancelFatigue")
		and not effectReplicatorModule:HasEffect("DownComesTheClaw")
		and not airDashBoolean
	then
		effectReplicatorModule:CreateEffect("RollCancelFatigue"):Debris(dodgeCooldown)
		dodgeCooldown = 0
	end

	if effectReplicatorModule:HasEffect("DanceBlade") then
		dodgeCooldown = 0
	end

	local dodgeCooldownTimestamp = tick()

	if dodgeCooldown > 0 then
		repeat
			task.wait()
		until dodgeCooldown <= tick() - dodgeCooldownTimestamp
			or effectReplicatorModule:HasEffect("DanceBlade")
			or effectReplicatorModule:HasEffect("PivotStepRESET")
	end

	dashItEffect:Remove()

	---@note: Inlined freefall function.
	if loadedFreefallAnimation.IsPlaying then
		local expectedDurationTime = 0.25

		if effectReplicatorModule:HasEffect("Jumped") then
			expectedDurationTime = expectedDurationTime + 0.2
		end

		local durationWaited = 0.0

		repeat
			durationWaited = durationWaited + task.wait()
		until effectReplicatorModule:HasEffect("Landed") or expectedDurationTime <= durationWaited

		if durationWaited < expectedDurationTime or loadedFreefallAnimation.IsPlaying then
			return
		end

		if effectReplicatorModule:HasEffect("DashIt") then
			repeat
				task.wait()
			until not effectReplicatorModule:HasEffect("DashIt")
		end

		if
			humanoid:GetState() == Enum.HumanoidStateType.Freefall
			and not effectReplicatorModule:HasEffect("Swimming")
			and not effectReplicatorModule:HasEffect("Gliding")
			and not effectReplicatorModule:HasEffect("Knocked")
		then
			loadedFreefallAnimation.Priority = Enum.AnimationPriority.Movement
			loadedFreefallAnimation:Play(0.3)
		end
	end

	noRollEffect:Remove()

	if effectReplicatorModule:HasEffect("Overcharge") then
		effectReplicatorModule:RemoveEffectsOfClass("Overcharge")
	end
end)

---Validate function.
---@param func function
---@return boolean
InputClient.validate = LPH_NO_VIRTUALIZE(function(func)
	local upvalues = debug.getupvalues(func)

	if not upvalues or #upvalues <= 0 then
		Logger.warn("Skipping function (%s) with no upvalues.", tostring(func))
		return false
	end

	return true
end)

---Update cache.
---@param consts any[]
InputClient.update = LPH_NO_VIRTUALIZE(function(consts)
	if consts[2] ~= "wait" then
		return Logger.warn("Ignoring bad update cache call for performance.")
	end

	InputClient.cache()
end)

---Cache InputClient module.
-- @note: I sold my soul to the GC gods because there's no other way. Updates are only done when needed.
InputClient.cache = LPH_NO_VIRTUALIZE(function()
	for _, value in next, getgc() do
		if typeof(value) ~= "function" or iscclosure(value) or isexecutorclosure(value) then
			continue
		end

		local functionName = debug.getinfo(value).name
		if not functionName then
			continue
		end

		if functionName ~= "Sprint" and functionName ~= "Roll" then
			continue
		end

		if not InputClient.validate(value) then
			continue
		end

		if functionName == "Sprint" then
			InputClient.sprintFunctionCache = value

			Logger.warn("Sprint function (%s) cache successful.", tostring(value))
		end

		if functionName == "Roll" then
			InputClient.rollFunctionCache = value

			Logger.warn("Roll function (%s) cache successful.", tostring(value))
		end

		if InputClient.sprintFunctionCache and InputClient.rollFunctionCache then
			break
		end
	end
end)

-- Return InputClient module.
return InputClient
