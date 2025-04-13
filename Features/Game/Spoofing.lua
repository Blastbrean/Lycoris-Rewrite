return LPH_NO_VIRTUALIZE(function()
	---@module Utility.Maid
	local Maid = require("Utility/Maid")

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.Configuration
	local Configuration = require("Utility/Configuration")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	---@module Utility.OriginalStoreManager
	local OriginalStoreManager = require("Utility/OriginalStoreManager")

	-- Spoofing module.
	---@note: Replace (e.g Konga Clutch Ring Spoofer) with Talent Spoofer & Instance Spoofer in the future.
	local Spoofing = { force = false }

	-- Services.
	local runService = game:GetService("RunService")
	local starterGui = game:GetService("StarterGui")
	local players = game:GetService("Players")
	local collectionService = game:GetService("CollectionService")
	local replicatedStorage = game:GetService("ReplicatedStorage")

	-- Signals.
	local renderStepped = Signal.new(runService.RenderStepped)

	-- Maid.
	local spoofingMaid = Maid.new()

	-- Original store managers.
	local infoSpoofMap = spoofingMaid:mark(OriginalStoreManager.new())

	-- Konga's clutch ring instance.
	local fakeKongaClutchRing = Instance.new("Folder")
	fakeKongaClutchRing.Name = "Ring:Konga's Clutch Ring"

	-- Freestyler's band instance.
	local fakeFreestylerBand = Instance.new("Folder")
	fakeFreestylerBand.Name = "Ring:Freestyler's Band"

	-- Timestamp.
	local lastTimestampRun = os.clock()

	-- Variables.
	local originalTags = nil

	-- Constants.
	local EXPECTED_EMOTE_CHILDREN = 20 + 1
	local EMOTE_SPOOFER_TAGS = {
		"EmotePack1",
		"EmotePack2",
		"MetalBadge",
	}

	---Update emote spoofer.
	local function updateEmoteSpoofer()
		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return
		end

		local playerGui = localPlayer.PlayerGui
		if not playerGui then
			return
		end

		local gestureGui = playerGui:FindFirstChild("GestureGui")
		if not gestureGui then
			return
		end

		local mainFrame = gestureGui:FindFirstChild("MainFrame")
		local gestureScroll = mainFrame and mainFrame:FindFirstChild("GestureScroll")
		if not gestureScroll then
			return
		end

		local starterGestureGui = starterGui:FindFirstChild("GestureGui")
		if not starterGestureGui then
			return
		end

		if not originalTags then
			originalTags = localPlayer:GetTags()
		end

		for _, tag in next, EMOTE_SPOOFER_TAGS do
			if originalTags[tag] then
				continue
			end

			collectionService:AddTag(localPlayer, tag)
		end

		if #gestureScroll:GetChildren() >= EXPECTED_EMOTE_CHILDREN then
			return
		end

		gestureGui:Destroy()

		local newGestureGui = starterGestureGui:Clone()
		newGestureGui.Parent = playerGui
	end

	---Reset emote spoofer.
	local function resetEmoteSpoofer()
		if not originalTags then
			return
		end

		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return
		end

		for _, tag in next, EMOTE_SPOOFER_TAGS do
			if not originalTags[tag] then
				continue
			end

			collectionService:RemoveTag(localPlayer, tag)
		end
	end

	---Update freestyler band spoof.
	local function updateFreestylerBandSpoof()
		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return
		end

		local backpack = localPlayer:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		fakeFreestylerBand.Parent = backpack
	end

	---Update konga clutch ring spoof.
	local function updateKongaClutchRingSpoof()
		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return
		end

		local backpack = localPlayer:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		fakeKongaClutchRing.Parent = backpack
	end

	---On Player GUI descendant added.
	---@param instance Instance
	local function onPgDescendantAdded(instance)
		if
			instance.Name ~= "DeathID"
			and instance.Name ~= "KillerPlayer"
			and instance.Name ~= "KillerCharacter"
			and instance.Name ~= "Timestamp"
		then
			return
		end

		if not instance:IsA("TextLabel") and not instance:IsA("TextBox") then
			return
		end

		instance.Visible = not (
			Configuration.expectToggleValue("InfoSpoofing")
			and Configuration.expectToggleValue("HideDeathInformation")
		)
	end

	---Update death information spoof.
	local function updateDeathInformationSpoof()
		local localPlayer = players.LocalPlayer
		local playerGui = localPlayer:FindFirstChild("PlayerGui")
		if not playerGui then
			return
		end

		local killGui = playerGui:FindFirstChild("KillGui")
		if not killGui then
			return
		end

		local splash = killGui:FindFirstChild("Splash")
		if not splash then
			return
		end

		for _, descendant in next, splash:GetDescendants() do
			onPgDescendantAdded(descendant)
		end
	end

	---Update spoofing.
	local function updateSpoofing()
		if os.clock() - lastTimestampRun <= 2.0 then
			return
		end

		lastTimestampRun = os.clock()

		if Configuration.expectToggleValue("EmoteSpoofer") then
			updateEmoteSpoofer()
		else
			resetEmoteSpoofer()
		end

		if Configuration.expectToggleValue("FreestylersBandSpoof") then
			updateFreestylerBandSpoof()
		else
			fakeFreestylerBand.Parent = nil
		end

		if Configuration.expectToggleValue("KongaClutchRingSpoof") then
			updateKongaClutchRingSpoof()
		else
			fakeFreestylerBand.Parent = nil
		end

		if not Configuration.expectToggleValue("InfoSpoofing") then
			infoSpoofMap:restore()
		end

		updateDeathInformationSpoof()
	end

	---Spoof game version.
	---@param value string
	function Spoofing.sgv(value)
		local player = players.LocalPlayer
		if not player then
			return
		end

		local playerGui = player:FindFirstChild("PlayerGui")
		if not playerGui then
			return
		end

		local worldInfo = playerGui:FindFirstChild("WorldInfo")
		local infoFrame = worldInfo and worldInfo:FindFirstChild("InfoFrame")
		local gameInfo = infoFrame and infoFrame:FindFirstChild("GameInfo")
		if not gameInfo then
			return
		end

		local gameVersionLabel = gameInfo:FindFirstChild("GameVersion")
		if not gameVersionLabel then
			return
		end

		infoSpoofMap:add(gameVersionLabel, "Text", value)
	end

	---Spoof date string.
	---@param value string
	function Spoofing.sds(value)
		local player = players.LocalPlayer
		if not player then
			return
		end

		local playerGui = player:FindFirstChild("PlayerGui")
		if not playerGui then
			return
		end

		local worldInfo = playerGui:FindFirstChild("WorldInfo")
		local infoFrame = worldInfo and worldInfo:FindFirstChild("InfoFrame")
		local worldInfoFrame = infoFrame and infoFrame:FindFirstChild("WorldInfo")
		if not worldInfoFrame then
			return
		end

		local dateLabel = worldInfoFrame:FindFirstChild("Date")
		if not dateLabel then
			return
		end

		infoSpoofMap:add(dateLabel, "Text", value)
	end

	---Spoof slot string.
	---@param value string
	function Spoofing.sss(value)
		local player = players.LocalPlayer
		if not player then
			return
		end

		local playerGui = player:FindFirstChild("PlayerGui")
		if not playerGui then
			return
		end

		local worldInfo = playerGui:FindFirstChild("WorldInfo")
		local infoFrame = worldInfo and worldInfo:FindFirstChild("InfoFrame")
		local characterInfo = infoFrame and infoFrame:FindFirstChild("CharacterInfo")
		if not characterInfo then
			return
		end

		local slotLabel = characterInfo:FindFirstChild("Slot")
		if not slotLabel then
			return
		end

		infoSpoofMap:add(slotLabel, "Text", value)
	end

	---Fire attribute changed signal.
	---@param instance Instance
	---@param attribute string
	function Spoofing.facs(instance, attribute)
		local original = instance:GetAttribute(attribute)
		instance:SetAttribute(attribute, "SPOOFING_RICS")
		instance:SetAttribute(attribute, original)
	end

	---Fire changed signal for value.
	---@param instance ValueBase
	function Spoofing.fvcs(instance)
		local original = instance.Value
		instance.Value = "SPOOFING_RICS"
		instance.Value = original
	end

	---Refresh changed signals for information.
	---@note: Attempts to trigger them w/e using 'firesignal' or 'getconnections' because they crash.
	function Spoofing.rics()
		for _, player in next, players:GetPlayers() do
			Spoofing.facs(player, "Guild")
			Spoofing.facs(player, "FirstName")
			Spoofing.facs(player, "LastName")

			local character = player.Character
			if not character then
				continue
			end

			Spoofing.facs(character, "GuildRich")

			local humanoid = character:FindFirstChild("Humanoid")
			if not humanoid then
				continue
			end

			Spoofing.facs(humanoid, "CharacterName")
		end

		local serverRegion = replicatedStorage:FindFirstChild("SERVER_REGION")
		local serverName = replicatedStorage:FindFirstChild("SERVER_NAME")
		local serverAge = replicatedStorage:FindFirstChild("SERVER_AGE")

		if not serverRegion or not serverName or not serverAge then
			return
		end

		Spoofing.fvcs(serverRegion)
		Spoofing.fvcs(serverName)
		Spoofing.fvcs(serverAge)
	end

	---Initialize spoofing.
	function Spoofing.init()
		-- Get player data.
		local localPlayer = players.LocalPlayer
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		local pgDescendantAdded = Signal.new(playerGui.DescendantAdded)

		-- Attach.
		spoofingMaid:add(renderStepped:connect("Spoofing_OnRenderStepped", updateSpoofing))
		spoofingMaid:add(pgDescendantAdded:connect("Spoofing_OnPGDescendantAdded", onPgDescendantAdded))

		-- Log.
		Logger.warn("Spoofing initialized.")
	end

	---Detach spoofing.
	function Spoofing.detach()
		-- Tell hooks that we need to clean up instead of spoofing - regardless of what user set.
		Spoofing.force = true

		-- Clean up maid.
		spoofingMaid:clean()

		-- Clean up spoofed data.
		Spoofing.rics()

		-- Clean up instances & other spoofing.
		fakeFreestylerBand.Parent = nil
		fakeKongaClutchRing.Parent = nil
		resetEmoteSpoofer()

		-- Log detach.
		Logger.warn("Spoofing detached.")
	end

	-- Return Spoofing module.
	return Spoofing
end)()
