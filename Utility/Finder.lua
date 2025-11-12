-- Finder utility is handled here.
local Finder = {}

-- Services.
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

---Check if we are near a position of a specified position.
---@param position Vector3
---@param range number
---@return boolean
Finder.near = LPH_NO_VIRTUALIZE(function(position, range)
	local localCharacter = players.LocalPlayer.Character
	if not localCharacter then
		return false
	end

	local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return false
	end

	return (position - localRootPart.Position).Magnitude <= range
end)

---Wait for the shrine. Deepwoken is weird so it can be both thrown or non-thrown?
---@return Model?
Finder.wshrine = LPH_NO_VIRTUALIZE(function()
	local thrown = workspace:FindFirstChild("Thrown")
	local waves = workspace:FindFirstChild("HallowtideWaves")
	local shrine = nil

	-- Wait.
	while not shrine do
		-- Look for the shrine in both locations.
		shrine = waves:FindFirstChild("HallowtideShrine") or thrown:FindFirstChild("HallowtideShrine")

		-- Wait.
		task.wait()
	end

	return shrine
end)

---Is a entity (not us or a player) within X studs of the specified position?
---@param position Vector3
---@param range number
---@return Model|nil
Finder.enear = LPH_NO_VIRTUALIZE(function(position, range)
	local live = workspace:FindFirstChild("Live")
	if not live then
		return nil
	end

	for _, entity in next, live:GetChildren() do
		if entity == players.LocalPlayer.Character then
			continue
		end

		if players:GetPlayerFromCharacter(entity) then
			continue
		end

		local rootPart = entity:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			continue
		end

		if (position - rootPart.Position).Magnitude > range then
			continue
		end

		return entity
	end

	return nil
end)

---Is a player within X studs of the specified position?
---@param position Vector3
---@param range number
---@return Player|nil
Finder.pnear = LPH_NO_VIRTUALIZE(function(position, range)
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

		if (position - rootPart.Position).Magnitude > range then
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

---Is a tool currently being locked by cooldown?
---@param tool Tool
---@return boolean
Finder.cdlocked = LPH_NO_VIRTUALIZE(function(tool)
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return nil
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return nil
	end

	for _, effect in next, effectReplicatorModule.Effects do
		if effect.Value ~= tool then
			continue
		end

		return true
	end

	return false
end)

---Find a mantra that is not on cooldown.
---@param name string? Specify the name of the mantra to find. It is matched.
---@return Tool?
Finder.ncdm = LPH_NO_VIRTUALIZE(function(name)
	local effectReplicator = replicatedStorage:FindFirstChild("EffectReplicator")
	if not effectReplicator then
		return nil
	end

	local effectReplicatorModule = require(effectReplicator)
	if not effectReplicatorModule then
		return nil
	end

	local backpack = players.LocalPlayer:FindFirstChild("Backpack")
	if not backpack then
		return nil
	end

	for _, item in next, backpack:GetChildren() do
		if not item:IsA("Tool") then
			continue
		end

		if not item.Name:match("Mantra:") or item.Name:match("Recalled") then
			continue
		end

		if name and (not item.Name:match(name)) then
			continue
		end

		if Finder.cdlocked(item) then
			continue
		end

		return item
	end
end)

---Return all current simple prompt text(s) for the player.
---@return table
Finder.sprompts = LPH_NO_VIRTUALIZE(function()
	local playerGui = players.LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return {}
	end

	local simplePrompt = playerGui:FindFirstChild("SimplePrompt")
	if not simplePrompt then
		return {}
	end

	local prompts = simplePrompt:FindFirstChild("Prompts")
	if not prompts then
		return {}
	end

	local texts = {}

	for _, prompt in next, prompts:GetChildren() do
		if not prompt:IsA("TextLabel") then
			continue
		end

		texts[#texts + 1] = prompt.Text
	end

	return texts
end)

---Get the nearest area marker.
---@param position Vector3 The position to check from.
---@return Model?
Finder.marker = LPH_NO_VIRTUALIZE(function(position)
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
end)

---Find the first tool equipped by a user by name.
---@param name string The name of the tool to find. It is matched.
---@return Tool?
Finder.etool = LPH_NO_VIRTUALIZE(function(name)
	local character = players.LocalPlayer.Character
	if not character then
		return nil
	end

	for _, item in next, character:GetChildren() do
		if not item:IsA("Tool") then
			continue
		end

		if not item.Name:match(name) then
			continue
		end

		return item
	end

	return nil
end)

---Find the first weapon without an enchant.
---@param name string The name of the weapon to find. It is matched.
---@return Tool?
Finder.weweapon = LPH_NO_VIRTUALIZE(function(name)
	local tools = Finder.tools(name, false)

	for _, tool in next, tools do
		local rstats = tool:GetAttribute("RichStats")
		if not rstats then
			continue
		end

		if rstats:match("Enchant") then
			continue
		end

		return tool
	end
end)

---Find the first tool in a backpack by name.
---@param name string The name of the tool to find. It is matched.
---@param exact boolean If true, the name must be an exact match.
---@return Tool?
Finder.tool = LPH_NO_VIRTUALIZE(function(name, exact)
	return Finder.tools(name, exact)[1]
end)

---Find the tools in a backpack by name.
---@param name string The name of the tool to find. It is matched.
---@param exact boolean If true, the name must be an exact match.
---@return Tool[]
Finder.tools = LPH_NO_VIRTUALIZE(function(name, exact)
	local backpack = players.LocalPlayer:FindFirstChild("Backpack")
	if not backpack then
		return {}
	end

	local tools = {}

	for _, item in next, backpack:GetChildren() do
		if not item:IsA("Tool") then
			continue
		end

		if exact and (item.Name ~= name) or (not item.Name:match(name)) then
			continue
		end

		tools[#tools + 1] = item
	end

	return tools
end)

---Get the nearest chest from a position.
---@param position Vector3 The position to check from.
---@param range number The maximum distance to check.
---@return Model?
Finder.chest = LPH_NO_VIRTUALIZE(function(position, range)
	local thrown = workspace:FindFirstChild("Thrown")
	if not thrown then
		return nil
	end

	local nearestChest = nil
	local nearestDistance = nil

	for _, chest in next, thrown:GetChildren() do
		if not chest:IsA("Model") then
			continue
		end

		local distance = (position - chest:GetPivot().Position).Magnitude

		if range and distance > range then
			continue
		end

		if nearestDistance and distance >= nearestDistance then
			continue
		end

		nearestChest = chest
		nearestDistance = distance
	end

	return nearestChest
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

---This function is sorted from the nearest to the farthest player.
---Get players within a certain range in studs from the local player.
---@param range number
---@return Model[]
Finder.gpir = LPH_NO_VIRTUALIZE(function(range)
	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	local localCharacter = players.LocalPlayer.Character
	local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return
	end

	local playersInRange = {}
	local playersDistance = {}

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

		local playerDistance = (rootPart.Position - localRootPart.Position).Magnitude
		if playerDistance > range then
			continue
		end

		table.insert(playersInRange, player)

		playersDistance[player] = playerDistance
	end

	table.sort(playersInRange, function(playerOne, playerTwo)
		return playersDistance[playerOne] < playersDistance[playerTwo]
	end)

	return playersInRange
end)

---This function is sorted from the nearest to the farthest entity.
---Get entity within a certain range in studs from the local player.
---@param range number
---@param pfilter boolean If true, filter out all players from the search.
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

	if not pfilter then
		return entitiesInRange
	end

	local list = {}

	for _, entity in next, entitiesInRange do
		if players:GetPlayerFromCharacter(entity) then
			continue
		end

		table.insert(list, entity)
	end

	return list
end)

-- Return Finder module.
return Finder
