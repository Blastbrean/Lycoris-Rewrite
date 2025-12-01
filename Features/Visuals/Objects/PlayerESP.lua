---@module Features.Visuals.Objects.EntityESP
local EntityESP = require("Features/Visuals/Objects/EntityESP")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.PlayerScanning
local PlayerScanning = require("Game/PlayerScanning")

---@class PlayerESP: EntityESP
local PlayerESP = setmetatable({}, { __index = EntityESP })
PlayerESP.__index = PlayerESP
PlayerESP.__type = "PlayerESP"

-- Formats.
local ESP_HEALTH = "[%i/%i]"
local ESP_POWER = "[Power %i]"
local ESP_DANGER_TIME = "[%s]"

---Check if a player has an oath.
---@return boolean
local hasOath = LPH_NO_VIRTUALIZE(function(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return false
	end

	for _, instance in next, backpack:GetChildren() do
		if not instance.Name:match("Oath") then
			continue
		end

		return true
	end

	return false
end)

---Update PlayerESP.
---@param self PlayerESP
PlayerESP.update = LPH_NO_VIRTUALIZE(function(self)
	local entity = self.entity
	local player = self.player
	local identifier = self.identifier

	local humanoid = entity:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return self:visible(false)
	end

	-- Update element visibility.
	local abar = self.abar
	local pbar = self.pbar
	local bbar = self.bbar
	local tbar = self.tbar
	local sbar = self.sbar

	abar.Visible = Configuration.idToggleValue(identifier, "ArmorBar")
	pbar.Visible = Configuration.idToggleValue(identifier, "PostureBar")
	bbar.Visible = Configuration.idToggleValue(identifier, "BloodBar")
	tbar.Visible = Configuration.idToggleValue(identifier, "TempoBar")
	sbar.Visible = Configuration.idToggleValue(identifier, "SanityBar")

	-- Update element information.
	local sanity = self.entity:FindFirstChild("Sanity")
	local tempo = self.entity:FindFirstChild("Tempo")
	local armor = self.entity:FindFirstChild("Armor")
	local blood = self.entity:FindFirstChild("Blood")
	local posture = self.entity:FindFirstChild("BreakMeter")

	if sbar then
		self.mbs(sbar, false, sanity and sanity.Value / sanity.MaxValue or 0.0)
	end

	if tbar then
		self.mbs(tbar, false, tempo and tempo.Value / tempo.MaxValue or 0.0)
	end

	if abar then
		self.mbs(abar, true, armor and armor.Value / armor.MaxValue or 0.0)
	end

	if bbar then
		self.mbs(bbar, false, blood and blood.Value / blood.MaxValue or 0.0)
	end

	if pbar then
		self.mbs(pbar, false, posture and posture.Value / posture.MaxValue or 0.0)
	end

	local level = entity:GetAttribute("Level") or -1
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

	local tags = { ESP_HEALTH:format(humanoid.Health or -1, humanoid.MaxHealth or -1), ESP_POWER:format(level) }

	local dangerTime = humanoid:GetAttribute("DangerExpiration")
	local dangerTimeLeft = dangerTime and math.ceil(dangerTime - workspace:GetServerTimeNow())

	if Configuration.idToggleValue(identifier, "ShowDangerTime") and dangerTimeLeft and dangerTimeLeft >= 0 then
		tags[#tags + 1] = ESP_DANGER_TIME:format(
			dangerTimeLeft >= 60 and os.date("%Mm %Ss", dangerTimeLeft) or os.date("%Ss", dangerTimeLeft)
		)
	end

	EntityESP.update(self, tags)

	local label = self.ncontainer:FindFirstChildOfClass("TextLabel")
	if not label then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end

	if Configuration.idToggleValue(identifier, "MarkOathUsers") and hasOath(player) then
		label.TextColor3 = Configuration.idOptionValue(identifier, "OathColor")
	end

	if Configuration.idToggleValue(identifier, "MarkAllies") and PlayerScanning.isAlly(player) then
		label.TextColor3 = Configuration.idOptionValue(identifier, "AllyColor")
	end

	local dlabel = self.dcontainer:FindFirstChildOfClass("TextLabel")
	if dlabel then
		dlabel.TextColor3 = label.TextColor3
	end
end)

---Add extra elements.
PlayerESP.extra = LPH_NO_VIRTUALIZE(function(self)
	self.abar = self:add("ArmorBar", "left", 6, function(container)
		self:cgb(container, false, true, Color3.new(0.00784314, 0.65098, 1))
	end)

	self.pbar = self:add("PostureBar", "bottom", 3, function(container)
		self:cgb(container, false, false, Color3.new(0.952941, 1, 0.0235294))
	end)

	self.bbar = self:add("BloodBar", "bottom", 3, function(container)
		self:cgb(container, false, false, Color3.new(1, 0, 0.0156863))
	end)

	self.tbar = self:add("TempoBar", "bottom", 3, function(container)
		self:cgb(container, false, false, Color3.new(1, 0.54902, 0))
	end)

	self.sbar = self:add("SanityBar", "bottom", 3, function(container)
		self:cgb(container, false, false, Color3.new(0, 0.0509804, 1))
	end)
end)

---Create new PlayerESP object.
---@param identifier string
---@param player Player
---@param character Model
function PlayerESP.new(identifier, player, character)
	local self = setmetatable(EntityESP.new(character, identifier, "Unknown Player"), PlayerESP)
	self.player = player
	self.identifier = identifier

	if character and character:IsA("Model") and not Configuration.expectOptionValue("NoPersisentESP") then
		character.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end

	self:setup()
	self:build()
	self:update()

	return self
end

-- Return PlayerESP module.
return PlayerESP
