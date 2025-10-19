-- EntityHistory module.
local EntityHistory = {}

-- Histories table.
local histories = {}

-- Max history seconds.
local MAX_HISTORY_SECS = 3.0

---Add an entry to the history list.
---@param idx any
---@param position CFrame
---@param velocity Vector3
---@param timestamp number
function EntityHistory.add(idx, position, velocity, timestamp)
	local history = histories[idx] or {}

	if not histories[idx] then
		histories[idx] = history
	end

	history[#history + 1] = {
		position = position,
		timestamp = timestamp,
		velocity = velocity,
	}

	while true do
		local tail = history[1]
		if not tail then
			break
		end

		if tick() - tail.timestamp <= MAX_HISTORY_SECS then
			break
		end

		table.remove(history, 1)
	end
end

---Get every velocity in the history, looking back a given time.
---@param index any
---@param time number
---@return Vector3[]?
function EntityHistory.vall(index, time)
	local history = histories[index]
	if not history then
		return nil
	end

	local out = {}

	for _, data in next, history do
		if tick() - data.timestamp > time then
			continue
		end

		out[#out + 1] = data.velocity
	end

	return out
end

---Get the horizontal angular velocity (yaw rate) for a current index.
---@param index any
---@return number?
function EntityHistory.yrate(index)
	local history = histories[index]
	if not history or #history < 2 then
		return nil
	end

	local latest = history[#history]
	local previous = history[#history - 1]
	local dt = latest.timestamp - previous.timestamp
	if dt <= 1e-4 then
		return nil
	end

	local prevLook = Vector3.new(previous.position.LookVector.X, 0, previous.position.LookVector.Z).Unit
	local latestLook = Vector3.new(latest.position.LookVector.X, 0, latest.position.LookVector.Z).Unit
	local dot = prevLook:Dot(latestLook)
	local crossY = prevLook:Cross(latestLook).Y
	local angle = math.atan2(crossY, dot)
	return angle / dt
end

---Divides the history into a number of equal steps and returns the position at each step.
---@param idx any
---@param steps number
---@param phds number History second limit for past hitbox detection.
---@return CFrame[]?
function EntityHistory.pstepped(idx, steps, phds)
	local history = histories[idx]
	if not history or #history == 0 then
		return nil
	end

	if not steps or steps <= 0 then
		return nil
	end

	local vhistory = {}
	local vhtime = history[#history].timestamp

	for _, data in next, history do
		if vhtime - data.timestamp > phds then
			continue
		end

		vhistory[#vhistory + 1] = data.position
	end

	if #vhistory == 0 then
		return {}
	end

	local count = math.min(steps, #vhistory)
	local out = table.create(count)

	for cidx = 1, count do
		out[cidx] = vhistory[math.max(math.floor((cidx * #vhistory) / count), 1)]
	end

	return out
end

---Get closest position (in time) to a timestamp.
---@param idx any
---@param timestamp number
---@return CFrame?
function EntityHistory.pclosest(idx, timestamp)
	if not histories[idx] then
		return nil
	end

	local closestDelta = nil
	local closestPosition = nil

	for _, data in next, histories[idx] do
		local delta = math.abs(timestamp - data.timestamp)

		if closestDelta and delta >= closestDelta then
			continue
		end

		closestPosition = data.position
		closestDelta = delta
	end

	return closestPosition
end

-- Return EntityHistory module.
return EntityHistory
