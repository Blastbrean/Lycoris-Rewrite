-- Finder utility is handled here.
local Finder = {}

-- Services.
local players = game:GetService("Players")

---Is a player within 200 studs of the specified position?
---@param position Vector3
---@return Player|nil
Finder.pnear = LPH_NO_VIRTUALIZE(function(position)
	for _, player in next, players:GetPlayers() do
		if player == players.LocalPlayer then
			continue
		end

		local character = player.Character
		if not character then
			continue
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			continue
		end

		if (position - rootPart.Position).Magnitude > 200 then
			continue
		end

		return player
	end

	return nil
end)

---Find an entity by its name.
---@param name string The name of the entity to find. It is matched.
---@return Model?
Finder.entity = LPH_NO_VIRTUALIZE(function(name)
	local live = workspace:FindFirstChild("Live")
	if not live then
		return nil
	end

	for _, child in next, live:GetChildren() do
		if not child.Name:match(name) then
			continue
		end

		return child
	end
end)

---Give an instance & a filter & a distance, return a sorted-by-distance list of parts which pass the filter and are within the distance.
---@param instance Instance The instance to check from.
---@param filter fun(part: BasePart): boolean A filter function which returns true if the part should be included.
---@param distance number The maximum distance in studs.
---@return BasePart[]
Finder.sdparts = LPH_NO_VIRTUALIZE(function(instance, filter, distance)
	local localCharacter = players.LocalPlayer.Character
	local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return
	end

	local validParts = {}
	local partsToDistance = {}

	for _, part in next, instance:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end

		if not filter(part) then
			continue
		end

		local pdistance = (part.Position - instance.Position).Magnitude

		if pdistance > distance then
			continue
		end

		validParts[#validParts + 1] = part
		partsToDistance[part] = pdistance
	end

	table.sort(validParts, function(partOne, partTwo)
		return partsToDistance[partOne] < partsToDistance[partTwo]
	end)

	return validParts
end)

---This function is sorted from the nearest to the farthest entity.
---Get entity within a certain range in studs from the local player.
---@param range number
---@param pfilter boolean? If true, only keep players. If false, only keep entities. If nil, do nothing.
---@return Model[]
Finder.geir = LPH_NO_VIRTUALIZE(function(range, pfilter)
	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	local localCharacter = players.LocalPlayer.Character
	local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return
	end

	local entitiesInRange = {}
	local entitiesDistance = {}

	for _, entity in next, live:GetChildren() do
		if entity == localCharacter then
			continue
		end

		local rootPart = entity:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			continue
		end

		local entityDistance = (rootPart.Position - localRootPart.Position).Magnitude
		if entityDistance > range then
			continue
		end

		table.insert(entitiesInRange, entity)

		entitiesDistance[entity] = entityDistance
	end

	table.sort(entitiesInRange, function(mobOne, mobTwo)
		return entitiesDistance[mobOne] < entitiesDistance[mobTwo]
	end)

	if pfilter == nil then
		return entitiesInRange
	end

	local list = {}

	for _, entity in next, entitiesInRange do
		local player = players:GetPlayerFromCharacter(entity)

		if pfilter and not player or player then
			continue
		end

		list[#list + 1] = player
	end

	return list
end)

-- Return Finder module.
return Finder
