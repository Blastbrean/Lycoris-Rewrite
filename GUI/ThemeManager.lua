local httpService = game:GetService("HttpService")
local ThemeManager = {}
do
	ThemeManager.Folder = "Lycoris-Rewrite-Themes"
	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {
		["Default"] = {
			1,
			httpService:JSONDecode(
				'{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}'
			),
		},
		["BBot"] = {
			2,
			httpService:JSONDecode(
				'{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}'
			),
		},
		["Fatality"] = {
			3,
			httpService:JSONDecode(
				'{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}'
			),
		},
		["Jester"] = {
			4,
			httpService:JSONDecode(
				'{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}'
			),
		},
		["Mint"] = {
			5,
			httpService:JSONDecode(
				'{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}'
			),
		},
		["Tokyo Night"] = {
			6,
			httpService:JSONDecode(
				'{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}'
			),
		},
		["Ubuntu"] = {
			7,
			httpService:JSONDecode(
				'{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}'
			),
		},
		["Quartz"] = {
			8,
			httpService:JSONDecode(
				'{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}'
			),
		},
	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]

		if not data then
			return
		end

		for idx, themeData in next, customThemeData or data[2] do
			if type(themeData) == "string" then
				self.Library[idx] = Color3.fromHex(themeData)

				if Options[idx] then
					Options[idx]:SetValueRGB(Color3.fromHex(themeData))
				end
			else
				self.Library[idx] = Color3.fromHSV(themeData.hue, themeData.sat, themeData.vib)

				if Options[idx] then
					Options[idx].Rainbow = themeData.rainbow
					Options[idx]:SetValue({ themeData.hue, themeData.sat, themeData.vib }, themeData.transparency)
				end
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		-- This allows us to force apply themes without loading the themes tab :)
		local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end

		self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
		self.Library:UpdateColorsUsingRegistry()
	end

	function ThemeManager:LoadDefault()
		local theme = "Default"
		local content = isfile(self.Folder .. "/default.txt") and readfile(self.Folder .. "/default.txt")

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
			theme = self.DefaultTheme
		end

		if isDefault then
			Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder .. "/default.txt", theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox
			:AddLabel("Background color")
			:AddColorPicker("BackgroundColor", { Default = self.Library.BackgroundColor })
		groupbox:AddLabel("Main color"):AddColorPicker("MainColor", { Default = self.Library.MainColor })
		groupbox:AddLabel("Accent color"):AddColorPicker("AccentColor", { Default = self.Library.AccentColor })
		groupbox:AddLabel("Outline color"):AddColorPicker("OutlineColor", { Default = self.Library.OutlineColor })
		groupbox:AddLabel("Font color"):AddColorPicker("FontColor", { Default = self.Library.FontColor })

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b)
			return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
		end)

		groupbox:AddDivider()
		groupbox:AddDropdown("ThemeManager_ThemeList", { Text = "Theme list", Values = ThemesArray, Default = 1 })

		groupbox:AddButton("Set as default", function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify(string.format("Set default theme to %q", Options.ThemeManager_ThemeList.Value))
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()
		groupbox:AddInput("ThemeManager_CustomThemeName", { Text = "Custom theme name" })
		groupbox:AddDropdown(
			"ThemeManager_CustomThemeList",
			{ Text = "Custom themes", Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 }
		)
		groupbox:AddDivider()

		groupbox
			:AddButton("Save theme", function()
				self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

				Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
				Options.ThemeManager_CustomThemeList:SetValue(nil)
			end)
			:AddButton("Load theme", function()
				self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value)
			end)

		groupbox:AddButton("Refresh list", function()
			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end)

		groupbox:AddButton("Set as default", function()
			if
				Options.ThemeManager_CustomThemeList.Value ~= nil
				and Options.ThemeManager_CustomThemeList.Value ~= ""
			then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(
					string.format("Set default theme to %q", Options.ThemeManager_CustomThemeList.Value)
				)
			end
		end)

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.MainColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.OutlineColor:OnChanged(UpdateTheme)
		Options.FontColor:OnChanged(UpdateTheme)
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. "/" .. file
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(httpService.JSONDecode, httpService, data)

		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(" ", "") == "" then
			return self.Library:Notify("Invalid file name for theme (empty)", 3)
		end

		local theme = {}
		local fields = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

		for _, field in next, fields do
			local option = Options[field]

			theme[field] = {
				type = "ColorPicker",
				hue = option.Hue,
				sat = option.Sat,
				vib = option.Vib,
				transparency = option.Transparency,
				rainbow = option.Rainbow,
			}
		end

		writefile(self.Folder .. "/" .. file .. ".json", httpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder)

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-5) == ".json" then
				-- i hate this but it has to be done ...

				local pos = file:find(".json", 1, true)
				local char = file:sub(pos, pos)

				while char ~= "/" and char ~= "\\" and char ~= "" do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == "/" or char == "\\" then
					table.insert(out, file:sub(pos + 1))
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:BuildFolderTree() end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
		self:BuildFolderTree()
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, "Must set ThemeManager.Library first!")
		return tab:AddLeftGroupbox("Theme Manager")
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, "Must set ThemeManager.Library first!")
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, "Must set ThemeManager.Library first!")
		self:CreateThemeManager(groupbox)
	end

	ThemeManager:BuildFolderTree()
end

return ThemeManager
