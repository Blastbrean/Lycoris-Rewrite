-- Targeting module.
---@note: Glorified extended non-utility Entities file.
local Targeting = {}

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.PlayerScanning
local PlayerScanning = require("Game/PlayerScanning")

---@module Features.Combat.Objects.Target
local Target = require("Features/Combat/Objects/Target")

---@module Utility.Table
local Table = require("Utility/Table")

-- Services.
local players = game:GetService("Players")
local userInputService = game:GetService("UserInputService")

---Get a list of all viable targets.
---@return Target[]
function Targeting.viable()
	local live = workspace:FindFirstChild("Live")
	if not live then
		return {}
	end

	local localCharacter = players.LocalPlayer.Character
	if not localCharacter then
		return {}
	end

	local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return {}
	end

	local currentCamera = workspace.CurrentCamera
	if not currentCamera then
		return {}
	end

	local targets = {}

	for _, entity in next, live:GetChildren() do
		if entity == localCharacter then
			continue
		end

		local playerFromCharacter = players:GetPlayerFromCharacter(entity)
		if not playerFromCharacter and Configuration.expectToggleValue("IgnoreMobs") then
			continue
		end

		local humanoid = entity:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			continue
		end

		local rootPart = entity:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			continue
		end

		if humanoid.Health <= 0 then
			continue
		end

		local displayNameFound = playerFromCharacter
			and table.find(Configuration.expectOptionValue("UsernameList"), playerFromCharacter.DisplayName)

		local usernameFound = playerFromCharacter
			and table.find(Configuration.expectOptionValue("UsernameList"), playerFromCharacter.Name)

		if displayNameFound or usernameFound then
			continue
		end

		if PlayerScanning.isAlly(entity) and Configuration.expectToggleValue("IgnoreAllies") then
			continue
		end

		local fieldOfViewToEntity =
			currentCamera.CFrame.LookVector:Dot((localRootPart.Position - rootPart.Position).Unit)

		local fieldOfViewLimit = Configuration.expectOptionValue("FOVLimit")

		if fieldOfViewLimit <= 0 or (fieldOfViewToEntity * -1) <= math.cos(math.rad(fieldOfViewLimit)) then
			continue
		end

		local currentDistance = (rootPart.Position - localRootPart.Position).Magnitude
		if currentDistance > Configuration.expectOptionValue("DistanceLimit") then
			continue
		end

		local mousePosition = userInputService:GetMouseLocation()
		local unitRay = workspace.CurrentCamera:ScreenPointToRay(mousePosition.X, mousePosition.Y)
		local distanceToCrosshair = unitRay:Distance(rootPart.Position)

		targets[#targets + 1] =
			Target.new(entity, humanoid, rootPart, distanceToCrosshair, fieldOfViewToEntity, currentDistance)
	end

	return targets
end

---Get the best targets through sorting.
---@return Target[]
function Targeting.best()
	local targets = Targeting.viable()
	local sortType = Configuration.expectOptionValue("PlayerSelectionType")
	local sortFunction = nil

	if sortType == "Closest To Crosshair" then
		sortFunction = function(first, second)
			return first.dc < second.dc
		end
	end

	if sortType == "Closest In Distance" then
		sortFunction = function(first, second)
			return first.du < second.du
		end
	end

	if sortType == "Least Health" then
		sortFunction = function(first, second)
			return first.humanoid.Health < second.humanoid.Health
		end
	end

	table.sort(targets, sortFunction)

	return Table.slice(targets, 1, Configuration.expectOptionValue("MaxTargets"))
end

---Find our model from a list of best targets.
---@param model Model
---@return Target?
function Targeting.find(model)
	for _, target in next, Targeting.best() do
		if target.character ~= model then
			continue
		end

		return target
	end
end

-- Return Targeting module.
return Targeting
