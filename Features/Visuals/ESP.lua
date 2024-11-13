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

-- ESP module.
local ESP = {}

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)
local gameDescendantAdded = Signal.new(game.DescendantAdded)
local gameDescendantRemoving = Signal.new(game.DescendantRemoving)

-- Maids.
local espMaid = Maid.new()

-- Objects.
local espObjects = {}

-- Constants.
local ESP_DISTANCE_FORMAT = "%s [%i]"
local ESP_DISTANCE_HUMANOID_FORMAT = "%s [%i/%i] [%i]"
local ESP_HUMANOID_FORMAT = "%s [%i/%i]"

---Humanoid ESP name callback.
---@param self HumanoidESP
---@param humanoid Humanoid
---@param distance number
local function humanoidESPNameCallback(self, humanoid, distance)
	local health = math.floor(humanoid.Health)
	local maxHealth = math.floor(humanoid.MaxHealth)
	local name = self.instance:GetAttribute("CharacterName") or self.instance.Name

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

-- Update ESP.
local function updateESP()
	for _, espObject in pairs(espObjects) do
		espObject:update()
	end
end

-- On descendant added.
---@param descendant Instance
local function onDescendantAdded(descendant)
	local isPlayerCharacter = players:GetPlayerFromCharacter(descendant)
	local isInLiveFolder = descendant.Parent == workspace:WaitForChild("Live")

	if descendant:IsA("Model") then
		if isInLiveFolder and isPlayerCharacter then
			espObjects[descendant] = HumanoidESP.new("Player", descendant, humanoidESPNameCallback)
			return
		end

		if isInLiveFolder and not isPlayerCharacter then
			espObjects[descendant] = HumanoidESP.new("Mob", descendant, humanoidESPNameCallback)
			return
		end

		if descendant.Parent == workspace:WaitForChild("NPCs") then
			espObjects[descendant] = HumanoidESP.new("NPC", descendant, humanoidESPNameCallback)
			return
		end
	end

	if descendant.Name == "AreaMarker" then
		espObjects[descendant] = BasicESP.new("AreaMarker", descendant, areaMarkerESPNameCallback)
		return
	end

	if descendant.Name == "LootUpdated" then
		espObjects[descendant] = BasicESP.new("Chest", descendant.Parent, createESPNameCallback("Chest"))
		return
	end

	if descendant.Name == "JobBoard" then
		espObjects[descendant] = BasicESP.new("JobBoard", descendant, createESPNameCallback("Job Board"))
		return
	end

	if descendant.Name == "BigArtifact" then
		espObjects[descendant] = BasicESP.new("Artifact", descendant, createESPNameCallback("Artifact"))
		return
	end

	if descendant.Name == "DepthsWhirlpool" then
		espObjects[descendant] = BasicESP.new("Whirlpool", descendant, createESPNameCallback("Whirlpool"))
		return
	end

	if descendant.Name == "ExplodeCrate" then
		espObjects[descendant] = BasicESP.new("ExplosiveBarrel", descendant, createESPNameCallback("Explosive Barrel"))
		return
	end

	if descendant.Name == "EventFeatherRef" then
		espObjects[descendant] = BasicESP.new("OwlFeathers", descendant, createESPNameCallback("Owl Feathers"))
		return
	end

	if descendant.Name:match("GuildDoor") then
		espObjects[descendant] = BasicESP.new("GuildDoor", descendant, createESPNameCallback("Guild Door"))
		return
	end

	if descendant.Name == "GuildBanner" then
		espObjects[descendant] = BasicESP.new("GuildBanner", descendant, createESPNameCallback("Guild Banner"))
		return
	end

	if descendant.Name == "Obelisk" then
		espObjects[descendant] = BasicESP.new("Obelisk", descendant, createESPNameCallback("Obelisk"))
		return
	end

	if descendant.Parent == workspace.Ingredients then
		espObjects[descendant] = BasicESP.new("Ingredient", descendant, createESPNameCallback(descendant.Name))
		return
	end

	if descendant.Name:match("ArmorBrick") then
		local billboardGui = descendant:FindFirstChild("BillboardGui")
		local armorBrickLabel = billboardGui and billboardGui:FindFirstChild("TextLabel")
		local armorBrickName = armorBrickLabel and armorBrickLabel.Text

		if not armorBrickLabel then
			armorBrickName = "Unknown Armor Brick"
		end

		espObjects[descendant] = BasicESP.new("ArmorBrick", descendant, createESPNameCallback(armorBrickName))
		return
	end

	if descendant.Name == "BellMeteor" then
		espObjects[descendant] = BasicESP.new("BellMeteor", descendant, createESPNameCallback("Bell Meteor"))
		return
	end

	if descendant.Name == "RareObelisk" then
		espObjects[descendant] = BasicESP.new("RareObelisk", descendant, createESPNameCallback("Rare Obelisk"))
		return
	end

	if descendant.Name == "HealBrick" then
		espObjects[descendant] = BasicESP.new("HealBrick", descendant, createESPNameCallback("Heal Brick"))
		return
	end

	if descendant.Name == "MantraObelisk" then
		espObjects[descendant] = BasicESP.new("MantraObelisk", descendant, createESPNameCallback("Mantra Obelisk"))
		return
	end

	if descendant:IsA("MeshPart") and descendant:FindFirstChild("InteractPrompt") then
		espObjects[descendant] = BasicESP.new("BRWeapon", descendant, createESPNameCallback(descendant.Name))
		return
	end
end

-- On descendant removing.
---@param descendant Instance
local function onDescendantRemoving(descendant)
	if not espObjects[descendant] then
		return
	end

	espObjects[descendant]:detach()
	espObjects[descendant] = nil
end

-- Initialize ESP.
function ESP.init()
	espMaid:add(renderStepped:connect("ESP_RenderStepped", updateESP))
	espMaid:add(gameDescendantAdded:connect("ESP_DescendantAdded", onDescendantAdded))
	espMaid:add(gameDescendantRemoving:connect("ESP_DescendantRemoving", onDescendantRemoving))
end

-- Detach ESP.
function ESP.detach()
	espMaid:clean()

	for _, espObject in pairs(espObjects) do
		espObject:detach()
	end
end

-- Return ESP module.
return ESP
