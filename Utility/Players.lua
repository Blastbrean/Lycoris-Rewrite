-- Player utility is handled here.
local Players = {}

-- Services.
local players = game:GetService("Players")

---Is a player within 200 studs of the specified position?
---@param position Vector3
---@return Player|nil
function Players.isNear(position)
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

---Is a player within 200 studs of the specified position?
---@param range number
---@return table&Player
function Players.getPlayersInRange(range)
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

	table.sort(playersInRange, function(a, b)
		return playersDistance[a] < playersDistance[b]
	end)

	return playersInRange
end

function Players.getMobsInRange(range)
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

	table.sort(mobsInRange, function(a, b)
		return mobsDistance[a] < mobsDistance[b]
	end)

	return mobsInRange
end

-- Return Players module.
return Players
