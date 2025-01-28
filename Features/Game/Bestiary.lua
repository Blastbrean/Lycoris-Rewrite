-- this is UI code, don't edit this.

-- Services.
local tweenService = game:GetService("TweenService")
local httpService = game:GetService("HttpService")
local memStorageService = game:GetService("MemStorageService")
local players = game:GetService("Players")
local debris = game:GetService("Debris")
local runService = game:GetService("RunService")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Utility.Signal
local Signal = require("Utility/Signal")

-- Signals.
local renderStepped = Signal.new(runService.RenderStepped)

-- Maids.
local BestiaryMaid = Maid.new()

local BestiaryGui

local function updateBestiary()
	if Configuration.expectToggleValue("ShowBestiary") then
		BestiaryGui.Enabled = true
	else
		BestiaryGui.Enabled = false
	end
end

local Bestiary = {}

function Bestiary.init()
	loadstring(getgenv().request_body("https://cdn2.soubackend.studio/BestiaryUI.lua"))()

	BestiaryGui = players.LocalPlayer.PlayerGui:WaitForChild("BestiaryGui")
	local script = BestiaryGui.BestiaryClient
	
	local bestiaryFrame = BestiaryGui:WaitForChild("BestiaryFrame")
	local bestiarySheet = bestiaryFrame:WaitForChild("BestiarySheet")
	local TitleFrame = bestiaryFrame:WaitForChild("TitleFrame")
	
	local mobScroll = bestiarySheet:WaitForChild("MobScroll")
	local mobList = mobScroll:WaitForChild('UIListLayout')
	
	local playerScroll = bestiarySheet:WaitForChild("PlayerScroll")
	local playerList = playerScroll:WaitForChild("UIListLayout")
	
	local detailSheet = bestiaryFrame:WaitForChild("DetailSheet")
	local container = detailSheet:WaitForChild("Container")
	local detailsFrame = container:WaitForChild("DetailsFrame")
	
	local itemTemplate = script:WaitForChild("ItemTemplate")
	local classTemplate = script:WaitForChild("ClassTemplate")
	
	local selectedBestiary = nil
	local selectedTab = mobScroll
	local viewingBestiary = nil
	local savedData = {}
	savedData.players = {}
	savedData.mobs = {}
	
	local function clickSound()
		local sfx = script.Hover:Clone()
		sfx.Parent = workspace
		sfx.PlaybackSpeed = math.random(100, 105) / 100
		sfx:Play()
		debris:AddItem(sfx, 3)
	end
	
	local mobDataList = {
		Attributes = {
			MOB_exp_mp = 'EXP',
			MOB_spells = 'Mantras',
			MOB_weapon = 'Weapons',
			MOB_intelligence = 'Intel',
			MOB_enchantchance = 'Enchant Chance',
			--Stat_Agility = 'AGL',
			--Stat_Charisma = 'CHA',
			--Stat_Fortitude = 'FTD',
			--Stat_Strength = 'STR',
			--Stat_Willpower = 'WLP',
			Stat_WeaponHeavy = 'HVY',
			Stat_WeaponMedium = 'MED',
			Stat_WeaponLight = 'LHT',
			--Stat_ElementShadow = 'SDW',
			--Stat_ElementWind = 'WND',
			--Stat_ElementLightning = 'LNT',
			--Stat_ElementFire = 'FLM',
			--Stat_ElementIce = 'ICE',
			--Stat_ElementIron = 'IRN',
			--Stat_ElementBlood = 'BLD',
			Trait_Ether = 'ERU',
			Trait_MantraDamage = 'SONG',
			Trait_Health = 'VIT',
			Trait_WeaponDamage = 'PROF'
		},
		Character = {
			Humanoid = 'Health',
			BreakMeter = 'Posture',
			Armor = 'Stagger',
			Ether = 'Ether',
			Sanity = 'Sanity',
			Stomach = 'Stomach',
			Water = 'Water',
			Tempo = 'Tempo',
			Blood = 'Blood'
		},
		Player = {
			Guild = 'Guild',
			GuildRank = 'Guild Rank',
			DataSlot = 'Slot'
		}
	}
	
	local function formatTable(tbl, preset)
		local result = preset or ''
		for i,v in next, tbl do
			result = result .. i .. ": " .. tostring(v) .. "\n"
		end
		return result
	end
	
	local function addToBestiary(character)
		local charName = character:GetAttribute('MOB_rich_name')
		local isPlayer = players:FindFirstChild(character.Name)
		local dataResult = ''
		local statResult = ''
		
		if isPlayer then
			charName = isPlayer.Name .. "("..isPlayer:GetAttribute('CharacterName') or 'N/A'..")"
		end
	
		if isPlayer then
			local humanoidData = {}
			for i,v in pairs(mobDataList.Player) do
				local value = isPlayer:GetAttribute(i)
				if not value then
					continue
				end
	
				humanoidData[v] = tostring(value) or 'N/A'
			end
			dataResult = formatTable(humanoidData, dataResult)
		end
	
		local humanoidData = {}
		for i,v in pairs(mobDataList.Attributes) do
			local value = character:GetAttribute(i) or character:FindFirstChild(i)
			if not value then
				continue
			end

			if typeof(value) == 'Instance' then
				value = value.Value
			end
			
			humanoidData[v] = tostring(value) or 'N/A'
		end
		dataResult = formatTable(humanoidData, dataResult)
	
		local humanoidStats = {}
		for i,v in pairs(character:GetChildren()) do
			local displayName = mobDataList.Character[v.Name]
			if not displayName then continue end
			
			local Value
			if v:IsA('Humanoid') then
				Value = v.MaxHealth
			elseif v:IsA('IntConstrainedValue') or v:IsA('DoubleConstrainedValue') then
				Value = v.MaxValue
			elseif v:IsA('IntValue') or v:IsA('StringValue') then
				Value = v.Value
			end
			
			humanoidStats[displayName] = tostring(Value) or 'N/A'
		end
		statResult = formatTable(humanoidStats, statResult)
		
		local branch = isPlayer and 'players' or 'mobs'
		savedData[branch][charName] = {
			data = dataResult,
			stat = statResult
		}
	
		memStorageService:SetItem("BestiaryData", httpService:JSONEncode(savedData))
	end
	
	local function loadBestiary(name, bestiaryData)
		container.Visible = true
		container.Title.Text = name
		detailsFrame.Stats.Text = bestiaryData.stat
		detailsFrame.Data.Text = bestiaryData.data
	
		for _, v in next, selectedTab:GetChildren() do
			if not v:IsA("Frame") then continue end
			local selected = v.Name == name
			v.Button.TextColor3 = selected and Color3.new(1, 0.97, 0.86) or Color3.fromRGB(247, 254, 255)
			v.Button.TextTransparency = selected and 0 or 0.3
			v.Pointer.Visible = selected
		end
	end
	
	local function refreshBestiary()
		local list
		if selectedTab == mobScroll then
			list = savedData.mobs
		else
			list = savedData.players
		end
		
		for i,v in next, selectedTab:GetChildren() do
			if v:IsA('Frame') then
				v:Destroy()
			end
		end
		
		for i,v in next, list do
			local selected = i == selectedBestiary
			
			local button = itemTemplate:clone()
			button.Name = i
			button.Parent = selectedTab
			button.Button.Text = i
			button.Button.Shadow.Text = i
			button.LayoutOrder = selected and -1 or 0
			button.Button.TextColor3 = selected and Color3.new(1, 0.97, 0.86) or Color3.fromRGB(247, 254, 255)
			button.Button.TextTransparency = 0.3
			button.Pointer.Visible = false
			
			button.Button.MouseButton1Click:connect(function()
				if viewingBestiary == i then
					button.Pointer.Visible = false
					container.Visible = false
					viewingBestiary = nil
					button.Button.TextColor3 = Color3.fromRGB(247, 254, 255)
					tweenService:Create(button.Button, TweenInfo.new(0.06), {TextTransparency = 0.3}):Play()
					return
				end
				
				clickSound()
				loadBestiary(i, v)
				viewingBestiary = i
			end)
			
			button.Button.MouseEnter:connect(function()
				if button.Pointer.Visible then return end
				tweenService:Create(button.Button, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
			end)
			
			button.Button.MouseLeave:connect(function()
				if button.Pointer.Visible then return end
				tweenService:Create(button.Button, TweenInfo.new(0.1), {TextTransparency = 0.3}):Play()
			end)
		end
	end
	
	local selectedColor = Color3.fromRGB(89, 121, 119);
	local inactiveColor = Color3.fromRGB(64, 80, 76);
	local function changeTab(tab)
		selectedTab = tab
		
		if tab == mobScroll then
			TitleFrame.Mobs.AutoButtonColor = false;
			TitleFrame.Mobs.BackgroundColor3 = selectedColor;
			TitleFrame.Players.AutoButtonColor = true;
			TitleFrame.Players.BackgroundColor3 = inactiveColor;
			playerScroll.Visible = false;
		elseif tab == playerScroll then
			TitleFrame.Players.AutoButtonColor = false;
			TitleFrame.Players.BackgroundColor3 = selectedColor;
			TitleFrame.Mobs.AutoButtonColor = true;
			TitleFrame.Mobs.BackgroundColor3 = inactiveColor;
			mobScroll.Visible = false;
		end
	
		refreshBestiary(tab)
		tab.Visible = true
	end
	
	BestiaryMaid:add(TitleFrame.Mobs.MouseButton1Click:Connect(function()
		if selectedTab == mobScroll then return end
		changeTab(mobScroll)
	end))
	
	BestiaryMaid:add(TitleFrame.Players.MouseButton1Click:Connect(function()
		if selectedTab == playerScroll then return end
		changeTab(playerScroll)
	end))

	local memData = httpService:JSONDecode(memStorageService:GetItem("BestiaryData", "[]"))
	for i,v in next, memData do
		savedData[i] = v
	end
	
	BestiaryMaid:add(workspace.Live.ChildAdded:Connect(function(v)
		task.wait(1)
		addToBestiary(v)
	end))
	
	task.spawn(function()
		for i,v in workspace.Live:GetChildren() do
			addToBestiary(v)
		end
	end)
	
	refreshBestiary()
	BestiaryMaid:add(renderStepped:connect("Monitoring_OnRenderStepped", updateBestiary))
end

function Bestiary.detach()
	BestiaryMaid:clean()
	BestiaryGui:Destroy()
end

return Bestiary