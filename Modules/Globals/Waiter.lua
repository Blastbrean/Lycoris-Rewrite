---Waiter module.
local Waiter = {}

---Find a track.
---@param aid string Animation ID to look for.
---@param animator Animator The animator to search in.
---@return AnimationTrack?
function Waiter.ftrack(aid, animator)
	for _, track in next, animator:GetPlayingAnimationTracks() do
		local animation = track.Animation
		if not animation then
			continue
		end

		if animation.AnimationId ~= aid then
			continue
		end

		return track
	end
end

---Wait for speed change.
---@param track AnimationTrack
---@return number
function Waiter.wfsc(track)
	local sstart = track.Speed

	while sstart == track.Speed do
		task.wait()
	end

	return sstart
end

---Stepped wait.
---@param defender Defender
---@param time number The time to wait in seconds.
---@param callback function The callback to run.
function Waiter.stw(defender, time, callback)
	local lastTimestamp = os.clock()
	local initialPing = defender.rtt()

	while (os.clock() - lastTimestamp) <= (time - initialPing) do
		-- Wait.
		task.wait()

		-- Step.
		callback()
	end
end

---Fetch a track.
---@param aid string Animation ID to look for.
---@param animator Animator The animator to search in.
---@return AnimationTrack?
function Waiter.fet(aid, animator)
	while task.wait() do
		local track = Waiter.ftrack(aid, animator)
		if not track then
			continue
		end

		return track
	end
end

-- Return Waiter module.
return Waiter
