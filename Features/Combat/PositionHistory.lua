-- PositionHistory module.
local PositionHistory = {}

-- History table.
local history = {}

---Add an entry to the history list.
---@param position CFrame
---@param timestamp number
function PositionHistory.add(position, timestamp)
	history[#history + 1] = {
		position = position,
		timestamp = timestamp,
	}

	while true do
		local tail = history[1]
		if not tail then
			break
		end

		if tick() - tail.timestamp <= 3.0 then
			break
		end

		table.remove(history, 1)
	end
end

---Get closest position (in time) to a timestamp.
---@param timestamp number
---@return Vector3
function PositionHistory.closest(timestamp)
	local closestDelta = nil
	local closestPosition = nil

	for _, data in next, history do
		local delta = math.abs(timestamp - data.timestamp)

		if closestDelta and delta >= closestDelta then
			continue
		end

		closestPosition = data.position
		closestDelta = delta
	end

	return closestPosition
end

-- Return PositionHistory module.
return PositionHistory
