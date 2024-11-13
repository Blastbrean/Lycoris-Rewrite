-- Astral farming.
local AstralFarm = {}

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Game.PlayerScanning
local PlayerScanning = require("Game/PlayerScanning")

---@module Game.ServerLeaving
local ServerLeaving = require("Game/ServerLeaving")

---@module Utility.InstanceWrapper
local InstanceWrapper = require("Utility/InstanceWrapper")

---@module Utility.SendInput
local SendInput = require("Utility/SendInput")

---@module Utility.Entitites
local Entitites = require("Utility/Entitites")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

-- Services.
local runService = game:GetService("RunService")
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Signals.
local runServiceHeartbeat = Signal.new(runService.Heartbeat)

-- Maid.
local astralFarmMaid = Maid.new()

---Carnivore stage.
---@param mob Model
---@param bodyVelocity BodyVelocity
local function carnivoreStage(mob, bodyVelocity)
	local localPlayer = playersService.LocalPlayer
	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local backpackWeapon = localPlayer.Backpack:FindFirstChild("Weapon")
	local characterWeapon = character:FindFirstChild("Weapon")

	if not backpackWeapon and not characterWeapon then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	if not characterWeapon then
		humanoid:EquipTool(backpackWeapon)
	end

	local mobHrp = mob:FindFirstChild("HumanoidRootPart")
	if not mobHrp then
		return
	end

	if (mobHrp.Position - rootPart.Position).Magnitude < 20 then
		bodyVelocity.Parent = nil

		local leftClick = KeyHandling.getRemote("LeftClick")
		if not leftClick then
			return
		end

		local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
		if not effectReplicator then
			return
		end

		local effectReplicatorModule = require(effectReplicator)
		if not effectReplicatorModule:FindEffect("LightAttack", true) then
			leftClick:FireServer(false, localPlayer:GetMouse().Hit, {})
		end

		if not effectReplicatorModule:FindEffect("CriticalCool") then
			SendInput.key(Enum.KeyCode.R)
		end
	else
		local cframeTowardsMob = CFrame.new(rootPart.Position, mobHrp.Position)
		bodyVelocity.Velocity = cframeTowardsMob.LookVector * 60
		bodyVelocity.Parent = rootPart
	end
end

---Food stage.
---@param food Tool
local function foodStage(food)
	local character = playersService.LocalPlayer.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	if not character:FindFirstChild(food.Name) then
		humanoid:EquipTool(food)
	end

	SendInput.mb1(0, 50)
end

---Find food tool(s) in the inventory.
---@return Tool?
local function findFoodInInventory()
	local foodInstance = nil
	local localPlayer = playersService.LocalPlayer

	for _, instance in pairs(localPlayer.Backpack:GetChildren()) do
		if not instance:IsA("Tool") then
			continue
		end

		if not instance:FindFirstChild("Food") then
			continue
		end

		if instance.Name == "Canteen" then
			continue
		end

		foodInstance = instance
	end

	return foodInstance
end

---Detect if a position is in the void sea.
---@return boolean
local function isInVoidSea(position)
	local replicatedInfo = replicatedStorage:FindFirstChild("Info")
	if not replicatedInfo then
		return error("no replicated info")
	end

	local realmInfo = replicatedInfo:FindFirstChild("RealmInfo")
	if not realmInfo then
		return error("no realm info")
	end

	local markerWorkspace = replicatedStorage:FindFirstChild("MarkerWorkspace")
	if not markerWorkspace then
		return error("no marker workspace")
	end

	local realmInfoModule = require(realmInfo)
	local realmInfoCurrentWorld = realmInfoModule.CurrentWorld
	local area = markerWorkspace:FindPartOnRayWithWhitelist(
		Ray.new(position, Vector3.new(0, 5000, 0)),
		{ markerWorkspace.AreaMarkers }
	)

	area = (area and area.Parent and area.Parent.Name) or nil

	local mapCentre = replicatedInfo:FindFirstChild("MAP_CENTRE")
	local mapBounds = replicatedInfo:FindFirstChild("MAP_BOUNDS")

	mapCentre = mapCentre and mapCentre.Value or Vector3.new()
	mapBounds = mapBounds and mapBounds.Value or Vector3.new(20000, 0, 20000)

	local deltaFromCenter = position - mapCentre
	local depthsCheck = position.Y < -100 and realmInfoCurrentWorld == "Depths" or false

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return error("no effect replicator")
	end

	local effectReplicatorModule = require(effectReplicator)
	if effectReplicatorModule:FindEffect("InGuildBase") then
		return false
	end

	return not depthsCheck
		and (
			(math.abs(deltaFromCenter.x) > mapBounds.X or math.abs(deltaFromCenter.z) > mapBounds.Z)
				and (not area or area ~= "The Floating Keep")
			or false
		)
end

---Astral farm loop.
local function astralFarmLoop()
	if not Configuration.expectToggleValue("AstralFarm") then
		return
	end

	local localPlayer = playersService.LocalPlayer

	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local stomach = character:FindFirstChild("Stomach")
	local water = character:FindFirstChild("Water")

	if not stomach or not water then
		return
	end

	if PlayerScanning.hasModerators() then
		return ServerLeaving.hopping and nil or ServerLeaving.hop()
	end

	local success, result = pcall(isInVoidSea, rootPart.Position)
	if not success or not result then
		return
	end

	local bodyVelocity = InstanceWrapper.create(astralFarmMaid, "AstralBodyVelocity", "BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(9e9, 0, 9e9)

	local isCarnivore = Configuration.expectToggleValue("AstralCarnivore")

	local foodPercentage = stomach.Value / stomach.MaxValue
	local waterPercentage = water.Value / water.MaxValue

	local foodThreshold = Options.AstralHungerLevel.Value / 100
	local waterThreshold = Options.AstralWaterLevel.Value / 100

	if foodPercentage <= foodThreshold and waterPercentage <= waterThreshold then
		local nearestMob = Entitites.findNearestMob()

		if isCarnivore and nearestMob then
			return carnivoreStage(nearestMob, bodyVelocity)
		end

		local heldTool = character:FindFirstChildOfClass("Tool")
		local food = heldTool and heldTool:FindFirstChild("Food") and heldTool or findFoodInInventory()

		if food then
			return foodStage()
		end
	end

	local bellMeteor = nil

	for _, instance in pairs(workspace.Thrown:GetChildren()) do
		if instance.Name ~= "BellMeteor" then
			continue
		end

		if Entitites.isNear(instance:GetPivot().Position) then
			continue
		end

		bellMeteor = instance
	end

	local distanceToMeteor = bellMeteor and (bellMeteor:GetPivot().Position - rootPart.Position).Magnitude or nil

	if not bellMeteor or distanceToMeteor.Magnitude > 2000 then
		bodyVelocity.Velocity = rootPart.CFrame.LookVector * (60 + Options.AstralSpeed.Value)
		bodyVelocity.Parent = rootPart
		return
	end

	local cframeTowardsBallMeteor = CFrame.new(rootPart.Position, bellMeteor:GetPivot().Position)
	bodyVelocity.Velocity = cframeTowardsBallMeteor.LookVector * 60
	bodyVelocity.Parent = rootPart

	if distanceToMeteor.Magnitude >= 30 then
		return
	end

	if Configuration.expectToggleValue("NotifyAstral") then
		request({
			Url = Options.AstralWebhook.Value,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = game:GetService("HttpService"):JSONEncode({
				content = "@everyone Astral meteor was found - pausing farm until it's toggled again.",
			}),
		})
	end

	Toggles.AstralFarm:SetValue(false)
end

---Toggle the automatic Astral Farm.
function AstralFarm.init()
	astralFarmMaid:add(runServiceHeartbeat:connect("AstralFarm_Loop", astralFarmLoop))
end

---Detach the Astral Farm.
function AstralFarm.detach()
	astralFarmMaid:clean()
end

-- Return AstralFarm module.
return AstralFarm
