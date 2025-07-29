---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Features.Combat.Objects.AnimatorDefender
local AnimatorDefender = require("Features/Combat/Objects/AnimatorDefender")

---@module Features.Combat.Objects.PartDefender
local PartDefender = require("Features/Combat/Objects/PartDefender")

---@module Features.Combat.Objects.SoundDefender
local SoundDefender = require("Features/Combat/Objects/SoundDefender")

---@module Features.Combat.Objects.EffectDefender
local EffectDefender = require("Features/Combat/Objects/EffectDefender")

---@module Utility.Configuration
local Configuration = require("Utility/Configuration")

---@module Game.InputClient
local InputClient = require("Game/InputClient")

---@module Features.Combat.PositionHistory
local PositionHistory = require("Features/Combat/PositionHistory")

---@module Features.Combat.Objects.Defender
local Defender = require("Features/Combat/Objects/Defender")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Handle all defense related functions.
local Defense = { lastMantraActivate = nil }

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

-- Maids.
local defenseMaid = Maid.new()

-- Defender objects.
local defenderObjects = {}
local defenderPartObjects = {}
local defenderAnimationObjects = {}

-- Stored deleted playback data.
local deletedPlaybackData = {}

-- Mob animations.
local mobAnimations = {}

-- Current wisp string & position.
local cws = nil
local cwp = nil

-- State.
local leftClickState = false

-- Update.
local lastVisualizationUpdate = os.clock()
local lastAutoWispUpdate = nil

---Iteratively find effect owner from effect data.
---@param data table
---@return Model?
local findEffectOwner = LPH_NO_VIRTUALIZE(function(data)
	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	for _, value in next, data do
		if typeof(value) ~= "Instance" or value.Parent ~= live or value == character then
			continue
		end

		return value
	end
end)

---Add animator defender.
---@param animator Animator
local addAnimatorDefender = LPH_NO_VIRTUALIZE(function(animator)
	local animationDefender = AnimatorDefender.new(animator, mobAnimations)
	defenderObjects[animator] = animationDefender
	defenderAnimationObjects[animator] = animationDefender
end)

---Add sound defender.
---@param sound Sound
local addSoundDefender = LPH_NO_VIRTUALIZE(function(sound)
	---@note: If there's nothing to base the sound position off of, then I'm just gonna skip it bruh.
	local part = sound:FindFirstAncestorWhichIsA("BasePart")
	if not part then
		return
	end

	-- Add sound defender.
	defenderObjects[sound] = SoundDefender.new(sound, part)
end)

---On game descendant added.
---@param descendant Instance
local onGameDescendantAdded = LPH_NO_VIRTUALIZE(function(descendant)
	if descendant:IsA("Animator") then
		return addAnimatorDefender(descendant)
	end

	if descendant:IsA("Sound") then
		return addSoundDefender(descendant)
	end

	if descendant:IsA("BasePart") then
		return Defense.cdpo(descendant)
	end
end)

---On game descendant removed.
---@param descendant Instance
local onGameDescendantRemoved = LPH_NO_VIRTUALIZE(function(descendant)
	local object = defenderObjects[descendant]
	if not object then
		return
	end

	if object.rpbdata then
		deletedPlaybackData[descendant] = object.rpbdata
	end

	if defenderPartObjects[descendant] then
		defenderPartObjects[descendant] = nil
	end

	if defenderAnimationObjects[descendant] then
		defenderAnimationObjects[descendant] = nil
	end

	object:detach()
	object[descendant] = nil
end)

---On client effect event.
---@param name string?
---@param data table?
local onClientEffectEvent = LPH_NO_VIRTUALIZE(function(name, data)
	if not name or not data then
		return
	end

	local owner = findEffectOwner(data)
	if not owner then
		return
	end

	defenderObjects[data] = EffectDefender.new(name, owner, data)
end)

---On effect replicated.
---@param effect table
local onEffectReplicated = LPH_NO_VIRTUALIZE(function(effect)
	if Configuration.expectToggleValue("EffectLogging") then
		print(string.format("%s", tostring(effect)))
	end

	---@note: Set a timestamp for light attack effects.
	--- This is a hack.
	if effect.Class == "LightAttack" then
		effect.index.Timestamp = os.clock() - Defender.ping()
	end

	if effect.Class ~= "UsingSpell" then
		return
	end

	if not Configuration.expectToggleValue("PerfectMantraCast") then
		return
	end

	local localPlayer = players.LocalPlayer
	local backpack = localPlayer:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	if not backpack:FindFirstChild("Talent:Eureka") then
		return
	end

	if Defense.lastMantraActivate and Defense.lastMantraActivate.Name:match("Dash") then
		return
	end

	InputClient.left()
end)

--On effect removing.
---@param effect table
local onEffectRemoving = LPH_NO_VIRTUALIZE(function(effect)
	if not Configuration.expectToggleValue("EffectLogging") then
		return
	end

	warn(string.format("%s", tostring(effect)))
end)

---Update history.
local updateHistory = LPH_NO_VIRTUALIZE(function()
	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	PositionHistory.add(humanoidRootPart.CFrame, tick())
end)

---Update visualizations.
local updateVisualizations = LPH_NO_VIRTUALIZE(function()
	if os.clock() - lastVisualizationUpdate <= 1.0 then
		return
	end

	lastVisualizationUpdate = os.clock()

	for _, object in next, defenderObjects do
		if not object.vupdate then
			continue
		end

		object:vupdate()
	end
end)

---Handle spell string & position.
---@param position number
---@param str string
local hssp = LPH_NO_VIRTUALIZE(function(position, str)
	if
		lastAutoWispUpdate
		and os.clock() - lastAutoWispUpdate <= (Configuration.expectOptionValue("AutoWispDelay") or 0)
	then
		return Logger.warn(
			"(%.2f - %.2f = %.2f vs. %.2f) Auto Wisp is on cooldown.",
			os.clock(),
			lastAutoWispUpdate,
			os.clock() - lastAutoWispUpdate,
			Configuration.expectToggleValue("AutoWispDelay")
		)
	end

	if position <= 0 or position > #str then
		return Logger.warn("Invalid position (%i vs. %i) for Auto Wisp.", position, #str)
	end

	local character = str:sub(position, position)
	if character ~= "Z" and character ~= "X" and character ~= "C" and character ~= "V" then
		return Logger.warn("Invalid character (%s) for Auto Wisp.", tostring(character))
	end

	local localPlayer = players.LocalPlayer
	local localPlayerCharacter = localPlayer.Character
	if not localPlayerCharacter then
		return
	end

	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return
	end

	local spellGui = playerGui:FindFirstChild("SpellGui")
	if not spellGui then
		return
	end

	local spellInput = spellGui:FindFirstChild("SpellInput")
	if not spellInput then
		return
	end

	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return
	end

	if not effectReplicatorModule:HasEffect("RitualCastingSpell") then
		return Logger.warn("RitualCastingSpell effect not found.")
	end

	if effectReplicatorModule:HasEffect("Knocked") then
		return Logger.warn("Knocked effect found.")
	end

	Logger.warn("Sending event for character (%s) with position (%i) and string (%s).", character, position, str)

	lastAutoWispUpdate = os.clock()

	spellInput:FireServer(character)
end)

---Update defenders.
local updateDefenders = LPH_NO_VIRTUALIZE(function()
	if Configuration.expectToggleValue("M1Hold") and leftClickState then
		InputClient.left()
	end

	if Configuration.expectToggleValue("AutoWisp") and cwp and cws then
		hssp(cwp, cws)
	end

	if not Configuration.expectToggleValue("EnableAutoDefense") then
		return
	end

	for _, object in next, defenderAnimationObjects do
		object:update()
	end

	for _, object in next, defenderPartObjects do
		object:update()
	end
end)

---Create a defender part object.
---@param part BasePart
---@param timing PartTiming
---@return PartDefender?
Defense.cdpo = LPH_NO_VIRTUALIZE(function(part, timing)
	local partDefender = PartDefender.new(part, timing)
	if not partDefender then
		return nil
	end

	defenderObjects[part] = partDefender
	defenderPartObjects[part] = partDefender

	return partDefender
end)

---Check if objects have blocking tasks.
---@return boolean
Defense.blocking = LPH_NO_VIRTUALIZE(function()
	for _, object in next, defenderObjects do
		if not object:blocking() then
			continue
		end

		return true
	end
end)

---Return the defender animation object for an entity.
---@param entity Instance
---@return AnimatorDefender?
Defense.dao = LPH_NO_VIRTUALIZE(function(entity)
	for _, object in next, defenderAnimationObjects do
		if object.entity ~= entity then
			continue
		end

		return object
	end
end)

---Get playback data of first defender with Animation ID.
---@param aid string
---@return PlaybackData?
Defense.agpd = LPH_NO_VIRTUALIZE(function(aid)
	---@note: Grabbing from 'rpbdata' means that we know that the data has been fully recorded.
	for _, object in next, defenderAnimationObjects do
		local pbdata = object.rpbdata[aid]
		if not pbdata then
			continue
		end

		return pbdata
	end

	---@note: Fallback to deleted playback data if that doesn't exist.
	for _, rpbdata in next, deletedPlaybackData do
		local pbdata = rpbdata[aid]
		if not pbdata then
			continue
		end

		return pbdata
	end
end)

---On spell event.
---@param name string
---@param data any?
local onSpellEvent = LPH_NO_VIRTUALIZE(function(name, data)
	-- Close.
	if name == "close" then
		cws = nil
		cwp = nil
		lastAutoWispUpdate = nil
	end

	-- Set the current position & string.
	if name == "start" then
		cws = data
		cwp = 1
		lastAutoWispUpdate = os.clock()
	end

	-- Shift our position if we were successful.
	if cws and cwp and name == "shift" then
		cwp = cwp + 1
	end
end)

---Initialize defense.
function Defense.init()
	-- Cache mob animations.
	local assetFolder = replicatedStorage:WaitForChild("Assets")
	local animationFolder = assetFolder:WaitForChild("Anims")
	local mobsAnimationFolder = animationFolder:WaitForChild("Mobs")

	for _, animation in next, mobsAnimationFolder:GetDescendants() do
		if not animation:IsA("Animation") then
			continue
		end

		if animation.Name == "RunningAttack" then
			continue
		end

		mobAnimations[animation.AnimationId] = animation
	end

	-- Local player.
	local localPlayer = players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local spellGui = playerGui:WaitForChild("SpellGui")

	-- Requests.
	local requests = replicatedStorage:WaitForChild("Requests")
	local clientEffect = requests:WaitForChild("ClientEffect")
	local clientEffectLarge = requests:WaitForChild("ClientEffectLarge")
	local clientEffectDirect = requests:WaitForChild("ClientEffectDirect")
	local spell = spellGui:WaitForChild("SpellInput")

	-- Signals.
	local gameDescendantAdded = Signal.new(game.DescendantAdded)
	local gameDescendantRemoved = Signal.new(game.DescendantRemoving)
	local inputBegan = Signal.new(userInputService.InputBegan)
	local inputEnded = Signal.new(userInputService.InputEnded)
	local renderStepped = Signal.new(runService.RenderStepped)
	local postSimulation = Signal.new(runService.PostSimulation)
	local clientEffectEvent = Signal.new(clientEffect.OnClientEvent)
	local clientEffectLargeEvent = Signal.new(clientEffectLarge.OnClientEvent)
	local cientEffectDirect = Signal.new(clientEffectDirect.Event)
	local spellEvent = Signal.new(spell.OnClientEvent)

	---@note: Need this to detect UI presses / game processed inputs.
	defenseMaid:mark(inputBegan:connect("Defense_OnInputBegan", function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		leftClickState = true
	end))

	defenseMaid:mark(inputEnded:connect("Defense_OnInputEnded", function(input, _)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		leftClickState = false
	end))

	defenseMaid:mark(gameDescendantAdded:connect("Defense_OnDescendantAdded", onGameDescendantAdded))
	defenseMaid:mark(gameDescendantRemoved:connect("Defense_OnDescendantRemoved", onGameDescendantRemoved))
	defenseMaid:mark(renderStepped:connect("Defense_UpdateVisualizations", updateVisualizations))
	defenseMaid:mark(renderStepped:connect("Defense_UpdateHistory", updateHistory))
	defenseMaid:mark(postSimulation:connect("Defense_UpdateDefenders", updateDefenders))
	defenseMaid:mark(clientEffectEvent:connect("Defense_ClientEffectEvent", onClientEffectEvent))
	defenseMaid:mark(clientEffectLargeEvent:connect("Defense_ClientEffectEventLarge", onClientEffectEvent))
	defenseMaid:mark(cientEffectDirect:connect("Defense_ClientEffectEventDirect", onClientEffectEvent))
	defenseMaid:mark(spellEvent:connect("Defense_SpellEvent", onSpellEvent))

	for _, descendant in next, game:GetDescendants() do
		onGameDescendantAdded(descendant)
	end

	---@note: Not type of RBXScriptSignal - but it works.
	local effectReplicator = replicatedStorage:WaitForChild("EffectReplicator")
	local effectReplicatorModule = require(effectReplicator)
	local effectAddedSignal = Signal.new(effectReplicatorModule.EffectAdded)
	local effectRemovingSignal = Signal.new(effectReplicatorModule.EffectRemoving)

	defenseMaid:mark(effectAddedSignal:connect("Defense_EffectReplicated", onEffectReplicated))
	defenseMaid:mark(effectRemovingSignal:connect("Defense_EffectRemoving", onEffectRemoving))

	for _, effect in next, effectReplicatorModule.Effects do
		onEffectReplicated(effect)
	end

	-- Log.
	Logger.warn("Defense initialized.")
end

---Detach defense.
function Defense.detach()
	for _, object in next, defenderObjects do
		object:detach()
	end

	defenseMaid:clean()

	Logger.warn("Defense detached.")
end

-- Return Defense module.
return Defense
