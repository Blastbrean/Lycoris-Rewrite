---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Features.Visuals.Objects.ModelESP
local ModelESP = require("Features/Visuals/Objects/ModelESP")

---@module Features.Visuals.Objects.PartESP
local PartESP = require("Features/Visuals/Objects/PartESP")

---@module Features.Visuals.Objects.MobESP
local MobESP = require("Features/Visuals/Objects/MobESP")

---@module Features.Visuals.Objects.PlayerESP
local PlayerESP = require("Features/Visuals/Objects/PlayerESP")

---@module Features.Visuals.Objects.FilteredESP
local FilteredESP = require("Features/Visuals/Objects/FilteredESP")

---@module Features.Visuals.Group
local Group = require("Features/Visuals/Group")

---@module Utility.Profiler
local Profiler = require("Utility/Profiler")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.OriginalStore
local OriginalStore = require("Utility/OriginalStore")

---@module Utility.OriginalStoreManager
local OriginalStoreManager = require("Utility/OriginalStoreManager")

-- Visuals module.
---@optimization: All Configuration calls are replaced with direct accessors.
---The rendering starts after our script is loaded; so we can assume the objects exist.
---@todo: Tag system so we can easily add new text "tags" to objects.
local Visuals = {}

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local textChatService = game:GetService("TextChatService")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local visualsMaid = Maid.new()

-- Groups.
local groups = {}

-- Original stores.
local fieldOfView = visualsMaid:mark(OriginalStore.new())

-- Original store managers.
local showRobloxChatMap = visualsMaid:mark(OriginalStoreManager.new())

---Update show roblox chat.
local function updateShowRobloxChat()
	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	local playerGui = localPlayer.PlayerGui
	if not playerGui then
		return
	end

	local chatWindowConfiguration = textChatService:FindFirstChild("ChatWindowConfiguration")
	if not chatWindowConfiguration then
		return
	end

	showRobloxChatMap:add(chatWindowConfiguration, "Enabled", true)

	local chatGui = playerGui:FindFirstChild("Chat")
	local chatFrame = chatGui and chatGui:FindFirstChild("Frame")

	local chatBarFrame = chatFrame and chatFrame:FindFirstChild("ChatBarParentFrame")
	local chatChannelFrame = chatFrame and chatFrame:FindFirstChild("ChatChannelParentFrame")

	if not chatBarFrame or not chatChannelFrame then
		return
	end

	showRobloxChatMap:add(chatBarFrame, "Position", UDim2.new(0, 0, 0, 195))
	showRobloxChatMap:add(chatChannelFrame, "Visible", true)
end

---Update visuals.
local function updateVisuals()
	for _, group in next, groups do
		group:update()
	end

	if Configuration.toggleValue("ModifyFieldOfView") then
		fieldOfView:set(workspace.CurrentCamera, "FieldOfView", Configuration.optionValue("FieldOfView"))
	else
		fieldOfView:restore()
	end

	if Configuration.toggleValue("ShowRobloxChat") then
		updateShowRobloxChat()
	else
		showRobloxChatMap:restore()
	end
end

---Emplace object.
---@param instance Instance
---@param object ModelESP|PartESP
local function emplaceObject(instance, object)
	local group = groups[object.identifier] or Group.new(object.identifier)

	group:insert(instance, object)

	groups[object.identifier] = group
end

---On Live ChildAdded.
---@param child Instance
local function onLiveChildrenAdded(child)
	if players:GetPlayerFromCharacter(child) then
		return
	end

	return emplaceObject(child, MobESP.new("Mob", child, child:GetAttribute("MOB_rich_name") or child.Name))
end

---On NPCs ChildAdded.
---@param child Instance
local function onNPCsChildAdded(child)
	return emplaceObject(child, ModelESP.new("NPC", child, child.Name))
end

---On Ingredients ChildAdded.
---@param child Instance
local function onIngredientsChildAdded(child)
	return emplaceObject(child, FilteredESP.new(PartESP.new("Ingredient", child, child.Name)))
end

---On Thrown ChildAdded.
---@param child Instance
local function onThrownChildAdded(child)
	local name = child.Name

	if name == "BellMeteor" then
		return emplaceObject(child, ModelESP.new("BellMeteor", child, "Bell Meteor"))
	end

	if name == "ExplodeCrate" then
		return emplaceObject(child, ModelESP.new("ExplosiveBarrel", child, "Explosive Barrel"))
	end

	if name == "BagDrop" then
		return emplaceObject(child, PartESP.new("BagDrop", child, "Bag"))
	end
end

---On Workspace ChildAdded.
---@param child Instance
local function onWorkspaceChildAdded(child)
	local name = child.Name

	if name == "JobBoard" then
		return emplaceObject(child, ModelESP.new("JobBoard", child, "Job Board"))
	end

	if name == "BigArtifact" and child:IsA("BasePart") then
		return emplaceObject(child, PartESP.new("Artifact", child, "Artifact"))
	end

	if name == "WindrunnerOrb" and child:IsA("BasePart") then
		return emplaceObject(child, PartESP.new("WindrunnerOrb", child, "Windrunner Orb"))
	end

	if name == "DepthsWhirlpool" then
		return emplaceObject(child, ModelESP.new("Whirlpool", child, "Whirlpool"))
	end

	if name == "EventFeatherRef" then
		return emplaceObject(child, PartESP.new("OwlFeathers", child, "Owl Feathers"))
	end

	if name:match("GuildDoor") then
		local doorName = child:GetAttribute("GuildName") or "Unidentified Guild Door"
		return emplaceObject(child, PartESP.new("GuildDoor", child, doorName))
	end

	if name == "GuildBanner" then
		return emplaceObject(child, ModelESP.new("GuildBanner", child, "Guild Banner"))
	end

	if name == "Obelisk" then
		return emplaceObject(child, ModelESP.new("Obelisk", child, "Obelisk"))
	end

	if name:match("ArmorBrick") then
		local billboardGui = child:FindFirstChild("BillboardGui")
		local armorBrickLabel = billboardGui and billboardGui:FindFirstChild("TextLabel")
		local armorBrickName = armorBrickLabel and armorBrickLabel.Text

		if not armorBrickLabel then
			armorBrickName = "Unknown Armor Brick"
		end

		return emplaceObject(child, PartESP.new("ArmorBrick", child, armorBrickName))
	end

	if name == "LootUpdated" then
		return emplaceObject(child, ModelESP.new("Chest", child.Parent, "Chest"))
	end

	if name == "RareObelisk" then
		return emplaceObject(child, PartESP.new("RareObelisk", child, "Rare Obelisk"))
	end

	if name == "HealBrick" then
		return emplaceObject(child, PartESP.new("HealBrick", child, "Heal Brick"))
	end

	if name == "MantraObelisk" then
		return emplaceObject(child, PartESP.new("MantraObelisk", child, "Mantra Obelisk"))
	end

	if child:IsA("MeshPart") and child:FindFirstChild("InteractPrompt") and not name:match("Barrel") then
		return emplaceObject(child, PartESP.new("BRWeapon", child, name))
	end
end

---On instance removing.
---@param inst Instance
local function onInstanceRemoving(inst)
	for _, group in next, groups do
		local object = group:remove(inst)
		if not object then
			continue
		end

		object:detach()
	end
end

---On player added.
---@todo: Clean this code up.
---@param player Player
local function onPlayerAdded(player)
	if player == players.LocalPlayer then
		return
	end

	local characterAdded = Signal.new(player.CharacterAdded)
	local characterRemoving = Signal.new(player.CharacterRemoving)
	local playerDestroying = Signal.new(player.Destroying)

	local characterAddedId = nil
	local characterRemovingId = nil
	local playerDestroyingId = nil

	characterAddedId = visualsMaid:add(characterAdded:connect("Visuals_OnCharacterAdded", function(character)
		emplaceObject(player, PlayerESP.new("Player", player, character))
	end))

	characterRemovingId = visualsMaid:add(characterRemoving:connect("Visuals_OnCharacterRemoving", function()
		onInstanceRemoving(player)
	end))

	playerDestroyingId = visualsMaid:add(playerDestroying:connect("Visuals_OnPlayerDestroying", function()
		visualsMaid[characterAddedId] = nil
		visualsMaid[characterRemovingId] = nil
		visualsMaid[playerDestroyingId] = nil
	end))

	local character = player.Character
	if not character then
		return
	end

	emplaceObject(player, PlayerESP.new("Player", player, character))
end

---Create children listener.
---@param instance Instance
---@param identifier string
---@param addedCallback function
---@param removingCallback function
local function createChildrenListener(instance, identifier, addedCallback, removingCallback)
	local childAdded = Signal.new(instance.ChildAdded)
	local childRemoved = Signal.new(instance.ChildRemoved)

	visualsMaid:add(childAdded:connect(string.format("Visuals_%sOnChildAdded", identifier), addedCallback))
	visualsMaid:add(childRemoved:connect(string.format("Visuals_%sOnChildRemoved", identifier), removingCallback))

	Profiler.run(string.format("Visuals_%sAddInitialChildren", identifier), function()
		for _, child in next, instance:GetChildren() do
			addedCallback(child)
		end
	end)
end

---Initialize update loop.
---@note: Read about optimization above for more information.
function Visuals.start()
	visualsMaid:add(renderStepped:connect("Visuals_RenderStepped", updateVisuals))
end

---Initialize Visuals.
function Visuals.init()
	local live = workspace:WaitForChild("Live")
	local npcs = workspace:WaitForChild("NPCs")
	local ingredients = workspace:WaitForChild("Ingredients")
	local thrown = workspace:WaitForChild("Thrown")

	createChildrenListener(workspace, "Workspace", onWorkspaceChildAdded, onInstanceRemoving)
	createChildrenListener(thrown, "Thrown", onThrownChildAdded, onInstanceRemoving)
	createChildrenListener(live, "Live", onLiveChildrenAdded, onInstanceRemoving)
	createChildrenListener(npcs, "NPCs", onNPCsChildAdded, onInstanceRemoving)
	createChildrenListener(ingredients, "Ingredients", onIngredientsChildAdded, onInstanceRemoving)
	createChildrenListener(players, "Players", onPlayerAdded, onInstanceRemoving)

	---@note: We only need to get this once.
	for _, descendant in next, replicatedStorage:WaitForChild("MarkerWorkspace"):GetDescendants() do
		if descendant.Name ~= "AreaMarker" then
			continue
		end

		local areaMarkerName = descendant.Parent.Name or "Unidentified Area Marker"
		emplaceObject(descendant, FilteredESP.new(PartESP.new("AreaMarker", descendant, areaMarkerName)))
	end
end

-- Detach Visuals.
function Visuals.detach()
	for _, group in next, groups do
		group:detach()
	end

	visualsMaid:clean()
end

-- Return Visuals module.
return Visuals
