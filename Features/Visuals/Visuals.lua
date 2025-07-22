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

---@module Utility.InstanceWrapper
local InstanceWrapper = require("Utility/InstanceWrapper")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Visuals module.
local Visuals = { currentBuilderData = nil }

-- Last visuals update.
local lastVisualsUpdate = os.clock()

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
local noAnimatedSeaMap = visualsMaid:mark(OriginalStoreManager.new())
local noPersistentMap = visualsMaid:mark(OriginalStoreManager.new())
local talentHighlighterMap = visualsMaid:mark(OriginalStoreManager.new())

---Update sanity tracker.
local updateSanityTracker = LPH_NO_VIRTUALIZE(function()
	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	local playerGui = localPlayer.PlayerGui
	if not playerGui then
		return
	end

	local currencyGui = playerGui:FindFirstChild("CurrencyGui")
	if not currencyGui then
		return
	end

	local currencyFrame = currencyGui:FindFirstChild("CurrencyFrame")
	if not currencyFrame then
		return
	end

	local crownsTextLabel = currencyFrame:FindFirstChild("Crowns")
	if not crownsTextLabel then
		return
	end

	-- Character.
	local character = localPlayer.Character
	if not character then
		return
	end

	local sanity = character:FindFirstChild("Sanity")
	if not sanity then
		return
	end

	-- Setup.
	local sanityTextLabel = InstanceWrapper.mark(visualsMaid, "SanityTextLabel", crownsTextLabel:Clone())
	sanityTextLabel.Name = "Sanity"
	sanityTextLabel.Parent = currencyFrame
	sanityTextLabel.Visible = true

	local mainColor = Color3.fromRGB(0, 191, 255)

	if sanity.Value <= sanity.MaxValue * 0.70 then
		mainColor = Color3.fromRGB(255, 239, 94)
	end

	if sanity.Value <= sanity.MaxValue * 0.50 then
		mainColor = Color3.fromRGB(255, 216, 110)
	end

	if sanity.Value <= sanity.MaxValue * 0.40 then
		mainColor = Color3.fromRGB(255, 111, 0)
	end

	if sanity.Value <= sanity.MaxValue * 0.20 then
		mainColor = Color3.fromRGB(255, 0, 0)
	end

	-- Amount.
	local amountLabel = sanityTextLabel:FindFirstChild("Amount")
	if not amountLabel then
		return
	end

	local formatString = ((sanity.Value / sanity.MaxValue) * 100) <= 1.0 and "%.2f" or "%i"
	amountLabel.Text = string.format(formatString, (sanity.Value / sanity.MaxValue) * 100) .. "%"
	amountLabel.TextColor3 = mainColor

	-- Icon.
	local icon = sanityTextLabel:FindFirstChild("Icon")
	if not icon then
		return
	end

	icon.Image = "http://www.roblox.com/asset/?id=16865012250"
	icon.ImageColor3 = mainColor
	icon.ImageRectOffset = Vector2.new(0, 0)
	icon.ImageRectSize = Vector2.new(0, 0)

	-- Lore.
	sanityTextLabel:SetAttribute("Tip_Title", "Sanity")
	sanityTextLabel:SetAttribute(
		"Tip_Desc",
		"The Flicker is a creeping affliction, awarded by the abyss for prolonged exposure to its horrors or a perverse talent for understanding its maddening secrets. This erosion of the mind holds a terrifying value in the afflicted's perception, granting a twisted understanding of the unseen, marking them as touched by powers beyond mortal comprehension."
	)
end)

---Update talent highlighter.
local updateTalentHighlighter = LPH_NO_VIRTUALIZE(function()
	local talentData = Visuals.currentBuilderData and Visuals.currentBuilderData.talents
	if not talentData then
		return
	end

	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	local playerGui = localPlayer.PlayerGui
	if not playerGui then
		return
	end

	local talentGui = playerGui:FindFirstChild("TalentGui")
	if not talentGui then
		return
	end

	local choiceFrame = talentGui:FindFirstChild("ChoiceFrame")
	if not choiceFrame then
		return
	end

	for _, instance in pairs(choiceFrame:GetChildren()) do
		if not instance:IsA("TextButton") then
			continue
		end

		local cardFrame = instance:FindFirstChild("CardFrame")
		if not cardFrame then
			continue
		end

		local talentInData = table.find(talentData, string.gsub(instance.Name, "^%s*(.-)%s*$", "%1"))

		talentHighlighterMap:add(
			cardFrame,
			"BackgroundColor3",
			talentInData and Color3.new(0, 255, 0) or Color3.new(255, 0, 0)
		)

		talentHighlighterMap:add(cardFrame, "BorderSizePixel", talentInData and 10 or 0)
	end
end)

---Update no persistence.
local updateNoPersistence = LPH_NO_VIRTUALIZE(function()
	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	for _, group in next, groups do
		for _, object in next, group:data() do
			if object.__type == "PlayerESP" and object.character and object.character:IsA("Model") then
				noPersistentMap:add(object.character, "ModelStreamingMode", Enum.ModelStreamingMode.Default)
			end

			if object.__type == "ModelESP" and object.model then
				noPersistentMap:add(object.model, "ModelStreamingMode", Enum.ModelStreamingMode.Default)
			end
		end
	end
end)

---Update show roblox chat.
local updateShowRobloxChat = LPH_NO_VIRTUALIZE(function()
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
end)

---Update no animated sea.
local updateNoAnimatedSea = LPH_NO_VIRTUALIZE(function()
	local localPlayer = players.LocalPlayer
	local playerScripts = localPlayer and localPlayer:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return
	end

	local seaClient = playerScripts:FindFirstChild("SeaClient")
	if not seaClient then
		return
	end

	noAnimatedSeaMap:add(seaClient, "Enabled", false)

	for _, descendant in next, seaClient:GetDescendants() do
		if not descendant:IsA("LocalScript") then
			continue
		end

		noAnimatedSeaMap:add(descendant, "Enabled", false)
	end
end)

---Update visuals.
local updateVisuals = LPH_NO_VIRTUALIZE(function()
	for _, group in next, groups do
		group:update()
	end

	if os.clock() - lastVisualsUpdate <= 1.0 then
		return
	end

	lastVisualsUpdate = os.clock()

	if Configuration.expectToggleValue("SanityTracker") then
		updateSanityTracker()
	else
		visualsMaid["SanityTextLabel"] = nil
	end

	if Configuration.expectToggleValue("TalentHighlighter") then
		updateTalentHighlighter()
	else
		talentHighlighterMap:restore()
	end

	if Configuration.expectToggleValue("NoPersisentESP") then
		updateNoPersistence()
	else
		noPersistentMap:restore()
	end

	if Configuration.expectToggleValue("NoAnimatedSea") then
		updateNoAnimatedSea()
	else
		noAnimatedSeaMap:restore()
	end

	if Configuration.expectToggleValue("ModifyFieldOfView") then
		fieldOfView:set(workspace.CurrentCamera, "FieldOfView", Configuration.expectOptionValue("FieldOfView"))
	else
		fieldOfView:restore()
	end

	if Configuration.expectToggleValue("ShowRobloxChat") then
		updateShowRobloxChat()
	else
		showRobloxChatMap:restore()
	end
end)

---Emplace object.
---@param instance Instance
---@param object ModelESP|PartESP
local emplaceObject = LPH_NO_VIRTUALIZE(function(instance, object)
	local group = groups[object.identifier] or Group.new(object.identifier)

	group:insert(instance, object)

	groups[object.identifier] = group
end)

---On Live ChildAdded.
---@param child Instance
local onLiveChildrenAdded = LPH_NO_VIRTUALIZE(function(child)
	if players:GetPlayerFromCharacter(child) then
		return
	end

	return emplaceObject(child, MobESP.new("Mob", child, child:GetAttribute("MOB_rich_name") or child.Name))
end)

---On NPCs ChildAdded.
---@param child Instance
local onNPCsChildAdded = LPH_NO_VIRTUALIZE(function(child)
	if child.Name == "WindrunnerOrb" and child:IsA("BasePart") then
		return emplaceObject(child, PartESP.new("WindrunnerOrb", child, "Windrunner Orb"))
	end

	return emplaceObject(child, ModelESP.new("NPC", child, child.Name))
end)

---On Ingredients ChildAdded.
---@param child Instance
local onIngredientsChildAdded = LPH_NO_VIRTUALIZE(function(child)
	return emplaceObject(child, FilteredESP.new(PartESP.new("Ingredient", child, child.Name)))
end)

---On Thrown ChildAdded.
---@param child Instance
local onThrownChildAdded = LPH_NO_VIRTUALIZE(function(child)
	local name = child.Name

	if name == "BellMeteor" then
		return emplaceObject(child, ModelESP.new("BellMeteor", child, "Bell Meteor"))
	end

	if name == "ExplodeCrate" then
		return emplaceObject(child, PartESP.new("ExplosiveBarrel", child, "Explosive Barrel"))
	end

	if name == "BagDrop" then
		return emplaceObject(child, PartESP.new("BagDrop", child, "Bag"))
	end

	if name == "EventFeatherRef" then
		return emplaceObject(child, PartESP.new("OwlFeathers", child, "Owl Feathers"))
	end

	if child:IsA("Model") and child:FindFirstChild("LootUpdated") then
		return emplaceObject(child, ModelESP.new("Chest", child, "Chest"))
	end
end)

---Create children listener.
---@param instance Instance
---@param identifier string
---@param addedCallback function
---@param removingCallback function
local createChildrenListener = LPH_NO_VIRTUALIZE(function(instance, identifier, addedCallback, removingCallback)
	local childAdded = Signal.new(instance.ChildAdded)
	local childRemoved = Signal.new(instance.ChildRemoved)

	visualsMaid:add(childAdded:connect(string.format("Visuals_%sOnChildAdded", identifier), addedCallback))
	visualsMaid:add(childRemoved:connect(string.format("Visuals_%sOnChildRemoved", identifier), removingCallback))

	Profiler.run(string.format("Visuals_%sAddInitialChildren", identifier), function()
		for _, child in next, instance:GetChildren() do
			addedCallback(child)
		end
	end)
end)

-- Forward declaration.
local onWorkspaceChildAdded = nil

---On instance removing.
---@param inst Instance
local onInstanceRemoving = LPH_NO_VIRTUALIZE(function(inst)
	for _, group in next, groups do
		local object = group:remove(inst)
		if not object then
			continue
		end

		object:detach()
	end
end)

---On Workspace ChildAdded.
---@param child Instance
onWorkspaceChildAdded = LPH_NO_VIRTUALIZE(function(child)
	local name = child.Name

	if name == "Layer2Floor2" then
		return createChildrenListener(child, "Layer2Floor2", onWorkspaceChildAdded, onInstanceRemoving)
	end

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

	if name == "MinistryCacheIndicator" then
		return emplaceObject(child, PartESP.new("MinistryCacheIndicator", child, "Ministry Cache Indicator"))
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
end)

---On player added.
---@param player Player
local onPlayerAdded = LPH_NO_VIRTUALIZE(function(player)
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
end)

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

	visualsMaid:add(renderStepped:connect("Visuals_RenderStepped", updateVisuals))

	Logger.warn("Visuals initialized.")
end

-- Detach Visuals.
function Visuals.detach()
	for _, group in next, groups do
		group:detach()
	end

	visualsMaid:clean()

	Logger.warn("Visuals detached.")
end

-- Return Visuals module.
return Visuals
