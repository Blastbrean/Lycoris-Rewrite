-- Entity utility is handled here.
local Entitites = {}

-- Services.
local players = game:GetService("Players")

---Is a player within 200 studs of the specified position?
---@param position Vector3
---@return Player|nil
function Entitites.isNear(position)
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
end

---This function is sorted from the nearest to the farthest player.
---Get players within a certain range in studs from the local player.
---@param range number
---@return Player[]
function Entitites.getPlayersInRange(range)
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
end

---This function is sorted from the nearest to the farthest mob.
---Get mobs within a certain range in studs from the local player.
---@param range number
---@return Model[]
function Entitites.getMobsInRange(range)
	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	local localCharacter = players.LocalPlayer.Character
	local localRootPart = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
	if not localRootPart then
		return
	end

	local mobsInRange = {}
	local mobsDistance = {}

	for _, entity in next, live:GetChildren() do
		if entity == localCharacter then
			continue
		end

		if players:GetPlayerFromCharacter(entity) then
			continue
		end

		local rootPart = entity:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			continue
		end

		local mobDistance = (rootPart.Position - localRootPart.Position).Magnitude
		if mobDistance > range then
			continue
		end

		table.insert(mobsInRange, entity)

		mobsDistance[entity] = mobDistance
	end

	table.sort(mobsInRange, function(mobOne, mobTwo)
		return mobsDistance[mobOne] < mobsDistance[mobTwo]
	end)

	return mobsInRange
end

---This function is sorted from the nearest to the farthest entity.
---Get entity within a certain range in studs from the local player.
---@param range number
---@return Model[]
function Entitites.getEntitiesInRange(range)
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

	return entitiesInRange
end

---Get the nearest entity to the local player.
---@param range number
---@return Model?
function Entitites.findNearestEntity(range)
	return Entitites.getEntitiesInRange(range or math.huge)[1]
end

---Get the nearest mob to the local player.
---@param range number
---@return Model?
function Entitites.findNearestMob(range)
	return Entitites.getMobsInRange(range or math.huge)[1]
end

-- Return Entitites module.
return Entitites
