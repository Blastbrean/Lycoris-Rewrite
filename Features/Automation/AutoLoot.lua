---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.JSON
local JSON = require("Utility/JSON")

---@module Utility.Table
local Table = require("Utility/Table")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Features.Automation.Objects.AutoLootOptions
local AutoLootOptions = require("Features/Automation/Objects/AutoLootOptions")

-- AutoLoot module.
local AutoLoot = { ignore = false }

-- Maid.
local autoLootMaid = Maid.new()

-- The choice remote that will be used. If it is invalidated, then the entire queue will be reset.
local choiceRemote = nil

-- The current prompt being processed.
local currentPrompt = nil

-- The current choice being looted.
local currentChoice = nil

-- The queue of items to be looted from the remote.
local lootQueue = {}

-- Are we currently in loot all mode?
local lootAll = false

-- Services.
local players = game:GetService("Players")
local runService = game:GetService("RunService")

---Wait for the current choice to be deleted.
---The function will return if the choice is not deleted. Else, it will remove it from the queue.
---@param options ScrollingFrame
---@param remote RemoteEvent
local function waitForChoiceDeletion(options, remote)
	local choiceObject = options:FindFirstChild(currentChoice)

	remote:FireServer(currentChoice)

	if choiceObject and choiceObject.Parent then
		return
	end

	if lootQueue[1] ~= currentChoice then
		error("We assumed that the current choice was the first in the queue, was the queue modified?")
	end

	table.remove(lootQueue, 1)

	currentChoice = nil
end

---Reset the AutoLoot module.
local function resetAutoLoot()
	choiceRemote = nil
	lootQueue = {}
	currentChoice = nil
	currentPrompt = nil
	lootAll = false
end

---On player GUI descendant added.
---@param descendant Instance
local function onPlayerGuiDescendantAdded(descendant)
	if descendant.Name ~= "ChoicePrompt" then
		return
	end

	if AutoLoot.ignore then
		return
	end

	if not Configuration.expectToggleValue("AutoLoot") then
		return
	end

	-- Wait for all the instances to replicate.
	descendant:WaitForChild("ChoiceFrame"):WaitForChild("Options")

	-- Start processing the prompt.
	AutoLoot.process(
		descendant,
		AutoLootOptions.new(
			Configuration.expectOptionValue("AutoLootStarsMin") or 0,
			Configuration.expectOptionValue("AutoLootStarsMax") or 0,
			Configuration.expectOptionValues("ItemNameList") or {},
			Configuration.expectToggleValue("AutoLootAll") or false
		)
	)
end

---Wait for the current prompt to be deleted.
---@param prompt ScreenGui
---@param remote RemoteEvent
---@param param string
local function waitForPromptDeletion(prompt, remote, param)
	repeat
		-- Close prompt.
		remote:FireServer(param)

		-- Wait.
		task.wait()
	until not prompt.Parent

	resetAutoLoot()
end

---Is the auto loot active?
---@return boolean
function AutoLoot.active()
	return choiceRemote ~= nil and currentPrompt ~= nil and #lootQueue > 0
end

---Update the AutoLoot module.
function AutoLoot.update()
	if not AutoLoot.ignore and not Configuration.expectToggleValue("AutoLoot") then
		return resetAutoLoot()
	end

	if not choiceRemote or not choiceRemote.Parent then
		return resetAutoLoot()
	end

	if not currentPrompt or not currentPrompt.Parent then
		return resetAutoLoot()
	end

	local choiceFrame = currentPrompt:FindFirstChild("ChoiceFrame")
	local options = choiceFrame and choiceFrame:FindFirstChild("Options")
	if not options then
		return resetAutoLoot()
	end

	if lootAll then
		return waitForPromptDeletion(currentPrompt, choiceRemote, "LOOT_ALL")
	end

	if currentChoice then
		return waitForChoiceDeletion(options, choiceRemote)
	end

	local itemToLoot = lootQueue[1]
	if not itemToLoot then
		return waitForPromptDeletion(currentPrompt, choiceRemote, "EXIT")
	end

	currentChoice = itemToLoot

	choiceRemote:FireServer(itemToLoot)
end

---Process a choice prompt and add the items with filtering to the loot queue.
---This function will reset the queue and set a new choice remote if it is valid.
---@param prompt ScreenGui The choice prompt to process.
---@param options AutoLootOptions The options to use.
function AutoLoot.process(prompt, options)
	local remote = prompt:FindFirstChild("Choice")
	if not remote or not remote:IsA("RemoteEvent") then
		return
	end

	local jsonLootData = prompt:GetAttribute("LootData")
	if typeof(jsonLootData) ~= "string" then
		return
	end

	local lootData = JSON.decode(jsonLootData)
	if typeof(lootData) ~= "table" then
		return
	end

	-- Reset the AutoLoot module.
	resetAutoLoot()

	-- Set the new data for processing.
	currentPrompt = prompt
	choiceRemote = remote
	lootAll = options.lall

	-- Process the loot data.
	for _, item in next, lootData do
		local rich = item.rich:gsub("%$%S*", "")
		local text = item.text

		if not text then
			continue
		end

		local matched = text:match("★")
		local stars = matched and #matched or 0

		if stars < options.smin or stars > options.smax then
			continue
		end

		local wanted, _ = Table.find(options.wanted, function(value, _)
			return rich:match(value)
		end)

		if not wanted then
			continue
		end

		lootQueue[#lootQueue + 1] = text
	end
end

---Initialize the AutoLoot module.
function AutoLoot.init()
	local localPlayer = players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	local preRender = Signal.new(runService.PreRender)
	local playerGuiDescendantAdded = Signal.new(playerGui.DescendantAdded)

	autoLootMaid:mark(playerGuiDescendantAdded:connect("AutoLoot_PlayerGuiDescendantAdded", onPlayerGuiDescendantAdded))
	autoLootMaid:mark(preRender:connect("AutoLoot_PreRender", AutoLoot.update))
end

---Detach the AutoLoot module.
function AutoLoot.detach()
	autoLootMaid:clean()
end

-- Return the AutoLoot module.
return AutoLoot
