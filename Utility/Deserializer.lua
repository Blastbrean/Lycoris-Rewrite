-- Deserializer module.
local Deserializer = {}

---@module Utility.DeserializerStream
local DeserializerStream = require("Utility/DeserializerStream")

-- Deserialization data map.
local byteToDataMap = {
	[0xc0] = nil,
	[0xc2] = false,
	[0xc3] = true,
	[0xc4] = DeserializerStream.byte,
	[0xc5] = DeserializerStream.short,
	[0xc6] = DeserializerStream.int,
	[0xca] = DeserializerStream.float,
	[0xcb] = DeserializerStream.double,
	[0xcc] = DeserializerStream.byte,
	[0xcd] = DeserializerStream.unsignedShort,
	[0xce] = DeserializerStream.unsignedInt,
	[0xcf] = DeserializerStream.unsignedLong,
	[0xd0] = DeserializerStream.byte,
	[0xd1] = DeserializerStream.short,
	[0xd2] = DeserializerStream.int,
	[0xd3] = DeserializerStream.long,
	[0xd9] = DeserializerStream.byte,
	[0xda] = DeserializerStream.unsignedShort,
	[0xdb] = DeserializerStream.unsignedInt,
	[0xdc] = DeserializerStream.unsignedShort,
	[0xdd] = DeserializerStream.unsignedInt,
	[0xde] = DeserializerStream.unsignedShort,
	[0xdf] = DeserializerStream.unsignedInt,
}

---Decode array with a specific length and recursively read.
---@param stream DeserializerStream
---@param length number
---@return table
local function decodeArray(stream, length)
	local elements = {}

	for i = 1, length do
		elements[i] = Deserializer.at(stream)
	end

	return elements
end

---Decode map with a specific length and recursively read.
---@param stream DeserializerStream
---@param length number
---@return table, number
local function decodeMap(stream, length)
	local elements = {}

	for _ = 1, length do
		elements[Deserializer.at(stream)] = Deserializer.at(stream)
	end

	return elements
end

---Deserialize the data at a specific position.
---@param stream DeserializerStream
---@return any
function Deserializer.at(stream)
	local byte = stream:byte()
	local byteData = byteToDataMap[byte] or function()
		error("Unhandled byte data: " .. byte)
	end

	if byte == 0xde or byte == 0xdf then
		return decodeMap(stream, byteData(stream))
	end

	if byte >= 0x80 and byte <= 0x8f then
		return decodeMap(stream, byte - 0x80)
	end

	if byte >= 0x90 and byte <= 0x9f then
		return decodeArray(stream, byte - 0x90)
	end

	if byte == 0xdc or byte == 0xdd then
		return decodeArray(stream, byteData(stream))
	end

	if byte == 0xc4 or byte == 0xc5 or byte == 0xc6 then
		return stream:le_read_bytes(byteData(stream))
	end

	if byte == 0xd9 or byte == 0xda or byte == 0xdb then
		return stream:string(byteData(stream))
	end

	if byte >= 0xa0 and byte <= 0xbf then
		return stream:string(byte - 0xa0)
	end

	if byte == 0xc0 or byte == 0xc1 or byte == 0xc2 then
		return byteToDataMap[byte]
	end

	if byte >= 0x00 and byte <= 0x7f then
		return byte
	end

	if byte >= 0xe0 and byte <= 0xff then
		return -32 + (byte - 0xe0)
	end

	return typeof(byteData) == "function" and byteData(stream) or byteData
end

---Starts recursively deserializing the data from the first index one time.
---@param data table
---@return any
function Deserializer.unmarshal_one(data)
	return Deserializer.at(DeserializerStream.new(data))
end

-- Return Deseralizer module.
return Deserializer
