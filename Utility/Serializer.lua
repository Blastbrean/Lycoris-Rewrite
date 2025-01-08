--[[
 * MessagePack serializer / decode (0.6.1) written in pure Lua 5.3 / Lua 5.4
 * written by Sebastian Steinhauer <s.steinhauer@yahoo.de>
 * modified by the Lycoris Team <discord.gg/lyc>
 *
 * This is free and unencumbered software released into the public domain.
 *
 * Anyone is free to copy, modify, publish, use, compile, sell, or
 * distribute this software, either in source code form or as a compiled
 * binary, for any purpose, commercial or non-commercial, and by any
 * means.
 *
 * In jurisdictions that recognize copyright laws, the author or authors
 * of this software dedicate any and all copyright interest in the
 * software to the public domain. We make this dedication for the benefit
 * of the public at large and to the detriment of our heirs and
 * successors. We intend this dedication to be an overt act of
 * relinquishment in perpetuity of all present and future rights to this
 * software under copyright law.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * For more information, please refer to <http://unlicense.org/>
]]

-- Serializer module.
local Serializer = {}

---Does a specified table match the layout of an array.
---@param tbl table
---@return boolean
local function isAnArray(tbl)
	local expected = 1

	for k in next, tbl do
		if k ~= expected then
			return false
		end

		expected = expected + 1
	end

	return true
end

---Serialize number to a float.
---@param value number
---@return string
local function serializeFloat(value)
	local serializedFloat = string.unpack("f", string.pack("f", value))
	if serializedFloat == value then
		return string.pack(">Bf", 0xca, value)
	end

	return string.pack(">Bd", 0xcb, value)
end

---Serialize number to a signed int.
---@param value number
---@return string
local function serializeSignedInt(value)
	if value < 128 then
		return string.pack("B", value)
	elseif value <= 0xff then
		return string.pack("BB", 0xcc, value)
	elseif value <= 0xffff then
		return string.pack(">BI2", 0xcd, value)
	elseif value <= 0xffffffff then
		return string.pack(">BI4", 0xce, value)
	end

	return string.pack(">BI8", 0xcf, value)
end

---Serialize number to a unsigned int.
---@param value number
---@return string
local function serializeUnsignedInt(value)
	if value >= -32 then
		return string.pack("B", 0xe0 + (value + 32))
	elseif value >= -128 then
		return string.pack("Bb", 0xd0, value)
	elseif value >= -32768 then
		return string.pack(">Bi2", 0xd1, value)
	elseif value >= -2147483648 then
		return string.pack(">Bi4", 0xd2, value)
	end

	return string.pack(">Bi8", 0xd3, value)
end

---Serialize string to a UTF8 string.
---@param value string
---@return string
local function serializeUtf8(value)
	local len = #value

	if len < 32 then
		return string.pack("B", 0xa0 + len) .. value
	elseif len < 256 then
		return string.pack(">Bs1", 0xd9, value)
	elseif len < 65536 then
		return string.pack(">Bs2", 0xda, value)
	end

	return string.pack(">Bs4", 0xdb, value)
end

---Serialize string to a string of bytes.
---@param value string
---@return string
local function serializeStringBytes(value)
	local len = #value

	if len < 256 then
		return string.pack(">Bs1", 0xc4, value)
	elseif len < 65536 then
		return string.pack(">Bs2", 0xc5, value)
	end

	return string.pack(">Bs4", 0xc6, value)
end

---Serialize table to a array.
---@param value table
---@return string
local function serializeArray(value)
	local elements = {}

	for i, v in pairs(value) do
		if type(v) ~= "function" and type(v) ~= "thread" and type(v) ~= "userdata" then
			elements[i] = Serializer.marshal(v)
		end
	end

	local result = table.concat(elements)
	local length = #elements

	if length < 16 then
		return string.pack(">B", 0x90 + length) .. result
	elseif length < 65536 then
		return string.pack(">BI2", 0xdc, length) .. result
	end

	return string.pack(">BI4", 0xdd, length) .. result
end

---Serialize table to a map.
---@param value table
---@return string
local function serializeMap(value)
	local elements = {}

	for k, v in pairs(value) do
		if type(v) ~= "function" and type(v) ~= "thread" and type(v) ~= "userdata" then
			elements[#elements + 1] = Serializer.marshal(k)
			elements[#elements + 1] = Serializer.marshal(v)
		end
	end

	local length = math.floor(#elements / 2)
	if length < 16 then
		return string.pack(">B", 0x80 + length) .. table.concat(elements)
	elseif length < 65536 then
		return string.pack(">BI2", 0xde, length) .. table.concat(elements)
	end

	return string.pack(">BI4", 0xdf, length) .. table.concat(elements)
end

---Serialize nil to a binary string.
---@return string
local function serializeNil()
	return string.pack("B", 0xc0)
end

---serialize table to a binary string
---@param value table
---@return string
local function serializeTable(value)
	return isAnArray(value) and serializeArray(value) or serializeMap(value)
end

---serialize boolean to a binary string
---@param value boolean
---@return string
local function serializeBoolean(value)
	return string.pack("B", value and 0xc3 or 0xc2)
end

---serialize int to a binary string
---@param value number
---@return string
local function serializeInt(value)
	return value >= 0 and serializeSignedInt(value) or serializeUnsignedInt(value)
end

---serialize number to a binary string
---@param value number
---@return string
local function serializeNumber(value)
	return value % 1 == 0 and serializeInt(value) or serializeFloat(value)
end

---serialize string to a binary string
---@param value number
---@return string
local function serializeString(value)
	return utf8.len(value) and serializeUtf8(value) or serializeStringBytes(value)
end

-- Types mapping to functions that serialize it.
local typeToSerializeMap = {
	["nil"] = serializeNil,
	["boolean"] = serializeBoolean,
	["number"] = serializeNumber,
	["string"] = serializeString,
	["table"] = serializeTable,
}

---Marshal a value into a binary string.
---@param value any
---@return string
function Serializer.marshal(value)
	return typeToSerializeMap[type(value)](value)
end

-- Return Serializer module.
return Serializer
