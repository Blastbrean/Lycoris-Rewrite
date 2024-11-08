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

		local playerDistance = player:DistanceFromCharacter(rootPart.Position)
		if playerDistance > range then
			continue
		end

		table.insert(playersInRange, player)
		table.insert(playersDistance, playerDistance)
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
	local mobsInRange = {}
	local mobsDistance = {}

	local character = players.LocalPlayer.Character
	local playerRootPart = character and character:FindFirstChild("HumanoidRootPart")

	for _, mob in next, workspace.Live:GetChildren() do
		if not playerRootPart then
			continue
		end

		if mob == character then
			continue
		end

		local rootPart = mob:FindFirstChild("HumanoidRootPart")
		if not rootPart then
			continue
		end

		local mobDistance = (rootPart.Position - playerRootPart.Position).Magnitude
		if mobDistance > range then
			continue
		end

		table.insert(mobsInRange, mob)
		table.insert(mobsDistance, mobDistance)
	end

	table.sort(mobsInRange, function(mobOne, mobTwo)
		return mobsDistance[mobOne] < mobsDistance[mobTwo]
	end)

	return mobsInRange
end

---Get the nearest mob to the local player.
---@return Model?
function Entitites.findNearestMob()
	local nearestMob = nil
	local nearestDistance = nil

	local live = workspace:FindFirstChild("Live")
	if not live then
		return
	end

	local character = players.LocalPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	for _, instance in pairs(live:GetChildren()) do
		if not instance:FindFirstChild("HumanoidRootPart") then
			continue
		end

		if not instance:FindFirstChild("Humanoid") then
			continue
		end

		if not instance:FindFirstChild("CustomRig") then
			continue
		end

		local torso = instance:FindFirstChild("Torso")
		if torso and torso:FindFirstChild("RagdollAttach") then
			continue
		end

		if instance == character then
			continue
		end

		local distance = (instance.HumanoidRootPart.Position - rootPart.Position).Magnitude

		if not nearestDistance or distance < nearestDistance then
			nearestDistance = distance
			nearestMob = instance
		end
	end

	return nearestMob
end

-- Return Entitites module.
return Entitites
