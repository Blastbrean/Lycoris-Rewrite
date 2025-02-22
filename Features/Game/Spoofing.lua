return LPH_NO_VIRTUALIZE(function()
	---@module Utility.Maid
	local Maid = require("Utility/Maid")

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.Configuration
	local Configuration = require("Utility/Configuration")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	-- Spoofing module.
	---@note: This is ugly as fuck.
	local Spoofing = {}

	-- Services.
	local runService = game:GetService("RunService")
	local starterGui = game:GetService("StarterGui")
	local players = game:GetService("Players")
	local collectionService = game:GetService("CollectionService")

	-- Signals.
	local renderStepped = Signal.new(runService.RenderStepped)

	-- Maid.
	local spoofingMaid = Maid.new()

	-- Konga's clutch ring instance.
	local fakeKongaClutchRing = Instance.new("Folder")
	fakeKongaClutchRing.Name = "Ring:Konga's Clutch Ring"

	-- Freestyler's band instance.
	local fakeFreestylerBand = Instance.new("Folder")
	fakeFreestylerBand.Name = "Ring:Freestyler's Band"

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

	---Update spoofing.
	local function updateSpoofing()
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
	end

	---Initialize spoofing.
	function Spoofing.init()
		-- Attach.
		spoofingMaid:add(renderStepped:connect("Spoofing_OnRenderStepped", updateSpoofing))

		-- Log.
		Logger.warn("Spoofing initialized.")
	end

	---Detach spoofing.
	function Spoofing.detach()
		spoofingMaid:clean()
		resetEmoteSpoofer()

		fakeFreestylerBand.Parent = nil
		fakeKongaClutchRing.Parent = nil

		Logger.warn("Spoofing detached.")
	end

	-- Return Spoofing module.
	return Spoofing
end)()
