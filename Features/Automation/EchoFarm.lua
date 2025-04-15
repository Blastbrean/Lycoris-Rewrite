---@module Utility.StateMachine
local StateMachine = require("Utility/StateMachine")

---@module Utility.Logger
local Logger = require("Utility/Logger")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Utility.PersistentData
local PersistentData = require("Utility/PersistentData")

---@module Utility.TaskSpawner
local TaskSpawner = require("Utility/TaskSpawner")

---@module Utility.Entitites
local Entitites = require("Utility/Entitites")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Game.KeyHandling
local KeyHandling = require("Game/KeyHandling")

---@module Utility.InstanceWrapper
local InstanceWrapper = require("Utility/InstanceWrapper")

-- Constants.
local LOBBY_PLACE_ID = 4111023553

-- Services.
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")

-- EchoFarm module.
local EchoFarm = { tweening = false }

-- Callbacks table.
---@note: For every callback that may yield, we must return early with async and spawn a task for it.
local Callbacks = {}

-- Echo farm maid.
local echoFarmMaid = Maid.new()

-- State maid.
---@note: Cleaned after every state exit.
local stateMaid = Maid.new()

---Find an ingredient in our inventory.
---@param name string
---@return BasePart|nil
local function findIngredient(name)
	local localPlayer = players.LocalPlayer
	local backpack = localPlayer:FindFirstChild("Backpack")

	local character = localPlayer.Character
	local ingredient = character and character:FindFirstChild(name)

	if ingredient then
		return ingredient
	end

	return backpack and backpack:FindFirstChild(name)
end

---Find nearest ingredient of the given name.
---@param position Vector3
---@param name string
---@return BasePart|nil
local function findNearestIngredient(position, name)
	local ingredients = workspace:WaitForChild("Ingredients")
	if not ingredients then
		return nil
	end

	local bestIngredient = nil
	local bestDistance = nil

	for _, ingredient in next, ingredients:GetChildren() do
		if ingredient.Name ~= name then
			continue
		end

		if not ingredient:IsA("BasePart") then
			continue
		end

		if not ingredient:FindFirstChild("InteractPrompt") then
			continue
		end

		if Entitites.isNear(ingredient.Position) then
			continue
		end

		local distance = (position - ingredient.Position).Magnitude

		if bestDistance and distance >= bestDistance then
			continue
		end

		bestIngredient = ingredient
		bestDistance = distance
	end

	return bestIngredient
end

---Find nearest campfire.
---@param position Vector3
---@return Model|nil
local function findNearestCampfire(position)
	local thrown = workspace:WaitForChild("Thrown")
	if not thrown then
		return nil
	end

	local bestCampfire = nil
	local bestDistance = nil

	for _, instance in next, thrown:GetChildren() do
		if instance.Name ~= "Campfire" or not instance:IsA("Model") then
			continue
		end

		if not instance:FindFirstChild("InteractPrompt") then
			continue
		end

		if Entitites.isNear(instance:GetPivot().Position) then
			continue
		end

		local distance = (position - instance.Position).Magnitude

		if bestDistance and distance >= bestDistance then
			continue
		end

		bestCampfire = instance
		bestDistance = distance
	end

	return bestCampfire
end

---Attempt to get the nearest ingredient of a given name.
---@note: This function yields, of course.
---@param name string
---@return BasePart|nil
local function getNearestIngredient(name)
	local localPlayer = players.LocalPlayer
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local ingredients = workspace:WaitForChild("Ingredients")

	local nearestIngredient = findNearestIngredient(humanoidRootPart.Position, name)
	if not nearestIngredient then
		return
	end

	local interactPrompt = nearestIngredient:FindFirstChild("InteractPrompt")
	if not interactPrompt then
		return
	end

	local distance = (nearestIngredient.Position - humanoidRootPart.Position).Magnitude
	local tween = InstanceWrapper.tween(stateMaid, "EchoFarmTween", humanoidRootPart, TweenInfo.new(distance / 80), {
		CFrame = CFrame.new(nearestIngredient.Position),
	})

	EchoFarm.tweening = true

	while nearestIngredient and nearestIngredient:IsDescendantOf(ingredients) do
		-- Wait.
		task.wait()

		-- Fire prompt.
		fireproximityprompt(interactPrompt)

		-- If we've not completed the tween, wait for it to complete.
		if
			tween.PlaybackState ~= Enum.PlaybackState.Begin
			and tween.PlaybackState ~= Enum.PlaybackState.Paused
			and tween.PlaybackState ~= Enum.PlaybackState.Completed
		then
			continue
		end

		-- Play it because we just completed it - keep trying to go towards the ingredient.
		tween:Play()
	end

	EchoFarm.tweening = false
end

---Server hop state.
---@param fsm StateMachine
---@return string?
function Callbacks.onenterserverhop(fsm)
	stateMaid:add(TaskSpawner.spawn("EchoFarmCallbacks_OnEnterServerHop", function()
		local requests = replicatedStorage:WaitForChild("Requests")
		local returnToMenu = requests:WaitForChild("ReturnToMenu")

		returnToMenu:FireServer()

		local localPlayer = players.LocalPlayer
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		local choicePrompt = playerGui:WaitForChild("ChoicePrompt")
		local choice = choicePrompt:WaitForChild("Choice")

		choice:FireServer(true)
	end))

	return fsm.ASYNC
end

---Wipe & teleport to self state.
---@param fsm StateMachine
---@return string?
function Callbacks.onentertwself(fsm)
	stateMaid:add(TaskSpawner.spawn("EchoFarmCallbacks_OnEnterTwSelf", function()
		local character = players.LocalPlayer.Character or players.LocalPlayer.CharacterAdded:Wait()
		local humanoidRootPart = character and character:WaitForChild("HumanoidRootPart")

		local npcs = workspace:WaitForChild("NPCs")
		local selfNpc = npcs:WaitForChild("Self")

		-- Attempt to repeatedly teleport until we're within 10 studs of the NPC.
		local selfCFrame = selfNpc:GetPivot()

		repeat
			-- Teleport to NPC.
			character:PivotTo(selfCFrame)

			-- Wait.
			task.wait()
		until (humanoidRootPart.Position - selfCFrame.Position).Magnitude <= 10

		-- Mark that we're coming from self state.
		PersistentData.set("shw", true)

		-- Get the dialogue event.
		local dialogueEvent = KeyHandling.getRemote("SendDialogue")
		if not dialogueEvent then
			return
		end

		-- Get interact prompt.
		local interactPrompt = selfNpc:WaitForChild("InteractPrompt")

		-- Constantly fire the interact prompt & fire the dialogue event.
		while task.wait() do
			-- Fire prompt.
			fireproximityprompt(interactPrompt)

			-- Send the dialogue event for [The End] so we can get wiped.
			dialogueEvent:FireServer({
				["choice"] = "[The End]",
			})
		end
	end))

	return fsm.ASYNC
end

---Ingredients state.
---@todo: Make a timeout to prevent infinite waiting. What if every ingredient has someone nearby on it?
---@param fsm StateMachine
---@param name string
---@return string?
function Callbacks.onenteringredients(fsm, name)
	stateMaid:add(TaskSpawner.spawn("EchoFarmCallbacks_OnEnterIngredients", function()
		while task.wait() do
			local hasBrowncapIngredient = findIngredient("Browncap")
			local hasDentifiloIngredient = findIngredient("Dentifilo")

			if not hasDentifiloIngredient then
				hasDentifiloIngredient = getNearestIngredient("Dentifilo") ~= nil
			end

			if not hasBrowncapIngredient then
				hasBrowncapIngredient = getNearestIngredient("Browncap") ~= nil
			end

			if hasDentifiloIngredient and hasBrowncapIngredient then
				break
			end
		end

		fsm:transition(name)
		fsm:campfire()
	end))

	return fsm.ASYNC
end

---Campfire state.
---@param fsm StateMachine
---@param name string
---@return string?
function Callbacks.onentercampfire(fsm, name)
	stateMaid:add(TaskSpawner.spawn("EchoFarmCallbacks_OnEnterCampfire", function()
		local localPlayer = players.LocalPlayer
		local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

		local nearestCampfire = findNearestCampfire(humanoidRootPart.Position)
		if not nearestCampfire then
			return
		end

		local interactPrompt = nearestCampfire:FindFirstChild("InteractPrompt")
		if not interactPrompt then
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

		local campfireCFrame = nearestCampfire:GetPivot()
		local distance = (campfireCFrame.Position - humanoidRootPart.Position).Magnitude
		local tween =
			InstanceWrapper.tween(stateMaid, "EchoFarmTween", humanoidRootPart, TweenInfo.new(distance / 80), {
				CFrame = CFrame.new(campfireCFrame.Position),
			})

		EchoFarm.tweening = true

		while not effectReplicatorModule:FindEffect("Resting") do
			-- Wait.
			task.wait()

			-- Fire prompt.
			fireproximityprompt(interactPrompt)

			-- If we've not completed the tween, wait for it to complete.
			if
				tween.PlaybackState ~= Enum.PlaybackState.Begin
				and tween.PlaybackState ~= Enum.PlaybackState.Paused
				and tween.PlaybackState ~= Enum.PlaybackState.Completed
			then
				continue
			end

			-- Play it because we just completed it - keep trying to go towards the ingredient.
			tween:Play()
		end

		EchoFarm.tweening = false

		fsm:transition(name)
		fsm:serverhop()
	end))

	return fsm.ASYNC
end

---Character setup state.
---@param fsm StateMachine
---@return string?
function Callbacks.onentercsetup(fsm)
	stateMaid:add(TaskSpawner.spawn("EchoFarmCallbacks_OnEnterCSetup", function()
		local requests = replicatedStorage:WaitForChild("Requests")
		local characterCreator = requests:WaitForChild("CharacterCreator")
		local toggleMetaModifier = requests:WaitForChild("ToggleMetaModifier")
		toggleMetaModifier:FireServer("All")

		local pickSpawn = characterCreator:WaitForChild("PickSpawn")
		pickSpawn:InvokeServer("Etris")

		local finishCreation = characterCreator:WaitForChild("FinishCreation")
		finishCreation:InvokeServer()
	end))

	return fsm.ASYNC
end

---Wipe slot state.
---@param fsm StateMachine
---@return string?
function Callbacks.onenterwslot(fsm)
	if PersistentData.get("shw") then
		return PersistentData.set("shw", false)
	end

	stateMaid:add(TaskSpawner.spawn("EchoFarmCallbacks_OnEnterWSlot", function()
		local lastUsedSlot = PersistentData.get("lus")
		if not lastUsedSlot then
			return error("The last used slot is nil.")
		end

		local requests = replicatedStorage:WaitForChild("Requests")
		local wipeSlot = requests:WaitForChild("WipeSlot")
		wipeSlot:InvokeServer(lastUsedSlot)
	end))

	return fsm.ASYNC
end

---Quick join state.
---@param fsm StateMachine
---@return string?
function Callbacks.onenterqjoin(fsm)
	stateMaid:add(TaskSpawner.spawn("EchoFarmCallbacks_OnEnterQJoin", function()
		local lastUsedSlot = PersistentData.get("lus")
		if not lastUsedSlot then
			return error("The last used slot is nil.")
		end

		local requests = replicatedStorage:WaitForChild("Requests")
		local startMenu = requests:WaitForChild("StartMenu")

		repeat
			-- Pick a slot.
			local start = startMenu:WaitForChild("Start")
			start:FireServer(lastUsedSlot, { PrivateTest = false })

			-- Pick a server.
			local pickServer = startMenu:WaitForChild("PickServer")
			pickServer:FireServer("none")
		until task.wait()
	end))

	return fsm.ASYNC
end

-- Create state machine.
local machine = StateMachine.create({
	events = {
		-- Server hop.
		{ name = "serverhop", from = "campfire", to = StateMachine.NONE },

		-- Fragments states.
		{ name = "twself", from = "none", to = "twself" },

		-- Overworld states.
		{ name = "ingredients", from = "none", to = "ingredients" },
		{ name = "ingredients", from = "ingredients", to = "campfire" },
		{ name = "campfire", from = "ingredients", to = "serverhop" },

		-- Selection states.
		{ name = "csetup", from = "none", to = "csetup" },
		{ name = "csetup", from = "csetup", to = "ingredients" },

		-- Lobby states.
		{ name = "wslot", from = "none", to = "wslot" },
		{ name = "wslot", from = "wslot", to = "qjoin" },
		{ name = "qjoin", from = "wslot", to = StateMachine.NONE },
	},
	dexit = function()
		stateMaid:clean()
	end,
	callbacks = Callbacks,
})

---Nearby player check.
local function runNearbyPlayerCheck()
	if machine:is("serverhop") or machine:is("none") then
		return
	end

	local localPlayer = players.LocalPlayer
	if not localPlayer then
		return
	end

	local character = localPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if not Entitites.isNear(rootPart.Position) then
		return
	end

	machine:serverhop()
end

---Get nearest area marker.
local function getNearestAreaMarker(position)
	local markerWorkspace = replicatedStorage:FindFirstChild("MarkerWorkspace")
	if not markerWorkspace then
		return nil
	end

	local areaMarkers = markerWorkspace:WaitForChild("AreaMarkers")
	if not areaMarkers then
		return nil
	end

	local nearestAreaMarker = nil
	local nearestDistance = nil

	for _, marker in next, areaMarkers:GetDescendants() do
		if not marker:IsA("Part") then
			continue
		end

		local distance = (position - marker.Position).Magnitude

		if nearestDistance and distance >= nearestDistance then
			continue
		end

		nearestAreaMarker = marker
		nearestDistance = distance
	end

	return nearestAreaMarker
end

---Handle start menu. In return, we return the character that loads in after.
---@note: This function yields if the character does not exist.
---@return Model|nil
local function handleStartMenu()
	local localPlayer = players.LocalPlayer
	local character = localPlayer.Character

	if localPlayer and localPlayer:FindFirstChild("CharacterHandler") then
		return
	end

	local requests = replicatedStorage:FindFirstChild("Requests")
	if not requests then
		return
	end

	local startMenu = requests:FindFirstChild("StartMenu")
	if not startMenu then
		return
	end

	local start = startMenu:FindFirstChild("Start")
	if not start then
		return
	end

	start:FireServer()

	return character or localPlayer.CharacterAdded:Wait()
end

---Start EchoFarm module.
function EchoFarm.start()
	if not machine:is("none") then
		return Logger.notify("Echo farm is already running.")
	end

	-- Go to the start of lobby states.
	if game.PlaceId == LOBBY_PLACE_ID then
		return machine:wslot()
	end

	PersistentData.set("shw", false)
	PersistentData.set("aei", true)

	local renderStepped = Signal.new(runService.RenderStepped)
	echoFarmMaid:add(renderStepped:connect("EchoFarm_NearbyPlayerCheck", runNearbyPlayerCheck))

	local character = handleStartMenu()
	local humanoidRootPart = character and character:WaitForChild("HumanoidRootPart")

	local localPlayer = players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	-- Go to the start of character states.
	if playerGui:FindFirstChild("CharacterCreator") then
		return machine:csetup()
	end

	local areaMarker = getNearestAreaMarker(humanoidRootPart.Position)
	local areaMarkerParent = areaMarker and areaMarker.Parent

	-- Go to start of fragment states.
	if areaMarkerParent.Name == "Fragments of Self" then
		return machine:twself()
	end

	-- Go to start of overworld states.
	return machine:ingredients()
end

---Stop EchoFarm module.
function EchoFarm.stop()
	echoFarmMaid:clean()

	PersistentData.set("aei", false)

	if machine:is("none") then
		return Logger.notify("Echo farm is already no longer running.")
	end

	machine.current = machine.NONE
	machine:cancelTransition(machine.currentTransitioningEvent)

	stateMaid:clean()
end

-- Return module.
return EchoFarm
