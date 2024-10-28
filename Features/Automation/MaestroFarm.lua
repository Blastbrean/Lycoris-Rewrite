-- Maestro farming.
local MaestroFarm = { finishedLoot = false, lootMap = {} }

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.SendInput
local SendInput = require("Utility/SendInput")

---@module Utility.Signal
local Signal = require("Utility/Signal")

-- Services.
local memStoreService = game:GetService("MemStorageService")
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local httpService = game:GetService("HttpService")

-- Instances.
local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
local virtualInputManager = Instance.new("VirtualInputManager")
local npcs = workspace:WaitForChild("NPCs")

-- Modules.
local effectReplicatorModule = require(effectReplicator)

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local maestroFarmMaid = Maid.new()

---Talk to Maestro to initiate fight for fight stage.
---@param maestro Model?
---@param rootPart BasePart
---@param dialogueFrame Frame
local function nonDangerInteractMaestro(maestro, rootPart, dialogueFrame)
	if not maestro then
		return
	end

	local interactPrompt = maestro:FindFirstChild("InteractPrompt")
	if not interactPrompt then
		return
	end

	if not dialogueFrame.Visible then
		fireproximityprompt(interactPrompt)
	else
		SendInput.key(Enum.KeyCode.One)
	end

	if not maestroFarmMaid["interactTween"] then
		return
	end

	maestroFarmMaid["interactTween"] = tweenService:Create(rootPart, TweenInfo.new(0.6), {
		CFrame = maestro.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0),
	})

	maestroFarmMaid["interactTween"]:Play()
end

---Talk stage.
local function updateTalk()
	local localPlayer = players.LocalPlayer

	local maestro = npcs:FindFirstChild("Maestro Evengarde Rest")
	if not maestro then
		return
	end

	local maestroHrp = maestro:FindFirstChild("HumanoidRootPart")
	if not maestroHrp then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	if (hrp.Position - maestroHrp.Position).Magnitude >= 20 then
		return humanoid:MoveTo(maestroHrp.Position)
	end

	local interactPrompt = hrp:FindFirstChild("InteractPrompt")
	if not interactPrompt then
		return
	end

	local dialogueGui = localPlayer.PlayerGui:FindFirstChild("DialogueGui")
	if not dialogueGui then
		return
	end

	local dialogueFrame = dialogueGui:FindFirstChild("DialogueFrame")
	if not dialogueFrame then
		return
	end

	if not dialogueFrame.Visible then
		return fireproximityprompt(interactPrompt)
	end

	memStoreService:SetItem("MaestroFinishedTalkStage", "true")
	memStoreService:SetItem("HandleStartMenu", "true")

	SendInput.key(Enum.KeyCode.One)
end

---Loot maestro.
---@param humanoid Humanoid
---@param character Model
local function lootMaestro(humanoid, character)
	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return
	end

	local maestroChest = thrown:FindFirstChild("Model")
	if not maestroChest then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local maestroChestRootPart = maestroChest:FindFirstChild("RootPart")
	if not maestroChestRootPart then
		return
	end

	SendInput.key(Enum.KeyCode.W)

	local maestroChestCFrame = maestroChestRootPart.CFrame * CFrame.new(0, 3.5, 0)
	local playerGui = players.LocalPlayer.PlayerGui

	-- Go towards chest.
	if not playerGui:FindFirstChild("ChoicePrompt") and not maestroFarmMaid["ChestTween"] then
		maestroFarmMaid["chestTween"] = tweenService:Create(hrp, TweenInfo.new(0.6), {
			CFrame = maestroChestCFrame,
		})

		maestroFarmMaid["chestTween"]:Play()
	end

	-- Open chest while it's not open.
	if not playerGui:FindFirstChild("ChoicePrompt") and maestroFarmMaid["ChestTween"] then
		fireproximityprompt(maestroChest:FindFirstChild("InteractPrompt"))
	end

	-- Wait for the prompt to close while we've tweened towards it.
	if playerGui:FindFirstChild("ChoicePrompt") and maestroFarmMaid["ChestTween"] then
		return
	end

	local lootMessage = string.format("Maestro Farm Loot (%s)\n", os.date("%x %X"))
	local lootMapEntries = 0

	for idx, value in pairs(MaestroFarm.lootMap) do
		lootMessage = lootMessage .. string.format("%s x%i\n", tostring(idx), value)
		lootMapEntries = lootMapEntries + 1
	end

	if lootMapEntries <= 0 then
		lootMessage = lootMessage .. "No loot was obtained this run."
	end

	if Options.AutoMaestroWebhook.Value ~= "" then
		request({
			Url = Options.AutoMaestroWebhook.Value,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = httpService:JSONEncode({
				content = "```" .. lootMessage .. "```",
			}),
		})
	end

	MaestroFarm.finishedLoot = true

	memStoreService:AddItem("HandleStartMenu", "true")
end

---Fight maestro.
---@param maestro Model
---@param hrp BasePart
---@param humanoid Humanoid
local function fightMaestro(maestro, hrp, humanoid)
	local maestroHrp = maestro:FindFirstChild("HumanoidRootPart")
	if not maestroHrp then
		return
	end

	humanoid:MoveTo((maestroHrp.CFrame * CFrame.new(0, 0, -3)).Position)

	if (maestroHrp.Position - maestroHrp.Position).Magnitude >= 16 then
		return
	end

	if Toggles.MaestroUseCritical.Value then
		virtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
		virtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
	end

	local leftClick = KeyHandling.getRemote("LeftClick")
	if not leftClick then
		return
	end

	leftClick:FireServer(false, players.LocalPlayer:GetMouse().Hit, {})
end

---Leave stage.
local function updateLeave()
	local dungeonExit = workspace:FindFirstChild("DungeonExit")
	if not dungeonExit then
		return
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	character:PivotTo(dungeonExit.CFrame)
end

---Fight stage.
local function updateFight()
	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return
	end

	local localPlayer = players.LocalPlayer
	local playerGui = localPlayer.PlayerGui

	local dialogueGui = playerGui:FindFirstChild("DialogueGui")
	if not dialogueGui then
		return
	end

	local dialogueFrame = dialogueGui:FindFirstChild("DialogueFrame")
	if not dialogueFrame then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local maestro = live:FindFirstChild(".evengarde1")

	if not effectReplicatorModule:FindEffect("Danger") then
		return nonDangerInteractMaestro(maestro, hrp, dialogueFrame)
	end

	---@todo: AI-breaker and Void Mobs.

	local weaponInBackpack = localPlayer.Backpack:FindFirstChild("Weapon")

	if not character:FindFirstChild("Weapon") and weaponInBackpack then
		humanoid:EquipTool(weaponInBackpack)
	end

	if maestro and hrp and humanoid then
		return fightMaestro(maestro, hrp, humanoid)
	end

	memStoreService:RemoveItem("MaestroFinishedTalkStage")

	local maestroChest = thrown:FindFirstChild("Model")

	if maestroChest then
		return lootMaestro(humanoid, character)
	end
end

---Toggle the automatic Maestro Farm.
function MaestroFarm.init()
	local requests = replicatedStorage:WaitForChild("Requests")
	local toolSplash = requests:WaitForChild("ToolSplash")
	local toolSplashClientEvent = Signal.new(toolSplash.OnClientEvent)

	maestroFarmMaid:add(toolSplashClientEvent:connect("MaestroAutoFarm_FightStageLootLog", function(tool, amount)
		if not Toggles.AutoMaestroFarm.Value then
			return
		end

		local toolQuantity = tool:FindFirstChild("Quantity")
		local toolName = tool.Name:match("$") and tool.Name:split("$")[1] or tool.Name

		amount = amount or (toolQuantity and toolQuantity.Value) or 1

		if not MaestroFarm.lootMap[toolName] then
			MaestroFarm.lootMap[toolName] = amount
		else
			MaestroFarm.lootMap[toolName] = MaestroFarm.lootMap[toolName] + 1
		end
	end))

	maestroFarmMaid:add(renderStepped:connect("MaestroAutoFarm_RenderStepped", function()
		if not Toggles.AutoMaestroFarm.Value then
			return
		end

		if MaestroFarm.finishedLoot then
			return updateLeave()
		end

		if memStoreService:HasItem("MaestroFinishedTalkStage") then
			return updateFight()
		end

		return updateTalk()
	end))
end

---Detach the Maestro Farm.
function MaestroFarm.detach()
	maestroFarmMaid:clean()
end

-- Return MaestroFarm module.
return MaestroFarm
