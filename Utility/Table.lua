-- Table utility functions.
local Table = {}

---Call a function on each element of a table.
---@param first table
---@param callback function
function Table.elements(first, callback)
	for _, element in next, first do
		if not callback(element) then
			continue
		end

		return true
	end
end

---Take a chunk out of an array into a new array.
---@param input any[]
---@param start number
---@param stop number
---@return any[]
function Table.slice(input, start, stop)
	local out = {}

	if start == nil then
		start = 1
	elseif start < 0 then
		start = #input + start + 1
	end
	if stop == nil then
		stop = #input
	elseif stop < 0 then
		stop = #input + stop + 1
	end

	for idx = start, stop do
		table.insert(out, input[idx])
	end

	return out
end

-- Return Table module.
return Table
