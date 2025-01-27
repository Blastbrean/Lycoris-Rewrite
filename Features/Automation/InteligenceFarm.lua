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

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

-- Services.
local players = game:GetService("Players")
local runService = game:GetService("RunService")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local autoIntelligenceMaid = Maid.new()

---Update inteligence.
local function updateInteligence()
	local inteligenceFarm = Toggles["AutoIntelligence"]
	if not inteligenceFarm or not inteligenceFarm.Value then
		return
	end

	local inteligenceFarmCap = Options["IntelligenceCap"]
	if not inteligenceFarmCap then
		return
	end

	local localPlayer = players.LocalPlayer
	local localPlayerCharacter = localPlayer.Character
	if not localPlayerCharacter then
		return
	end

	if not Attributes.isNotAtCap(localPlayerCharacter, "Stat_Intelligence", inteligenceFarmCap.Value) then
		Logger.longNotify("Intelligence AutoFarm is automatically stopping.")
		return inteligenceFarm:SetValue(false)
	end

	local humanoid = localPlayerCharacter:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return Logger.warn("Backpack not found.")
	end

	local characterBook = localPlayerCharacter:FindFirstChild("Math Textbook")
	local backpackBook = backpack:FindFirstChild("Math Textbook")

	if not characterBook and backpackBook then
		return humanoid:EquipTool(backpackBook)
	end

	local choicePrompt = localPlayer.PlayerGui:FindFirstChild("ChoicePrompt")
	if not choicePrompt then
		return SendInput.mb1(0, 0)
	end

	local choiceFrame = choicePrompt:FindFirstChild("ChoiceFrame")
	if not choiceFrame then
		return Logger.warn("Choice frame not found.")
	end

	local descSheet = choiceFrame:FindFirstChild("DescSheet")
	if not descSheet then
		return Logger.warn("Desc sheet not found.")
	end

	local options = choiceFrame:FindFirstChild("Options")
	if not options then
		return Logger.warn("Options not found.")
	end

	local desc = descSheet:FindFirstChild("Desc")
	if not desc then
		return Logger.warn("Desc not found.")
	end

	local isMathChoice = options:FindFirstChildOfClass("TextButton")
	if not isMathChoice or (isMathChoice and not tonumber(isMathChoice.Name)) then
		return Logger.warn("Math choice not found.")
	end

	local choice = choicePrompt:FindFirstChild("Choice")
	if not choice then
		return Logger.warn("Choice not found.")
	end

	local operation = desc.Text:lower()
	local text = desc.Text:split(" ")

	local expected = nil
	local numberOne, numberTwo = tonumber(text[3]), tonumber(table.pack(text[5]:gsub("?", ""))[1])

	if operation:match("times") then
		expected = numberOne * numberTwo
	elseif operation:match("minus") then
		expected = numberOne - numberTwo
	elseif operation:match("times") then
		expected = numberOne + numberTwo
	elseif operation:match("divided") then
		expected = numberOne / numberTwo
	end

	if not expected then
		return Logger.warn("Expected value not found.")
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

	if Attributes.isNotAtCap(localPlayerCharacter, "Stat_Intelligence", inteligenceFarmCap.Value) then
		return
	end

	humanoid:UnequipTools()

	Logger.longNotify("Intelligence AutoFarm is automatically stopping.")
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
