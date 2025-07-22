-- Fish farming.
local FishFarm = {}

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Services.
local players = game:GetService("Players")
local runService = game:GetService("RunService")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local fishFarmMaid = Maid.new()

-- Timestamp.
local fishFarmTimestamp = os.clock()

-- State.
local wasActivated = false

---Update fish farm.
local function updateFishFarm()
	if os.clock() - fishFarmTimestamp < 0.1 then
		return
	end

	fishFarmTimestamp = os.clock()

	if not Configuration.expectToggleValue("AutoFish") then
		return
	end

	local localPlayer = players.LocalPlayer
	local localPlayerCharacter = localPlayer.Character
	if not localPlayerCharacter then
		return
	end

	local humanoid = localPlayerCharacter:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	local characterRod = localPlayerCharacter:FindFirstChild("Fishing Rod")
	local backpackRod = backpack:FindFirstChild("Fishing Rod")

	if not characterRod then
		return backpackRod and humanoid:EquipTool(backpackRod)
	end

	local handle = characterRod:FindFirstChild("Handle")
	local rod = handle and handle:FindFirstChild("Rod")
	local bobby = rod and rod:FindFirstChild("bobby")
	if not bobby then
		return
	end

	local addBait = characterRod:FindFirstChild("AddBait")
	if not addBait then
		return
	end

	local baitTable = {
		"Plumfruit",
		"Pomar",
		"Gobletto",
		"Squid",
		"Dentifilo",
		"Seaweed Bundle",
		"Urchin",
		"Browncap",
		"Chum",
		"Calabash",
		"Pufferfish",
		"Redd",
	}

	for _, baitName in next, baitTable do
		local bait = backpack:FindFirstChild(baitName)
		if not bait then
			continue
		end

		if bobby:FindFirstChild("bait") then
			break
		end

		return addBait:FireServer(bait)
	end

	local hook = bobby:FindFirstChild("hook")
	if not hook then
		return
	end

	if hook.Transparency ~= 1.0 then
		wasActivated = not wasActivated
		return wasActivated and characterRod:Deactivate() or characterRod:Activate()
	end

	local inputUpdate = characterRod:FindFirstChild("InputUpdate")
	if not inputUpdate then
		return
	end

	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local fishingGui = playerGui:FindFirstChild("FishingGui")
	if not fishingGui or not fishingGui.Enabled then
		return
	end

	local mainFrame = fishingGui:FindFirstChild("MainFrame")
	if not mainFrame then
		return
	end

	local holdA = mainFrame:FindFirstChild("HoldA")
	local holdS = mainFrame:FindFirstChild("HoldS")
	local holdD = mainFrame:FindFirstChild("HoldD")
	if not holdA or not holdS or not holdD then
		return
	end

	inputUpdate:FireServer({
		a = holdA.Visible,
		s = holdS.Visible,
		d = holdD.Visible,
	})
end

---Fish farming.
function FishFarm.init()
	-- Attach the fish farm.
	fishFarmMaid:add(renderStepped:connect("FishFarm_RenderStepped", updateFishFarm))

	-- Log.
	Logger.warn("Fish Farm initialized.")
end

---Detach the fish farm.
function FishFarm.detach()
	-- Clean the maid.
	fishFarmMaid:clean()

	-- Log.
	Logger.warn("Fish Farm detached.")
end

-- Return FishFarm module.
return FishFarm
