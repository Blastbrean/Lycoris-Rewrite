-- Player scanning is handled here.
local PlayerScanning = { scanDataCache = {} }

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

-- Services.
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local collectionService = game:GetService("CollectionService")

-- Maid.
local playerScanningMaid = Maid.new()

---Fetch roblox data.
---@param url string
---@return table
local function fetchRobloxData(url)
	local response = nil

	while true do
		response = request({
			Url = url,
			Method = "GET",
			Headers = {
				["Content-Type"] = "application/json",
			},
		})

		if response.StatusCode ~= 429 then
			break
		end

		task.wait(30)
	end

	if not response or not response.Success or not response.Body then
		return error("Failed to fetch Roblox data.")
	end

	return httpService:JSONDecode(response.Body)
end

---Are there moderators in the server?
---@return table
function PlayerScanning.hasModerators()
	for _, scanData in next, PlayerScanning.scanDataCache do
		if not scanData.staffRank then
			continue
		end

		return false
	end

	return true
end

---Get staff rank - nil if they're not a staff.
---@param player Player
---@return string?
function PlayerScanning.getStaffRank(player)
	local responseData = fetchRobloxData({
		Url = ("https://groups.roblox.com/v2/users/%i/groups/roles?includeLocked=true"):format(player.UserId),
		Method = "GET",
		Headers = {
			["Content-Type"] = "application/json",
		},
	})

	for _, groupData in pairs(responseData.data) do
		if groupData.group.id ~= 5212858 then
			continue
		end

		if groupData.role.rank <= 0 then
			continue
		end

		return groupData.role.name
	end

	return nil
end

---On player added.
---@param player Player
function PlayerScanning.onPlayerAdded(player)
	if player == players.LocalPlayer then
		return
	end

	local success, staffRank = pcall(PlayerScanning.getStaffRank(player))
	if not success then
		return Logger.notify("Failed to get staff rank for %s - this server is potentially unsafe.", player.Name)
	end

	local scanData = { staffRank = staffRank }

	if Configuration.expectToggleValue("NotifyMod") and scanData.staffRank then
		local moderatorSound = Instance.new("Sound", game:GetService("CoreGui"))
		moderatorSound.SoundId = "rbxassetid://247824088"
		moderatorSound.PlaybackSpeed = 1
		moderatorSound.Volume = 5
		moderatorSound.PlayOnRemove = true
		moderatorSound:Destroy()

		Logger.notify("%s is a staff member with the rank %s.", player.Name, scanData.staffRank)
	end

	PlayerScanning.scanDataCache[player] = scanData

	repeat
		task.wait()
	until collectionService:HasTag(player.Backpack, "Loaded") and player.Backpack:GetChildren() >= 1

	if
		Configuration.expectToggleValue("NotifyVoidWalker")
		and player.Backpack:FindFirstChild("Talent:Voidwalker Contract")
	then
		Logger.notify("%s has the Voidwalker Contract talent.", player.Name)
	end

	if not Configuration.expectToggleValue("NotifyMythic") then
		return
	end

	for _, tool in next, player.Backpack:GetChildren() do
		if not tool:IsA("Tool") then
			continue
		end

		local rarity = tool:FindFirstChild("Rarity")
		if not rarity then
			continue
		end

		if rarity.Value ~= "Mythic" then
			continue
		end

		local weaponData = tool:FindFirstChild("WeaponData")
		if not weaponData then
			continue
		end

		local weaponDataJson = base64.decode(weaponData.Value):sub(1, #base64.decode(weaponData.Value) - 2)
		local weaponDataDecoded = httpService:JSONDecode(weaponDataJson)

		if weaponDataDecoded.SoulBound then
			continue
		end

		local toolName = tool.Name:split("$")[1]

		local toolQuality = tool:FindFirstChild("Quality") and tool.Quality.Value or 0
		local toolEnchant = tool:FindFirstChild("Enchant") and tool.Enchant.Value

		local toolEnchantTag = string.format("[%s Enchant]", toolEnchant)

		if not toolEnchant or toolEnchant == "" then
			toolEnchantTag = "[No Enchant]"
		end

		local toolQualityTag = string.format("[%i Stars]", toolQuality)

		if toolQuality == 0 then
			toolQualityTag = "[No Stars]"
		end

		Logger.notify(
			"%s has the Legendary Weapon %s %s %s and it is non-soulbound.",
			player.Name,
			toolName,
			toolQualityTag,
			toolEnchantTag
		)
	end
end

---On player removing.
---@param player Player
function PlayerScanning.onPlayerRemoving(player)
	PlayerScanning.scanDataCache[player] = nil
end

---Initialize PlayerScanning.
function PlayerScanning.init()
	-- Signals.
	local playerAddedSignal = Signal.new(players.PlayerAdded)
	local playerRemovingSignal = Signal.new(players.PlayerRemoving)

	-- Connect events.
	playerScanningMaid:add(playerAddedSignal:connect("PlayerScanning_OnPlayerAdded", PlayerScanning.onPlayerAdded))
	playerScanningMaid:add(
		playerRemovingSignal:connect("PlayerScanning_OnPlayerRemoving", PlayerScanning.onPlayerRemoving)
	)

	-- Run event(s) for existing players.
	for _, player in next, players:GetPlayers() do
		PlayerScanning.onPlayerAdded(player)
	end
end

---Detach PlayerScanning.
function PlayerScanning.detach()
	playerScanningMaid:clean()
end

-- Return PlayerScanning module.
return PlayerScanning
