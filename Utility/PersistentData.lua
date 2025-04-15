---@module Utility.Serializer
local Serializer = require("Utility/Serializer")

---@module Utility.Deserializer
local Deserializer = require("Utility/Deserializer")

---@module Utility.Logger
local Logger = require("Utility/Logger")

-- PersistentData module.
local PersistentData = {
	_data = {
		-- First timestamp of when Lycoris was loaded.
		fli = nil,

		-- The last used slot.
		lus = nil,

		-- Echo farm persistence - did we trigger a server hop from wiping our character? If so, skip the wipe slot handler.
		shw = false,

		-- Echo farm persistence - do we need to activate on initialization?
		aei = false,
	},
}

-- Generate mapping.
---@todo: De-duplicate me.
local charByteMap = {}

for idx = 0, 255 do
	charByteMap[string.char(idx)] = idx
end

---String to byte array.
---@param str string
---@return string
local function stringToByteArray(str)
	local chars = {}
	local idx = 1

	repeat
		chars[idx] = charByteMap[str:sub(idx, idx)]
		idx = idx + 1
	until idx == #str + 1

	return chars
end

-- Services.
local memStorageService = game:GetService("MemStorageService")

---Get a field in the persistent data.
---@param field string
---@return any
function PersistentData.get(field)
	return PersistentData._data[field]
end

---Change a field in the persistent data.
---@param field string
---@param value any
function PersistentData.set(field, value)
	if not field or not value then
		return
	end

	-- Set persistent field.
	PersistentData._data[field] = value

	-- Save the persistent data.
	memStorageService:SetItem("LYCORIS_PERSISTENT_DATA", Serializer.marshal(PersistentData._data))
end

---Initialize PersistentData module.
function PersistentData.init()
	if not memStorageService:HasItem("LYCORIS_PERSISTENT_DATA") then
		return
	end

	local success, result =
		pcall(Deserializer.unmarshal_one, stringToByteArray(memStorageService:GetItem("LYCORIS_PERSISTENT_DATA")))

	if not success then
		return Logger.warn("(%s) Failed to deserialize PersistentData snapshot.", tostring(result))
	end

	Logger.warn("(%s) Successfully loaded PersistentData snapshot.", tostring(result))

	PersistentData._data = result
end

-- Return PersistentData module.
return PersistentData
