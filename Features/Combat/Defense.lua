---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Features.Combat.Object.AnimatorDefender
local AnimatorDefender = require("Features/Combat/Object/AnimatorDefender")

-- Handle all defense related functions.
local Defense = {}

-- Maids.
local defenseMaid = Maid.new()

-- Animator defender objects.
local arDefenderObjects = {}

-- On live descendant added.
local function onLiveDescendantAdded(child)
	if not child:IsA("Animator") then
		return
	end

	arDefenderObjects[child] = AnimatorDefender.new(child)
end

-- On live descendant removed.
local function onLiveDescendantRemoved(child)
	local arDefenderObject = arDefenderObjects[child]
	if not arDefenderObject then
		return
	end

	arDefenderObject:detach()
	arDefenderObjects[child] = nil
end

---Initialize defense.
function Defense.init()
	local live = workspace:WaitForChild("Live")
	local liveDescendantAdded = Signal.new(live.ChildAdded)
	local liveDescendantRemoved = Signal.new(live.ChildRemoved)

	defenseMaid:add(liveDescendantAdded:connect("Defense_LiveDescendantAdded", onLiveDescendantAdded))
	defenseMaid:add(liveDescendantRemoved:connect("Defense_LiveDescendantRemoved", onLiveDescendantRemoved))

	for _, child in next, live:GetDescendants() do
		onLiveDescendantAdded(child)
	end
end

---Detach defense.
function Defense.detach()
	for _, arDefenderObject in next, arDefenderObjects do
		arDefenderObject:detach()
	end

	defenseMaid:clean()
end

-- Return Defense module.
return Defense
