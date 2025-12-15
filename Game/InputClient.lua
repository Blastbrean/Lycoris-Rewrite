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

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

-- Services.
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")

-- Functions.
local unreliableFireServer = Instance.new("UnreliableRemoteEvent").FireServer

-- Cache.
local inputDataCache = nil

-- Tracks.
local freefallTrack = nil
local slideJumpTrack = nil
local cancelLeftTrack = nil
local cancelRightTrack = nil
local jumpAnimTrack = nil

---Check if we landed.
---@return boolean
local landedCheck = LPH_NO_VIRTUALIZE(function()
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	local humanController = InputClient.getHumanController()
	if not humanController then
		return
	end

	local sprintSpeed = effectReplicatorModule:FindEffect("SprintSpeed")
	if not sprintSpeed then
		return
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local characterHandler = character:FindFirstChild("CharacterHandler")
	local inputClient = characterHandler and characterHandler:FindFirstChild("InputClient")
	if not inputClient then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	local torso = character:FindFirstChild("Torso")
	if not torso then
		return
	end

	local groundSensor = humanController.GroundSensor
	if not groundSensor then
		return
	end

	local stopDodge = KeyHandling.getRemote("StopDodge")
	if not stopDodge then
		return
	end

	local inputData = InputClient.getInputData()
	if not inputData then
		return
	end

	local repDebris = replicatedStorage:FindFirstChild("Debris")
	if not repDebris then
		return
	end

	local sounds = replicatedStorage:FindFirstChild("Sounds")
	local sliding = sounds and sounds:FindFirstChild("Sliding")
	if not sliding then
		return
	end

	local modules = replicatedStorage:FindFirstChild("Modules")
	local vectorMaths = modules and modules:FindFirstChild("VectorMaths")
	local vectorMathModule = vectorMaths and require(vectorMaths)
	if not vectorMathModule then
		return
	end

	local sensedPart = groundSensor.SensedPart

	if not effectReplicatorModule:HasAny("Swimming", "ClientSwim", "Gliding", "Knocked") then
		if not sensedPart then
			return false
		end

		if sensedPart and sensedPart.CollisionGroup == "Ship" then
			effectReplicatorModule:EnsureEffect("OnShip")
		elseif effectReplicatorModule:HasEffect("OnShip") then
			effectReplicatorModule:RemoveEffectsOfClass("OnShip")
		end
	end

	if freefallTrack.IsPlaying then
		freefallTrack:Stop(0.15)
	end

	if not effectReplicatorModule:HasEffect("Falling") then
		return true
	end

	effectReplicatorModule:RemoveEffectsOfClass("Falling")
	effectReplicatorModule:RemoveEffectsOfClass("ShipJump")
	effectReplicatorModule:RemoveEffectsOfClass("WingDashCooldown")

	humanoid.Jump = false

	effectReplicatorModule:CreateEffect("Landed"):Debris(0.05)

	if effectReplicatorModule:HasEffect("SlideJumping") and not effectReplicatorModule:HasEffect("GravityField") then
		effectReplicatorModule:RemoveEffectsOfClass("SlideJumping")

		if sprintSpeed and sprintSpeed.Value >= 9 then
			sprintSpeed.Value = sprintSpeed.Value - 3
		end

		local lookVector = root.CFrame.LookVector * 3
		local slideJump = torso:FindFirstChild("SlideJump")

		if slideJump then
			slideJump:Destroy()
		end

		if effectReplicatorModule:HasEffect("Sprinting") then
			humanoid:LoadAnimation(inputClient.SlideJumpTransition):Play(nil, 0.65)
		else
			humanoid:LoadAnimation(inputClient.LandingAnim):Play(nil, 0.65)
		end

		if slideJumpTrack.IsPlaying and effectReplicatorModule:HasEffect("Equipped") then
			slideJumpTrack:Stop(0.15)
		end

		stopDodge:FireServer(inputData, effectReplicatorModule:HasEffect("LightAttack"), true)

		local lookVectorUnitMulti = lookVector.Unit * 50

		if sensedPart and sensedPart.AssemblyMass > root.AssemblyMass then
			lookVectorUnitMulti = lookVectorUnitMulti
				+ vectorMathModule.getVelocityAtPoint(sensedPart, groundSensor.HitFrame.Position)
		end

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Name = "SlideJump2"
		bodyVelocity.Velocity = lookVectorUnitMulti
		bodyVelocity.MaxForce = Vector3.new(80000, 80000, 80000, 0)
		bodyVelocity:AddTag("AllowedBM")
		bodyVelocity.Parent = torso

		repDebris:Fire(bodyVelocity, 0.2)

		local slidingSound = sliding:Clone()
		slidingSound.Parent = root
		slidingSound:Play()

		repDebris:Fire(slidingSound, 0.25)

		tweenService
			:Create(slidingSound, TweenInfo.new(0.25), {
				Volume = 0,
			})
			:Play()
	end

	task.delay(0.1, function()
		effectReplicatorModule:RemoveEffectsOfClass("WallJumpCD")
		effectReplicatorModule:RemoveEffectsOfClass("BigMomentum")
		task.wait(2)
	end)

	return true
end)

---Check if we're in freefall.
local freefallCheck = LPH_NO_VIRTUALIZE(function()
	if landedCheck() then
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

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if effectReplicatorModule:HasEffect("OnShip") then
		effectReplicatorModule:RemoveEffectsOfClass("OnShip")
		effectReplicatorModule:EnsureEffect("ShipJump"):Debris(5, true)
	end

	effectReplicatorModule:EnsureEffect("Falling")

	local fallTime = tick() - (effectReplicatorModule:GetEffectEpoch("Falling") or 0)

	if
		effectReplicatorModule:HasAny("DashIt", "Jumped", "UsingAbility", "LightAttack", "Action")
		or root.AssemblyLinearVelocity.Y > 0
	then
		return freefallTrack.IsPlaying and freefallTrack:Stop(0.1)
	end

	if freefallTrack.IsPlaying then
		return
	end

	if fallTime > 0.5 and root.AssemblyLinearVelocity.Y < 0 then
		freefallTrack.Priority = Enum.AnimationPriority.Movement
		freefallTrack:Play(0.3)
	end
end)

---In air check.
---@return boolean
local inAirCheck = LPH_NO_VIRTUALIZE(function()
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

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return
	end

	if effectReplicatorModule:HasEffect("Swimming") then
		return false
	elseif humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		return true
	elseif effectReplicatorModule:HasEffect("AirBorne") then
		return true
	else
		return false
	end
end)

---Movement check.
---@return boolean
local movementCheck = LPH_NO_VIRTUALIZE(function()
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if effectReplicatorModule:HasEffect("Action") then
		return false
	elseif effectReplicatorModule:HasEffect("NoParkour") then
		return false
	elseif effectReplicatorModule:HasEffect("Knocked") or effectReplicatorModule:HasEffect("Unconscious") then
		return false
	elseif effectReplicatorModule:HasEffect("Pinned") or effectReplicatorModule:HasEffect("Carried") then
		return false
	else
		return true
	end
end)

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

---Fetch human controller.
---@return table?
InputClient.getHumanController = LPH_NO_VIRTUALIZE(function()
	---@note: Shouldn't be too many connections to PreAnimation.
	for _, connection in next, getconnections(runService.PreAnimation) do
		local func = connection.Function
		if not func then
			continue
		end

		if iscclosure(func) or isexecutorclosure(func) then
			continue
		end

		local upvalues = debug.getupvalues(func)
		if not upvalues then
			continue
		end

		for _, upvalue in next, upvalues do
			if typeof(upvalue) ~= "table" then
				continue
			end

			if upvalue.Jumping == nil then
				continue
			end

			return upvalue
		end
	end

	return nil
end)

---Fetch input data.
---@return table?
InputClient.getInputData = LPH_NO_VIRTUALIZE(function()
	return inputDataCache
end)

---Left click function.
---@param cframe CFrame
---@param ignoreChecks boolean
InputClient.left = LPH_NO_VIRTUALIZE(function(cframe, ignoreChecks)
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

	if not ignoreChecks then
		if
			effectReplicatorModule:HasEffect("LightAttack")
			or effectReplicatorModule:HasEffect("CriticalAttack")
			or effectReplicatorModule:HasEffect("Followup")
			or effectReplicatorModule:HasEffect("Parried")
		then
			return
		end
	end

	---@note: Missing M1-Hold and Input Buffering functionality but I don't think the caller cares about it.
	-- Call like the game does it so our hooks go through.
	unreliableFireServer(leftClickRemote, inAirCheck(), cframe, inputData)
end)

---Activate mantra.
---@param tool Tool
InputClient.amantra = LPH_NO_VIRTUALIZE(function(tool)
	local character = players.LocalPlayer.Character
	if not character then
		return Logger.warn("Cannot activate mantra without character.")
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return Logger.warn("Cannot activate mantra without humanoid root part.")
	end

	local characterHandler = character:FindFirstChild("CharacterHandler")
	if not characterHandler then
		return Logger.warn("Cannot activate mantra without character handler.")
	end

	local requests = characterHandler:FindFirstChild("Requests")
	if not requests then
		return Logger.warn("Cannot activate mantra without requests.")
	end

	local activateMantraRemote = requests:FindFirstChild("ActivateMantra")
	if not activateMantraRemote then
		return Logger.warn("Cannot activate mantra without ActivateMantra remote.")
	end

	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
		return Logger.warn("Cannot activate mantra without valid tool.")
	end

	activateMantraRemote:FireServer(tool)
end)

---Vent function.
InputClient.vent = LPH_NO_VIRTUALIZE(function()
	local character = players.LocalPlayer.Character
	if not character then
		return Logger.warn("Cannot vent without character.")
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return Logger.warn("Cannot vent without humanoid root part.")
	end

	local characterHandler = character:FindFirstChild("CharacterHandler")
	if not characterHandler then
		return Logger.warn("Cannot vent without character handler.")
	end

	local requests = characterHandler:FindFirstChild("Requests")
	if not requests then
		return Logger.warn("Cannot vent without requests.")
	end

	local ventRemote = requests:FindFirstChild("Vent")
	if not ventRemote then
		return Logger.warn("Cannot vent without vent remote.")
	end

	ventRemote:FireServer()
end)

---Dodge function.
---@param options DodgeOptions
InputClient.dodge = LPH_NO_VIRTUALIZE(function(options)
	local dodge = KeyHandling.getRemote("Dodge")
	if not dodge then
		return Logger.warn("Cannot dodge without dodge remote.")
	end

	if options.direct then
		return dodge:FireServer("roll", nil, nil, false)
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return Logger.warn("Cannot dodge without effect replicator.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return Logger.warn("Cannot dodge without effect replicator module.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return Logger.warn("Cannot dodge without character.")
	end

	local characterHandler = character:FindFirstChild("CharacterHandler")
	local inputClient = characterHandler and characterHandler:FindFirstChild("InputClient")
	if not inputClient then
		return Logger.warn("Cannot dodge without input client.")
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return Logger.warn("Cannot dodge without humanoid.")
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return Logger.warn("Cannot dodge without humanoid root part.")
	end

	local unblock = KeyHandling.getRemote("Unblock")
	if not unblock then
		return Logger.warn("Cannot dodge without unblock remote.")
	end

	local stopDodge = KeyHandling.getRemote("StopDodge")
	if not stopDodge then
		return Logger.warn("Cannot dodge without stop dodge remote.")
	end

	local inputData = InputClient.getInputData()
	if not inputData then
		return Logger.warn("Cannot dodge without input data.")
	end

	local requests = replicatedStorage:FindFirstChild("Requests")
	local clientEffectDirect = requests and requests:FindFirstChild("ClientEffectDirect")
	if not clientEffectDirect then
		return Logger.warn("Cannot dodge without ClientEffectDirect remote.")
	end

	local characterHashes = replicatedStorage:FindFirstChild("CharacterHashes")
	local characterHashesModule = characterHashes and require(characterHashes)
	local characterHashData = characterHashesModule and characterHashesModule.GetDynamic(character)
	if not characterHashData then
		return Logger.warn("Cannot dodge without character hash data.")
	end

	local sounds = replicatedStorage:FindFirstChild("Sounds")
	local windFlash = sounds and sounds:FindFirstChild("WindFlash")
	local windFlashTwo = sounds and sounds:FindFirstChild("WindFlash2")
	local ssLightning = sounds and sounds:FindFirstChild("SSlightning")
	local waterDashSound = sounds and sounds:FindFirstChild("WaterDash")
	local flap2 = sounds and sounds:FindFirstChild("Flap2")
	local airDodge = sounds and sounds:FindFirstChild("AirDodge")
	local rollSound = sounds and sounds:FindFirstChild("Roll")

	if
		not windFlash
		or not windFlashTwo
		or not ssLightning
		or not waterDashSound
		or not flap2
		or not airDodge
		or not rollSound
	then
		return Logger.warn("Cannot dodge without required sounds.")
	end

	local assets = replicatedStorage:FindFirstChild("Assets")
	local staticSpear = assets and assets:FindFirstChild("StaticSpear1")
	local staticSpearTwo = assets and assets:FindFirstChild("StaticSpear2")

	local anims = assets and assets:FindFirstChild("Anims")
	local movement = anims and anims:FindFirstChild("Movement")
	local roll = movement and movement:FindFirstChild("Roll")
	local waterDash = movement and movement:FindFirstChild("WaterDash")

	local forwardRoll = roll and roll:FindFirstChild("ForwardRoll")
	local backRoll = roll and roll:FindFirstChild("BackRoll")
	local rightRoll = roll and roll:FindFirstChild("RightRoll")
	local leftRoll = roll and roll:FindFirstChild("LeftRoll")

	if not forwardRoll or not backRoll or not rightRoll or not leftRoll then
		return Logger.warn("Cannot dodge without roll animations.")
	end

	local forwardWaterDash = waterDash and waterDash:FindFirstChild("ForwardWaterDash")
	local backWaterDash = waterDash and waterDash:FindFirstChild("BackWaterDash")
	local rightWaterDash = waterDash and waterDash:FindFirstChild("RightWaterDash")
	local leftWaterDash = waterDash and waterDash:FindFirstChild("LeftWaterDash")

	if not forwardWaterDash or not backWaterDash or not rightWaterDash or not leftWaterDash then
		return Logger.warn("Cannot dodge without water dash animations.")
	end

	local rollToWaterMap = {
		[forwardRoll] = forwardWaterDash,
		[backRoll] = backWaterDash,
		[rightRoll] = rightWaterDash,
		[leftRoll] = leftWaterDash,
	}

	if not staticSpear or not staticSpearTwo then
		return Logger.warn("Cannot dodge without static spear assets.")
	end

	if not freefallTrack or not slideJumpTrack then
		return Logger.warn("Cannot dodge without freefall or slide jump tracks.")
	end

	if not cancelLeftTrack or not cancelRightTrack then
		return Logger.warn("Cannot dodge without cancel tracks.")
	end

	local humanController = InputClient.getHumanController()
	if not humanController then
		return Logger.warn("Cannot dodge without human controller.")
	end

	local repDebris = replicatedStorage:FindFirstChild("Debris")
	if not repDebris then
		return Logger.warn("Cannot dodge without Debris service.")
	end

	local modules = replicatedStorage:FindFirstChild("Modules")
	local vectorMaths = modules and modules:FindFirstChild("VectorMaths")
	local vectorMathModule = vectorMaths and require(vectorMaths)

	local collisionUtils = modules and modules:FindFirstChild("CollisionUtils")
	local collisionUtilsModule = collisionUtils and require(collisionUtils)

	local checks = modules and modules:FindFirstChild("Checks")
	local checksModule = checks and require(checks)(effectReplicatorModule)

	if not vectorMathModule or not collisionUtilsModule or not checksModule then
		return Logger.warn("Cannot dodge without required modules.")
	end

	local rootAttachment = root:FindFirstChild("RootAttachment")
	if not rootAttachment then
		return Logger.warn("Cannot dodge without root attachment.")
	end

	local clientSwim = effectReplicatorModule:FindEffect("ClientSwim")
	local wingDash = not effectReplicatorModule:HasEffect("WingDashCooldown")
		and effectReplicatorModule:HasEffect("Wings")

	local lightAttack = effectReplicatorModule:HasEffect("LightAttack")

	if options.actionRolling then
		lightAttack = false
	end

	if effectReplicatorModule:HasEffect("CarryObject") and not clientSwim then
		return
	elseif
		not options.actionRolling
		and (effectReplicatorModule:HasEffect("UsingSpell") or effectReplicatorModule:HasEffect("CastingSpell"))
	then
		return
	elseif not movementCheck() then
		return
	elseif effectReplicatorModule:HasEffect("NoAttack") and not effectReplicatorModule:HasEffect("CanRoll") then
		return
	elseif effectReplicatorModule:HasEffect("Dodged") or effectReplicatorModule:HasEffect("Dodge") then
		return
	elseif effectReplicatorModule:HasEffect("NoRoll") or effectReplicatorModule:HasEffect("PreventRoll") then
		return
	elseif effectReplicatorModule:HasEffect("SwimRestrict") and effectReplicatorModule:HasEffect("Swimming") then
		return
	elseif effectReplicatorModule:HasEffect("Stun") then
		return
	elseif effectReplicatorModule:HasEffect("Action") or effectReplicatorModule:HasEffect("MobileAction") then
		return
	elseif effectReplicatorModule:HasEffect("Carried") then
		return
	else
		local pressureForward = effectReplicatorModule:FindEffect("PressureForward")
		if lightAttack and not pressureForward then
			return
		else
			if effectReplicatorModule:HasEffect("Blocking") then
				unblock:FireServer()
			end

			if effectReplicatorModule:HasEffect("ClientSlide") then
				return
			elseif root:FindFirstChild("GravBV") then
				return
			else
				freefallTrack:Stop(0.3)

				local rollType = clientSwim and "waterdash" or "roll"
				local robloxEnv = getrenv()._G

				if characterHashData.Flashwind and effectReplicatorModule:HasEffect("Flashcharge") then
					robloxEnv.Sound(windFlash, root)
					robloxEnv.Sound(windFlashTwo, root)
				end

				local pressureForwarding = false

				if
					effectReplicatorModule:HasEffect("PressureForward")
					or effectReplicatorModule:HasEffect("GaleDash")
					or effectReplicatorModule:HasEffect("Flashcharge")
					or effectReplicatorModule:HasEffect("PhantomStep")
						and not effectReplicatorModule:HasEffect("PhantomStepDashCD")
				then
					pressureForwarding = true

					effectReplicatorModule:CreateEffect("PressureForwarding"):Debris(0.5)

					if characterHashData.Flashwind and not effectReplicatorModule:FindEffect("FlashwindCD") then
						effectReplicatorModule:CreateEffect("Flashcharge"):Debris(3)

						local flashWindCooldown = effectReplicatorModule:CreateEffect("FlashwindCD")
						flashWindCooldown:AddTag("CDName", "Flashwind")
						flashWindCooldown:Debris(15)

						local rightHand = character:FindFirstChild("RightHand")
						local handWeapon = rightHand and rightHand:FindFirstChild("HandWeapon")
						if handWeapon then
							robloxEnv.Emit(staticSpear, handWeapon, 1, {
								Duration = 6,
								Color = Color3.new(0.721569, 1, 0.203922),
							})

							robloxEnv.Emit(staticSpearTwo, handWeapon, 1, {
								Duration = 6,
								Color = Color3.new(0.721569, 1, 0.203922),
							})

							robloxEnv.Sound(ssLightning, handWeapon, {
								Duration = 6,
							})

							robloxEnv.Sound(windFlash, handWeapon, {
								Duration = 6,
							})
						end
					end
				end

				local healthPercentage = humanoid.Health / humanoid.MaxHealth

				if characterHashData["Endurance Runner"] then
					healthPercentage = 0.25 + healthPercentage * 0.75
				end

				local usedAgility = 60 + character.PassiveAgility.Value * 0.5 * healthPercentage
				local rushOfAncients = false

				if characterHashData.Lowstride and effectReplicatorModule:FindEffect("ClientCrouch") then
					usedAgility = usedAgility + 10
				end

				if
					characterHashData["Rush of Ancients"]
					and not effectReplicatorModule:HasEffect("AncientRushCD")
					and effectReplicatorModule:FindEffectWithTag("MaxMomentum")
				then
					rushOfAncients = true

					if healthPercentage < 0.5 then
						local cooldownTime = math.clamp(1 - healthPercentage, 0, 1) * 5 + 3
						local ancientRushCD = effectReplicatorModule:CreateEffect("AncientRushCD")
						ancientRushCD:AddTag("CDName", "Rush of Ancients")
						ancientRushCD:Debris(cooldownTime)
					end

					if effectReplicatorModule:HasEffect("Danger") then
						local ancientRushCD = effectReplicatorModule:CreateEffect("AncientRushCD")
						ancientRushCD:AddTag("CDName", "Rush of Ancients")
						ancientRushCD:Debris(8)
					end

					usedAgility = usedAgility + (20 + 15 * healthPercentage)
				end

				if effectReplicatorModule:HasEffect("SpinAttack") then
					dodge:FireServer(rollType, true)
				else
					dodge:FireServer(rollType, nil, nil, rushOfAncients)
				end

				effectReplicatorModule:CreateEffect("ClientDodge"):Debris(0.3)

				local noRoll = effectReplicatorModule:CreateEffect("NoRoll")
				noRoll:Debris(2.3)

				local rollTime = 0.2

				if
					(
						effectReplicatorModule:HasEffect("GodSpeed")
						or effectReplicatorModule:HasEffect("Overcharged")
						or effectReplicatorModule:HasEffect("Flashcharge")
					) and not effectReplicatorModule:HasEffect("ClientSwim")
				then
					rollTime = 0.5

					if characterHashData.Flashwind and not effectReplicatorModule:HasEffect("FlashwindCD") then
						effectReplicatorModule:CreateEffect("Flashcharge"):Debris(3)

						local flashWindCooldown = effectReplicatorModule:CreateEffect("FlashwindCD")
						flashWindCooldown:AddTag("CDName", "Flashwind")
						flashWindCooldown:Debris(15)

						local rightHand = character:FindFirstChild("RightHand")
						local handWeapon = rightHand and rightHand:FindFirstChild("HandWeapon")
						if handWeapon then
							robloxEnv.Emit(staticSpear, handWeapon, 1, {
								Duration = 6,
								Color = Color3.new(0.721569, 1, 0.203922),
							})

							robloxEnv.Emit(staticSpearTwo, handWeapon, 1, {
								Duration = 6,
								Color = Color3.new(0.721569, 1, 0.203922),
							})

							robloxEnv.Sound(ssLightning, handWeapon, {
								Duration = 6,
							})

							robloxEnv.Sound(windFlash, handWeapon, {
								Duration = 6,
							})
						end
					end
				end

				local usedRollAnimation = nil
				local lookVectorRoot = root.CFrame.LookVector
				local moveDirection = humanoid.MoveDirection

				if moveDirection.Magnitude < 0.1 then
					moveDirection = -lookVectorRoot
				end

				local rollDegree = math.deg((math.acos((math.clamp(moveDirection:Dot(lookVectorRoot), -1, 1)))))

				if rollDegree <= 45 then
					usedRollAnimation = forwardRoll
				elseif rollDegree > 45 and rollDegree < 135 then
					local diagonalRollDegree = math.deg(
						(
							math.acos(
								(
									math.clamp(
										moveDirection:Dot((Vector3.new(-lookVectorRoot.z, 0, lookVectorRoot.x))),
										-1,
										1
									)
								)
							)
						)
					)

					if diagonalRollDegree <= 45 then
						usedRollAnimation = rightRoll
					elseif diagonalRollDegree > 135 then
						usedRollAnimation = leftRoll
					else
						usedRollAnimation = backRoll
					end
				else
					usedRollAnimation = backRoll
				end

				local noAirPenalty = false
				local airDash = false
				local inAirBackRoll = false

				if
					inAirCheck()
					and not effectReplicatorModule:HasEffect("ClientSwim")
					and not characterHashData["Chained Ring"]
					and not effectReplicatorModule:HasEffect("GravityField")
				then
					if usedRollAnimation == backRoll then
						inAirBackRoll = true
					else
						noAirPenalty = true
						usedAgility = 35
						airDash = true
					end
				end

				if clientSwim then
					usedAgility = 30 + 10 * healthPercentage
					noAirPenalty = true
					usedRollAnimation = rollToWaterMap[usedRollAnimation] or usedRollAnimation
				end

				if usedRollAnimation == backRoll then
					usedAgility = usedAgility - 10
				end

				if pressureForwarding then
					usedRollAnimation = inputClient.PressureSlide
					rollTime = 0.5
				end

				local inArcSuit = effectReplicatorModule:HasEffect("ArcSuit") and characterHashData["Arc Module: Dash"]

				if inArcSuit then
					usedAgility = usedAgility - 5
					usedRollAnimation = inputClient.PressureSlide
					rollTime = 0.3
					clientEffectDirect:Fire("WindTrails", {
						char = character,
						Duration = 0.3,
					})
				end

				if effectReplicatorModule:HasEffect("ReducedRoll") and not inArcSuit then
					usedAgility = usedAgility - 10
				end

				if effectReplicatorModule:HasEffect("GravityField") then
					noAirPenalty = true
					usedAgility = usedAgility * 0.2
				end

				if airDash then
					usedRollAnimation = inputClient.AirDash
				end

				local usedRollTrack = humanoid:LoadAnimation(usedRollAnimation)

				if pressureForwarding then
					usedRollTrack.Priority = Enum.AnimationPriority.Movement
				end

				local usedRollSpeed = 1

				if effectReplicatorModule:HasEffect("SlowTime") then
					rollTime = 1
					usedAgility = 10
					usedRollSpeed = 0.5
				elseif effectReplicatorModule:HasEffect("StopTime") then
					rollTime = 0.1
					usedAgility = -100
					usedRollSpeed = 0.01
				end

				if not effectReplicatorModule:HasEffect("SlowDodge") then
					local weight = 0
					local heavyShoulder = false

					for _, effect in next, effectReplicatorModule:GetEffectsOfClass("MetalCombo") do
						if effect:HasTag("heavyshoulder") then
							heavyShoulder = true
						end

						weight = weight + effect.Value
					end

					if weight >= 3 and heavyShoulder then
						effectReplicatorModule:CreateEffect("SlowDodge"):Debris(1)
					end
				end

				if effectReplicatorModule:HasEffect("SlowDodge") then
					rollTime = rollTime + 0.1
					usedRollSpeed = usedRollSpeed * 0.75
					usedAgility = math.max(usedAgility - 20, 10)
				end

				if
					not effectReplicatorModule:HasEffect("GodSpeed")
					and not effectReplicatorModule:HasEffect("ClientSwim")
				then
					if pressureForwarding then
						usedRollTrack:Play(0.1, 0.5, usedRollSpeed)
					else
						usedRollTrack:Play(0.1, 1, usedRollSpeed)
					end
				end

				local inArcDash = effectReplicatorModule:HasEffect("ArcSuit") and characterHashData["Arc Module: Dash"]
				local dashIt = effectReplicatorModule:CreateEffect("DashIt")

				if rollType == "waterdash" then
					robloxEnv.Sound(waterDashSound, root)
				elseif airDash then
					if wingDash then
						robloxEnv.Sound(flap2, root)
						effectReplicatorModule:CreateEffect("WingDashCooldown")
					else
						robloxEnv.Sound(airDodge, root)
					end
				elseif inAirBackRoll then
					robloxEnv.Sound(airDodge, root, {
						PlaybackSpeed = 5,
					})
				elseif not inArcDash then
					robloxEnv.Sound(rollSound, root)
				end

				if inAirBackRoll then
					root.AssemblyLinearVelocity = Vector3.new()
					clientEffectDirect:Fire("GaleLeapDown", {
						char = character,
					})
				end

				effectReplicatorModule:RemoveEffectsOfClass("ShipJump")
				effectReplicatorModule:RemoveEffectsOfClass("ForceSlide")

				local usedBodyVelocity = nil
				local groundSensor = humanController.GroundSensor
				local rollStart = tick()

				clientEffectDirect:Fire("footprintCheck", {
					char = character,
					strength = 1.8,
				})

				local isScyphozia = characterHashData.IsScyphozia
				local giveRollCancelFatigue = false

				task.spawn(function()
					if airDash then
						moveDirection = workspace.CurrentCamera.CFrame.LookVector
						usedAgility = 50 + healthPercentage * 20

						local rollDuration = 1.3

						if wingDash and not isScyphozia then
							if checksModule.HorMobilityChain() then
								usedAgility = 50 + healthPercentage * 25
							else
								usedAgility = 50 + healthPercentage * 30
							end
						end

						if isScyphozia then
							usedAgility = usedAgility * 0.8
						end

						if effectReplicatorModule:HasEffect("Carrying") then
							usedAgility = usedAgility * 0.75
						end

						if effectReplicatorModule:HasEffect("GravityField") then
							usedAgility = usedAgility * 0.5
							rollDuration = rollDuration * 0.5
						end

						local bvVelocity = Vector3.new(1, 1, 1, 0) * usedAgility
						local groundVelocity = moveDirection * bvVelocity

						if groundSensor then
							local sensedPart = groundSensor.SensedPart
							if sensedPart and sensedPart.AssemblyMass > root.AssemblyMass then
								groundVelocity = groundVelocity
									+ vectorMathModule.getVelocityAtPoint(sensedPart, groundSensor.HitFrame.Position)
							end
						end

						root.AssemblyLinearVelocity = groundVelocity
						usedBodyVelocity = Instance.new("BodyVelocity")
						usedBodyVelocity:AddTag("AllowedBM")
						usedBodyVelocity.MaxForce = Vector3.new(50000, 50000, 50000, 0)
						usedBodyVelocity.Velocity = moveDirection * bvVelocity
						usedBodyVelocity.Name = pressureForwarding and "EasyCancel" or "Mover"
						usedBodyVelocity.Parent = root

						repDebris:Fire(usedBodyVelocity, rollDuration)
						clientEffectDirect:Fire("WindTrails", {
							char = character,
							Duration = rollDuration + 0.4,
						})

						if inArcDash then
							clientEffectDirect:Fire("ArcExhaust", {
								char = character,
								dur = 0.6,
							})
						else
							clientEffectDirect:Fire("GaleLeap15", {
								char = character,
							})
						end

						local clientAirDodge = effectReplicatorModule:CreateEffect("ClientAirDodge")

						while task.wait() do
							if effectReplicatorModule:HasEffect("MantraCasted") and usedRollTrack.IsPlaying then
								usedRollTrack:Stop()
							end

							local hasAttackAny = effectReplicatorModule:HasAny("LightAttack", "UsingAbility")
									and not pressureForwarding
								or effectReplicatorModule:HasEffect("UsingSpell")

							if options.actionRolling then
								hasAttackAny = false
							end

							if
								hasAttackAny
								or effectReplicatorModule:HasEffect("Feint")
								or effectReplicatorModule:HasEffect("ClientFeint")
								or effectReplicatorModule:HasEffect("Parry")
								or effectReplicatorModule:HasEffect("DodgedFrame")
								or (options.rollCancel and tick() - rollStart > options.rollCancelDelay)
							then
								stopDodge:FireServer(inputData, effectReplicatorModule:HasEffect("LightAttack"), true)

								if
									characterHashData["Death from Above"]
									or effectReplicatorModule:HasEffect("RevealBleeding")
										and characterHashData["Float Like a Butterfly"]
								then
									pcall(function()
										requests.ServerAirDashCancel:FireServer()
									end)
								end

								usedRollTrack:Stop()

								if inputData.A then
									cancelLeftTrack:Play(0.1)
								else
									cancelRightTrack:Play(0.1)
								end

								repDebris:Fire(usedBodyVelocity, 0.1)
								usedBodyVelocity.MaxForce = Vector3.new(100, 0, 100, 0)
								usedBodyVelocity.Velocity = Vector3.new(0, 0, 0, 0)
								giveRollCancelFatigue = true
								break
							else
								if usedBodyVelocity and usedBodyVelocity.Parent then
									local cameraLookVectorVel = workspace.CurrentCamera.CFrame.LookVector * bvVelocity
									local raycast = workspace:Raycast(
										root.Position,
										-humanController.Manager.UpDirection * 30,
										collisionUtilsModule.vehicleParams
									)

									if raycast then
										cameraLookVectorVel = cameraLookVectorVel
											+ vectorMathModule.getVelocityAtPoint(raycast.Instance, raycast.Position)
									end

									usedBodyVelocity.MaxForce = Vector3.new(50000, 50000, 50000, 0)

									if (not wingDash or pressureForwarding) and cameraLookVectorVel.Y > 0 then
										cameraLookVectorVel = cameraLookVectorVel * Vector3.new(1, 0.5, 1, 0)
									end

									usedBodyVelocity.Velocity = cameraLookVectorVel
								end

								if
									rollTime < tick() - rollStart
									or not usedBodyVelocity
									or not usedBodyVelocity.Parent
									or not inAirCheck()
									or root:FindFirstChild("GravBV")
								then
									break
								end
							end
						end

						clientAirDodge:Remove()
						usedRollTrack:Stop()

						if tick() - rollStart < rollTime then
							effectReplicatorModule:CreateEffect("ForceSlide", {
								Debris = 0.3,
							})

							humanoid:LoadAnimation(inputClient.LandingAnim):Play()

							local forcedBodyVelocity = Instance.new("BodyVelocity")
							forcedBodyVelocity:AddTag("AllowedBM")
							forcedBodyVelocity.MaxForce = Vector3.new(50000, 0, 50000, 0)
							forcedBodyVelocity.Velocity = root.CFrame.LookVector * 60
							forcedBodyVelocity.Parent = root
							repDebris:Fire(forcedBodyVelocity, 0.2)
						end
					else
						usedBodyVelocity = Instance.new("LinearVelocity")
						usedBodyVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
						usedBodyVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
						usedBodyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
						usedBodyVelocity.VectorVelocity = moveDirection * usedAgility
						usedBodyVelocity.MaxAxesForce = Vector3.new(8000, 8000, 8000, 0)
						usedBodyVelocity.Attachment0 = rootAttachment
						usedBodyVelocity.Name = pressureForwarding and "EasyCancel" or "Mover"
						usedBodyVelocity:AddTag("AllowedBM")
						usedBodyVelocity.Parent = rootAttachment

						repDebris:Fire(usedBodyVelocity, rollTime)
						moveDirection = moveDirection * Vector3.new(1, 0, 1, 0)

						local maxAxesForce = usedBodyVelocity.MaxAxesForce
						local rootVelocity = moveDirection * usedAgility

						if groundSensor then
							local sensedPart = groundSensor.SensedPart

							if sensedPart and sensedPart.AssemblyMass > root.AssemblyMass then
								rootVelocity = rootVelocity
									+ vectorMathModule.getVelocityAtPoint(sensedPart, groundSensor.HitFrame.Position)
							end

							rootVelocity = (CFrame.lookAlong(
								Vector3.new(0, 0, 0, 0),
								groundSensor.HitNormal,
								(Vector3.new(0, 0, 1, 0))
							) * CFrame.Angles(-1.5707963267948966, 0, 0)).Rotation:VectorToWorldSpace(
								rootVelocity
							)
						end

						root.AssemblyLinearVelocity = rootVelocity
						usedBodyVelocity.VectorVelocity = rootVelocity

						repeat
							task.wait()

							if effectReplicatorModule:HasEffect("MantraCasted") and usedRollTrack.IsPlaying then
								usedRollTrack:Stop(0)
							end

							if not noAirPenalty and inAirCheck() then
								noAirPenalty = true
								usedAgility = usedAgility - 10
							end

							local effectCancel = effectReplicatorModule:FindEffect("Feint")
								or effectReplicatorModule:HasEffect("ClientFeint")
								or effectReplicatorModule:HasEffect("Parry")
								or effectReplicatorModule:HasEffect("Parried")
								or effectReplicatorModule:HasEffect("DodgedFrame")

							local hasAttackAny = effectReplicatorModule:HasAny("LightAttack", "UsingAbility")
									and not effectReplicatorModule:HasEffect("PressureForwarding")
								or effectReplicatorModule:HasEffect("CastingSpell")
								or effectReplicatorModule:HasEffect("UsingSpell")

							if options.actionRolling then
								hasAttackAny = false
							end

							local rollCancelInvoke = (
								options.rollCancel and tick() - rollStart > options.rollCancelDelay
							)

							if effectCancel or hasAttackAny or rollCancelInvoke then
								stopDodge:FireServer(inputData, effectReplicatorModule:HasEffect("LightAttack"))

								if usedRollTrack.IsPlaying then
									usedRollTrack:Stop(0)
								end

								if
									(
										effectReplicatorModule:FindEffect("Feint")
										or effectReplicatorModule:HasEffect("ClientFeint")
										or rollCancelInvoke
									)
									and not cancelLeftTrack.IsPlaying
									and not cancelRightTrack.IsPlaying
								then
									if inputData.A then
										cancelLeftTrack:Play(0.1)
									else
										cancelRightTrack:Play(0.1)
									end
								end

								if effectCancel then
									giveRollCancelFatigue = true
								else
									giveRollCancelFatigue = "mantra"
									break
								end
							end

							if usedBodyVelocity and usedBodyVelocity.Parent then
								local innerMoveDirection = humanoid.MoveDirection

								if innerMoveDirection.Magnitude < 0.1 then
									innerMoveDirection = moveDirection
								end

								moveDirection = innerMoveDirection

								if giveRollCancelFatigue == true and usedAgility >= 30 then
									usedAgility = usedAgility - 10
								end

								local vecVelocity = moveDirection * usedAgility

								maxAxesForce = Vector3.new(8000, 8000, 8000, 0)

								if groundSensor then
									local sensedPart = groundSensor.SensedPart
									if sensedPart then
										if sensedPart.AssemblyMass > root.AssemblyMass then
											vecVelocity = vecVelocity
												+ vectorMathModule.getVelocityAtPoint(
													sensedPart,
													groundSensor.HitFrame.Position
												)
										end

										vecVelocity = (CFrame.lookAlong(
											Vector3.new(0, 0, 0, 0),
											groundSensor.HitNormal,
											(Vector3.new(0, 0, 1, 0))
										) * CFrame.Angles(-1.5707963267948966, 0, 0)).Rotation:VectorToWorldSpace(
											vecVelocity
										)
									else
										maxAxesForce = maxAxesForce * Vector3.new(1, 0, 1, 0)
									end
								end

								if root.AssemblyLinearVelocity.Unit:Angle(vecVelocity.Unit) > 0.17453292519943295 then
									maxAxesForce = maxAxesForce * 5
								end

								if
									workspace:Raycast(
										root.Position,
										root.AssemblyLinearVelocity.Unit,
										collisionUtilsModule.solidParams
									)
								then
									maxAxesForce = maxAxesForce
										* Vector3.new(0.800000011920929, 1, 0.800000011920929, 0)
								end

								usedBodyVelocity.MaxAxesForce = maxAxesForce
								usedBodyVelocity.VectorVelocity = vecVelocity
							end
						until rollTime < tick() - rollStart
							or not usedBodyVelocity
							or not usedBodyVelocity.Parent
							or root:FindFirstChild("GravBV")
							or effectReplicatorModule:HasEffect("CancelDodge")
							or pressureForwarding and effectReplicatorModule:FindEffect("Parried")
					end

					clientEffectDirect:Fire("footprintCheck", {
						char = character,
						strength = 1.5,
					})

					if pressureForwarding or inArcDash then
						usedRollTrack:Stop()
					end

					if usedBodyVelocity then
						usedBodyVelocity:Destroy()
					end

					if giveRollCancelFatigue then
						local hrpVelocity = Vector3.new(0, 0, 0, 0)
						local sensedPart = groundSensor.SensedPart

						if sensedPart and sensedPart.AssemblyMass > root.AssemblyMass then
							hrpVelocity = hrpVelocity
								+ vectorMathModule.getVelocityAtPoint(sensedPart, groundSensor.HitFrame.Position)
						end

						local assemblyLinearVelocity = root.AssemblyLinearVelocity
						root.AssemblyLinearVelocity =
							Vector3.new(hrpVelocity.X, assemblyLinearVelocity.Y, hrpVelocity.Z)
					end

					local timeout = 1.3

					if
						effectReplicatorModule:HasEffect("RollCancelFatigue")
						and (
							effectReplicatorModule:HasEffect("DownComesTheClaw") or not characterHashData["Tap Dancer"]
						)
					then
						timeout = 1.8
					end

					if characterHashData["Volt Reflex"] then
						timeout = 2.22
					end

					if
						giveRollCancelFatigue
						and not effectReplicatorModule:HasEffect("RollCancelFatigue")
						and not effectReplicatorModule:HasEffect("DownComesTheClaw")
						and not airDash
					then
						effectReplicatorModule:CreateEffect("RollCancelFatigue"):Debris(timeout)
						timeout = 0
					end

					if effectReplicatorModule:HasEffect("DanceBlade") then
						timeout = 0
					end

					local startTime = tick()

					if timeout > 0 then
						local ticker = 0

						repeat
							task.wait()
							ticker = ticker + 0.1
						until timeout <= tick() - startTime
							or effectReplicatorModule:HasEffect("DanceBlade")
							or effectReplicatorModule:HasEffect("PivotStepRESET")
					end

					dashIt:Remove()
					freefallCheck()
					noRoll:Remove()

					if effectReplicatorModule:HasEffect("Overcharge") then
						effectReplicatorModule:RemoveEffectsOfClass("Overcharge")
					end
				end)
			end
		end
	end
end)

---Jump end function.
InputClient.ejump = LPH_NO_VIRTUALIZE(function()
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return Logger.warn("Cannot dodge without effect replicator.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return Logger.warn("Cannot dodge without effect replicator module.")
	end

	if not jumpAnimTrack then
		return Logger.warn("Cannot jump without jump animation track.")
	end

	local character = players.LocalPlayer.Character
	if not character then
		return Logger.warn("Cannot jump without character.")
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return Logger.warn("Cannot jump without humanoid root part.")
	end

	local characterHandler = character:FindFirstChild("CharacterHandler")
	if not characterHandler then
		return Logger.warn("Cannot jump without character handler.")
	end

	local requests = characterHandler:FindFirstChild("Requests")
	if not requests then
		return Logger.warn("Cannot jump without requests.")
	end

	local jumpRemote = requests:FindFirstChild("Jump")
	if not jumpRemote then
		return Logger.warn("Cannot jump without jump remote.")
	end

	effectReplicatorModule:CreateEffect("Jumped"):Debris(0.1)
	jumpAnimTrack:Play(0.05)

	if effectReplicatorModule:HasEffect("HasWeapon") then
		jumpAnimTrack.Priority = Enum.AnimationPriority.Idle
	else
		jumpAnimTrack.Priority = Enum.AnimationPriority.Movement
	end

	TaskSpawner.delay("InputClient_EJump_Track", function()
		return 0.4
	end, function()
		jumpAnimTrack:AdjustSpeed(0.5)
		jumpAnimTrack:Stop(0.1)
	end)

	TaskSpawner.spawn("InputClient_EJump_Loop", function()
		local start = os.clock()

		while task.wait() do
			if os.clock() - start >= 0.2 then
				break
			end

			if not jumpAnimTrack or not jumpAnimTrack.IsPlaying then
				break
			end

			jumpRemote:FireServer()
		end
	end)
end)

---Re-created feint function.
InputClient.feint = LPH_NO_VIRTUALIZE(function()
	local character = players.LocalPlayer.Character
	if not character then
		return Logger.warn("Cannot feint without character.")
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return Logger.warn("Cannot feint without humanoid root part.")
	end

	local characterHandler = character:FindFirstChild("CharacterHandler")
	if not characterHandler then
		return Logger.warn("Cannot feint without character handler.")
	end

	local requests = characterHandler:FindFirstChild("Requests")
	if not requests then
		return Logger.warn("Cannot feint without requests.")
	end

	local feintReleaseRemote = requests:FindFirstChild("FeintRelease")
	if not feintReleaseRemote then
		return Logger.warn("Cannot feint without feint release remote.")
	end

	local inputDataTable = InputClient.getInputData()
	if not inputDataTable then
		return Logger.warn("Cannot feint without input data.")
	end

	local feintClickRemote = KeyHandling.getRemote("FeintClick")
	if not feintClickRemote then
		return Logger.warn("Cannot feint without feint click remote.")
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return Logger.warn("Cannot dodge without effect replicator.")
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return Logger.warn("Cannot dodge without effect replicator module.")
	end

	-- ClientFeint inlined
	if effectReplicatorModule:HasEffect("ClientDodge") then
		effectReplicatorModule:CreateEffect("ClientFeint"):Debris(0.4)
	end

	if humanoidRootPart:FindFirstChild("ClientRemove") then
		humanoidRootPart.ClientRemove:Destroy()
	end

	inputDataTable["Right"] = true

	feintClickRemote:FireServer(inputDataTable)

	feintReleaseRemote:FireServer(inputDataTable)

	inputDataTable["Right"] = false
end)

---Cache InputClient module. Returns whether the caching was a success or not.
---@note: I sold my soul to the GC gods because there's no other way. This basically does a ton of intensive stuff. Updates are only done when needed.
InputClient.cache = LPH_NO_VIRTUALIZE(function()
	-- Invalidate previous cache.
	InputClient.sprintFunctionCache = nil
	InputClient.rollFunctionCache = nil
	inputDataCache = nil

	-- Intercept new Sprint and Roll functions.
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

		local upvalues = debug.getupvalues(value)

		if not upvalues or #upvalues <= 0 then
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

	-- Store input data.
	local inputData = {}

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
		if not manualTableFind(consts, ".lastHBCheck") then
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
	inputDataCache = inputData

	-- Perform caching.
	local assets = replicatedStorage:FindFirstChild("Assets")
	local anims = assets and assets:FindFirstChild("Anims")
	local movement = anims and anims:FindFirstChild("Movement")
	local roll = movement and movement:FindFirstChild("Roll")
	local cancelLeft = roll and roll:FindFirstChild("CancelLeft")
	local cancelRight = roll and roll:FindFirstChild("CancelRight")

	local character = players.LocalPlayer.Character
	local characterHandler = character and character:FindFirstChild("CharacterHandler")
	local inputClient = characterHandler and characterHandler:FindFirstChild("InputClient")
	local freefallAnim = inputClient and inputClient:FindFirstChild("FreefallAnim")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local slideJumpAnim = inputClient and inputClient:FindFirstChild("SlideJump")
	local jumpAnim = inputClient and inputClient:FindFirstChild("Jump")

	if not slideJumpAnim or not jumpAnim or not humanoid or not cancelLeft or not cancelRight or not freefallAnim then
		return false
	end

	slideJumpTrack = humanoid:LoadAnimation(slideJumpAnim)
	freefallTrack = humanoid:LoadAnimation(freefallAnim)
	cancelLeftTrack = humanoid:LoadAnimation(cancelLeft)
	cancelRightTrack = humanoid:LoadAnimation(cancelRight)
	jumpAnimTrack = humanoid:LoadAnimation(jumpAnim)

	-- Return whether we were successful.
	return InputClient.sprintFunctionCache ~= nil and InputClient.rollFunctionCache ~= nil and inputDataCache ~= nil
end)

-- Return InputClient module.
return InputClient
