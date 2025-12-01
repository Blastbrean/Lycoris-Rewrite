return LPH_NO_VIRTUALIZE(function()
	local httpService = game:GetService("HttpService")

	---Export UDim2 to a serializable table.
	---@param udim2 UDim2
	---@return table
	local function uDIm2Export(udim2)
		return {
			xScale = udim2.X.Scale,
			xOffset = udim2.X.Offset,
			yScale = udim2.Y.Scale,
			yOffset = udim2.Y.Offset,
		}
	end

	---Import UDim2 from a serializable table.
	---@param serialized table
	---@return UDim2
	local function uDim2Import(serialized)
		return UDim2.new(serialized.xScale, serialized.xOffset, serialized.yScale, serialized.yOffset)
	end

	local SaveManager = {}
	do
		SaveManager.Folder = "Lycoris-Rewrite-Configs"
		SaveManager.Ignore = {}
		SaveManager.Parser = {
			Toggle = {
				Save = function(idx, object)
					return { type = "Toggle", idx = idx, value = object.Value }
				end,
				Load = function(idx, data)
					if Toggles[idx] then
						Toggles[idx]:SetValue(data.value)
					end
				end,
			},
			Slider = {
				Save = function(idx, object)
					return { type = "Slider", idx = idx, value = tostring(object.Value) }
				end,
				Load = function(idx, data)
					if Options[idx] then
						Options[idx]:SetValue(data.value)
					end
				end,
			},
			Dropdown = {
				Save = function(idx, object)
					return {
						type = "Dropdown",
						idx = idx,
						value = object.Value,
						values = object.SaveValues and object.Values or nil,
						mutli = object.Multi,
					}
				end,
				Load = function(idx, data)
					if Options[idx] then
						Options[idx]:SetValue(data.value)

						if not data.values then
							return
						end

						Options[idx]:SetValues(data.values)
					end
				end,
			},
			ColorPicker = {
				Save = function(idx, object)
					return {
						type = "ColorPicker",
						idx = idx,
						hue = object.Hue,
						sat = object.Sat,
						vib = object.Vib,
						transparency = object.Transparency,
						rainbow = object.Rainbow,
					}
				end,
				Load = function(idx, data)
					if Options[idx] then
						Options[idx].Rainbow = data.rainbow
						Options[idx]:SetValue({ data.hue, data.sat, data.vib }, data.transparency)
						Options[idx]:Display()
					end
				end,
			},
			KeyPicker = {
				Save = function(idx, object)
					return { type = "KeyPicker", idx = idx, mode = object.Mode, key = object.Value }
				end,
				Load = function(idx, data)
					if Options[idx] then
						Options[idx]:SetValue({ data.key, data.mode })
					end
				end,
			},

			Input = {
				Save = function(idx, object)
					return { type = "Input", idx = idx, text = object.Value }
				end,
				Load = function(idx, data)
					if Options[idx] and type(data.text) == "string" then
						Options[idx]:SetValue(data.text)
					end
				end,
			},
		}

		function SaveManager:SetIgnoreIndexes(list)
			for _, key in next, list do
				self.Ignore[key] = true
			end
		end

		function SaveManager:SetFolder(folder)
			self.Folder = folder
			self:BuildFolderTree()
		end

		function SaveManager:Save(name)
			if not name then
				return false, "no config file is selected"
			end

			local fullPath = self.Folder .. "/" .. name .. ".json"

			local data = {
				objects = {},
				keybindFramePosition = uDIm2Export(self.Library.KeybindFrame.Position),
				watermarkFramePosition = uDIm2Export(self.Library.Watermark.Position),
				infoLoggerFramePosition = uDIm2Export(self.Library.InfoLoggerFrame.Position),
				infoLoggerBlacklistHistory = self.Library.InfoLoggerData.KeyBlacklistHistory,
				infoLoggerBlacklist = self.Library.InfoLoggerData.KeyBlacklistList,
				infoLoggerCycle = self.Library.InfoLoggerData.InfoLoggerCycle,
				animationVisualizerFramePosition = uDIm2Export(self.Library.AnimationVisualizerFrame.Position),
				overrideData = self.Library.OverrideData,
			}

			for idx, toggle in next, Toggles do
				if self.Ignore[idx] then
					continue
				end

				table.insert(data.objects, self.Parser[toggle.Type].Save(idx, toggle))
			end

			for idx, option in next, Options do
				if not self.Parser[option.Type] then
					continue
				end
				if self.Ignore[idx] then
					continue
				end

				table.insert(data.objects, self.Parser[option.Type].Save(idx, option))
			end

			local success, encoded = pcall(httpService.JSONEncode, httpService, data)
			if not success then
				return false, "failed to encode data"
			end

			writefile(fullPath, encoded)
			return true
		end

		function SaveManager:Load(name)
			if not name then
				return false, "no config file is selected"
			end

			local file = self.Folder .. "/" .. name .. ".json"
			if not isfile(file) then
				return false, "invalid file"
			end

			local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(file))
			if not success then
				return false, "decode error"
			end

			if decoded.keybindFramePosition then
				self.Library.KeybindFrame.Position = uDim2Import(decoded.keybindFramePosition)
			end

			if decoded.watermarkFramePosition then
				self.Library.Watermark.Position = uDim2Import(decoded.watermarkFramePosition)
			end

			if decoded.infoLoggerFramePosition then
				self.Library.InfoLoggerFrame.Position = uDim2Import(decoded.infoLoggerFramePosition)
			end

			if decoded.infoLoggerBlacklistHistory then
				self.Library.InfoLoggerData.KeyBlacklistHistory = decoded.infoLoggerBlacklistHistory
			end

			if decoded.animationVisualizerFramePosition then
				self.Library.AnimationVisualizerFrame.Position = uDim2Import(decoded.animationVisualizerFramePosition)
			end

			local timingList = Options["TimingOverrideList"]

			if decoded.overrideData and timingList then
				self.Library.OverrideData = decoded.overrideData

				local values = {}

				for rname, _ in next, decoded.overrideData do
					values[#values + 1] = rname
				end

				timingList:SetValues(values)
			end

			for _, option in next, decoded.objects do
				if self.Parser[option.type] then
					task.spawn(function()
						self.Parser[option.type].Load(option.idx, option)
					end) -- task.spawn() so the config loading wont get stuck.
				end
			end

			if decoded.infoLoggerBlacklist then
				self.Library.InfoLoggerData.KeyBlacklistList = decoded.infoLoggerBlacklist
				self.Library:RefreshInfoLogger()
				if Options and Options.BlacklistedKeys then
					Options.BlacklistedKeys:SetValues(self.Library:KeyBlacklists())
				end
			end

			if decoded.infoLoggerCycle then
				self.Library.InfoLoggerData.InfoLoggerCycle = decoded.infoLoggerCycle
				self.Library:RefreshInfoLogger()
				if Options and Options.BlacklistedKeys then
					Options.BlacklistedKeys:SetValues(self.Library:KeyBlacklists())
				end
			end

			return true
		end

		function SaveManager:IgnoreThemeSettings()
			self:SetIgnoreIndexes({
				"BackgroundColor",
				"MainColor",
				"AccentColor",
				"OutlineColor",
				"FontColor", -- themes
				"ThemeManager_ThemeList",
				"ThemeManager_CustomThemeList",
				"ThemeManager_CustomThemeName", -- themes
			})
		end

		function SaveManager:BuildFolderTree()
			local paths = {
				self.Folder,
			}

			for i = 1, #paths do
				local str = paths[i]
				if not isfolder(str) then
					makefolder(str)
				end
			end
		end

		function SaveManager:RefreshConfigList()
			local list = listfiles(self.Folder)

			local out = {}
			for i = 1, #list do
				local file = list[i]
				if file:sub(-5) == ".json" then
					-- i hate this but it has to be done ...

					local pos = file:find(".json", 1, true)
					local start = pos

					local char = file:sub(pos, pos)
					while char ~= "/" and char ~= "\\" and char ~= "" do
						pos = pos - 1
						char = file:sub(pos, pos)
					end

					if char == "/" or char == "\\" then
						table.insert(out, file:sub(pos + 1, start - 1))
					end
				end
			end

			return out
		end

		function SaveManager:SetLibrary(library)
			self.Library = library
		end

		function SaveManager:LoadAutoloadConfig()
			if isfile(self.Folder .. "/autoload.txt") then
				local name = readfile(self.Folder .. "/autoload.txt")

				local success, err = self:Load(name)
				if not success then
					return self.Library:Notify("Failed to load autoload config: " .. err)
				end

				self.Library:Notify(string.format("Auto loaded config %q", name))
			end
		end

		function SaveManager:BuildConfigSection(tab)
			assert(self.Library, "Must set SaveManager.Library")

			local section = tab:AddRightGroupbox("Config Manager")

			section:AddInput("SaveManager_ConfigName", { Text = "Config name" })
			section:AddDropdown(
				"SaveManager_ConfigList",
				{ Text = "Config list", Values = self:RefreshConfigList(), AllowNull = true }
			)

			section:AddDivider()

			section
				:AddButton("Create config", function()
					local name = Options.SaveManager_ConfigName.Value

					if name:gsub(" ", "") == "" then
						return self.Library:Notify("Invalid config name (empty)", 2)
					end

					local success, err = self:Save(name)
					if not success then
						return self.Library:Notify("Failed to save config: " .. err)
					end

					self.Library:Notify(string.format("Created config %q", name))

					Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
					Options.SaveManager_ConfigList:SetValue(nil)
				end)
				:AddButton("Load config", function()
					local name = Options.SaveManager_ConfigList.Value

					local success, err = self:Load(name)
					if not success then
						return self.Library:Notify("Failed to load config: " .. err)
					end

					self.Library:Notify(string.format("Loaded config %q", name))
				end)

			section:AddButton("Overwrite config", function()
				local name = Options.SaveManager_ConfigList.Value

				local success, err = self:Save(name)
				if not success then
					return self.Library:Notify("Failed to overwrite config: " .. err)
				end

				self.Library:Notify(string.format("Overwrote config %q", name))
			end)

			section:AddButton("Refresh list", function()
				Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
				Options.SaveManager_ConfigList:SetValue(nil)
			end)

			section:AddButton("Set as autoload", function()
				local name = Options.SaveManager_ConfigList.Value
				writefile(self.Folder .. "/autoload.txt", name)
				SaveManager.AutoloadLabel:SetText("Current autoload config: " .. name)
				self.Library:Notify(string.format("Set %q to auto load", name))
			end)

			SaveManager.AutoloadLabel = section:AddLabel("Current autoload config: none", true)

			if isfile(self.Folder .. "/autoload.txt") then
				local name = readfile(self.Folder .. "/autoload.txt")
				SaveManager.AutoloadLabel:SetText("Current autoload config: " .. name)
			end

			SaveManager:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName" })
		end

		SaveManager:BuildFolderTree()
	end

	return SaveManager
end)()
