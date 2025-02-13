-- Player scanning is handled here.
local PlayerScanning = {
	scanQueue = {},
	scanDataCache = {},
	friendCache = {},
	waitingForLoad = {},
	scanning = false,
}

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Services.
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")
local collectionService = game:GetService("CollectionService")
local runService = game:GetService("RunService")

-- Maid.
local playerScanningMaid = Maid.new()

-- Timestamp.
local lastRateLimit = nil

---Run player scans.
local function runPlayerScans()
	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	for player, _ in next, PlayerScanning.scanQueue do
		if not PlayerScanning.scanDataCache[player] then
			local success, result = pcall(PlayerScanning.getStaffRank, player)

			if not success then
				if result:match("Rate-limited.") then
					continue
				end

				if result:match("On rate-limit cooldown.") then
					continue
				end

				Logger.warn("Scan player %s ran into error '%s' while getting staff rank.", player.Name, result)

				Logger.longNotify("Failed to scan player %s for moderator status.", player.Name, result)

				PlayerScanning.scanQueue[player] = nil

				continue
			end

			if Configuration.expectToggleValue("NotifyMod") and result then
				local moderatorSound = Instance.new("Sound", game:GetService("CoreGui"))
				moderatorSound.SoundId = "rbxassetid://6045346303"
				moderatorSound.PlaybackSpeed = 1
				moderatorSound.Volume = 10
				moderatorSound.PlayOnRemove = true
				moderatorSound:Destroy()

				Logger.longNotify("%s is a staff member with the rank '%s' in group.", player.Name, result)
			end

			PlayerScanning.scanDataCache[player] = { staffRank = result }
		end

		local backpack = player:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		if not collectionService:HasTag(backpack, "Loaded") or #backpack:GetChildren() < 1 then
			if not PlayerScanning.waitingForLoad[player] then
				Logger.warn("Player scanning is waiting for %s to load in the game.", player.Name)
			end

			PlayerScanning.waitingForLoad[player] = true

			continue
		end

		if
			Configuration.expectToggleValue("NotifyVoidWalker")
			and backpack:FindFirstChild("Talent:Voidwalker Contract")
		then
			Logger.longNotify("%s has the Voidwalker Contract talent.", player.Name)
		end

		if Configuration.expectToggleValue("NotifyMythic") then
			for _, tool in next, backpack:GetChildren() do
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

				local toolEnchantTag = nil

				if not toolEnchant or toolEnchant == "" then
					toolEnchantTag = "[No Enchant]"
				else
					toolEnchantTag = string.format("[%s Enchant]", toolEnchant)
				end

				local toolQualityTag = string.format("[%i Stars]", toolQuality)

				if toolQuality == 0 then
					toolQualityTag = "[No Stars]"
				end

				Logger.longNotify(
					"%s has the Legendary Weapon '%s' %s %s and it is non-soulbound.",
					player.Name,
					toolName,
					toolQualityTag,
					toolEnchantTag
				)
			end
		end

		PlayerScanning.scanQueue[player] = nil

		PlayerScanning.friendCache[player] = localPlayer:GetFriendStatus(player) == Enum.FriendStatus.Friend

		Logger.warn("Player scanning finished scanning %s in queue.", player.Name)
	end
end

---Are there moderators in the server?
---@return table
function PlayerScanning.hasModerators()
	for _, scanData in next, PlayerScanning.scanDataCache do
		if not scanData.staffRank then
			continue
		end

		return true
	end

	return false
end

---Is a player an ally?
---@param player Player
---@return boolean
function PlayerScanning.isAlly(player)
	return PlayerScanning.friendCache[player]
		or player:GetAttribute("Guild") == players.LocalPlayer:GetAttribute("Guild")
end

---Fetch roblox data.
---@param url string
---@return table
local function fetchRobloxData(url)
	if lastRateLimit and os.clock() - lastRateLimit <= 30 then
		return error("On rate-limit cooldown.")
	end

	local response = request({
		Url = url,
		Method = "GET",
		Headers = {
			["Content-Type"] = "application/json",
		},
	})

	if response.StatusCode == 429 then
		Logger.longNotify("Player scanning is being rate-limited and results will be delayed.")
		Logger.longNotify("Please stay in the server with caution.")

		lastRateLimit = os.clock()

		return error("Rate-limited.")
	end

	if not response then
		return error("Failed to fetch Roblox data.")
	end

	if not response.Success then
		return error(
			string.format("Failed to successfully fetch Roblox data with status code %i.", response.StatusCode)
		)
	end

	if not response.Body then
		return error("Failed to find Roblox data.")
	end

	return httpService:JSONDecode(response.Body)
end

---Get staff rank - nil if they're not a staff.
---@param player Player
---@return string?
function PlayerScanning.getStaffRank(player)
	local responseData =
		fetchRobloxData(("https://groups.roblox.com/v2/users/%i/groups/roles?includeLocked=true"):format(player.UserId))

	for _, groupData in next, responseData.data do
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

---Update player scanning.
---@note: Request will yield - so we need a debounce to prevent multiple scan loops.
---@note: We must defer the error back to the caller and reset the scanning debounce so errors will not break the scanning loop.
function PlayerScanning.update()
	if PlayerScanning.scanning then
		return
	end

	PlayerScanning.scanning = true

	local success, result = pcall(runPlayerScans)

	PlayerScanning.scanning = false

	if success then
		return
	end

	return error(result)
end

---On friend status changed.
---@param player Player
---@param status Enum.FriendStatus
function PlayerScanning.friend(player, status)
	PlayerScanning.friendCache[player] = status == Enum.FriendStatus.Friend
end

---On player added.
---@param player Player
function PlayerScanning.onPlayerAdded(player)
	if player == players.LocalPlayer then
		return
	end

	PlayerScanning.scanQueue[player] = true
end

---On player removing.
---@param player Player
function PlayerScanning.onPlayerRemoving(player)
	PlayerScanning.scanQueue[player] = nil
	PlayerScanning.scanDataCache[player] = nil
	PlayerScanning.friendCache[player] = nil
	PlayerScanning.waitingForLoad[player] = nil
end

---Initialize PlayerScanning.
function PlayerScanning.init()
	-- Signals.
	local playerAddedSignal = Signal.new(players.PlayerAdded)
	local playerRemovingSignal = Signal.new(players.PlayerRemoving)
	local renderSteppedSignal = Signal.new(runService.RenderStepped)
	local friendStatusChanged = Signal.new(players.LocalPlayer.FriendStatusChanged)

	-- Connect events.
	playerScanningMaid:add(friendStatusChanged:connect("PlayerScanning_OnFriendStatusChanged", PlayerScanning.friend))
	playerScanningMaid:add(renderSteppedSignal:connect("PlayerScanning_Update", PlayerScanning.update))
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
