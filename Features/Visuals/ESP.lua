---@note: This isn't the greatest way to do things.
---Preferably, each ESP object should have its own module and be created in a more organized manner.
---But that's obviously way too time-consuming, repetitive, and boring.
---So, I just took our previous way from our previous codebase to dynamically create ESP objects for many types.

---The name callback(s) feel very messy and should be thought up in a different way in the future.
---Also, the way we're handling ESP objects is very messy and should be thought up in a differently too.
---We'll do that later though.

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

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)
local workspaceDescendantAdded = Signal.new(workspace.DescendantAdded)
local workspaceDescendantRemoving = Signal.new(workspace.DescendantRemoving)

-- Maids.
local espMaid = Maid.new()

-- Maps.
local espMap = {}

-- Constants.
local ESP_DISTANCE_FORMAT = "%s [%i]"
local ESP_DISTANCE_HUMANOID_FORMAT = "%s [%i/%i] [%i]"
local ESP_DISTANCE_PLAYER_FORMAT = "%s [%i/%i] [%i] [Power %i]"
local ESP_HUMANOID_FORMAT = "%s [%i/%i]"
local ESP_PLAYER_FORMAT = "%s [%i/%i] [Power %i]"

---Player ESP name callback.
---@param self HumanoidESP
---@param humanoid Humanoid
---@param distance number
local function playerESPNameCallback(self, humanoid, distance)
	local health = math.floor(humanoid.Health)
	local maxHealth = math.floor(humanoid.MaxHealth)

	local player = players:GetPlayerFromCharacter(self.instance)
	if not player then
		return "No Player Found"
	end

	local name = player:GetAttribute("CharacterName") or self.instance.Name
	local level = self.instance:GetAttribute("Level") or -1

	if Toggles[VisualsTab.identify(self.identifier, "Distance")].Value then
		return ESP_DISTANCE_PLAYER_FORMAT:format(name, health, maxHealth, distance, level)
	else
		return ESP_PLAYER_FORMAT:format(name, health, maxHealth, level)
	end
end

---Mob ESP name callback.
---@param self HumanoidESP
---@param humanoid Humanoid
---@param distance number
local function mobESPNameCallback(self, humanoid, distance)
	local health = math.floor(humanoid.Health)
	local maxHealth = math.floor(humanoid.MaxHealth)
	local name = self.instance:GetAttribute("MOB_rich_name") or self.instance.Name

	if Toggles[VisualsTab.identify(self.identifier, "Distance")].Value then
		return ESP_DISTANCE_HUMANOID_FORMAT:format(name, health, maxHealth, distance)
	else
		return ESP_HUMANOID_FORMAT:format(name, health, maxHealth)
	end
end

---Area Marker ESP name callback.
---@param self BasicESP
---@param distance number
---@param parent Instance
local function areaMarkerESPNameCallback(self, distance, parent)
	local areaMarkerName = self.instance.Parent.Name or "Unidentified Area Marker"

	if Toggles[VisualsTab.identify(self.identifier, "Distance")].Value then
		return ESP_DISTANCE_FORMAT:format(areaMarkerName, distance)
	else
		return areaMarkerName
	end
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
	local function updateGroup(group)
		for _, object in next, group.objects do
			Profiler.run(string.format("ESP_Update_%s", object.identifier), object.update, object)
		end

		group.updating = true
	end

	local function setInvisibleGroup(group)
		for _, object in next, group.objects do
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
		objects = {},
		updating = false,
	}

	if not espMap[object.identifier] then
		espMap[object.identifier] = groupData
	end

	espMap[object.identifier].objects[instance] = object
end

---On descendant added.
---@param descendant Instance
local function onDescendantAdded(descendant)
	local playerFromCharacter = players:GetPlayerFromCharacter(descendant)
	local isInLiveFolder = descendant.Parent == workspace:WaitForChild("Live")

	if descendant:IsA("Model") then
		if isInLiveFolder and playerFromCharacter and playerFromCharacter ~= players.LocalPlayer then
			emplaceObject(descendant, HumanoidESP.new("Player", descendant, playerESPNameCallback))
			return
		end

		if isInLiveFolder and not playerFromCharacter then
			emplaceObject(descendant, HumanoidESP.new("Mob", descendant, mobESPNameCallback))
			return
		end

		if descendant.Parent == workspace:WaitForChild("NPCs") then
			emplaceObject(descendant, BasicESP.new("NPC", descendant, createESPNameCallback("NPC")))
			return
		end
	end

	if descendant.Name == "JobBoard" then
		emplaceObject(descendant, BasicESP.new("JobBoard", descendant, createESPNameCallback("Job Board")))
		return
	end

	if descendant.Name == "BigArtifact" then
		emplaceObject(descendant, BasicESP.new("Artifact", descendant, createESPNameCallback("Artifact")))
		return
	end

	if descendant.Name == "DepthsWhirlpool" then
		emplaceObject(descendant, BasicESP.new("Whirlpool", descendant, createESPNameCallback("Whirlpool")))
		return
	end

	if descendant.Name == "ExplodeCrate" then
		emplaceObject(
			descendant,
			BasicESP.new("ExplosiveBarrel", descendant, createESPNameCallback("Explosive Barrel"))
		)
		return
	end

	if descendant.Name == "EventFeatherRef" then
		emplaceObject(descendant, BasicESP.new("OwlFeathers", descendant, createESPNameCallback("Owl Feathers")))
		return
	end

	if descendant.Name:match("GuildDoor") then
		emplaceObject(descendant, BasicESP.new("GuildDoor", descendant, createESPNameCallback("Guild Door")))
		return
	end

	if descendant.Name == "GuildBanner" then
		emplaceObject(descendant, BasicESP.new("GuildBanner", descendant, createESPNameCallback("Guild Banner")))
		return
	end

	if descendant.Name == "Obelisk" then
		emplaceObject(descendant, BasicESP.new("Obelisk", descendant, createESPNameCallback("Obelisk")))
		return
	end

	if descendant.Name:match("ArmorBrick") then
		local billboardGui = descendant:FindFirstChild("BillboardGui")
		local armorBrickLabel = billboardGui and billboardGui:FindFirstChild("TextLabel")
		local armorBrickName = armorBrickLabel and armorBrickLabel.Text

		if not armorBrickLabel then
			armorBrickName = "Unknown Armor Brick"
		end

		emplaceObject(descendant, BasicESP.new("ArmorBrick", descendant, createESPNameCallback(armorBrickName)))
		return
	end

	if descendant.Name == "AreaMarker" then
		emplaceObject(descendant, BasicESP.new("AreaMarker", descendant.Parent, areaMarkerESPNameCallback))
		return
	end

	if descendant.Name == "LootUpdated" then
		emplaceObject(descendant, BasicESP.new("Chest", descendant.Parent, createESPNameCallback("Chest")))
		return
	end

	if descendant.Parent == workspace.Ingredients then
		emplaceObject(descendant, BasicESP.new("Ingredient", descendant, createESPNameCallback(descendant.Name)))
		return
	end

	if descendant.Name == "BellMeteor" then
		emplaceObject(descendant, BasicESP.new("BellMeteor", descendant, createESPNameCallback("Bell Meteor")))
		return
	end

	if descendant.Name == "RareObelisk" then
		emplaceObject(descendant, BasicESP.new("RareObelisk", descendant, createESPNameCallback("Rare Obelisk")))
		return
	end

	if descendant.Name == "HealBrick" then
		emplaceObject(descendant, BasicESP.new("HealBrick", descendant, createESPNameCallback("Heal Brick")))
		return
	end

	if descendant.Name == "MantraObelisk" then
		emplaceObject(descendant, BasicESP.new("MantraObelisk", descendant, createESPNameCallback("Mantra Obelisk")))
		return
	end

	if descendant:IsA("MeshPart") and descendant:FindFirstChild("InteractPrompt") then
		emplaceObject(descendant, BasicESP.new("BRWeapon", descendant, createESPNameCallback(descendant.Name)))
		return
	end
end

-- On descendant removing.
---@param descendant Instance
local function onDescendantRemoving(descendant)
	for _, group in next, espMap do
		if not group.objects[descendant] then
			return
		end

		group.objects[descendant]:detach()
		group.objects[descendant] = nil
	end
end

-- Initialize ESP.
function ESP.init()
	espMaid:add(renderStepped:connect("ESP_RenderStepped", updateESP))
	espMaid:add(workspaceDescendantAdded:connect("ESP_DescendantAdded", onDescendantAdded))
	espMaid:add(workspaceDescendantRemoving:connect("ESP_DescendantRemoving", onDescendantRemoving))

	---@note: Massive freeze here while loading.
	---When I'm not lazy, let's try to more specifically search for the instances we need.
	for _, descendant in pairs(workspace:GetDescendants()) do
		onDescendantAdded(descendant)
	end
end

-- Detach ESP.
function ESP.detach()
	espMaid:clean()

	for _, group in next, espMap do
		for _, object in next, group.objects do
			object:detach()
		end
	end
end

-- Return ESP module.
return ESP
