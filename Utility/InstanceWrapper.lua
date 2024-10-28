-- Instance wrapper module - used for continously updating functions that require instances.
local InstanceWrapper = {}

-- Services.
local collectionService = game:GetService("CollectionService")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---Cache an instance, clean the instance up through a maid, and automatically uncache on deletion.
---@param instanceMaid Maid
---@param identifier string
---@param type string
---@param parent Instance
---@return Instance
function InstanceWrapper.create(instanceMaid, identifier, type, parent)
	local maidInstance = instanceMaid[identifier]
	if maidInstance then
		return maidInstance
	end

	local newInstance = Instance.new(type, parent)
	local on_ancestor_change = Signal.new(newInstance.AncestryChanged)

	if newInstance:IsA("BodyVelocity") then
		collectionService:AddTag(newInstance, "AllowedBM")
	end

	instanceMaid[identifier] = maidInstance
	instanceMaid:add(on_ancestor_change:connect("SerenityInstance_OnAncestorChange", function(_)
		if newInstance:IsDescendantOf(game) then
			return
		end

		instanceMaid:removeTask(identifier)
	end))

	return newInstance
end

-- Return InstanceWrapper module
return InstanceWrapper
