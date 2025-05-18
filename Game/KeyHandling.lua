-- KeyHandler related stuff is handled here.
local KeyHandling = {}

-- Key-handler tables.
local remoteTable = nil
local randomTable = nil

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- Hash cache.
local hashCache = {}

---Number to string.
---@param num number
---@param iter number
---@return string
local function nts(num, iter)
	local str = ""

	for _ = 1, iter do
		local v78 = num % 256
		str = string.char(v78) .. str
		num = (num - v78) / 256
	end

	return str
end

---String to number.
---@param str string
---@param len number
---@return number
local function stn(str, len)
	local num = 0

	for i = len, len + 3 do
		num = num * 256 + string.byte(str, i)
	end

	return num
end

---SHA-256 preprocess.
---@param msg string
---@param len number
---@return string
local function preprocess(msg, len)
	return msg .. string.char(128) .. string.rep(string.char(0), 64 - (len + 9) % 64) .. nts(8 * len, 8)
end

---Process SHA-256 digest block.
---@param msg string
---@param i number
---@param H table
local function digest(msg, i, H)
	local chunks = {}

	for j = 1, 16 do
		chunks[j] = stn(msg, i + (j - 1) * 4)
	end

	for j = 17, 64 do
		local v103 = chunks[j - 15]
		local v104 = bit32.bxor(bit32.rrotate(v103, 7), bit32.rrotate(v103, 18), bit32.rshift(v103, 3))
		v103 = chunks[j - 2]
		chunks[j] = chunks[j - 16]
			+ v104
			+ chunks[j - 7]
			+ bit32.bxor(bit32.rrotate(v103, 17), bit32.rrotate(v103, 19), bit32.rshift(v103, 10))
	end

	local a = H[1]
	local b = H[2]
	local c = H[3]
	local d = H[4]
	local e = H[5]
	local f = H[6]
	local g = H[7]
	local h = H[8]

	for iter = 1, 64 do
		local v114 = bit32.bxor(bit32.rrotate(a, 2), bit32.rrotate(a, 13), bit32.rrotate(a, 22))
			+ bit32.bxor(bit32.band(a, b), bit32.band(a, c), bit32.band(b, c))
		local v115 = bit32.bxor(bit32.rrotate(e, 6), bit32.rrotate(e, 11), bit32.rrotate(e, 25))
		local v116 = bit32.bxor(bit32.band(e, f), bit32.band(bit32.bnot(e), g))
		local v117 = h + v115 + v116 + randomTable[iter] + chunks[iter]
		local l_g_0 = g
		local l_f_0 = f
		local l_v109_0 = e
		local v121 = d + v117
		local l_v107_0 = c
		local l_v106_0 = b
		local l_v105_0 = a

		a = v117 + v114
		b = l_v105_0
		c = l_v106_0
		d = l_v107_0
		e = v121
		f = l_v109_0
		g = l_f_0
		h = l_g_0
	end

	H[1] = bit32.band(H[1] + a)
	H[2] = bit32.band(H[2] + b)
	H[3] = bit32.band(H[3] + c)
	H[4] = bit32.band(H[4] + d)
	H[5] = bit32.band(H[5] + e)
	H[6] = bit32.band(H[6] + f)
	H[7] = bit32.band(H[7] + g)
	H[8] = bit32.band(H[8] + h)
end

---Convert remote name to an hashed SHA-256 one.
---@param remoteName string
---@return string
local function hash(remoteName)
	local processed = preprocess(remoteName, #remoteName)

	local ht = {
		1779033703,
		3144134277,
		1013904242,
		2773480762,
		1359893119,
		2600822924,
		528734635,
		1541459225,
	}

	for iter = 1, #remoteName, 64 do
		digest(processed, iter, ht)
	end

	return nts(ht[1], 4)
		.. nts(ht[2], 4)
		.. nts(ht[3], 4)
		.. nts(ht[4], 4)
		.. nts(ht[5], 4)
		.. nts(ht[6], 4)
		.. nts(ht[7], 4)
		.. nts(ht[8], 4)
end

---Initialize the KeyHandler module.
KeyHandling.init = LPH_NO_VIRTUALIZE(function()
	local retries = 0

	while true do
		for _, value in next, getgc(true) do
			if typeof(value) ~= "table" then
				continue
			end

			if getrawmetatable(value) then
				continue
			end

			local firstIndex, firstValue = next(value)

			if typeof(firstIndex) ~= "number" then
				continue
			end

			if typeof(firstValue) ~= "number" then
				continue
			end

			if firstValue < 100000 or firstValue > 100000000 then
				continue
			end

			if #value ~= 68 then
				continue
			end

			randomTable = value
		end

		for _, value in next, getgc(true) do
			if typeof(value) ~= "table" then
				continue
			end

			if getrawmetatable(value) then
				continue
			end

			if #value ~= 0 then
				continue
			end

			local firstIndex, firstValue = next(value)

			if typeof(firstIndex) ~= "string" then
				continue
			end
			if typeof(firstValue) ~= "Instance" then
				continue
			end

			if not firstValue:IsA("BaseRemoteEvent") then
				continue
			end

			remoteTable = value
		end

		if remoteTable and randomTable then
			break
		end

		Logger.warn(
			"KeyHandler retry (%i attempts) with results (%s, %s)",
			retries,
			tostring(remoteTable),
			tostring(randomTable)
		)

		retries = retries + 1

		if retries >= 10 then
			return Logger.warn("KeyHandler failed to initialize after 10 attempts.")
		end

		task.wait(0.5)
	end
end)

---Get remote from a specific remote name.
---@param remoteName string
---@return Instance|nil
KeyHandling.getRemote = LPH_NO_VIRTUALIZE(function(remoteName)
	if not randomTable and not remoteTable then
		return nil
	end

	local hashedRemoteName = hashCache[remoteName] or hash(remoteName)

	if not hashCache[remoteName] then
		hashCache[remoteName] = hashedRemoteName
	end

	return remoteTable[hashedRemoteName]
end)

-- Return KeyHandling module.
return KeyHandling
