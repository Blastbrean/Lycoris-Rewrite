-- Instance wrapper module - used for continously updating functions that require instances.
local InstanceWrapper = {}

-- Services.
local collectionService = game:GetService("CollectionService")

---@module Utility.Signal
local Signal = require("Utility/Signal")

---Cache an instance, clean the instance up through a maid, and automatically uncache on deletion.
---@param instanceMaid Maid
---@param identifier any
---@param inst Instance
---@return Instance
InstanceWrapper.mark = LPH_NO_VIRTUALIZE(function(instanceMaid, identifier, inst)
	local maidInstance = instanceMaid[identifier]
	if maidInstance then
		return maidInstance
	end

	local onAncestorChange = Signal.new(inst.AncestryChanged)

	if inst:IsA("BodyVelocity") then
		collectionService:AddTag(inst, "AllowedBM")
	end

	instanceMaid[identifier] = inst
	instanceMaid:add(onAncestorChange:connect("Instance_OnAncestorChange", function(_)
		if inst:IsDescendantOf(game) then
			return
		end

		instanceMaid:removeTask(identifier)
	end))

	return inst
end)

---Create & cache an instance, clean the instance up through a maid, and automatically uncache on deletion.
---@param instanceMaid Maid
---@param identifier any
---@param type string
---@param parent Instance?
---@return Instance
InstanceWrapper.create = LPH_NO_VIRTUALIZE(function(instanceMaid, identifier, type, parent)
	local maidInstance = instanceMaid[identifier]
	if maidInstance then
		return maidInstance
	end

	local newInstance = Instance.new(type, parent)
	local onAncestorChange = Signal.new(newInstance.AncestryChanged)

	if newInstance:IsA("BodyVelocity") then
		collectionService:AddTag(newInstance, "AllowedBM")
	end

	instanceMaid[identifier] = newInstance
	instanceMaid:add(onAncestorChange:connect("Instance_OnAncestorChange", function(_)
		if newInstance:IsDescendantOf(game) then
			return
		end

		instanceMaid:removeTask(identifier)
	end))

	return newInstance
end)

-- Return InstanceWrapper module
return InstanceWrapper
