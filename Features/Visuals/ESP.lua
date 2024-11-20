---@note: This isn't the greatest way to do things.
---Preferably, each ESP object should have its own module and be created in a more organized manner.
---But that's obviously way too time-consuming, repetitive, and boring.
---So, I just took our previous way from our previous codebase to dynamically create ESP objects for many types.

---The name callback(s) feel very messy and should be thought up in a different way in the future.
---Also, the way we're handling ESP objects is very messy and should be thought up in a differently too.
---We'll do that later though.

-- Cached functions.
local osClock = os.clock

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Features.Visuals.Objects.BasicESP
local BasicESP = require("Features/Visuals/Objects/BasicESP")

---@module Features.Visuals.Objects.HumanoidESP
local HumanoidESP = require("Features/Visuals/Objects/HumanoidESP")

---@module Menu.VisualsTab
local VisualsTab = require("Menu/VisualsTab")

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module GUI.Configuration
local Configuration = require("GUI/Configuration")

-- ESP module.
local ESP = {}

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)
local workspaceDescendantAdded = Signal.new(workspace.DescendantAdded)
local workspaceDescendantRemoving = Signal.new(workspace.DescendantRemoving)
local playerAdded = Signal.new(players.PlayerAdded)
local playerRemoving = Signal.new(players.PlayerRemoving)

-- Maids.
local espMaid = Maid.new()

-- Maps.
local espMap = {}

-- Constants.
local ESP_DISTANCE_FORMAT = "%s [%i]"
local ESP_DISTANCE_HUMANOID_FORMAT = "%s [%i/%i] [%i]"
local ESP_HUMANOID_FORMAT = "%s [%i/%i]"

local ESP_TEMPO_BLOOD_HP_BLOCK = "\n[%i%% tempo] [%i%% blood] [%i%% posture] [%i%% health] [%.1f bars]\n"
local ESP_PLAYER_FORMAT = "%s [%i/%i] [Power %i]"
local ESP_DISTANCE_PLAYER_FORMAT = "%s [%i/%i] [%i] [Power %i]"

---Player ESP name callback.
---@param player Player
---@param level number
---@param tempoValue IntValue
---@param bloodValue IntValue
---@param breakMeterValue IntValue
local function createPlayerESPNameCallback(player, level, tempoValue, bloodValue, breakMeterValue)
	local function nameCallback(self, humanoid, distance)
		local health = humanoid.Health
		local maxHealth = humanoid.MaxHealth

		local healthPercentage = health / maxHealth
		local healthInBars = math.clamp(healthPercentage / 0.20, 0, 5)

		local espName = player:GetAttribute("CharacterName") or player.Name

		if Toggles[VisualsTab.identify(self.identifier, "UseRobloxUsername")].Value then
			espName = player.Name
		end

		local tempoBloodHp = ESP_TEMPO_BLOOD_HP_BLOCK:format(
			tempoValue.Value / tempoValue.MaxValue * 100,
			(bloodValue.Value / bloodValue.MaxValue) * 100,
			(breakMeterValue.Value / breakMeterValue.MaxValue) * 100,
			healthPercentage * 100,
			healthInBars
		)

		local espString = nil

		if Toggles[VisualsTab.identify(self.identifier, "Distance")].Value then
			espString = ESP_DISTANCE_PLAYER_FORMAT:format(espName, health, maxHealth, distance, level)
		else
			espString = ESP_PLAYER_FORMAT:format(espName, health, maxHealth, level)
		end

		if Toggles[VisualsTab.identify(self.identifier, "ShowExtraInformation")].Value then
			return espString .. tempoBloodHp
		else
			return espString
		end
	end

	return nameCallback
end

---Create Humanoid ESP name callback.
---@param espName string
local function createHumanoidESPNameCallback(espName)
	local function nameCallback(self, humanoid, distance)
		local health = math.floor(humanoid.Health)
		local maxHealth = math.floor(humanoid.MaxHealth)

		if Toggles[VisualsTab.identify(self.identifier, "Distance")].Value then
			return ESP_DISTANCE_HUMANOID_FORMAT:format(espName, health, maxHealth, distance)
		else
			return ESP_HUMANOID_FORMAT:format(espName, health, maxHealth)
		end
	end

	return nameCallback
end

---Create ESP name callback.
---@param espName string
local function createESPNameCallback(espName)
	local function nameCallback(self, distance, _)
		if Toggles[VisualsTab.identify(self.identifier, "Distance")].Value then
			return ESP_DISTANCE_FORMAT:format(espName, distance)
		else
			return espName
		end
	end

	return nameCallback
end

---Update ESP.
local function updateESP()
	local function updateObject(object)
		local delayUpdate = object.delayUpdate

		if delayUpdate and osClock() <= delayUpdate then
			return
		end

		Profiler.run(string.format("ESP_Update_%s", object.identifier), object.update, object)
	end

	local function updateGroup(group)
		local stack = group.stack

		if Configuration.expectToggleValue("ESPSplitUpdates") then
			local totalParts = (Configuration.expectOptionValue("ESPSplitFrames") or 2)
			local objectsPerPart = math.ceil(#stack / totalParts)
			local currentPart = group.currentPart or 1

			local startIdx = (currentPart - 1) * objectsPerPart + 1
			local endIdx = math.min(currentPart * objectsPerPart, #stack)

			for i = startIdx, endIdx do
				updateObject(stack[i])
			end

			group.currentPart = currentPart + 1

			if group.currentPart > totalParts then
				group.currentPart = 1
			end
		else
			for _, object in next, stack do
				updateObject(object)
			end
		end

		group.updating = true
	end

	local function setInvisibleGroup(group)
		for _, object in next, group.stack do
			object:setVisible(false)
		end

		group.updating = false
	end

	for identifier, group in next, espMap do
		if Configuration.expectToggleValue(VisualsTab.identify(identifier, "Enable")) then
			updateGroup(group)
		elseif group.updating then
			setInvisibleGroup(group)
		end
	end
end

---Emplace object.
---@param instance Instance
---@param object BasicESP
local function emplaceObject(instance, object)
	local groupData = {
		stack = {},
		updating = false,
		currentPart = nil,
	}

	if not espMap[object.identifier] then
		espMap[object.identifier] = groupData
	end

	local stack = espMap[object.identifier].stack
	stack[#stack + 1] = object
end

---On descendant added.
---@param descendant Instance
local function onDescendantAdded(descendant)
	local isModel = descendant:IsA("Model")
	local isBasePart = descendant:IsA("BasePart")

	if not isBasePart and not isModel then
		return
	end

	local name = descendant.Name
	local parent = descendant.Parent

	if isModel then
		local isInLiveFolder = parent == workspace:WaitForChild("Live")
		local playerFromCharacter = players:GetPlayerFromCharacter(descendant)

		if isInLiveFolder and not playerFromCharacter then
			local richName = descendant:GetAttribute("MOB_rich_name")
			local nameCallback = createHumanoidESPNameCallback(richName or descendant.Name)
			return emplaceObject(descendant, HumanoidESP.new("Mob", descendant, nameCallback))
		end

		if parent == workspace:WaitForChild("NPCs") then
			return emplaceObject(descendant, BasicESP.new("NPC", descendant, createESPNameCallback(name)))
		end
	end

	if name == "JobBoard" then
		return emplaceObject(descendant, BasicESP.new("JobBoard", descendant, createESPNameCallback("Job Board")))
	end

	if name == "BigArtifact" then
		return emplaceObject(descendant, BasicESP.new("Artifact", descendant, createESPNameCallback("Artifact")))
	end

	if name == "DepthsWhirlpool" then
		return emplaceObject(descendant, BasicESP.new("Whirlpool", descendant, createESPNameCallback("Whirlpool")))
	end

	if name == "ExplodeCrate" then
		return emplaceObject(
			descendant,
			BasicESP.new("ExplosiveBarrel", descendant, createESPNameCallback("Explosive Barrel"))
		)
	end

	if name == "EventFeatherRef" then
		return emplaceObject(descendant, BasicESP.new("OwlFeathers", descendant, createESPNameCallback("Owl Feathers")))
	end

	if name:match("GuildDoor") then
		local nameCallback = createESPNameCallback(descendant:GetAttribute("GuildName") or "Unidentified Guild Door")
		return emplaceObject(descendant, BasicESP.new("GuildDoor", descendant, nameCallback))
	end

	if name == "GuildBanner" then
		return emplaceObject(descendant, BasicESP.new("GuildBanner", descendant, createESPNameCallback("Guild Banner")))
	end

	if name == "Obelisk" then
		return emplaceObject(descendant, BasicESP.new("Obelisk", descendant, createESPNameCallback("Obelisk")))
	end

	if name:match("ArmorBrick") then
		local billboardGui = descendant:FindFirstChild("BillboardGui")
		local armorBrickLabel = billboardGui and billboardGui:FindFirstChild("TextLabel")
		local armorBrickName = armorBrickLabel and armorBrickLabel.Text

		if not armorBrickLabel then
			armorBrickName = "Unknown Armor Brick"
		end

		return emplaceObject(descendant, BasicESP.new("ArmorBrick", descendant, createESPNameCallback(armorBrickName)))
	end

	if name == "AreaMarker" then
		local nameCallback = createESPNameCallback(descendant.Parent.Name or "Unidentified Area Marker")
		return emplaceObject(descendant, BasicESP.new("AreaMarker", descendant, nameCallback))
	end

	if name == "LootUpdated" then
		return emplaceObject(descendant, BasicESP.new("Chest", descendant.Parent, createESPNameCallback("Chest")))
	end

	if descendant.Parent == workspace.Ingredients then
		return emplaceObject(descendant, BasicESP.new("Ingredient", descendant, createESPNameCallback(name)))
	end

	if name == "BellMeteor" then
		return emplaceObject(descendant, BasicESP.new("BellMeteor", descendant, createESPNameCallback("Bell Meteor")))
	end

	if name == "RareObelisk" then
		return emplaceObject(descendant, BasicESP.new("RareObelisk", descendant, createESPNameCallback("Rare Obelisk")))
	end

	if name == "HealBrick" then
		return emplaceObject(descendant, BasicESP.new("HealBrick", descendant, createESPNameCallback("Heal Brick")))
	end

	if name == "MantraObelisk" then
		return emplaceObject(
			descendant,
			BasicESP.new("MantraObelisk", descendant, createESPNameCallback("Mantra Obelisk"))
		)
	end

	if descendant:IsA("MeshPart") and descendant:FindFirstChild("InteractPrompt") then
		return emplaceObject(descendant, BasicESP.new("BRWeapon", descendant, createESPNameCallback(name)))
	end
end

---On descendant removing.
---@param descendant Instance
local function onDescendantRemoving(descendant)
	for _, group in next, espMap do
		local stack = group.stack

		local objectIdx = table.find(stack, descendant)
		if not objectIdx then
			continue
		end

		stack[objectIdx]:detach()
		stack[objectIdx] = nil
	end
end

---On player removing.
---@param player Player
local function onPlayerRemoving(player)
	for _, group in next, espMap do
		local stack = group.stack

		local objectIdx = table.find(stack, player)
		if not objectIdx then
			continue
		end

		stack[objectIdx]:detach()
		stack[objectIdx] = nil
	end
end

---On player added.
---@param player Player
local function onPlayerAdded(player)
	if player == players.LocalPlayer then
		return
	end

	local function onCharacterAdded(character)
		local level = character:GetAttribute("Level")
		local breakMeterValue = character:WaitForChild("BreakMeter")
		local bloodValue = character:WaitForChild("Blood")
		local tempoValue = character:WaitForChild("Tempo")

		local nameCallback = createPlayerESPNameCallback(player, level, tempoValue, bloodValue, breakMeterValue)

		emplaceObject(player, HumanoidESP.new("Player", character, nameCallback))
	end

	local characterAdded = Signal.new(player.CharacterAdded)
	local characterRemoving = Signal.new(player.CharacterRemoving)

	---@note: Clean these up when the player is removed?
	espMaid:add(characterAdded:connect("ESP_OnCharacterAdded", onCharacterAdded))
	espMaid:add(characterRemoving:connect("ESP_OnCharacterRemoving", onPlayerRemoving))

	local character = player.Character
	if not character then
		return
	end

	onCharacterAdded(player.Character)
end

-- Initialize ESP.
function ESP.init()
	espMaid:add(renderStepped:connect("ESP_RenderStepped", updateESP))
	espMaid:add(workspaceDescendantAdded:connect("ESP_DescendantAdded", onDescendantAdded))
	espMaid:add(workspaceDescendantRemoving:connect("ESP_DescendantRemoving", onDescendantRemoving))
	espMaid:add(playerAdded:connect("ESP_PlayerAdded", onPlayerAdded))
	espMaid:add(playerRemoving:connect("ESP_PlayerRemoving", onPlayerRemoving))

	---@note: Massive freeze here while loading.
	---When I'm not lazy, let's try to more specifically search for the instances we need.
	for _, descendant in pairs(workspace:GetDescendants()) do
		onDescendantAdded(descendant)
	end

	---@note: We only need to initially get the Area Markers just once.
	for _, descendant in pairs(replicatedStorage:WaitForChild("MarkerWorkspace"):GetDescendants()) do
		onDescendantAdded(descendant)
	end

	---@note: We need to seperate player scanning because they will not be detected when new characters are added.
	for _, player in pairs(players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

-- Detach ESP.
function ESP.detach()
	espMaid:clean()

	for _, group in next, espMap do
		for _, object in next, group.stack do
			object:detach()
		end
	end
end

-- Return ESP module.
return ESP
