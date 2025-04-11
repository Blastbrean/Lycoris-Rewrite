---@module Features.Visuals.Objects.InstanceESP
local InstanceESP = require("Features/Visuals/Objects/InstanceESP")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.PlayerScanning
local PlayerScanning = require("Game/PlayerScanning")

---@class PlayerESP: InstanceESP
---@field baseLabel string
---@field player Player
---@field character Model
---@field identifier string
---@field shadow Part
local PlayerESP = setmetatable({}, { __index = InstanceESP })
PlayerESP.__index = PlayerESP
PlayerESP.__type = "PlayerESP"

-- Services.
local players = game:GetService("Players")

-- Formats.
local ESP_HEALTH = "[%i/%i]"
local ESP_POWER = "[Power %i]"
local ESP_TEMPO = "[%i%% tempo]"
local ESP_BLOOD = "[%i%% blood]"
local ESP_POSTURE = "[%i%% posture]"
local ESP_VIEW_ANGLE = "[%.2f view angle vs. %.2f]"
local ESP_HEALTH_PERCENTAGE = "[%i%% health]"
local ESP_HEALTH_BARS = "[%.1f bars]"
local ESP_DANGER_TIME = "[%s on timer]"

---Update PlayerESP.
PlayerESP.update = LPH_NO_VIRTUALIZE(function(self)
	local model = self.character
	local player = self.player
	local identifier = self.identifier

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return self:visible(false)
	end

	local level = model:GetAttribute("Level") or -1
	local playerNameType = Configuration.idOptionValue(identifier, "PlayerNameType")
	local playerName = "Unknown Player"

	if playerNameType == "Character Name" then
		playerName = player:GetAttribute("CharacterName")
	elseif playerNameType == "Roblox Display Name" then
		playerName = player.DisplayName
	elseif playerNameType == "Roblox Username" then
		playerName = player.Name
	end

	if Configuration.expectToggleValue("InfoSpoofing") and Configuration.expectToggleValue("SpoofOtherPlayers") then
		playerName = "Linoria V2 On Top"
	end

	self.label = playerName

	local health = humanoid.Health
	local maxHealth = humanoid.MaxHealth

	local tags = { ESP_HEALTH:format(health or -1, maxHealth or -1), ESP_POWER:format(level) }

	if Configuration.idToggleValue(identifier, "ShowTempo") then
		local tempoValue = model:FindFirstChild("Tempo")
		local percentage = tempoValue and (tempoValue.Value / tempoValue.MaxValue * 100)
		tags[#tags + 1] = tempoValue and ESP_TEMPO:format(percentage) or "[Unknown Tempo]"
	end

	if Configuration.idToggleValue(identifier, "ShowBlood") then
		local bloodValue = model:FindFirstChild("Blood")
		local percentage = bloodValue and (bloodValue.Value / bloodValue.MaxValue * 100)
		tags[#tags + 1] = bloodValue and ESP_BLOOD:format(percentage) or "[Unknown Blood]"
	end

	if Configuration.idToggleValue(identifier, "ShowPosture") then
		local breakMeterValue = model:FindFirstChild("BreakMeter")
		local percentage = breakMeterValue and (breakMeterValue.Value / breakMeterValue.MaxValue * 100)
		tags[#tags + 1] = breakMeterValue and ESP_POSTURE:format(percentage) or "[Unknown Posture]"
	end

	if Configuration.idToggleValue(identifier, "ShowHealthPercentage") then
		local percentage = health / maxHealth * 100
		tags[#tags + 1] = ESP_HEALTH_PERCENTAGE:format(percentage)
	end

	if Configuration.idToggleValue(identifier, "ShowHealthBars") then
		local healthPercentage = health / maxHealth
		local healthInBars = math.clamp(healthPercentage / 0.20, 0, 5)
		tags[#tags + 1] = ESP_HEALTH_BARS:format(healthInBars)
	end

	local modelPosition = model:GetPivot().Position
	local predictedPosition = nil
	local usedPosition = nil

	local mapPosition = model:GetAttribute("MapPos")
	local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")

	if not humanoidRootPart then
		predictedPosition = mapPosition and Vector3.new(mapPosition.X, modelPosition.Y, mapPosition.Z) or nil
		tags[#tags + 1] = mapPosition and "[Unknown Height]" or "[Not Loaded]"
	end

	usedPosition = predictedPosition or modelPosition

	local currentCamera = workspace.CurrentCamera
	local character = players.LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if Configuration.idToggleValue(identifier, "ShowViewAngle") and rootPart then
		tags[#tags + 1] = ESP_VIEW_ANGLE:format(
			currentCamera.CFrame.LookVector:Dot((rootPart.Position - usedPosition).Unit) * -1,
			math.cos(math.rad((Configuration.expectOptionValue("FOVLimit"))))
		)
	end

	local dangerTime = humanoid:GetAttribute("DangerExpiration")
	local dangerTimeLeft = dangerTime and math.ceil(dangerTime - workspace:GetServerTimeNow())

	if Configuration.idToggleValue(identifier, "ShowDangerTime") and dangerTimeLeft and dangerTimeLeft >= 0 then
		tags[#tags + 1] = ESP_DANGER_TIME:format(
			dangerTimeLeft >= 60 and os.date("%Mm %Ss", dangerTimeLeft) or os.date("%Ss", dangerTimeLeft)
		)
	end

	self.shadow.Position = usedPosition

	local expectedAdornee = predictedPosition and self.shadow or model

	if expectedAdornee == nil or not expectedAdornee.Parent or not expectedAdornee.Parent:IsDescendantOf(game) then
		return self:visible(false)
	end

	---@note: BillboardGUIs only update when a property of it changes.
	if self.billboard.Adornee ~= expectedAdornee then
		self.billboard.Adornee = expectedAdornee
	end

	InstanceESP.update(self, usedPosition, tags)

	if not Configuration.idToggleValue(identifier, "MarkAllies") then
		return
	end

	if not PlayerScanning.isAlly(player) then
		return
	end

	self.text.TextColor3 = Configuration.idOptionValue(identifier, "AllyColor")
end)

---Create new PlayerESP object.
---@param identifier string
---@param player Player
---@param character Model
function PlayerESP.new(identifier, player, character)
	local shadow = Instance.new("Part")
	shadow.Transparency = 1.0
	shadow.Parent = game:GetService("CoreGui")

	local self = setmetatable(InstanceESP.new(shadow, identifier, "Unknown Player"), PlayerESP)
	self.player = player
	self.character = character
	self.identifier = identifier
	self.shadow = self.maid:mark(shadow)

	if character and character:IsA("Model") and not Configuration.expectOptionValue("NoPersisentESP") then
		character.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end

	return self
end

-- Return PlayerESP module.
return PlayerESP
