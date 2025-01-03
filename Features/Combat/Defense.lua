---@module Utility.Signal
local Signal = require("Utility/Signal")

---@module Utility.Maid
local Maid = require("Utility/Maid")

---@module Features.Combat.Objects.AnimatorDefender
local AnimatorDefender = require("Features/Combat/Objects/AnimatorDefender")

-- Handle all defense related functions.
local Defense = {}

-- Maids.
local defenseMaid = Maid.new()

-- Animation defender objects.
local animationDefenderObjects = {}

-- On live descendant added.
local function onLiveDescendantAdded(child)
	if not child:IsA("Animator") then
		return
	end

	animationDefenderObjects[child] = AnimatorDefender.new(child)
end

-- On live descendant removed.
local function onLiveDescendantRemoved(child)
	local animationDefenderObject = animationDefenderObjects[child]
	if not animationDefenderObject then
		return
	end

	animationDefenderObject:detach()
	animationDefenderObject[child] = nil
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
	for _, animationDefenderObject in next, animationDefenderObjects do
		animationDefenderObject:detach()
	end

	defenseMaid:clean()
end

-- Return Defense module.
return Defense
