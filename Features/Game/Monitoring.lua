return LPH_NO_VIRTUALIZE(function()
	---@module Utility.Maid
	local Maid = require("Utility/Maid")

	---@module Utility.Signal
	local Signal = require("Utility/Signal")

	---@module Utility.Configuration
	local Configuration = require("Utility/Configuration")

	---@module Utility.OriginalStore
	local OriginalStore = require("Utility/OriginalStore")

	---@module Utility.OriginalStoreManager
	local OriginalStoreManager = require("Utility/OriginalStoreManager")

	---@module Utility.CoreGuiManager
	local CoreGuiManager = require("Utility/CoreGuiManager")

	---@module Utility.TaskSpawner
	local TaskSpawner = require("Utility/TaskSpawner")

	---@module Utility.JSON
	local JSON = require("Utility/JSON")

	---@module Utility.Logger
	local Logger = require("Utility/Logger")

	---@module Utility.Finder
	local Finder = require("Utility/Finder")

	---@module Game.LeaderboardClient
	local LeaderboardClient = require("Game/LeaderboardClient")

	-- Monitoring module.
	local Monitoring = { subject = nil, seen = {} }

	-- Services.
	local runService = game:GetService("RunService")
	local players = game:GetService("Players")

	-- Signals.
	local renderStepped = Signal.new(runService.RenderStepped)

	-- Maids.
	local monitoringMaid = Maid.new()
	local spectateMaid = Maid.new()
	local buildStealMaid = Maid.new()

	-- Instances.
	local beepSound = CoreGuiManager.imark(Instance.new("Sound"))

	-- Update limiting.
	local lastUpdateTime = os.clock()

	-- Original stores.
	local cameraSubject = spectateMaid:mark(OriginalStore.new())

	-- Original store managers.
	local showHiddenMap = spectateMaid:mark(OriginalStoreManager.new())

	---Fetch name.
	local function fetchName(player)
		local spoofName = Configuration.expectToggleValue("InfoSpoofing")
			and Configuration.expectToggleValue("SpoofOtherPlayers")

		return spoofName and "[REDACTED]"
			or string.format("(%s) %s", player:GetAttribute("CharacterName") or "Unknown Character Name", player.Name)
	end

	---On spectate input began.
	---@param player Player
	---@param input InputObject
	local function onSpectateInputBegan(player, input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		-- Fetch name for player.
		local usedName = fetchName(player)

		-- Get data.
		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return Logger.notify("Failed to spectate '%s' because the local player does not exist.", usedName)
		end

		local character = player.Character
		if not character then
			return Logger.notify("Failed to spectate '%s' because their character does not exist.", usedName)
		end

		local mapPosition = character:GetAttribute("MapPos")
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		-- Request a stream if we're able to and we know that they're not loaded in.
		if mapPosition and not humanoidRootPart then
			spectateMaid:add(
				TaskSpawner.spawn(
					"Monitoring_RequestStreamMapPos",
					players.LocalPlayer.RequestStreamAroundAsync,
					players.LocalPlayer,
					mapPosition,
					0.1
				)
			)

			return Logger.notify("Requesting stream for unloaded character '%s' - try again later.", usedName)
		end

		-- Fail because they're *truly* not loaded in.
		if not humanoidRootPart then
			return Logger.notify("Failed to spectate '%s' because they are not loaded in.", usedName)
		end

		local shouldUpdateSubject = Monitoring.subject ~= humanoidRootPart and players.LocalPlayer ~= player

		Monitoring.subject = shouldUpdateSubject and humanoidRootPart or nil

		if shouldUpdateSubject then
			Logger.notify("Started spectating player %s.", usedName)
		else
			Logger.notify("Reset spectating camera subject.")
		end
	end

	---On build steal player.
	---@param player Player
	local function onBuildStealPlayer(player)
		local character = player.Character
		if not character then
			return Logger.notify(
				"Failed to steal build from '%s' because their character does not exist.",
				fetchName(player)
			)
		end

		local backpack = player:FindFirstChild("Backpack")
		if not backpack then
			return Logger.notify(
				"Failed to steal build from '%s' because their backpack does not exist.",
				fetchName(player)
			)
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return Logger.notify(
				"Failed to steal build from '%s' because their humanoid does not exist.",
				fetchName(player)
			)
		end

		-- Prepare data.
		local data = {
			version = 3,
			stats = {
				buildName = string.format("(%i) (%s) Stolen Build", os.time(), player.Name),
				buildDescription = "(.gg/lyc) Build stolen using Linoria V2's Build Stealer feature. Pre-shrine must be solved for. Stuff can be missing or bugged. Finally, check notes.",
				buildAuthor = ".gg/lyc",
				power = character:GetAttribute("Level"),
				pointsUntilNextPower = 67,
				points = 67,
				pointSpent = 67,
				traitPoints = 0,
				traits = {
					Vitality = character:GetAttribute("Trait_Health"),
					Erudition = character:GetAttribute("Trait_Ether"),
					Songchant = character:GetAttribute("Trait_MantraDamage"),
					Proficiency = character:GetAttribute("Trait_WeaponDamage"),
				},
				meta = {
					Race = "None",
					Oath = "None",
					Murmur = "None",
					Bell = "None",
					Origin = "Castaway",
					Outfit = "None",
				},
			},
			attributes = {
				weapon = {
					["Heavy Wep."] = character:GetAttribute("Stat_WeaponHeavy"),
					["Medium Wep."] = character:GetAttribute("Stat_WeaponMedium"),
					["Light Wep."] = character:GetAttribute("Stat_WeaponLight"),
				},
				base = {
					Strength = character:GetAttribute("Stat_Strength"),
					Fortitude = character:GetAttribute("Stat_Fortitude"),
					Agility = character:GetAttribute("Stat_Agility"),
					Intelligence = character:GetAttribute("Stat_Intelligence"),
					Willpower = character:GetAttribute("Stat_Willpower"),
					Charisma = character:GetAttribute("Stat_Charisma"),
				},
				attunement = {
					Flamecharm = character:GetAttribute("Stat_ElementFire"),
					Frostdraw = character:GetAttribute("Stat_ElementIce"),
					Thundercall = character:GetAttribute("Stat_ElementThunder"),
					Galebreathe = character:GetAttribute("Stat_ElementWind"),
					Shadowcast = character:GetAttribute("Stat_ElementShadow"),
					Ironsing = character:GetAttribute("Stat_ElementMetal"),
					Bloodrend = character:GetAttribute("Stat_ElementBlood"),
				},
			},
			content = {
				mantraModifications = {},
				notes = "",
			},
			meta = {
				tags = {},
				isPrivate = true,
			},
			talents = {},
			mantras = {},
			weapons = "",
			enchant = "",
			motif = "",
			preShrine = {
				base = {
					Strength = 100,
					Fortitude = 100,
					Agility = 100,
					Intelligence = 100,
					Willpower = 100,
					Charisma = 100,
				},
				weapon = {
					["Heavy Wep."] = 100,
					["Medium Wep."] = 100,
					["Light Wep."] = 100,
				},
				attunement = {
					Flamecharm = 100,
					Frostdraw = 100,
					Thundercall = 100,
					Galebreathe = 100,
					Shadowcast = 100,
					Ironsing = 100,
					Bloodrend = 100,
				},
			},
			postShrine = nil,
			favoritedTalents = {},
		}

		data.postShrine = data.attributes

		local stats = data.stats
		local meta = data.stats.meta
		local boonIdx = 1
		local flawIdx = 1
		local notes = {}

		-- Fix data.
		for _, instance in next, backpack:GetChildren() do
			local filtered = string.gsub(instance.Name, "Talent:", "")

			if filtered:match("Murmur") then
				meta.Murmur = filtered:gsub("Murmur: ", "")
			end

			if filtered:match("Oath") then
				meta.Oath = filtered:gsub("Oath: ", "")
			end

			if filtered:match("Resonance") then
				meta.Bell = filtered:gsub("Resonance:", "")
			end

			if filtered:match("Boon") then
				stats["boon" .. boonIdx] = filtered:gsub("Boon:", "")
				boonIdx = boonIdx + 1
			end

			if filtered:match("Flaw") then
				stats["flaw" .. flawIdx] = filtered:gsub("Flaw:", "")
				flawIdx = flawIdx + 1
			end

			if filtered:match("Mantra") and instance:GetAttribute("DisplayName") then
				notes[#notes + 1] = (filtered:match("RecalledMantra") and "[RECALLED MANTRA]" or "[USED MANTRA]")
					.. " "
					.. (instance:GetAttribute("RichStats") or "NO RICH STATS?")
					.. "\n"

				if filtered:match("RecalledMantra") then
					continue
				end

				data.mantras[#data.mantras + 1] = instance:GetAttribute("DisplayName")
				data.content.mantraModifications[instance:GetAttribute("DisplayName")] = {}
			end

			if instance.Name == "Weapon" then
				notes[#notes + 1] = "[USED WEAPON] " .. (instance:GetAttribute("RichStats") or filtered)
			end

			if instance.Name:match("Talent") then
				data.talents[#data.talents + 1] = filtered
			end
		end

		for _, instance in next, character:GetChildren() do
			if instance.Name == "Ring" then
				notes[#notes + 1] = string.format("[EQUIPPED RING] %s\n", instance:GetAttribute("DisplayName"))
					.. (instance:GetAttribute("RichStats") or instance.Name)
			end

			if instance.Name == "Shirt" then
				notes[#notes + 1] = "[EQUIPPED SHIRT ID] " .. instance.ShirtTemplate
			end

			if instance.Name == "Pants" then
				notes[#notes + 1] = "[EQUIPPED PANTS ID] " .. instance.PantsTemplate
			end

			if
				instance.Name:match("Equipment")
				and instance:GetAttribute("RichStats")
				and instance:GetAttribute("DisplayName")
			then
				notes[#notes + 1] = string.format(
					"[EQUIPPED EQUIPMENT] [%s] %s\n",
					instance.Name,
					instance:GetAttribute("DisplayName")
				) .. instance:GetAttribute("RichStats")
			end
		end

		notes[#notes + 1] = string.format("[HEALTH] %.2f/%.2f", humanoid.Health, humanoid.MaxHealth)

		data.content.notes = table.concat(notes, "\n\n")

		-- Create builder link.
		local response = request({
			Url = "https://api.deepwoken.co/build",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = JSON.encode(data),
		})

		if not response then
			return Logger.notify("Failed to steal build from '%s' due to no response.", fetchName(player))
		end

		if not response.Success then
			return Logger.notify(
				"(Status %i) Failed to steal build from '%s' due to build creation failure.",
				response.StatusCode,
				fetchName(player)
			)
		end

		if not response.Body then
			return Logger.notify("Failed to steal build from '%s' due to no response body.", fetchName(player))
		end

		local decoded = JSON.decode(response.Body)

		if not decoded or not decoded.id then
			return Logger.notify(
				"(Status %i) Failed to steal build from '%s' due to invalid response body.",
				response.StatusCode,
				fetchName(player)
			)
		end

		-- Set clipboard.
		setclipboard(string.format("https://deepwoken.co/builder?id=%s", decoded.id))

		-- Notify.
		Logger.notify("Stole build from '%s' and copied the builder link to your clipboard.", fetchName(player))
	end

	---Update build stealing.
	local function updateBuildStealing()
		local leaderboardMap, refreshLeaderboard = LeaderboardClient.gld(), LeaderboardClient.glrf()
		if not leaderboardMap or not refreshLeaderboard then
			return cameraSubject:restore()
		end

		-- Refresh leaderboard state.
		refreshLeaderboard()

		-- Update leaderboard based on state.
		for player, frame in next, leaderboardMap do
			local inputBegan = Signal.new(frame.InputBegan)
			local label = string.format("Monitoring_InputBegan_Steal_%s", player.Name)

			if buildStealMaid[frame] then
				continue
			end

			buildStealMaid[frame] = inputBegan:connect(label, function(input)
				if input.KeyCode ~= Enum.KeyCode.P then
					return
				end

				onBuildStealPlayer(player)
			end)
		end
	end

	---Update spectating.
	local function updateSpectating()
		local leaderboardMap, refreshLeaderboard = LeaderboardClient.gld(), LeaderboardClient.glrf()
		if not leaderboardMap or not refreshLeaderboard then
			return cameraSubject:restore()
		end

		-- Refresh leaderboard state.
		refreshLeaderboard()

		-- Update leaderboard based on state.
		for player, frame in next, leaderboardMap do
			local inputBegan = Signal.new(frame.InputBegan)
			local label = string.format("Monitoring_InputBegan%s", player.Name)

			if Configuration.expectToggleValue("ShowHiddenPlayers") then
				showHiddenMap:add(frame, "Visible", true)
			end

			if spectateMaid[frame] then
				continue
			end

			spectateMaid[frame] = inputBegan:connect(label, function(input)
				onSpectateInputBegan(player, input)
			end)
		end
	end

	---Update player proximity.
	local function updatePlayerProximity()
		local proximityRange = Configuration.expectOptionValue("PlayerProximityRange") or 350
		local playersInRange = Finder.geir(proximityRange, true)
		if not playersInRange then
			return
		end

		local localPlayer = players.LocalPlayer
		if not localPlayer then
			return
		end

		local backpack = localPlayer:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		-- Handle monitoring.
		for player, _ in next, Monitoring.seen do
			local isInPlayerRange = table.find(playersInRange, player)
			if isInPlayerRange then
				continue
			end

			local removeNotification = Monitoring.seen[player]

			removeNotification()

			Monitoring.seen[player] = nil
		end

		for _, player in next, playersInRange do
			if Monitoring.seen[player] ~= nil then
				continue
			end

			if
				Configuration.expectToggleValue("PlayerProximityVW")
				and not backpack:FindFirstChild("Talent:Voidwalker Contract")
			then
				continue
			end

			Monitoring.seen[player] =
				Logger.mnnotify("%s entered your proximity radius of %i studs.", fetchName(player), proximityRange)

			if Configuration.expectToggleValue("PlayerProximityBeep") then
				beepSound.SoundId = "rbxassetid://100849623977896"
				beepSound.PlaybackSpeed = 1
				beepSound.Volume = Configuration.expectOptionValue("PlayerProximityBeepVolume") or 0.1
				beepSound:Play()
			end
		end
	end

	---Update subject montioring.
	local function updateSubjectMonitoring()
		-- Set camera subject.
		cameraSubject:set(workspace.CurrentCamera, "CameraSubject", Monitoring.subject)

		if Monitoring.subject ~= nil then
			players.LocalPlayer:AddTag("ForcedSubject")
		else
			players.LocalPlayer:RemoveTag("ForcedSubject")
		end

		-- Request stream.
		spectateMaid:add(
			TaskSpawner.spawn(
				"Monitoring_RequestStreamSpectate",
				players.LocalPlayer.RequestStreamAroundAsync,
				players.LocalPlayer,
				Monitoring.subject.Position,
				0.1
			)
		)
	end

	---Update monitoring.
	local function updateMonitoring()
		if Monitoring.subject then
			updateSubjectMonitoring()
		else
			cameraSubject:restore()
		end

		if os.clock() - lastUpdateTime <= 2.0 then
			return
		end

		lastUpdateTime = os.clock()

		if Configuration.expectToggleValue("BuildStealer") then
			updateBuildStealing()
		else
			buildStealMaid:clean()
		end

		if Configuration.expectToggleValue("PlayerSpectating") then
			updateSpectating()
		else
			spectateMaid:clean()
		end

		if Configuration.expectToggleValue("PlayerProximity") then
			updatePlayerProximity()
		end
	end

	---Initialize monitoring.
	function Monitoring.init()
		-- Attach.
		monitoringMaid:add(renderStepped:connect("Monitoring_OnRenderStepped", updateMonitoring))

		-- Log.
		Logger.warn("Monitoring initialized.")
	end

	---Detach spectating.
	function Monitoring.detach()
		-- Clean.
		monitoringMaid:clean()
		buildStealMaid:clean()
		spectateMaid:clean()
		showHiddenMap:restore()

		-- Get leaderboard data.
		local refreshLeaderboard = LeaderboardClient.glrf()

		-- Refresh leaderboard.
		if refreshLeaderboard then
			refreshLeaderboard()
		end

		-- Log.
		Logger.warn("Monitoring detached.")
	end

	-- Return Monitoring module.
	return Monitoring
end)()
