-- Inteligence farming.
local InteligenceFarm = {}

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Attributes
local Attributes = require("Utility/Attributes")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@Module Utility.SendInput
local SendInput = require("Utility/SendInput")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

-- Services.
local players = game:GetService("Players")
local runService = game:GetService("RunService")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local autoIntelligenceMaid = Maid.new()

---Update inteligence.
local function updateInteligence()
	if not Configuration.expectToggleValue("IntelligenceFarm") then
		return
	end

	if not Attributes.isNotAtCap("Stat_Intelligence", Options.IntelligenceCap.Value) then
		return Toggles.InteligenceFarm:SetValue(false)
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

	local characterBook = localPlayerCharacter:FindFirstChild("Math Textbook")
	local backpackBook = localPlayer.BackPack:FindFirstChild("Math Textbook")

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

	local descSheet = choiceFrame:FindFirstChild("DescSheet")
	if not descSheet then
		return
	end

	local desc = descSheet:FindFirstChild("Desc")
	if not desc then
		return
	end

	local options = descSheet:FindFirstChild("Options")
	if not options then
		return
	end

	local isMathChoice = options:FindFirstChildOfClass("TextButton")
	if not isMathChoice or (isMathChoice and not tonumber(isMathChoice.Name)) then
		return
	end

	local choice = choicePrompt:FindFirstChild("Choice")
	if not choice then
		return
	end

	local operation = desc.Text:lower()
	local text = desc.Text:split(" ")

	local expected = nil
	local numberOne, numberTwo = tonumber(text[3]), tonumber(text[5]:gsub("?", ""))

	if operation:match("times") then
		expected = numberOne * numberTwo
	elseif operation:match("minus") then
		expected = numberOne - numberTwo
	elseif operation:match("times") then
		expected = numberOne + numberTwo
	elseif operation:match("divided") then
		expected = numberOne / numberTwo
	end

	local deltaTable = {}
	local buttonMap = {}

	for _, child in pairs(options:GetChildren()) do
		if not child:IsA("TextButton") then
			continue
		end

		local number = tonumber(child.Text) or 0
		local delta = math.abs(number - expected)

		deltaTable[#deltaTable + 1] = delta
		buttonMap[delta] = number
	end

	table.sort(deltaTable, function(deltaOne, deltaTwo)
		return deltaOne < deltaTwo
	end)

	choice:FireServer(buttonMap[deltaTable[1]])

	if Attributes.isNotAtCap("Stat_Intelligence", Options.IntelligenceCap.Value) then
		return
	end

	humanoid:UnequipTools()

	Logger.notify("Intelligence AutoFarm Stopped")
end

---Intelligence farming.
function InteligenceFarm.init()
	autoIntelligenceMaid:add(renderStepped:connect("AttributeFarmIntelligence_OnPreRender", updateInteligence))
end

---Detach the inteligence farm.
function InteligenceFarm.detach()
	autoIntelligenceMaid:clean()
end

-- Return InteligenceFarm module
return InteligenceFarm
