--[[
	wavelength UI Library
	Usage:
		local Library = loadstring(game:HttpGet("RAW_URL"))()
		local Window = Library:CreateWindow({ Name = "wavelength", Size = UDim2.fromOffset(560, 420) })
		local Tab = Window:AddTab("visuals")
		local Sec = Tab:AddSection("players", 1)
		local t = Sec:AddToggle({ Name = "box", Flag = "Box", Default = false, Callback = function(v) end })
		t:AddColorpicker({ Flag = "BoxColor", Default = Color3.fromRGB(255,255,255), NoAlpha = true })
		t:AddDropdown({ Name = "type", Flag = "BoxType", Items = {"square","corner"}, Default = "square" })
		Sec:AddSlider({ Name = "distance", Flag = "Dist", Min = 0, Max = 250, Default = 250, Increment = 1, Suffix = "st" })
		Window:AddSettingsTab()
		Window:Init()
]]

local Library = {}
Library.__index = Library

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local function getParent()
	if typeof(gethui) == "function" then
		local ok, g = pcall(gethui)
		if ok and g then return g end
	end
	local ok, cg = pcall(function() return CoreGui end)
	if ok and cg then return cg end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function clamp(n, a, b)
	return math.min(b, math.max(a, n))
end

Library.Theme = {
	Background = Color3.fromRGB(18, 18, 20),
	Section = Color3.fromRGB(24, 24, 27),
	SectionBorder = Color3.fromRGB(40, 40, 46),
	Border = Color3.fromRGB(12, 12, 14),
	Text = Color3.fromRGB(220, 220, 225),
	TextDim = Color3.fromRGB(140, 140, 150),
	Accent = Color3.fromRGB(160, 140, 255),
	Accent2 = Color3.fromRGB(100, 80, 200),
	ToggleOff = Color3.fromRGB(40, 40, 46),
	ToggleOn = Color3.fromRGB(160, 140, 255),
	SliderBg = Color3.fromRGB(32, 32, 38),
	InputBg = Color3.fromRGB(28, 28, 34),
	Hover = Color3.fromRGB(36, 36, 42),
}

Library.Flags = {}
Library.Setters = {}
Library._flagCbs = {}
Library.Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
Library.FontSize = 12
Library.Running = true

function Library:GetFlag(name) return self.Flags[name] end
function Library:SetFlag(name, value)
	self.Flags[name] = value
	if self.Setters[name] then pcall(self.Setters[name], value) end
	local list = self._flagCbs[name]
	if list then for _, cb in ipairs(list) do pcall(cb, value) end end
end
function Library:OnFlag(name, cb)
	self._flagCbs[name] = self._flagCbs[name] or {}
	table.insert(self._flagCbs[name], cb)
end

function Library:Notify(opts)
	opts = opts or {}
	local text = tostring(opts.Text or opts.text or "")
	local dur = opts.Duration or opts.duration or 2
	local parent = getParent()
	local gui = parent:FindFirstChild("WL_Notifs")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "WL_Notifs"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = parent
	end
	local f = Instance.new("Frame")
	f.BackgroundColor3 = self.Theme.Background
	f.BorderSizePixel = 0
	f.Size = UDim2.fromOffset(math.clamp(#text * 7 + 24, 120, 360), 28)
	f.AnchorPoint = Vector2.new(1, 0)
	f.Position = UDim2.new(1, -12, 0, 12 + (#gui:GetChildren() * 34))
	f.Parent = gui
	local st = Instance.new("UIStroke")
	st.Color = self.Theme.Border
	st.Thickness = 2
	st.Parent = f
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 2)
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = self.Theme.Accent
	bar.Parent = f
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -12, 1, -2)
	lbl.Position = UDim2.fromOffset(6, 2)
	lbl.FontFace = self.Font
	lbl.TextSize = self.FontSize
	lbl.TextColor3 = self.Theme.Text
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = text
	lbl.Parent = f
	task.delay(dur, function() if f.Parent then f:Destroy() end end)
end

local function mk(class, props)
	local o = Instance.new(class)
	if props then for k, v in pairs(props) do o[k] = v end end
	return o
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.LineJoinMode = Enum.LineJoinMode.Miter
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function textLabel(parent, props)
	local t = mk("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Library.Font,
		TextSize = Library.FontSize,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		Parent = parent,
	})
	if props then for k, v in pairs(props) do t[k] = v end end
	return t
end

function Library:CreateWindow(opts)
	opts = opts or {}
	local name = opts.Name or "wavelength"
	local size = opts.Size or UDim2.fromOffset(560, 420)
	local win = { Library = self, Tabs = {}, TabOrder = {}, CurrentTab = nil, Flags = self.Flags }

	local gui = mk("ScreenGui", {
		Name = "WL_" .. name,
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = getParent(),
	})
	win.Gui = gui

	local shell = mk("Frame", {
		Name = "Shell",
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Active = true,
		Parent = gui,
	})
	win.Shell = shell
	stroke(shell, self.Theme.Border, 2)

	local accentBar = mk("Frame", {
		Name = "AccentBar",
		Size = UDim2.new(1, 0, 0, 2),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 5,
		Parent = shell,
	})
	local accentGrad = mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, self.Theme.Accent),
			ColorSequenceKeypoint.new(0.5, self.Theme.Accent2),
			ColorSequenceKeypoint.new(1, self.Theme.Accent),
		}),
		Parent = accentBar,
	})
	task.spawn(function()
		while self.Running and accentGrad.Parent do
			accentGrad.Offset = Vector2.new((tick() * 0.25 % 2) - 1, 0)
			task.wait(0.03)
		end
	end)

	local titleBar = mk("Frame", {
		Name = "TitleBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.fromOffset(0, 2),
		Parent = shell,
	})
	win.TitleBar = titleBar
	textLabel(titleBar, {
		Text = string.lower(name),
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		TextColor3 = self.Theme.TextDim,
	})

	do
		local dragging, startPos, startInput
		titleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				startPos = shell.Position
				startInput = input.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then dragging = false end
				end)
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local d = input.Position - startInput
				shell.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
	end

	local tabBar = mk("Frame", {
		Name = "TabBar",
		BackgroundColor3 = self.Theme.Section,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.fromOffset(8, 30),
		Parent = shell,
	})
	stroke(tabBar, self.Theme.SectionBorder, 1)
	win.TabBar = tabBar
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabBar,
	})

	local content = mk("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -70),
		Position = UDim2.fromOffset(8, 64),
		ClipsDescendants = true,
		Parent = shell,
	})
	win.Content = content

	local popupLayer = mk("Frame", {
		Name = "Popups",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 100,
		Parent = gui,
	})
	win.PopupLayer = popupLayer
	win.OpenPopup = nil

	function win:ClosePopups()
		if self.OpenPopup and self.OpenPopup.Parent then self.OpenPopup:Destroy() end
		self.OpenPopup = nil
		for _, ch in ipairs(self.PopupLayer:GetChildren()) do ch:Destroy() end
	end

	function win:AddTab(tabName)
		tabName = string.lower(tostring(tabName))
		local tab = { Name = tabName, Window = self, Sections = {}, Library = Library }

		local btn = mk("TextButton", {
			Name = tabName,
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 80, 1, 0),
			FontFace = Library.Font,
			TextSize = Library.FontSize,
			Text = tabName,
			TextColor3 = Library.Theme.TextDim,
			BorderSizePixel = 0,
			LayoutOrder = #self.TabOrder + 1,
			Parent = self.TabBar,
		})
		tab.Button = btn

		local under = mk("Frame", {
			Name = "Accent",
			BackgroundColor3 = Library.Theme.Accent,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -12, 0, 2),
			Position = UDim2.new(0, 6, 1, -2),
			Visible = false,
			ZIndex = 2,
			Parent = btn,
		})
		tab.Underline = under

		local page = mk("Frame", {
			Name = tabName,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = self.Content,
		})
		tab.Page = page

		local left = mk("ScrollingFrame", {
			Name = "Left",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(0.5, -4, 1, 0),
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Library.Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = page,
		})
		local right = mk("ScrollingFrame", {
			Name = "Right",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(0.5, -4, 1, 0),
			Position = UDim2.new(0.5, 4, 0, 0),
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Library.Theme.Accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = page,
		})
		mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
		mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right })
		mk("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), Parent = left })
		mk("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), Parent = right })
		tab.Left, tab.Right = left, right

		btn.MouseButton1Click:Connect(function() self:SelectTab(tabName) end)
		self.Tabs[tabName] = tab
		self.TabOrder[#self.TabOrder + 1] = tabName
		if not self.CurrentTab then self:SelectTab(tabName) end

		function tab:AddSection(sectionName, side)
			return Library:_CreateSection(self, sectionName, side == 2 and self.Right or self.Left)
		end
		return tab
	end

	function win:SelectTab(tabName)
		tabName = string.lower(tostring(tabName))
		for n, tab in pairs(self.Tabs) do
			local on = n == tabName
			tab.Page.Visible = on
			tab.Underline.Visible = on
			tab.Button.TextColor3 = on and Library.Theme.Text or Library.Theme.TextDim
		end
		self.CurrentTab = tabName
		self:ClosePopups()
	end

	function win:AddSettingsTab()
		return Library:_CreateSettingsTab(self)
	end

	function win:Init()
		if not Library.Flags.MenuKeybind then
			Library.Flags.MenuKeybind = Enum.KeyCode.RightShift
		end
		UIS.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.KeyCode == Library.Flags.MenuKeybind then
				shell.Visible = not shell.Visible
				if not shell.Visible then win:ClosePopups() end
			end
		end)
	end

	function win:Unload()
		Library.Running = false
		self:ClosePopups()
		if gui then gui:Destroy() end
		local parent = getParent()
		local g = parent:FindFirstChild("WL_Notifs")
		if g then g:Destroy() end
	end

	return win
end

function Library:_CreateSection(tab, name, parentCol)
	name = string.lower(tostring(name))
	local lib = self
	local sec = { Name = name, Tab = tab, Items = {}, _order = 0 }

	local frame = mk("Frame", {
		Name = name,
		BackgroundColor3 = lib.Theme.Section,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 28),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #parentCol:GetChildren() + 1,
		Parent = parentCol,
	})
	stroke(frame, lib.Theme.SectionBorder, 1)

	local header = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = frame,
	})
	mk("Frame", {
		BackgroundColor3 = lib.Theme.SectionBorder,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -16, 0, 1),
		Position = UDim2.new(0, 8, 0.5, 0),
		Parent = header,
	})
	textLabel(header, {
		Text = "  " .. name .. "  ",
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = lib.Theme.Section,
		BackgroundTransparency = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		TextColor3 = lib.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
	})

	local body = mk("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 0),
		Position = UDim2.fromOffset(6, 22),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	})
	mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	mk("UIPadding", { PaddingBottom = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), Parent = body })
	sec.Frame, sec.Body = frame, body

	function sec:_nextOrder() self._order += 1; return self._order end
	function sec:_row(height)
		return mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, height or 20),
			LayoutOrder = self:_nextOrder(),
			Parent = self.Body,
		})
	end
	function sec:AddToggle(opts) return lib:_AddToggle(self, opts) end
	function sec:AddSlider(opts) return lib:_AddSlider(self, opts) end
	function sec:AddDropdown(opts) return lib:_AddDropdown(self, opts) end
	function sec:AddButton(opts) return lib:_AddButton(self, opts) end
	function sec:AddKeybind(opts) return lib:_AddKeybind(self, opts) end
	function sec:AddColorpicker(opts) return lib:_AddColorpicker(self, opts) end
	function sec:AddLabel(opts)
		local r = self:_row(18)
		textLabel(r, {
			Text = string.lower(tostring(opts.Name or opts.Text or "")),
			Size = UDim2.new(1, 0, 1, 0),
			TextColor3 = lib.Theme.TextDim,
		})
		return r
	end
	return sec
end

function Library:_AddToggle(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "toggle"))
	local flag = opts.Flag or name
	local default = opts.Default == true
	local cb = opts.Callback
	local lib = self
	lib.Flags[flag] = default

	local row = sec:_row(20)
	local box = mk("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = default and lib.Theme.ToggleOn or lib.Theme.ToggleOff,
		BorderSizePixel = 0,
		Parent = row,
	})
	stroke(box, lib.Theme.SectionBorder, 1)
	textLabel(row, { Text = name, Size = UDim2.new(1, -22, 1, 0), Position = UDim2.fromOffset(20, 0) })
	local hit = mk("TextButton", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "", Parent = row })

	local obj = { Flag = flag, Row = row, Box = box }
	local function set(v, silent)
		v = v and true or false
		lib.Flags[flag] = v
		box.BackgroundColor3 = v and lib.Theme.ToggleOn or lib.Theme.ToggleOff
		if not silent and cb then pcall(cb, v) end
		if obj._subs then for _, sub in ipairs(obj._subs) do sub.Visible = v end end
	end
	lib.Setters[flag] = set
	hit.MouseButton1Click:Connect(function() set(not lib.Flags[flag]) end)

	function obj:AddColorpicker(cOpts) return lib:_AttachColorpicker(row, cOpts or {}) end
	function obj:AddKeybind(kOpts) return lib:_AttachKeybind(row, kOpts or {}) end
	function obj:AddSub(elementRow)
		obj._subs = obj._subs or {}
		table.insert(obj._subs, elementRow)
		elementRow.Visible = lib.Flags[flag]
		local pad = elementRow:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", elementRow)
		pad.PaddingLeft = UDim.new(0, 12)
		return elementRow
	end
	function obj:AddToggle(sOpts)
		local o = lib:_AddToggle(sec, sOpts); self:AddSub(o.Row); return o
	end
	function obj:AddSlider(sOpts)
		local o = lib:_AddSlider(sec, sOpts); self:AddSub(o.Row); return o
	end
	function obj:AddDropdown(sOpts)
		local o = lib:_AddDropdown(sec, sOpts); self:AddSub(o.Row); return o
	end
	return obj
end

function Library:_AddSlider(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "slider"))
	local flag = opts.Flag or name
	local min, max = opts.Min or 0, opts.Max or 100
	local def, inc = opts.Default or min, opts.Increment or 1
	local suffix, cb = opts.Suffix or "", opts.Callback
	local lib = self
	lib.Flags[flag] = def

	local row = sec:_row(32)
	textLabel(row, { Text = name, Size = UDim2.new(1, -50, 0, 14) })
	local valLbl = textLabel(row, {
		Text = tostring(def) .. suffix,
		Size = UDim2.fromOffset(48, 14),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = lib.Theme.TextDim,
	})
	local track = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 0, 18),
		BackgroundColor3 = lib.Theme.SliderBg,
		BorderSizePixel = 0,
		Parent = row,
	})
	stroke(track, lib.Theme.SectionBorder, 1)
	local fill = mk("Frame", {
		Size = UDim2.new(clamp((def - min) / math.max(max - min, 1e-6), 0, 1), 0, 1, 0),
		BackgroundColor3 = lib.Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	mk("Frame", {
		Size = UDim2.fromOffset(2, 10),
		Position = UDim2.new(1, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = lib.Theme.Text,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = fill,
	})

	local obj = { Flag = flag, Row = row }
	local function set(v, silent)
		v = clamp(tonumber(v) or def, min, max)
		if inc >= 1 then v = math.floor(v / inc + 0.5) * inc
		else
			local d = tostring(inc):match("%.(%d+)")
			local places = d and #d or 1
			v = math.floor(v / inc + 0.5) * inc
			v = tonumber(string.format("%." .. places .. "f", v)) or v
		end
		v = clamp(v, min, max)
		lib.Flags[flag] = v
		fill.Size = UDim2.new((v - min) / math.max(max - min, 1e-6), 0, 1, 0)
		local display = (max >= 1000 and v >= max) and "inf" or v
		valLbl.Text = tostring(display) .. (display == "inf" and "" or suffix)
		if not silent and cb then pcall(cb, v) end
	end
	lib.Setters[flag] = set
	set(def, true)

	local sliding = false
	local function fromX(x)
		local abs, sz = track.AbsolutePosition.X, track.AbsoluteSize.X
		if sz <= 0 then return end
		set(min + (max - min) * clamp((x - abs) / sz, 0, 1))
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true; fromX(input.Position.X)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	return obj
end

function Library:_AddDropdown(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "dropdown"))
	local flag = opts.Flag or name
	local items, multi = opts.Items or {}, opts.Multi == true
	local default, cb = opts.Default, opts.Callback
	local lib, win = self, sec.Tab.Window
	if multi then lib.Flags[flag] = type(default) == "table" and default or {}
	else lib.Flags[flag] = default or (items[1] and string.lower(tostring(items[1]))) or "" end

	local row = sec:_row(36)
	textLabel(row, { Text = name, Size = UDim2.new(1, 0, 0, 14) })
	local box = mk("TextButton", {
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 18),
		Position = UDim2.fromOffset(0, 16),
		BackgroundColor3 = lib.Theme.InputBg,
		BorderSizePixel = 0,
		Text = "",
		Parent = row,
	})
	stroke(box, lib.Theme.SectionBorder, 1)
	local boxLbl = textLabel(box, {
		Text = multi and table.concat(lib.Flags[flag], ", ") or tostring(lib.Flags[flag]),
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.fromOffset(4, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local obj = { Flag = flag, Row = row }
	local function display()
		if multi then
			local t = lib.Flags[flag]
			boxLbl.Text = (#t > 0) and table.concat(t, ", ") or "none"
		else boxLbl.Text = tostring(lib.Flags[flag] or "") end
	end
	local function set(v, silent)
		lib.Flags[flag] = v; display()
		if not silent and cb then pcall(cb, v) end
	end
	lib.Setters[flag] = set

	box.MouseButton1Click:Connect(function()
		if win.OpenPopup and win.OpenPopup.Name == "DD_" .. flag then win:ClosePopups() return end
		win:ClosePopups()
		local pop = mk("Frame", {
			Name = "DD_" .. flag,
			BackgroundColor3 = lib.Theme.Background,
			BorderSizePixel = 0,
			ZIndex = 200,
			Parent = win.PopupLayer,
		})
		stroke(pop, lib.Theme.Border, 2)
		local abs, sz = box.AbsolutePosition, box.AbsoluteSize
		pop.Position = UDim2.fromOffset(abs.X, abs.Y + sz.Y + 2)
		pop.Size = UDim2.fromOffset(math.max(sz.X, 120), math.min(#items * 20 + 4, 160))
		local scroll = mk("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1), ScrollBarThickness = 2,
			CanvasSize = UDim2.new(0, 0, 0, #items * 20), Parent = pop,
		})
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
		for i, it in ipairs(items) do
			local label = string.lower(tostring(it))
			local b = mk("TextButton", {
				AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 20),
				BackgroundColor3 = lib.Theme.Section, BorderSizePixel = 0,
				Text = "  " .. label, FontFace = lib.Font, TextSize = lib.FontSize,
				TextColor3 = lib.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = i, Parent = scroll,
			})
			b.MouseButton1Click:Connect(function()
				if multi then
					local list = type(lib.Flags[flag]) == "table" and { unpack(lib.Flags[flag]) } or {}
					local idx = table.find(list, label)
					if idx then table.remove(list, idx) else table.insert(list, label) end
					set(list)
				else set(label); win:ClosePopups() end
			end)
		end
		win.OpenPopup = pop
	end)
	return obj
end

function Library:_AddButton(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "button"))
	local cb = opts.Callback
	local lib = self
	local row = sec:_row(22)
	local btn = mk("TextButton", {
		AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = lib.Theme.InputBg, BorderSizePixel = 0,
		Text = name, FontFace = lib.Font, TextSize = lib.FontSize,
		TextColor3 = lib.Theme.Text, Parent = row,
	})
	stroke(btn, lib.Theme.SectionBorder, 1)
	btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
	return { Row = row, Button = btn }
end

function Library:_AttachKeybind(row, opts)
	opts = opts or {}
	local flag = opts.Flag or "Keybind"
	local default = opts.Default or Enum.KeyCode.Unknown
	local cb = opts.Callback
	local lib = self
	lib.Flags[flag] = default
	local pad = row:GetAttribute("RightPad") or 2
	local lbl = textLabel(row, {
		Text = "[...]", Size = UDim2.fromOffset(40, 14),
		Position = UDim2.new(1, -pad, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = lib.Theme.TextDim, ZIndex = 5,
	})
	row:SetAttribute("RightPad", pad + 44)
	local function keyName(k)
		if typeof(k) ~= "EnumItem" or k == Enum.KeyCode.Unknown then return "..." end
		return k.Name
	end
	lbl.Text = "[" .. keyName(lib.Flags[flag]) .. "]"
	local listening = false
	local hit = mk("TextButton", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 14),
		Position = lbl.Position, AnchorPoint = Vector2.new(1, 0.5), Text = "", ZIndex = 6, Parent = row,
	})
	hit.MouseButton1Click:Connect(function() listening = true; lbl.Text = "[...]" end)
	local function set(v, silent)
		lib.Flags[flag] = v; lbl.Text = "[" .. keyName(v) .. "]"
		if not silent and cb then pcall(cb, v) end
	end
	lib.Setters[flag] = set
	UIS.InputBegan:Connect(function(input, gp)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then listening = false; set(input.KeyCode) end
			return
		end
		if gp then return end
		if input.KeyCode == lib.Flags[flag] and lib.Flags[flag] ~= Enum.KeyCode.Unknown then
			if cb then pcall(cb, input.KeyCode, true) end
		end
	end)
	return { Flag = flag, Label = lbl }
end

function Library:_AddKeybind(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "keybind"))
	local row = sec:_row(20)
	textLabel(row, { Text = name, Size = UDim2.new(1, -50, 1, 0) })
	local kb = self:_AttachKeybind(row, opts)
	kb.Row = row
	return kb
end

function Library:_AttachColorpicker(row, opts)
	opts = opts or {}
	local flag = opts.Flag or "Color"
	local default = opts.Default or Color3.fromRGB(255, 255, 255)
	local noAlpha = opts.NoAlpha == true
	local title = string.lower(tostring(opts.Name or "color"))
	local cb = opts.Callback
	local lib = self
	lib.Flags[flag] = default
	local alphaKey = flag .. "Transparency"
	if not noAlpha then lib.Flags[alphaKey] = opts.Alpha or 0 end

	local pad = row:GetAttribute("RightPad") or 2
	local sw = mk("TextButton", {
		AutoButtonColor = false, Size = UDim2.fromOffset(28, 14),
		Position = UDim2.new(1, -pad, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = default, BorderSizePixel = 0, Text = "", ZIndex = 5, Parent = row,
	})
	stroke(sw, default, 1)
	row:SetAttribute("RightPad", pad + 32)
	local h, s, v = default:ToHSV()

	local function apply(silent)
		local c = Color3.fromHSV(h, s, v)
		lib.Flags[flag] = c
		sw.BackgroundColor3 = c
		local st = sw:FindFirstChildOfClass("UIStroke")
		if st then st.Color = c end
		if not noAlpha then sw.BackgroundTransparency = lib.Flags[alphaKey] or 0 end
		if not silent and cb then pcall(cb, c, lib.Flags[alphaKey] or 0) end
	end
	lib.Setters[flag] = function(val)
		if typeof(val) == "Color3" then h, s, v = val:ToHSV(); apply(true) end
	end

	sw.MouseButton1Click:Connect(function()
		local gui = sw:FindFirstAncestorOfClass("ScreenGui")
		if not gui then return end
		local layer = gui:FindFirstChild("Popups")
		if not layer then return end
		local existing = layer:FindFirstChild("CP_" .. flag)
		if existing then existing:Destroy() return end
		for _, ch in ipairs(layer:GetChildren()) do ch:Destroy() end

		local pop = mk("Frame", {
			Name = "CP_" .. flag, BackgroundColor3 = lib.Theme.Background, BorderSizePixel = 0,
			Size = UDim2.fromOffset(noAlpha and 180 or 200, noAlpha and 170 or 200), ZIndex = 200, Parent = layer,
		})
		stroke(pop, lib.Theme.Border, 2)
		pop.Position = UDim2.fromOffset(sw.AbsolutePosition.X - 160, sw.AbsolutePosition.Y + 18)
		textLabel(pop, { Text = title, Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(6, 4), TextColor3 = lib.Theme.TextDim })

		local map = mk("ImageLabel", {
			Size = UDim2.fromOffset(150, 150), Position = UDim2.fromOffset(8, 22),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
			Image = "rbxassetid://4155801252", Parent = pop,
		})
		stroke(map, lib.Theme.SectionBorder, 1)
		local cursor = mk("Frame", {
			Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = map,
		})
		stroke(cursor, Color3.new(0, 0, 0), 1)
		local hueBar = mk("Frame", {
			Size = UDim2.fromOffset(14, 150), Position = UDim2.fromOffset(164, 22),
			BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = pop,
		})
		stroke(hueBar, lib.Theme.SectionBorder, 1)
		mk("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
			}),
			Parent = hueBar,
		})
		local hueCap = mk("Frame", {
			Size = UDim2.new(1, 4, 0, 2), Position = UDim2.new(0.5, 0, h, 0),
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0, Parent = hueBar,
		})
		local function refreshCursor()
			cursor.Position = UDim2.new(s, 0, 1 - v, 0)
			map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			hueCap.Position = UDim2.new(0.5, 0, h, 0)
			apply()
		end
		refreshCursor()
		local function bindDrag(frame, fn)
			local held = false
			frame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then held = true; fn(input.Position) end
			end)
			UIS.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then held = false end
			end)
			UIS.InputChanged:Connect(function(input)
				if held and input.UserInputType == Enum.UserInputType.MouseMovement then fn(input.Position) end
			end)
		end
		bindDrag(map, function(pos)
			local a, z = map.AbsolutePosition, map.AbsoluteSize
			s = clamp((pos.X - a.X) / z.X, 0, 1)
			v = 1 - clamp((pos.Y - a.Y) / z.Y, 0, 1)
			refreshCursor()
		end)
		bindDrag(hueBar, function(pos)
			local a, z = hueBar.AbsolutePosition, hueBar.AbsoluteSize
			h = clamp((pos.Y - a.Y) / z.Y, 0, 1)
			refreshCursor()
		end)
		if not noAlpha then
			local aBar = mk("Frame", {
				Size = UDim2.new(0, 150, 0, 12), Position = UDim2.fromOffset(8, 178),
				BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = pop,
			})
			stroke(aBar, lib.Theme.SectionBorder, 1)
			mk("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, s, v)), Parent = aBar })
			local aCap = mk("Frame", {
				Size = UDim2.fromOffset(2, 14), Position = UDim2.new(lib.Flags[alphaKey] or 0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0, Parent = aBar,
			})
			bindDrag(aBar, function(pos)
				local a, z = aBar.AbsolutePosition, aBar.AbsoluteSize
				lib.Flags[alphaKey] = clamp((pos.X - a.X) / z.X, 0, 1)
				aCap.Position = UDim2.new(lib.Flags[alphaKey], 0, 0.5, 0)
				apply()
			end)
		end
	end)
	return { Flag = flag, Swatch = sw }
end

function Library:_AddColorpicker(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "color"))
	local row = sec:_row(20)
	textLabel(row, { Text = name, Size = UDim2.new(1, -36, 1, 0) })
	local cp = self:_AttachColorpicker(row, opts)
	cp.Row = row
	return cp
end

function Library:_CreateSettingsTab(win)
	local tab = win:AddTab("settings")
	local lib = self
	local CONFIG_FOLDER = "wavelength_configs"

	local function ensureFolder()
		if isfolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
	end
	local function listConfigs()
		ensureFolder()
		if not listfiles then return {} end
		local out = {}
		for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
			local n = f:match("([^/\\]+)%.json$")
			if n then out[#out + 1] = n end
		end
		table.sort(out)
		return out
	end
	local function serialize()
		local data = {}
		for k, v in pairs(lib.Flags) do
			if typeof(v) == "EnumItem" then data[k] = { __enum = tostring(v) }
			elseif typeof(v) == "Color3" then data[k] = { __color = { v.R, v.G, v.B } }
			else data[k] = v end
		end
		return data
	end
	local function apply(data)
		if type(data) ~= "table" then return end
		for k, v in pairs(data) do
			if type(v) == "table" and v.__color then
				local col = Color3.new(v.__color[1], v.__color[2], v.__color[3])
				lib.Flags[k] = col
				if lib.Setters[k] then lib.Setters[k](col) end
			elseif type(v) == "table" and v.__enum then
				local n = v.__enum:match("KeyCode%.(.+)$") or v.__enum
				local ok, enum = pcall(function() return Enum.KeyCode[n] end)
				if ok then lib.Flags[k] = enum; if lib.Setters[k] then lib.Setters[k](enum) end end
			else
				lib.Flags[k] = v
				if lib.Setters[k] then lib.Setters[k](v) end
			end
		end
	end

	local cfgSec = tab:AddSection("configs", 1)
	local selected, listBody = nil, nil
	local function refreshList()
		if listBody then listBody:Destroy() end
		listBody = mk("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 50, Parent = cfgSec.Body,
		})
		mk("UIListLayout", { Padding = UDim.new(0, 2), Parent = listBody })
		for _, name in ipairs(listConfigs()) do
			local b = mk("TextButton", {
				AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 18),
				BackgroundColor3 = selected == name and lib.Theme.Hover or lib.Theme.InputBg,
				BorderSizePixel = 0, Text = "  " .. name, FontFace = lib.Font, TextSize = lib.FontSize,
				TextColor3 = lib.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = listBody,
			})
			stroke(b, lib.Theme.SectionBorder, 1)
			b.MouseButton1Click:Connect(function() selected = name; refreshList() end)
		end
	end

	local nameBox
	do
		local row = cfgSec:_row(40)
		textLabel(row, { Text = "name", Size = UDim2.new(1, 0, 0, 14) })
		nameBox = mk("TextBox", {
			Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 16),
			BackgroundColor3 = lib.Theme.InputBg, BorderSizePixel = 0, Text = "",
			PlaceholderText = "config name", FontFace = lib.Font, TextSize = lib.FontSize,
			TextColor3 = lib.Theme.Text, ClearTextOnFocus = false, Parent = row,
		})
		stroke(nameBox, lib.Theme.SectionBorder, 1)
	end
	cfgSec:AddButton({
		Name = "save",
		Callback = function()
			local n = nameBox.Text
			if n == "" and selected then n = selected end
			if not n or n == "" then lib:Notify({ Text = "enter a config name", Duration = 2 }) return end
			ensureFolder()
			writefile(CONFIG_FOLDER .. "/" .. n .. ".json", HttpService:JSONEncode(serialize()))
			selected = n; refreshList()
			lib:Notify({ Text = 'created "' .. n .. '" main config', Duration = 2 })
		end,
	})
	cfgSec:AddButton({
		Name = "load",
		Callback = function()
			if not selected then lib:Notify({ Text = "select a config first", Duration = 2 }) return end
			local ok, data = pcall(function()
				return HttpService:JSONDecode(readfile(CONFIG_FOLDER .. "/" .. selected .. ".json"))
			end)
			if ok and type(data) == "table" then
				apply(data)
				lib:Notify({ Text = 'loaded "' .. selected .. '" main config', Duration = 2 })
			else lib:Notify({ Text = "load failed", Duration = 2 }) end
		end,
	})
	cfgSec:AddButton({
		Name = "delete",
		Callback = function()
			if not selected then return end
			pcall(function() delfile(CONFIG_FOLDER .. "/" .. selected .. ".json") end)
			lib:Notify({ Text = 'deleted "' .. selected .. '" main config', Duration = 2 })
			selected = nil; refreshList()
		end,
	})
	refreshList()

	local setSec = tab:AddSection("settings", 2)
	setSec:AddKeybind({ Name = "menu key", Flag = "MenuKeybind", Default = Enum.KeyCode.RightShift })
	setSec:AddColorpicker({
		Name = "accent", Flag = "ThemeAccent", Default = lib.Theme.Accent, NoAlpha = true,
		Callback = function(c) lib.Theme.Accent = c end,
	})
	setSec:AddColorpicker({
		Name = "border", Flag = "ThemeBorder", Default = lib.Theme.Border, NoAlpha = true,
		Callback = function(c) lib.Theme.Border = c end,
	})
	local unloadArmed = false
	setSec:AddButton({
		Name = "unload",
		Callback = function()
			if not unloadArmed then
				unloadArmed = true
				lib:Notify({ Text = "click unload again to confirm", Duration = 2 })
				task.delay(2, function() unloadArmed = false end)
				return
			end
			win:Unload()
		end,
	})
	return tab
end

return Library
