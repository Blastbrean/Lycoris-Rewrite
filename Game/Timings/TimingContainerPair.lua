---@class TimingContainerPair
---@field _data TimingContainer[]
local TimingContainerPair = {}
TimingContainerPair.__index = TimingContainerPair

---Create new TimingContainerPair object.
---@param default TimingContainer
---@param config TimingContainer
---@return TimingContainerPair
function TimingContainerPair.new(default, config)
	local self = setmetatable({}, TimingContainerPair)

	self._data = {
		default = default,
		config = config,
	}

	return self
end

---Get default.
---@return TimingContainer
function TimingContainerPair:default()
	return self._data.default
end

---Get config.
---@return TimingContainer
function TimingContainerPair:config()
	return self._data.config
end

---Index timing container.
---@param key any?
---@return Timing?
function TimingContainerPair:index(key)
	for _, container in next, self._data do
		local timing = container.timings[key]
		if not timing then
			continue
		end

		return timing
	end
end

---Find timing from name.
---@param name string
---@return Timing?
function TimingContainerPair:find(name)
	for _, container in next, self._data do
		local timing = container:find(name)
		if not timing then
			continue
		end

		return timing
	end
end

---List all timing names.
---@return string[]
function TimingContainerPair:names()
	local names = {}

	for _, container in next, self._data do
		for _, timing in next, container.timings do
			table.insert(names, timing.name)
		end
	end

	return names
end

---Get timing from stack.
---@param idx any
---@return Timing?
function TimingContainerPair:get(idx)
	for _, container in next, self._data do
		local timing = container.timings[idx]
		if not timing then
			continue
		end

		return timing
	end
end

-- Return TimingContainerStack module.
return TimingContainerPair
