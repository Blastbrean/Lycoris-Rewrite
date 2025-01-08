---@class DeserializerStream
---@field source table
---@field index number
local DeserializerStream = {}
DeserializerStream.__index = DeserializerStream

---Read bytes in little endian.
---@param len number
---@return number[]
function DeserializerStream:leReadBytes(len)
	local bytes = {}

	for idx = self.index + 1, self.index + len do
		bytes[#bytes + 1] = self.source[idx]
	end

	self.index = self.index + len

	if self.index > #self.source then
		return error("leReadBytes - read overflow")
	end

	return bytes
end

---Read bytes in big endianess format.
---@param len number
---@return number[]
function DeserializerStream:beReadBytes(len)
	local bytes = {}

	for idx = self.index + len, self.index + 1, -1 do
		bytes[#bytes + 1] = self.source[idx]
	end

	self.index = self.index + len

	if self.index > #self.source then
		return error("beReadBytes - read overflow")
	end

	return bytes
end

---Read string.
---@param len number
---@return string
function DeserializerStream:string(len)
	local src = self.source
	local buf = buffer.create(len)

	for idx = self.index + 1, self.index + len do
		buffer.writeu8(buf, idx - self.index - 1, src[idx])
	end

	self.index = self.index + len

	---@note: Inlined leReadBytes.
	if self.index > #self.source then
		return error("string - read overflow")
	end

	return buffer.readstring(buf, 0, len)
end

---Read unsigned long.
---@return number
function DeserializerStream:unsignedLong()
	local bytes = self:be_read_bytes(8)
	local p1 = bit32.bor(bytes[1], bit32.lshift(bytes[2], 8), bit32.lshift(bytes[3], 16), bit32.lshift(bytes[4], 24))
	local p2 = bit32.bor(bytes[5], bit32.lshift(bytes[6], 8), bit32.lshift(bytes[7], 16), bit32.lshift(bytes[8], 24))
	return bit32.bor(p1, bit32.lshift(p2, 32))
end

---Read unsigned int.
---@return number
function DeserializerStream:unsignedInt()
	local bytes = self:be_read_bytes(4)
	return bit32.bor(bytes[1], bit32.lshift(bytes[2], 8), bit32.lshift(bytes[3], 16), bit32.lshift(bytes[4], 24))
end

---Read unsigned short.
---@return number
function DeserializerStream:unsignedShort()
	local bytes = self:beReadBytes(2)
	return bit32.bor(bytes[1], bit32.lshift(bytes[2], 8))
end

---Read float.
---@return number
function DeserializerStream:float()
	local bytes = self:beReadBytes(4)
	local sign = (-1) ^ bit32.rshift(bytes[4], 7)
	local exp = bit32.rshift(bytes[3], 7) + bit32.lshift(bit32.band(bytes[4], 0x7F), 1)
	local frac = bytes[1] + bit32.lshift(bytes[2], 8) + bit32.lshift(bit32.band(bytes[3], 0x7F), 16)
	local normal = 1

	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0
			exp = 1
		end
	elseif exp == 0x7F then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end

	return sign * 2 ^ (exp - 127) * (1 + normal / 2 ^ 23)
end

---Read double.
---@return number
function DeserializerStream:double()
	local bytes = self:beReadBytes(8)
	local sign = (-1) ^ bit32.rshift(bytes[8], 7)
	local exp = bit32.lshift(bit32.band(bytes[8], 0x7F), 4) + bit32.rshift(bytes[7], 4)
	local frac = bit32.band(bytes[7], 0x0F) * 2 ^ 48
	local normal = 1

	frac = frac
		+ (bytes[6] * 2 ^ 40)
		+ (bytes[5] * 2 ^ 32)
		+ (bytes[4] * 2 ^ 24)
		+ (bytes[3] * 2 ^ 16)
		+ (bytes[2] * 2 ^ 8)
		+ bytes[1]

	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0
			exp = 1
		end
	elseif exp == 0x7FF then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end

	return sign * 2 ^ (exp - 1023) * (normal + frac / 2 ^ 52)
end

---Read long.
---@return number
function DeserializerStream:long()
	local value = self:unsignedLong()

	if bit32.band(value, 0x8000000000000000) ~= 0x0 then
		value = value - 0x800000000000000
	end

	return value
end

---Read int.
---@return number
function DeserializerStream:int()
	local value = self:unsignedInt()

	if bit32.band(value, 0x80000000) ~= 0 then
		value = value - 0x100000000
	end

	return value
end

---Read short.
---@return number
function DeserializerStream:short()
	local value = self:unsignedShort()

	if bit32.band(value, 0x8000) ~= 0 then
		value = value - 0x10000
	end

	return value
end

---Read byte.
---@return number
function DeserializerStream:byte()
	local bytes = self:leReadBytes(1)
	return bytes[1]
end

---Create new DeserializerStream object.
---@param source table
---@return DeserializerStream
function DeserializerStream.new(source)
	local self = setmetatable({}, DeserializerStream)
	self.source = source
	self.index = 0
	return self
end

-- Return DeserializerStream module.
return DeserializerStream
