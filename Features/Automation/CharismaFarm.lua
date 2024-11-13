-- Charisma farming.
local CharismaFarm = {}

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Attributes
local Attributes = require("Utility/Attributes")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.SendInput
local SendInput = require("Utility/SendInput")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

-- Services.
local players = game:GetService("Players")
local runService = game:GetService("RunService")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local autoCharismaMaid = Maid.new()

---Update charisma.
local function updateCharisma()
	if not Configuration.expectToggleValue("CharismaFarm") then
		return
	end

	if not Attributes.isNotAtCap("Stat_Charisma", Options.CharismaCap.Value) then
		return Toggles.CharismaFarm:SetValue(false)
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

	local characterBook = localPlayerCharacter:FindFirstChild("How to Make Friends")
	local backpackBook = localPlayer.BackPack:FindFirstChild("How to Make Friends")

	if not characterBook and backpackBook then
		return humanoid:EquipTool(backpackBook)
	end

	local choicePrompt = localPlayer.PlayerGui:FindFirstChild("ChoicePrompt")
	if not choicePrompt then
		return SendInput.mb1(0, 0)
	end

	local choiceFrame = choicePrompt:FindFirstChild("ChoiceFrame")
	if not choiceFrame then
		return
	end

	local choice = choicePrompt:FindFirstChild("Choice")
	if not choice then
		return
	end

	if not choiceFrame:FindFirstChild("Options") or not choiceFrame:FindFirstChild("DescSheet") then
		return
	end

	local description = choiceFrame:FindFirstChild("Desc")
	if not description then
		return
	end

	local text = description.Text:split("\n")
	local charismaLine = text[2]:sub(2, -2)

	choice:InvokeServer(charismaLine)

	if Attributes.isNotAtCap("Stat_Charisma", Options.CharismaCap.Value) then
		return
	end

	humanoid:UnequipTools()

	Logger.notify("Intelligence AutoFarm Stopped")
end

---Charisma farming.
function CharismaFarm.init()
	autoCharismaMaid:add(renderStepped:connect("AttributeFarmCharisma_OnPreRender", updateCharisma))
end

---Detach the charisma farm.
function CharismaFarm.detach()
	autoCharismaMaid:clean()
end

-- Return CharismaFarm module
return CharismaFarm
