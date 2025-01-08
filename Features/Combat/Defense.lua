---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Features.Combat.Objects.AnimatorDefender
local AnimatorDefender = require("Features/Combat/Objects/AnimatorDefender")

-- Handle all defense related functions.
local Defense = {}

-- Services.
local players = game:GetService("Players")

-- Maids.
local defenseMaid = Maid.new()

-- Defender objects.
local defenderObjects = {}

-- On live descendant added.
local function onLiveDescendantAdded(child)
	if not child:IsA("Animator") then
		return
	end

	local localCharacter = players.LocalPlayer.Character

	if localCharacter and child:IsDescendantOf(players.LocalPlayer.Character) then
		return
	end

	defenderObjects[child] = AnimatorDefender.new(child)
end

-- On live descendant removed.
local function onLiveDescendantRemoved(child)
	local defenderObject = defenderObjects[child]
	if not defenderObject then
		return
	end

	defenderObject:detach()
	defenderObject[child] = nil
end

---Initialize defense.
function Defense.init()
	local live = workspace:WaitForChild("Live")

	-- Signals.
	local liveDescendantAdded = Signal.new(live.DescendantAdded)
	local liveDescendantRemoved = Signal.new(live.DescendantRemoving)

	defenseMaid:add(liveDescendantAdded:connect("Defense_LiveDescendantAdded", onLiveDescendantAdded))
	defenseMaid:add(liveDescendantRemoved:connect("Defense_LiveDescendantRemoved", onLiveDescendantRemoved))

	for _, descendant in next, live:GetDescendants() do
		onLiveDescendantAdded(descendant)
	end
end

---Detach defense.
function Defense.detach()
	for _, defenderObject in next, defenderObjects do
		defenderObject:detach()
	end

	defenseMaid:clean()
end

-- Return Defense module.
return Defense
