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

---@module Utility.Table
local Table = require("Utility/Table")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Visuals module.
local Visuals = { bdata = nil, drinfo = nil }

-- Last visuals update.
local lastVisualsUpdate = os.clock()

-- Services.
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local textChatService = game:GetService("TextChatService")
local userInputService = game:GetService("UserInputService")
local guiService = game:GetService("GuiService")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local visualsMaid = Maid.new()
local builderAssistanceMaid = Maid.new()

-- Card frames.
local cardFrames = {}

-- Map.
local labelMap = {}
local hoveringMap = {}

-- Terrain attachments.
local attachments = {}

-- Groups.
local groups = {}

-- Original stores.
local fieldOfView = visualsMaid:mark(OriginalStore.new())

-- Original store managers.
local showRobloxChatMap = visualsMaid:mark(OriginalStoreManager.new())
local noAnimatedSeaMap = visualsMaid:mark(OriginalStoreManager.new())
local noPersistentMap = visualsMaid:mark(OriginalStoreManager.new())
local buildAssistanceMap = visualsMaid:mark(OriginalStoreManager.new())
local jobBoardMap = visualsMaid:mark(OriginalStoreManager.new())

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

	if sanity.Value <= sanity.MaxValue * 0.10 then
		mainColor = Color3.fromRGB(255, 0, 0)
	end

	if sanity.Value <= 0.0 then
		mainColor = Color3.fromRGB(114, 114, 114)
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

---On Player GUI descendant added.
---@param descendant Instance
local onPlayerGuiDescendantAdded = LPH_NO_VIRTUALIZE(function(descendant)
	if descendant.Name ~= "CardFrame" then
		return
	end

	cardFrames[descendant] = true
end)

---On Player GUI descendant removed.
---@param descendant Instance
local onPlayerGuiDescendantRemoving = LPH_NO_VIRTUALIZE(function(descendant)
	if not cardFrames[descendant] then
		return
	end

	cardFrames[descendant] = nil
end)

---Update card frames.
local updateCardFrames = LPH_NO_VIRTUALIZE(function()
	for frame in next, cardFrames do
		local title = frame:FindFirstChild("Title")
		if not title then
			continue
		end

		local border = frame:FindFirstChild("Border")
		if not border then
			continue
		end

		local drinfo = Visuals.drinfo
		if not drinfo then
			continue
		end

		---@type BuilderData
		local bdata = Visuals.bdata
		if not bdata then
			continue
		end

		local trimmedName = string.gsub(title.Text, "^%s*(.-)%s*$", "%1")
		local cardInData = table.find(bdata.talents, trimmedName) or table.find(bdata.mantras, trimmedName)

		buildAssistanceMap:add(border, "ImageColor3", cardInData and Color3.new(0, 255, 0) or Color3.new(255, 0, 0))

		if
			cardInData
			and bdata.ddata:possible(trimmedName, bdata.pre)
			and not bdata.ddata:possible(trimmedName, bdata.post)
		then
			buildAssistanceMap:add(border, "ImageColor3", Color3.new(255, 0, 255))
		end

		if cardInData then
			continue
		end

		local mappingMatch = {
			["Vitality"] = { expectedValue = bdata.traits["Vitality"], value = drinfo["TraitHealth"] },
			["Erudition"] = { expectedValue = bdata.traits["Erudition"], value = drinfo["TraitEther"] },
			["Proficiency"] = { expectedValue = bdata.traits["Proficiency"], value = drinfo["TraitWeaponDamage"] },
			["Songchant"] = { expectedValue = bdata.traits["Songchant"], value = drinfo["TraitMantraDamage"] },
		}

		for idx, data in next, mappingMatch do
			if not title.Text:match(idx) then
				continue
			end

			buildAssistanceMap:add(
				border,
				"ImageColor3",
				data.expectedValue ~= data.value and Color3.new(0, 255, 0) or Color3.new(255, 0, 0)
			)
		end
	end
end)

---Update power background.
---@param jframe Frame
local updatePowerBackground = LPH_NO_VIRTUALIZE(function(jframe)
	local panels = jframe and jframe:FindFirstChild("Panels")
	local infoFrame = panels and panels:FindFirstChild("InfoFrame")
	local sheets = infoFrame and infoFrame:FindFirstChild("Sheets")
	local power = sheets and sheets:FindFirstChild("Power")
	local background = power and power:FindFirstChild("Background")
	if not background then
		return
	end

	local drinfo = Visuals.drinfo
	if not drinfo then
		return
	end

	---@type BuilderData
	local bdata = Visuals.bdata
	if not bdata then
		return
	end

	---@note: We do not care if there is no pre-shrine state at all.
	if not bdata:dshrine() then
		return
	end

	local color = Color3.fromRGB(245, 137, 5)
	local pstate = bdata:ipre(drinfo)

	if pstate == 0 then
		color = Color3.fromRGB(97, 4, 113)
	end

	if pstate == 1 then
		color = Color3.fromRGB(37, 129, 236)
	end

	buildAssistanceMap:add(background, "BackgroundColor3", color)
end)

---Update attribute frame.
---@param jframe Frame
local updateAttributeFrame = LPH_NO_VIRTUALIZE(function(jframe)
	local panels = jframe:FindFirstChild("Panels")
	local attributeFrame = panels and panels:FindFirstChild("AttributeFrame")
	local sheets = attributeFrame and attributeFrame:FindFirstChild("Sheets")
	if not sheets then
		return
	end

	local drinfo = Visuals.drinfo
	if not drinfo then
		return
	end

	---@type BuilderData
	local bdata = Visuals.bdata
	if not bdata then
		return
	end

	local attributes = bdata:attributes(drinfo)
	local mapping = {
		["Agility"] = attributes.base["Agility"],
		["Strength"] = attributes.base["Strength"],
		["Fortitude"] = attributes.base["Fortitude"],
		["Intelligence"] = attributes.base["Intelligence"],
		["Willpower"] = attributes.base["Willpower"],
		["Charisma"] = attributes.base["Charisma"],
		["ElementBlood"] = attributes.attunement["Bloodrend"],
		["ElementFire"] = attributes.attunement["Flamecharm"],
		["ElementIce"] = attributes.attunement["Frostdraw"],
		["ElementLightning"] = attributes.attunement["Thundercall"],
		["ElementWind"] = attributes.attunement["Galebreathe"],
		["ElementShadow"] = attributes.attunement["Shadowcast"],
		["ElementMetal"] = attributes.attunement["Ironsing"],
		["WeaponHeavy"] = attributes.weapon["Heavy Wep."],
		["WeaponMedium"] = attributes.weapon["Medium Wep."],
		["WeaponLight"] = attributes.weapon["Light Wep."],
	}

	for _, instance in next, sheets:GetDescendants() do
		if not instance:IsA("TextButton") then
			continue
		end

		local expectedValue = mapping[instance.Name]
		if not expectedValue then
			continue
		end

		local background = instance:FindFirstChild("Background")
		if not background then
			continue
		end

		local valueLabel = instance:FindFirstChild("Value")
		if not valueLabel then
			continue
		end

		local statInvested = tonumber(drinfo["Stat" .. instance.Name])
		if not statInvested then
			continue
		end

		local value = (bdata:ipre(drinfo) == 0 and statInvested <= 0) and statInvested or tonumber(valueLabel.Text)
		if not value then
			continue
		end

		local abbrevLabel = instance:FindFirstChild("Abbrev")
		if not abbrevLabel then
			continue
		end

		local color = expectedValue ~= value and Color3.fromRGB(9, 136, 0) or Color3.fromRGB(127, 0, 2)

		if value > expectedValue then
			color = Color3.fromRGB(128, 128, 128)
		end

		buildAssistanceMap:add(background, "BackgroundColor3", color)

		buildAssistanceMap:add(abbrevLabel, "Text", string.format("GET (%i)", expectedValue))
	end
end)

---Update traits.
---@param jframe Frame
local updateTraits = LPH_NO_VIRTUALIZE(function(jframe)
	local panels = jframe:FindFirstChild("Panels")
	local infoFrame = panels and panels:FindFirstChild("InfoFrame")
	local sheets = infoFrame and infoFrame:FindFirstChild("Sheets")
	local traitSheet = sheets and sheets:FindFirstChild("TraitSheet")
	local container = traitSheet and traitSheet:FindFirstChild("Container")
	if not container then
		return
	end

	local drinfo = Visuals.drinfo
	if not drinfo then
		return
	end

	---@type BuilderData
	local bdata = Visuals.bdata
	if not bdata then
		return
	end

	local mapping = {
		["Ether"] = bdata.traits["Erudition"],
		["Health"] = bdata.traits["Vitality"],
		["WeaponDamage"] = bdata.traits["Proficiency"],
		["MantraDamage"] = bdata.traits["Songchant"],
	}

	for _, instance in next, sheets:GetDescendants() do
		if not instance:IsA("Frame") then
			continue
		end

		local expectedValue = mapping[instance.Name]
		if not expectedValue then
			continue
		end

		local background = instance:FindFirstChild("Background")
		if not background then
			continue
		end

		local valueLabel = instance:FindFirstChild("Value")
		if not valueLabel then
			continue
		end

		local value = tonumber(valueLabel.Text)
		if not value then
			continue
		end

		local color = expectedValue ~= value and Color3.fromRGB(9, 136, 0) or Color3.fromRGB(127, 0, 2)

		if value > expectedValue then
			color = Color3.fromRGB(128, 128, 128)
		end

		buildAssistanceMap:add(background, "BackgroundColor3", color)
	end
end)

---Update talent sheet.
---@param jframe Frame
local updateTalentSheet = LPH_NO_VIRTUALIZE(function(jframe)
	local panels = jframe:FindFirstChild("TalentSheet")
	local container = panels and panels:FindFirstChild("Container")
	local talentScroll = container and container:FindFirstChild("TalentScroll")
	if not talentScroll then
		return
	end

	local drinfo = Visuals.drinfo
	if not drinfo then
		return
	end

	---@type BuilderData
	local bdata = Visuals.bdata
	if not bdata then
		return
	end

	local divider = talentScroll:FindFirstChild("8ZQuestDivider")
	if not divider then
		return
	end

	local label = talentScroll:FindFirstChildWhichIsA("TextLabel")
	if not label then
		return
	end

	-- clean maid to re-setup
	builderAssistanceMaid:clean()

	-- create state
	labelMap = {}

	-- first step: color everything inside and remove everything that is in the builder list already
	local filteredTalents = table.clone(bdata.talents)

	for _, instance in next, talentScroll:GetDescendants() do
		if not instance:IsA("TextLabel") then
			continue
		end

		local idx = Table.find(filteredTalents, function(value, _)
			return instance.Text:match(value)
		end)

		if not idx then
			continue
		end

		buildAssistanceMap:add(instance, "TextColor3", Color3.fromRGB(9, 255, 0))

		filteredTalents[idx] = nil
	end

	-- pre second step: create a nice looking separator
	local tseparator = InstanceWrapper.mark(builderAssistanceMaid, "tdivider", divider:Clone())
	tseparator.Name = "LMissingTalentDivider"
	tseparator.Parent = talentScroll

	-- second step: add every filtered talent as red (or purple if pre-shrine)
	for _, talent in next, filteredTalents do
		local data = bdata.ddata:get(talent)
		if not data then
			continue
		end

		local nlabel = InstanceWrapper.mark(builderAssistanceMaid, talent, label:Clone())
		local pshlocked = (bdata.ddata:possible(talent, bdata.pre) and not bdata.ddata:possible(talent, bdata.post))
		nlabel.Name = "M" .. talent
		nlabel.Text = talent
		nlabel.TextColor3 = pshlocked and Color3.fromRGB(255, 4, 255) or Color3.fromRGB(255, 0, 2)
		nlabel.Parent = talentScroll

		labelMap[nlabel.Name] = data
	end

	-- pre third step: create a nice looking separator
	local mseparator = InstanceWrapper.mark(builderAssistanceMaid, "mdivider", divider:Clone())
	mseparator.Name = "XMissingMantraDivider"
	mseparator.Parent = talentScroll

	-- third step: add every mantra as red (or purple if pre-shrine)
	for _, mantra in next, bdata.mantras do
		local data = bdata.ddata:get(mantra)
		if not data then
			continue
		end

		local idx = Table.find(players.LocalPlayer.Backpack:GetChildren(), function(value, _)
			local displayName = value:GetAttribute("DisplayName")
			return displayName and displayName:match(mantra)
		end)

		local nlabel = InstanceWrapper.mark(builderAssistanceMaid, mantra, label:Clone())
		local pshlocked = (bdata.ddata:possible(mantra, bdata.pre) and not bdata.ddata:possible(mantra, bdata.post))
		nlabel.Name = "Z" .. mantra
		nlabel.Text = mantra
		nlabel.TextColor3 = pshlocked and Color3.fromRGB(255, 4, 255) or Color3.fromRGB(255, 0, 2)
		nlabel.Parent = talentScroll

		if idx then
			nlabel.TextColor3 = Color3.fromRGB(9, 255, 0)
		end

		labelMap[nlabel.Name] = data
	end
end)

---Update card hovering.
local updateCardHovering = LPH_NO_VIRTUALIZE(function()
	local localPlayer = players.LocalPlayer
	local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
	local backpackGui = playerGui and playerGui:FindFirstChild("BackpackGui")
	if not backpackGui then
		return
	end

	local bpJournalFrame = backpackGui and backpackGui:FindFirstChild("JournalFrame")
	if not bpJournalFrame then
		return
	end

	local talentSheet = bpJournalFrame:FindFirstChild("TalentSheet")
	local container = talentSheet and talentSheet:FindFirstChild("Container")
	local talentScroll = container and container:FindFirstChild("TalentScroll")
	if not talentScroll then
		return
	end

	local talentDisplay = talentSheet and talentSheet:FindFirstChild("TalentDisplay")
	local cardFrame = talentDisplay and talentDisplay:FindFirstChild("CardFrame")
	if not cardFrame then
		return
	end

	local icon = cardFrame:FindFirstChild("Icon")
	local stats = cardFrame:FindFirstChild("Stats")
	local class = cardFrame:FindFirstChild("Class")
	local desc = cardFrame:FindFirstChild("Desc")
	local title = cardFrame:FindFirstChild("Title")
	if not icon or not stats or not class or not desc or not title then
		return
	end

	local playerGui = players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local mousePosition = userInputService:GetMouseLocation() - guiService:GetGuiInset()
	if not mousePosition then
		return
	end

	local guiObjects = playerGui:GetGuiObjectsAtPosition(mousePosition.X, mousePosition.Y)

	-- Remove any objects that we are no longer hovering over
	for name, _ in next, hoveringMap do
		if Table.find(guiObjects, function(object)
			return object.Name == name
		end) then
			continue
		end

		local object = talentScroll:FindFirstChild(name)
		if not object then
			continue
		end

		object.TextTransparency = 0.4

		hoveringMap[name] = nil
	end

	local firstHoveringData = nil
	local hoveringOverTalent = false

	-- Update any objects that we are currently hovering over
	for _, object in next, guiObjects do
		if not hoveringOverTalent and object:IsDescendantOf(talentSheet) then
			hoveringOverTalent = true
		end

		local data = labelMap[object.Name]
		if not data then
			continue
		end

		object.TextTransparency = 0.1

		---@note: Go off names because they should be unique and they constantly regenerate
		hoveringMap[object.Name] = true

		-- Set data.
		firstHoveringData = firstHoveringData or data
	end

	talentDisplay.Visible = hoveringOverTalent
	stats.Text = ""

	if not firstHoveringData then
		return
	end

	desc.Text = firstHoveringData.desc or "N/A"
	title.Text = firstHoveringData.name or "N/A"
	class.Text = firstHoveringData.category or "???"
	icon.ImageRectOffset = Vector2.new(0, 0)
	icon.Image = "rbxassetid://94097748688985"

	local reqData = firstHoveringData.reqs
	local reqTags = {}
	local tagMap = {
		["Strength"] = "STR",
		["Fortitude"] = "FTD",
		["Agility"] = "AGI",
		["Intelligence"] = "INT",
		["Willpower"] = "WIL",
		["Charisma"] = "CHA",
		["Mind"] = "MIND",
		["Body"] = "BODY",
		["Heavy Wep."] = "WEP",
		["Medium Wep."] = "WEP",
		["Light Wep."] = "WEP",
		["Flamecharm"] = "FLM",
		["Frostdraw"] = "FRST",
		["Thundercall"] = "THUN",
		["Galebreathe"] = "GALE",
		["Shadowcast"] = "SDW",
		["Ironsing"] = "IRON",
		["Bloodrend"] = "BLD",
	}

	local function checkAttributes(attributes)
		for idx, requirement in next, attributes do
			local tag = tagMap[idx]
			if not tag then
				continue
			end

			if requirement == 0 then
				continue
			end

			reqTags[#reqTags + 1] = string.format("%s %s", requirement, tag)
		end
	end

	if reqData.power ~= "0" then
		reqTags[#reqTags + 1] = string.format("PWR %s", reqData.power)
	end

	checkAttributes(reqData.base)
	checkAttributes(reqData.weapon)
	checkAttributes(reqData.attunement)

	stats.Text = table.concat(reqTags, ", ")
end)

---Update train.
---@param jframe Frame
local updateTrain = LPH_NO_VIRTUALIZE(function(jframe)
	local panels = jframe:FindFirstChild("Panels")
	local attributeFrame = panels and panels:FindFirstChild("AttributeFrame")
	local sheets = attributeFrame and attributeFrame:FindFirstChild("Sheets")
	if not sheets then
		return
	end

	local drinfo = Visuals.drinfo
	if not drinfo then
		return
	end

	---@type BuilderData
	local bdata = Visuals.bdata
	if not bdata then
		return
	end

	local attributes = bdata:attributes(drinfo)
	local mapping = {
		["Agility"] = attributes.base["Agility"],
		["Strength"] = attributes.base["Strength"],
		["Fortitude"] = attributes.base["Fortitude"],
		["Intelligence"] = attributes.base["Intelligence"],
		["Willpower"] = attributes.base["Willpower"],
		["Charisma"] = attributes.base["Charisma"],
		["ElementBlood"] = attributes.attunement["Bloodrend"],
		["ElementFire"] = attributes.attunement["Flamecharm"],
		["ElementIce"] = attributes.attunement["Frostdraw"],
		["ElementLightning"] = attributes.attunement["Thundercall"],
		["ElementWind"] = attributes.attunement["Galebreathe"],
		["ElementShadow"] = attributes.attunement["Shadowcast"],
		["ElementMetal"] = attributes.attunement["Ironsing"],
		["WeaponHeavy"] = attributes.weapon["Heavy Wep."],
		["WeaponMedium"] = attributes.weapon["Medium Wep."],
		["WeaponLight"] = attributes.weapon["Light Wep."],
	}

	for _, instance in next, sheets:GetDescendants() do
		if not instance:IsA("TextButton") then
			continue
		end

		local expectedValue = mapping[instance.Name]
		if not expectedValue then
			continue
		end

		local train = instance:FindFirstChild("Train")
		if not train then
			continue
		end

		if not train.Visible then
			continue
		end

		local valueLabel = instance:FindFirstChild("Value")
		if not valueLabel then
			continue
		end

		local statInvested = tonumber(drinfo["Stat" .. instance.Name])
		if not statInvested then
			continue
		end

		local value = (bdata:ipre(drinfo) == 0 and statInvested <= 0) and statInvested or tonumber(valueLabel.Text)
		if not value then
			continue
		end

		local color = expectedValue ~= value and Color3.fromRGB(9, 136, 0) or Color3.fromRGB(127, 0, 2)

		if value > expectedValue then
			color = Color3.fromRGB(128, 128, 128)
		end

		buildAssistanceMap:add(train, "ImageColor3", color)
	end
end)

---Update build assistance.
local updateBuildAssistance = LPH_NO_VIRTUALIZE(function()
	updateCardFrames()

	local localPlayer = players.LocalPlayer
	local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
	local backpackGui = playerGui and playerGui:FindFirstChild("BackpackGui")
	if not backpackGui then
		return
	end

	local bpJournalFrame = backpackGui and backpackGui:FindFirstChild("JournalFrame")
	if not bpJournalFrame then
		return
	end

	updateAttributeFrame(bpJournalFrame)
	updateTraits(bpJournalFrame)
	updatePowerBackground(bpJournalFrame)
	updateTalentSheet(bpJournalFrame)
	updateTrain(bpJournalFrame)
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

	---@note: Probably set a proper restore for this?
	--- But, in Deepwoken, users cannot realisitically access the Roblox chat anyway.
	textChatService.OnIncomingMessage = function(message)
		local source = message.TextSource
		if not source then
			return
		end

		local player = players:GetPlayerByUserId(source.UserId)
		if not player then
			return
		end

		message.PrefixText = string.gsub(message.PrefixText, player.DisplayName, player.Name)
		message.PrefixText = string.format(
			"(%s) %s",
			player:GetAttribute("CharacterName") or "Unknown Character Name",
			message.PrefixText
		)
	end
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

---Update terrain attachments.
local updateTerrainAttachments = LPH_NO_VIRTUALIZE(function()
	for _, attachment in next, attachments do
		local jtg = attachment:FindFirstChild("JobTrackerGui")
		if not jtg then
			continue
		end

		jobBoardMap:add(jtg, "MaxDistance", Configuration.idOptionValue("JobBoard", "MaxDistance") or 1e9)
	end
end)

---Update visuals.
local updateVisuals = LPH_NO_VIRTUALIZE(function()
	for _, group in next, groups do
		group:update()
	end

	if Configuration.expectToggleValue("BuildAssistance") then
		updateCardHovering()
	end

	if os.clock() - lastVisualsUpdate <= 1.0 then
		return
	end

	lastVisualsUpdate = os.clock()

	if Configuration.idToggleValue("JobBoard", "Enable") then
		updateTerrainAttachments()
	else
		jobBoardMap:restore()
	end

	if Configuration.expectToggleValue("SanityTracker") then
		updateSanityTracker()
	else
		visualsMaid["SanityTextLabel"] = nil
	end

	if Configuration.expectToggleValue("BuildAssistance") then
		updateBuildAssistance()
	else
		buildAssistanceMap:restore()
		builderAssistanceMaid:clean()
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

	-- safeguard lol
	if players:FindFirstChild(child.Name) then
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

	if name == "MinistryCacheIndicator" then
		return emplaceObject(child, PartESP.new("MinistryCacheIndicator", child, "Ministry Cache Indicator"))
	end

	if name == "BigArtifact" and child:IsA("Model") then
		return emplaceObject(child, ModelESP.new("Artifact", child, "Artifact"))
	end

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

	if child:IsA("Model") and child:WaitForChild("LootUpdated", 0.1) then
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

	if name == "BellKeys" then
		for _, descendant in next, child:GetDescendants() do
			if not descendant:IsA("BasePart") then
				continue
			end

			if descendant.Name ~= "BellKey" then
				continue
			end

			return emplaceObject(descendant, PartESP.new("BellKey", descendant, "Bell Key"))
		end
	end

	if name == "JobBoard" then
		return emplaceObject(child, ModelESP.new("JobBoard", child, "Job Board"))
	end

	if name == "BigArtifact" and child:IsA("Model") then
		return emplaceObject(child, ModelESP.new("Artifact", child, "Artifact"))
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

---On terrain added.
local onTerrainChildAdded = LPH_NO_VIRTUALIZE(function(child)
	if child.Name ~= "Attachment" and not child:IsA("Attachment") then
		return
	end

	attachments[#attachments + 1] = child
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
	local terrain = workspace:WaitForChild("Terrain")

	createChildrenListener(terrain, "Terrain", onTerrainChildAdded, onInstanceRemoving)
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

	local localPlayer = players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local playerGuiDescendantAdded = Signal.new(playerGui.DescendantAdded)
	local playerGuiDescendantRemoving = Signal.new(playerGui.DescendantRemoving)

	visualsMaid:add(playerGuiDescendantAdded:connect("Visuals_OnPlayerGuiDescendantAdded", onPlayerGuiDescendantAdded))
	visualsMaid:add(
		playerGuiDescendantRemoving:connect("Visuals_OnPlayerGuiDescendantRemoving", onPlayerGuiDescendantRemoving)
	)
	visualsMaid:add(renderStepped:connect("Visuals_RenderStepped", updateVisuals))

	for _, descendant in next, playerGui:GetDescendants() do
		onPlayerGuiDescendantAdded(descendant)
	end

	local info = replicatedStorage:WaitForChild("Info")
	local dataReplication = info:WaitForChild("DataReplication")
	local dataReplicationModule = require(dataReplication)

	Visuals.drinfo = dataReplicationModule.GetData()

	Logger.warn("Visuals initialized.")
end

-- Detach Visuals.
function Visuals.detach()
	for _, group in next, groups do
		group:detach()
	end

	visualsMaid:clean()
	builderAssistanceMaid:clean()

	Logger.warn("Visuals detached.")
end

-- Return Visuals module.
return Visuals
