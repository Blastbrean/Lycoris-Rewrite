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

-- Return Players module.
return Players
