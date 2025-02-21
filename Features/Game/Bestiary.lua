-- Bestiary module.
local Bestiary = {}

-- Services.
local tweenService = game:GetService("TweenService")
local httpService = game:GetService("HttpService")
local memStorageService = game:GetService("MemStorageService")
local players = game:GetService("Players")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

-- Maids.
local maid = Maid.new()

-- Data.
local savedData = { mobs = {}, players = {} }
local selectedBestiary = nil
local selectedTab = nil
local viewingBestiary = nil

-- Main GUI.
---@type ScreenGui
local bestiaryGui = maid:mark(Instance.new("ScreenGui"))
bestiaryGui.ResetOnSpawn = true

-- Constants.
local BUTTON_SELECTED_COLOR = Color3.fromRGB(89, 121, 119)
local BUTTON_INACTIVE_COLOR = Color3.fromRGB(64, 80, 76)
local MOB_SCRAPER_LIST = {
	Attributes = {
		MOB_exp_mp = "EXP",
		MOB_spells = "Mantras",
		MOB_weapon = "Weapons",
		MOB_intelligence = "Intel",
		MOB_enchantchance = "Enchant Chance",
		Stat_WeaponHeavy = "HVY",
		Stat_WeaponMedium = "MED",
		Stat_WeaponLight = "LHT",
		Trait_Ether = "ERU",
		Trait_MantraDamage = "SONG",
		Trait_Health = "VIT",
		Trait_WeaponDamage = "PROF",
		Level = "LVL",
		--Stat_Agility = 'AGL',
		--Stat_Charisma = 'CHA',
		--Stat_Fortitude = 'FTD',
		--Stat_Strength = 'STR',
		--Stat_Willpower = 'WLP',
		--Stat_ElementShadow = 'SDW',
		--Stat_ElementWind = 'WND',
		--Stat_ElementLightning = 'LNT',
		--Stat_ElementFire = 'FLM',
		--Stat_ElementIce = 'ICE',
		--Stat_ElementIron = 'IRN',
		--Stat_ElementBlood = 'BLD',
	},
	Character = {
		Humanoid = "Health",
		BreakMeter = "Posture",
		Armor = "Stagger",
		ExpMP = "EXP",
		Ether = "Ether",
		Sanity = "Sanity",
		Stomach = "Stomach",
		Water = "Water",
		Tempo = "Tempo",
		Blood = "Blood",
	},
	Player = {
		Guild = "Guild",
		GuildRank = "Guild Rank",
		DataSlot = "Slot",
	},
}

-- Instances.
local bestiaryClient = Instance.new("Part")
local bestiaryFrame = Instance.new("Frame")
local overlay = Instance.new("ImageLabel")
local detailSheet = Instance.new("Frame")
local container = Instance.new("ScrollingFrame")
local uiPadding = Instance.new("UIPadding")
local title = Instance.new("TextLabel")
local divider = Instance.new("Frame")
local detailsFrame = Instance.new("Frame")
local uiListLayout = Instance.new("UIListLayout")
local stats = Instance.new("TextLabel")
local titleStats = Instance.new("TextLabel")
local reqDivider = Instance.new("Frame")
local titleData = Instance.new("TextLabel")
local data = Instance.new("TextLabel")
local pipe = Instance.new("ImageLabel")
local bestiarySheet = Instance.new("Frame")
local uiPadding_2 = Instance.new("UIPadding")
local playerScroll = Instance.new("ScrollingFrame")
local playerList = Instance.new("UIListLayout")
local mobScroll = Instance.new("ScrollingFrame")
local mobList = Instance.new("UIListLayout")
local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
local uiSizeConstraint = Instance.new("UISizeConstraint")
local titleFrame = Instance.new("Frame")
local pipe_2 = Instance.new("ImageLabel")
local mobs = Instance.new("TextButton")
local overlay_2 = Instance.new("ImageLabel")
local playersButton = Instance.new("TextButton")
local overlay_3 = Instance.new("ImageLabel")
local background = Instance.new("ImageLabel")
local classTemplate = Instance.new("Frame")
local class = Instance.new("Frame")
local header = Instance.new("TextLabel")
local shadow_2 = Instance.new("TextLabel")
local divider_2 = Instance.new("Frame")
local divider_3 = Instance.new("Frame")
local divider_4 = Instance.new("Frame")
local items = Instance.new("Frame")
local uiListLayout_4 = Instance.new("UIListLayout")
local itemTemplate_2 = Instance.new("Frame")
local button_2 = Instance.new("TextButton")
local shadow_3 = Instance.new("TextLabel")
local pointer_2 = Instance.new("ImageLabel")
local hover = Instance.new("Sound")
local click = Instance.new("Sound")

-- Properties.
bestiaryClient.Name = "BestiaryClient"
bestiaryClient.Parent = bestiaryGui

click.SoundId = "rbxassetid://4729609016"
click.Name = "click"
click.Parent = bestiaryClient

hover.SoundId = "rbxassetid://4729721770"
hover.Name = "hover"
hover.Parent = bestiaryClient

bestiaryFrame.Name = "BestiaryFrame"
bestiaryFrame.Parent = bestiaryGui
bestiaryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bestiaryFrame.BackgroundColor3 = Color3.fromRGB(59, 62, 67)
bestiaryFrame.BackgroundTransparency = 0.100
bestiaryFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
bestiaryFrame.BorderSizePixel = 0
bestiaryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
bestiaryFrame.Size = UDim2.new(0.400000006, 0, 0.400000006, 0)

overlay.Name = "overlay"
overlay.Parent = bestiaryFrame
overlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
overlay.BackgroundTransparency = 1.000
overlay.BorderColor3 = Color3.fromRGB(27, 42, 53)
overlay.BorderSizePixel = 0
overlay.Position = UDim2.new(0, -3, 0, -3)
overlay.Size = UDim2.new(1, 6, 1, 6)
overlay.ZIndex = 2
overlay.Image = "http://www.roblox.com/asset/?id=4280422108"
overlay.ImageColor3 = Color3.fromRGB(183, 197, 211)
overlay.ScaleType = Enum.ScaleType.Slice
overlay.SliceCenter = Rect.new(14, 14, 18, 18)

detailSheet.Name = "detailSheet"
detailSheet.Parent = bestiaryFrame
detailSheet.BackgroundColor3 = Color3.fromRGB(229, 224, 202)
detailSheet.BorderColor3 = Color3.fromRGB(27, 42, 53)
detailSheet.BorderSizePixel = 0
detailSheet.Position = UDim2.new(0.400000006, 0, 0, -1)
detailSheet.Size = UDim2.new(0.600000024, 0, 1, 2)

container.Name = "container"
container.Parent = detailSheet
container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
container.BackgroundTransparency = 1.000
container.BorderColor3 = Color3.fromRGB(27, 42, 53)
container.BorderSizePixel = 0
container.Size = UDim2.new(1, 0, 1, 0)
container.Visible = false
container.BottomImage = "http://www.roblox.com/asset/?id=4292732835"
container.CanvasSize = UDim2.new(0, 0, 0, 96)
container.MidImage = "rbxassetid://6864023366"
container.ScrollBarThickness = 8
container.TopImage = "http://www.roblox.com/asset/?id=4292727598"
container.VerticalScrollBarInset = Enum.ScrollBarInset.Always

uiPadding.Parent = container
uiPadding.PaddingBottom = UDim.new(0, 8)
uiPadding.PaddingLeft = UDim.new(0, 8)
uiPadding.PaddingTop = UDim.new(0, 8)

title.Name = "title"
title.Parent = container
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1.000
title.BorderColor3 = Color3.fromRGB(27, 42, 53)
title.Position = UDim2.new(0.505, 0, 0.0877500623, 0)
title.Size = UDim2.new(0.48659873, 0, -0.0244997963, 40)
title.Font = Enum.Font.Garamond
title.Text = "Ministry Necormancer"
title.TextColor3 = Color3.fromRGB(49, 48, 41)
title.TextSize = 20.000
title.TextWrapped = true
title.TextYAlignment = Enum.TextYAlignment.Bottom

divider.Name = "divider"
divider.Parent = container
divider.AnchorPoint = Vector2.new(0.5, 0.5)
divider.BackgroundColor3 = Color3.fromRGB(49, 48, 41)
divider.BackgroundTransparency = 0.900
divider.BorderColor3 = Color3.fromRGB(27, 42, 53)
divider.BorderSizePixel = 0
divider.Position = UDim2.new(0.5, 0, 0.150000006, 0)
divider.Rotation = 90.000
divider.Size = UDim2.new(0, 1, 1, -50)

detailsFrame.Name = "detailsFrame"
detailsFrame.Parent = container
detailsFrame.AnchorPoint = Vector2.new(0.5, 0)
detailsFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
detailsFrame.BackgroundTransparency = 1.000
detailsFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
detailsFrame.Position = UDim2.new(0.502133131, 0, 0.161249459, 0)
detailsFrame.Size = UDim2.new(0.995733917, 0, 0.976561904, -50)

uiListLayout.Parent = detailsFrame
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

stats.Name = "Stats"
stats.Parent = detailsFrame
stats.AnchorPoint = Vector2.new(0.5, 0)
stats.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
stats.BackgroundTransparency = 1.000
stats.BorderColor3 = Color3.fromRGB(27, 42, 53)
stats.LayoutOrder = 1
stats.Position = UDim2.new(0.49999994, 0, 0, 20)
stats.Size = UDim2.new(0.999999881, 0, 0.119319342, 40)
stats.Font = Enum.Font.SourceSans
stats.Text = ""
stats.TextColor3 = Color3.fromRGB(49, 48, 41)
stats.TextSize = 14.000
stats.TextWrapped = true
stats.TextYAlignment = Enum.TextYAlignment.Top

titleStats.Name = "titleStats"
titleStats.Parent = detailsFrame
titleStats.AnchorPoint = Vector2.new(0.5, 0)
titleStats.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleStats.BackgroundTransparency = 1.000
titleStats.BorderColor3 = Color3.fromRGB(27, 42, 53)
titleStats.Position = UDim2.new(0.75, 0, 0, 0)
titleStats.Size = UDim2.new(1, 0, 0, 20)
titleStats.Font = Enum.Font.Garamond
titleStats.Text = "Humanoid Stats"
titleStats.TextColor3 = Color3.fromRGB(49, 48, 41)
titleStats.TextSize = 18.000
titleStats.TextWrapped = true
titleStats.TextYAlignment = Enum.TextYAlignment.Bottom

reqDivider.Name = "reqDivider"
reqDivider.Parent = detailsFrame
reqDivider.BackgroundColor3 = Color3.fromRGB(49, 48, 41)
reqDivider.BackgroundTransparency = 0.900
reqDivider.BorderColor3 = Color3.fromRGB(27, 42, 53)
reqDivider.BorderSizePixel = 0
reqDivider.LayoutOrder = 2
reqDivider.Position = UDim2.new(0.5, 1, 0, 124)
reqDivider.Size = UDim2.new(1, -1, 0, 1)

titleData.Name = "titleData"
titleData.Parent = detailsFrame
titleData.AnchorPoint = Vector2.new(0.5, 0)
titleData.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleData.BackgroundTransparency = 1.000
titleData.BorderColor3 = Color3.fromRGB(27, 42, 53)
titleData.LayoutOrder = 3
titleData.Position = UDim2.new(0.75, 0, 0, 0)
titleData.Size = UDim2.new(1, 0, 0, 20)
titleData.Font = Enum.Font.Garamond
titleData.Text = "Humanoid Data"
titleData.TextColor3 = Color3.fromRGB(49, 48, 41)
titleData.TextSize = 18.000
titleData.TextWrapped = true
titleData.TextYAlignment = Enum.TextYAlignment.Bottom

data.Name = "Data"
data.Parent = detailsFrame
data.AnchorPoint = Vector2.new(0.5, 0)
data.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
data.BackgroundTransparency = 1.000
data.BorderColor3 = Color3.fromRGB(27, 42, 53)
data.LayoutOrder = 4
data.Position = UDim2.new(0.49999994, 0, 0.360871732, 20)
data.Size = UDim2.new(0.999999881, 0, 0.414831609, 30)
data.Font = Enum.Font.SourceSans
data.Text = ""
data.TextColor3 = Color3.fromRGB(49, 48, 41)
data.TextSize = 14.000
data.TextWrapped = true
data.TextYAlignment = Enum.TextYAlignment.Top

pipe.Name = "pipe"
pipe.Parent = detailSheet
pipe.AnchorPoint = Vector2.new(1, 0)
pipe.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
pipe.BackgroundTransparency = 1.000
pipe.BorderColor3 = Color3.fromRGB(27, 42, 53)
pipe.BorderSizePixel = 0
pipe.Position = UDim2.new(0, 1, 0, 0)
pipe.Size = UDim2.new(0, 5, 1, 0)
pipe.ZIndex = 2
pipe.Image = "http://www.roblox.com/asset/?id=5031802572"
pipe.ImageColor3 = Color3.fromRGB(183, 197, 211)

bestiarySheet.Name = "bestiarySheet"
bestiarySheet.Parent = bestiaryFrame
bestiarySheet.BackgroundColor3 = Color3.fromRGB(229, 224, 202)
bestiarySheet.BackgroundTransparency = 1.000
bestiarySheet.BorderColor3 = Color3.fromRGB(27, 42, 53)
bestiarySheet.BorderSizePixel = 0
bestiarySheet.Size = UDim2.new(0.400000006, 0, 1, 0)

uiPadding_2.Parent = bestiarySheet
uiPadding_2.PaddingBottom = UDim.new(0, 4)
uiPadding_2.PaddingLeft = UDim.new(0, 4)
uiPadding_2.PaddingRight = UDim.new(0, 4)
uiPadding_2.PaddingTop = UDim.new(0, 4)

playerScroll.Name = "playerScroll"
playerScroll.Parent = bestiarySheet
playerScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
playerScroll.BackgroundTransparency = 1.000
playerScroll.BorderColor3 = Color3.fromRGB(27, 42, 53)
playerScroll.BorderSizePixel = 0
playerScroll.Position = UDim2.new(0, 0, 0, 24)
playerScroll.Size = UDim2.new(1, 0, 1, -24)
playerScroll.Visible = false
playerScroll.BottomImage = "http://www.roblox.com/asset/?id=4292732835"
playerScroll.MidImage = "rbxassetid://6864023366"
playerScroll.ScrollBarThickness = 8
playerScroll.TopImage = "http://www.roblox.com/asset/?id=4292727598"
playerScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always

playerList.Parent = playerScroll
playerList.SortOrder = Enum.SortOrder.LayoutOrder

mobScroll.Name = "mobScroll"
mobScroll.Parent = bestiarySheet
mobScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mobScroll.BackgroundTransparency = 1.000
mobScroll.BorderColor3 = Color3.fromRGB(27, 42, 53)
mobScroll.BorderSizePixel = 0
mobScroll.Position = UDim2.new(0, 0, 0, 24)
mobScroll.Size = UDim2.new(1, 0, 1, -24)
mobScroll.BottomImage = "http://www.roblox.com/asset/?id=4292732835"
mobScroll.MidImage = "rbxassetid://6864023366"
mobScroll.ScrollBarThickness = 8
mobScroll.TopImage = "http://www.roblox.com/asset/?id=4292727598"
mobScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always

mobList.Parent = mobScroll
mobList.SortOrder = Enum.SortOrder.LayoutOrder

uiAspectRatioConstraint.Parent = bestiaryFrame
uiAspectRatioConstraint.AspectRatio = 1.500
uiAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Height

uiSizeConstraint.Parent = bestiaryFrame
uiSizeConstraint.MaxSize = Vector2.new(800, 800)
uiSizeConstraint.MinSize = Vector2.new(500, 600)

titleFrame.Name = "titleFrame"
titleFrame.Parent = bestiaryFrame
titleFrame.BackgroundColor3 = Color3.fromRGB(68, 73, 77)
titleFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
titleFrame.BorderSizePixel = 0
titleFrame.Size = UDim2.new(0.400000006, 0, 0, 26)

pipe_2.Name = "pipe"
pipe_2.Parent = titleFrame
pipe_2.AnchorPoint = Vector2.new(0, 1)
pipe_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
pipe_2.BackgroundTransparency = 1.000
pipe_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
pipe_2.BorderSizePixel = 0
pipe_2.Position = UDim2.new(0, 0, 1, 2)
pipe_2.Size = UDim2.new(1, 0, 0, 5)
pipe_2.Image = "http://www.roblox.com/asset/?id=5035647017"
pipe_2.ImageColor3 = Color3.fromRGB(183, 197, 211)

mobs.Name = "mobs"
mobs.Parent = titleFrame
mobs.BackgroundColor3 = Color3.fromRGB(64, 80, 76)
mobs.BorderColor3 = Color3.fromRGB(27, 42, 53)
mobs.BorderSizePixel = 0
mobs.Position = UDim2.new(0, 4, 0, 2)
mobs.Size = UDim2.new(0, 70, 0, 20)
mobs.Font = Enum.Font.SourceSans
mobs.Text = "Mobs"
mobs.TextColor3 = Color3.fromRGB(255, 255, 255)
mobs.TextSize = 16.000
mobs.TextStrokeTransparency = 0.600
mobs.TextWrapped = true

overlay_2.Name = "overlay"
overlay_2.Parent = mobs
overlay_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
overlay_2.BackgroundTransparency = 1.000
overlay_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
overlay_2.BorderSizePixel = 0
overlay_2.Position = UDim2.new(0, -1, 0, -1)
overlay_2.Size = UDim2.new(1, 2, 1, 2)
overlay_2.Image = "http://www.roblox.com/asset/?id=4645592841"
overlay_2.ImageColor3 = Color3.fromRGB(183, 197, 211)
overlay_2.ScaleType = Enum.ScaleType.Slice
overlay_2.SliceCenter = Rect.new(8, 8, 8, 8)

playersButton.Name = "playersButton"
playersButton.Parent = titleFrame
playersButton.BackgroundColor3 = Color3.fromRGB(64, 80, 76)
playersButton.BorderColor3 = Color3.fromRGB(27, 42, 53)
playersButton.BorderSizePixel = 0
playersButton.Position = UDim2.new(0, 78, 0, 2)
playersButton.Size = UDim2.new(0, 70, 0, 20)
playersButton.Font = Enum.Font.SourceSans
playersButton.Text = "Players"
playersButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playersButton.TextSize = 16.000
playersButton.TextStrokeTransparency = 0.600
playersButton.TextWrapped = true

overlay_3.Name = "overlay"
overlay_3.Parent = playersButton
overlay_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
overlay_3.BackgroundTransparency = 1.000
overlay_3.BorderColor3 = Color3.fromRGB(27, 42, 53)
overlay_3.BorderSizePixel = 0
overlay_3.Position = UDim2.new(0, -1, 0, -1)
overlay_3.Size = UDim2.new(1, 2, 1, 2)
overlay_3.Image = "http://www.roblox.com/asset/?id=4645592841"
overlay_3.ImageColor3 = Color3.fromRGB(183, 197, 211)
overlay_3.ScaleType = Enum.ScaleType.Slice
overlay_3.SliceCenter = Rect.new(8, 8, 8, 8)

background.Name = "background"
background.Parent = bestiaryFrame
background.AnchorPoint = Vector2.new(0, 1)
background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
background.BackgroundTransparency = 1.000
background.BorderColor3 = Color3.fromRGB(0, 0, 0)
background.BorderSizePixel = 0
background.Position = UDim2.new(0, 0, 1, 0)
background.Size = UDim2.new(0.400000006, 0, 1, -27)
background.Image = "http://www.roblox.com/asset/?id=4280494932"
background.ImageColor3 = Color3.fromRGB(4, 5, 6)
background.ImageTransparency = 0.870
background.ScaleType = Enum.ScaleType.Tile
background.TileSize = UDim2.new(0, 32, 0, 32)

classTemplate.Name = "classTemplate"
classTemplate.Parent = bestiaryClient
classTemplate.BackgroundColor3 = Color3.fromRGB(13, 70, 124)
classTemplate.BackgroundTransparency = 1.000
classTemplate.BorderColor3 = Color3.fromRGB(27, 42, 53)
classTemplate.BorderSizePixel = 0
classTemplate.LayoutOrder = -1
classTemplate.Selectable = true
classTemplate.Size = UDim2.new(1, 0, 0, 20)

class.Name = "class"
class.Parent = classTemplate
class.BackgroundColor3 = Color3.fromRGB(184, 160, 97)
class.BackgroundTransparency = 1.000
class.BorderColor3 = Color3.fromRGB(27, 42, 53)
class.BorderSizePixel = 0
class.Position = UDim2.new(0, 5, 0, 4)
class.Size = UDim2.new(1, -15, 0, 16)

header.Name = "header"
header.Parent = class
header.Active = true
header.BackgroundColor3 = Color3.fromRGB(184, 130, 37)
header.BackgroundTransparency = 1.000
header.BorderColor3 = Color3.fromRGB(27, 42, 53)
header.BorderSizePixel = 0
header.Selectable = true
header.Size = UDim2.new(1, 0, 1, 0)
header.ZIndex = 2
header.Font = Enum.Font.Fantasy
header.Text = "Power 15"
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.TextSize = 16.000
header.TextStrokeColor3 = Color3.fromRGB(41, 50, 53)
header.TextStrokeTransparency = 0.100
header.TextWrapped = true
header.TextXAlignment = Enum.TextXAlignment.Left

shadow_2.Name = "Shadow"
shadow_2.Parent = header
shadow_2.Active = true
shadow_2.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
shadow_2.BackgroundTransparency = 1.000
shadow_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
shadow_2.Position = UDim2.new(0, 2, 0, 2)
shadow_2.Selectable = true
shadow_2.Size = UDim2.new(1, 0, 1, 0)
shadow_2.Font = Enum.Font.Fantasy
shadow_2.Text = "Power 15"
shadow_2.TextColor3 = Color3.fromRGB(0, 0, 0)
shadow_2.TextSize = 16.000
shadow_2.TextStrokeColor3 = Color3.fromRGB(41, 50, 53)
shadow_2.TextTransparency = 0.700
shadow_2.TextWrapped = true
shadow_2.TextXAlignment = Enum.TextXAlignment.Left

divider_2.Name = "Divider"
divider_2.Parent = class
divider_2.AnchorPoint = Vector2.new(1, 0.5)
divider_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider_2.BackgroundTransparency = 0.600
divider_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
divider_2.Position = UDim2.new(1, 0, 0.5, 0)
divider_2.Size = UDim2.new(0, 110, 0, 1)

divider_3.Name = "Divider"
divider_3.Parent = divider_2
divider_3.AnchorPoint = Vector2.new(1, 0)
divider_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider_3.BackgroundTransparency = 0.600
divider_3.BorderColor3 = Color3.fromRGB(27, 42, 53)
divider_3.Position = UDim2.new(0, -1, 0, 0)
divider_3.Size = UDim2.new(0, 2, 0, 1)

divider_4.Name = "Divider"
divider_4.Parent = divider_2
divider_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider_4.BackgroundTransparency = 0.600
divider_4.BorderColor3 = Color3.fromRGB(27, 42, 53)
divider_4.Position = UDim2.new(1, 1, 0, 0)
divider_4.Size = UDim2.new(0, 2, 0, 1)

items.Name = "items"
items.Parent = classTemplate
items.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
items.BackgroundTransparency = 1.000
items.BorderColor3 = Color3.fromRGB(27, 42, 53)
items.Position = UDim2.new(0, 0, 0, 20)
items.Size = UDim2.new(1, 0, 0, 20)

uiListLayout_4.Parent = items
uiListLayout_4.SortOrder = Enum.SortOrder.LayoutOrder

itemTemplate_2.Name = "ItemTemplate"
itemTemplate_2.Parent = bestiaryClient
itemTemplate_2.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
itemTemplate_2.BackgroundTransparency = 1.000
itemTemplate_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
itemTemplate_2.Selectable = true
itemTemplate_2.Size = UDim2.new(1, 0, 0, 20)

button_2.Name = "Button"
button_2.Parent = itemTemplate_2
button_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
button_2.BackgroundTransparency = 1.000
button_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
button_2.Position = UDim2.new(0, 15, 0, 0)
button_2.Size = UDim2.new(1, -15, 1, 0)
button_2.ZIndex = 2
button_2.AutoButtonColor = false
button_2.Font = Enum.Font.SourceSansSemibold
button_2.Text = "Heavy Lifting"
button_2.TextColor3 = Color3.fromRGB(247, 254, 255)
button_2.TextSize = 18.000
button_2.TextStrokeColor3 = Color3.fromRGB(41, 50, 53)
button_2.TextStrokeTransparency = 0.100
button_2.TextWrapped = true
button_2.TextXAlignment = Enum.TextXAlignment.Left

shadow_3.Name = "Shadow"
shadow_3.Parent = button_2
shadow_3.Active = true
shadow_3.BackgroundColor3 = Color3.fromRGB(248, 248, 248)
shadow_3.BackgroundTransparency = 1.000
shadow_3.BorderColor3 = Color3.fromRGB(27, 42, 53)
shadow_3.Position = UDim2.new(0, 2, 0, 2)
shadow_3.Selectable = true
shadow_3.Size = UDim2.new(1, 0, 1, 0)
shadow_3.Font = Enum.Font.SourceSansSemibold
shadow_3.Text = "Heavy Lifting"
shadow_3.TextColor3 = Color3.fromRGB(0, 0, 0)
shadow_3.TextSize = 18.000
shadow_3.TextStrokeColor3 = Color3.fromRGB(41, 50, 53)
shadow_3.TextTransparency = 0.700
shadow_3.TextWrapped = true
shadow_3.TextXAlignment = Enum.TextXAlignment.Left

pointer_2.Name = "Pointer"
pointer_2.Parent = itemTemplate_2
pointer_2.AnchorPoint = Vector2.new(0, 0.5)
pointer_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
pointer_2.BackgroundTransparency = 1.000
pointer_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
pointer_2.Position = UDim2.new(0, -3, 0.5, 0)
pointer_2.Size = UDim2.new(0, 16, 0, 16)
pointer_2.Image = "http://www.roblox.com/asset/?id=5031741051"
pointer_2.ImageColor3 = Color3.fromRGB(252, 255, 255)
pointer_2.ImageTransparency = 0.100
pointer_2.ScaleType = Enum.ScaleType.Slice

---Refresh the interface with the current data.
local function refreshInterface()
	local list = selectedTab == mobScroll and savedData.mobs or savedData.players

	-- Destroy old children.
	for _, children in next, selectedTab:GetChildren() do
		if not children:IsA("Frame") then
			continue
		end

		children:Destroy()
	end

	-- Create new children.
	for name, listData in next, list do
		local selected = name == selectedBestiary

		-- Add button.
		local button = itemTemplate_2:Clone()
		button.Name = name
		button.Parent = selectedTab
		button.Button.Text = name
		button.Button.Shadow.Text = name
		button.LayoutOrder = selected and -1 or 0
		button.Button.TextColor3 = selected and Color3.new(1, 0.97, 0.86) or Color3.fromRGB(247, 254, 255)
		button.Button.TextTransparency = 0.3
		button.Pointer.Visible = false

		-- Add signals.
		local buttonClicked = Signal.new(button.Button.MouseButton1Click)
		local buttonEnter = Signal.new(button.Button.MouseEnter)
		local buttonLeave = Signal.new(button.Button.MouseLeave)

		-- Connect signals.
		maid:add(buttonClicked:connect("Bestiary_OnButtonClicked", function()
			-- Check if we're already viewing the bestiary.
			if viewingBestiary == name then
				button.Pointer.Visible = false
				container.Visible = false
				viewingBestiary = nil
				button.Button.TextColor3 = Color3.fromRGB(247, 254, 255)
				tweenService:Create(button.Button, TweenInfo.new(0.06), { TextTransparency = 0.3 }):Play()
				return
			end

			-- Play sound.
			local sfx = hover:Clone()
			sfx.Parent = game:GetService("CoreGui")
			sfx.PlaybackSpeed = math.random(100, 105) / 100
			sfx.PlayOnRemove = true
			sfx:Destroy()

			-- Set details.
			container.Visible = true
			container.title.Text = name
			detailsFrame.Stats.Text = listData.stat
			detailsFrame.Data.Text = listData.data

			-- Set the button colors.
			for _, tabButton in next, selectedTab:GetChildren() do
				if not tabButton:IsA("Frame") then
					continue
				end

				local selection = tabButton.Name == name
				tabButton.Button.TextColor3 = selection and Color3.new(1, 0.97, 0.86) or Color3.fromRGB(247, 254, 255)
				tabButton.Button.TextTransparency = selection and 0 or 0.3
				tabButton.Pointer.Visible = selection
			end

			-- Set the viewing bestiary.
			viewingBestiary = name
		end))

		maid:add(buttonEnter:connect("Bestiary_OnButtonEnter", function()
			if button.Pointer.Visible then
				return
			end

			tweenService:Create(button.Button, TweenInfo.new(0.1), { TextTransparency = 0 }):Play()
		end))

		maid:add(buttonLeave:connect("Bestiary_OnButtonLeave", function()
			if button.Pointer.Visible then
				return
			end

			tweenService:Create(button.Button, TweenInfo.new(0.1), { TextTransparency = 0.3 }):Play()
		end))
	end
end

---Format a table into a string.
---@param tbl table
---@return string
local function formatTable(tbl)
	local result = ""

	for index, value in next, tbl do
		result = result .. index .. ": " .. tostring(value) .. "\n"
	end

	return result
end

---Add an entity to the Bestiary.
---@param character Model
local function onAddEntity(character)
	local player = players:FindFirstChild(character.Name)
	local name = player and string.format("%s (%s)", player.Name, player:GetAttribute("CharacterName"))
		or character:GetAttribute("MOB_rich_name")

	if not name then
		name = character.Name
	end

	local humanoidData = {}
	local humanoidStats = {}

	for index, value in next, MOB_SCRAPER_LIST.Attributes do
		local attribute = character:GetAttribute(index)
		if not attribute then
			continue
		end

		if typeof(attribute) == "Instance" then
			attribute = attribute.Value
		end

		humanoidData[value] = tostring(attribute) or "N/A"
	end

	for _, instance in next, character:GetChildren() do
		local displayName = MOB_SCRAPER_LIST.Character[instance.Name]
		if not displayName then
			continue
		end

		local instanceValue = nil

		if instance:IsA("Humanoid") then
			instanceValue = instance.MaxHealth
		elseif instance:IsA("IntConstrainedValue") or instance:IsA("DoubleConstrainedValue") then
			instanceValue = instance.MaxValue
		elseif instance:IsA("IntValue") or instance:IsA("StringValue") or instance:IsA("NumberValue") then
			instanceValue = instance.Value
		end

		humanoidStats[displayName] = tostring(instanceValue) or "N/A"
	end

	if player then
		for index, value in pairs(MOB_SCRAPER_LIST.Player) do
			local attribute = player:GetAttribute(index)
			if not attribute then
				continue
			end

			humanoidData[value] = tostring(attribute) or "N/A"
		end
	end

	savedData[player and "players" or "mobs"][name] = {
		data = formatTable(humanoidData),
		stat = formatTable(humanoidStats),
	}

	memStorageService:SetItem("BestiaryData", httpService:JSONEncode(savedData))
end

---Set the visibility of the Bestiary.
---@param state boolean
function Bestiary.visible(state)
	bestiaryGui.Enabled = state
end

---Initialize the Bestiary module.
function Bestiary.init()
	-- Set thread identity.
	setthreadidentity(7)

	-- Load the initial memory data.
	local memoryData = httpService:JSONDecode(memStorageService:GetItem("BestiaryData", "[]"))
	for index, value in next, memoryData do
		savedData[index] = value
	end

	-- Fetch instances.
	local live = workspace:WaitForChild("Live")

	-- Add a default selected tab.
	selectedTab = mobScroll

	-- Initialize GUI.
	bestiaryGui.Name = "BestiaryGui"
	bestiaryGui.Parent = gethui() or game:GetService("CoreGui")
	bestiaryGui.Enabled = false
	bestiaryGui.DisplayOrder = 1

	-- Add signals.
	local onMobsClick = Signal.new(mobs.MouseButton1Click)
	local onPlayersClick = Signal.new(playersButton.MouseButton1Click)
	local liveChildAdded = Signal.new(workspace.Live.ChildAdded)

	maid:add(onMobsClick:connect("Bestiary_OnMobsClick", function()
		if selectedTab == mobScroll then
			return
		end

		-- Set the button colors.
		mobs.AutoButtonColor = false
		mobs.BackgroundColor3 = BUTTON_SELECTED_COLOR
		playersButton.AutoButtonColor = true
		playersButton.BackgroundColor3 = BUTTON_INACTIVE_COLOR
		mobScroll.CanvasSize = UDim2.new(0, 0, 0, playerList.AbsoluteContentSize.Y)

		-- Set the selected tab.
		selectedTab = mobScroll

		-- Set other scroll visibility off.
		playerScroll.Visible = false

		-- Refresh the bestiary.
		refreshInterface()

		-- Set the scroll visibility on.
		mobScroll.Visible = true
	end))

	maid:add(onPlayersClick:connect("Bestiary_OnPlayersClick", function()
		if selectedTab == playerScroll then
			return
		end

		-- Set the button colors.
		mobs.AutoButtonColor = false
		mobs.BackgroundColor3 = BUTTON_INACTIVE_COLOR
		playersButton.AutoButtonColor = true
		playersButton.BackgroundColor3 = BUTTON_SELECTED_COLOR
		playerScroll.CanvasSize = UDim2.new(0, 0, 0, mobList.AbsoluteContentSize.Y)

		-- Set the selected tab.
		selectedTab = playerScroll

		-- Set other scroll visibility off.
		mobScroll.Visible = false

		-- Refresh the bestiary.
		refreshInterface()

		-- Set the scroll visibility on.
		playerScroll.Visible = true
	end))

	maid:add(liveChildAdded:connect("Bestiary_OnLiveChildAdded", function(entity)
		maid:add(TaskSpawner.delay("Bestiary_OnAddEntity", 1.0, onAddEntity, entity))
	end))

	-- Add initial entities.
	for _, entity in next, live:GetChildren() do
		onAddEntity(entity)
	end

	-- Refresh the interface.
	refreshInterface()
end

---Detach the Bestiary module.
function Bestiary.detach()
	maid:clean()
end

-- Return Bestiary module.
return Bestiary
