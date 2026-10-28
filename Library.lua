--[[
	wavelength UI Library
	https://github.com/illorsm/wavelength

	local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/illorsm/wavelength/main/Library.lua"))()
	local Window = Library:CreateWindow({ Name = "wavelength" })
	local Tab = Window:AddTab("visuals")
	local Sec = Tab:AddSection("players", 1)
	local t = Sec:AddToggle({ Name = "box", Flag = "Box", Default = false })
	t:AddColorpicker({ Flag = "BoxColor", Default = Color3.fromRGB(255,255,255), NoAlpha = true })
	Window:AddSettingsTab()
	Window:Init()
]]

local Library = { Flags = {}, Setters = {}, Connections = {}, Running = true }
Library.__index = Library

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local function gethuiparent()
	if typeof(gethui) == "function" then
		local ok, g = pcall(gethui)
		if ok and g then return g end
	end
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	return LP:WaitForChild("PlayerGui")
end

local function clamp(n, a, b) return math.min(b, math.max(a, n)) end

-- ── Theme (matches prior wavelength menu) ──
Library.Theme = {
	Text = Color3.fromRGB(235, 235, 235),
	TextDim = Color3.fromRGB(160, 160, 160),
	Border = Color3.fromRGB(0, 0, 0),
	SectionBorder = Color3.fromRGB(0, 0, 0),
	Accent1 = Color3.fromRGB(255, 255, 255),
	Accent2 = Color3.fromRGB(0, 0, 0),
	Background = Color3.fromRGB(36, 36, 36),
	SectionBg = Color3.fromRGB(18, 18, 18),
	ControlBg = Color3.fromRGB(28, 28, 28),
	ToggleOff = Color3.fromRGB(55, 55, 55),
	SliderBg = Color3.fromRGB(45, 45, 45),
}

-- try Proggy Clean style size
Library.FontSize = 12
do
	local ok, font = pcall(function()
		return Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	end)
	Library.Font = ok and font or Font.fromEnum(Enum.Font.Code)
end

function Library:GetFlag(f) return self.Flags[f] end
function Library:SetFlag(f, v)
	self.Flags[f] = v
	if self.Setters[f] then pcall(self.Setters[f], v) end
end
function Library:OnFlag(f, cb)
	local old = self.Setters[f]
	self.Setters[f] = function(v)
		if old then pcall(old, v) end
		pcall(cb, v)
	end
end

local function mk(c, p)
	local o = Instance.new(c)
	if p then for k, v in pairs(p) do o[k] = v end end
	return o
end

local function outline(parent, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or Library.Theme.Border
	s.Thickness = thick or 1
	s.LineJoinMode = Enum.LineJoinMode.Miter
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function lbl(parent, props)
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

function Library:Notify(opts)
	opts = opts or {}
	local text = tostring(opts.Text or "")
	local dur = opts.Duration or 2
	local parent = gethuiparent()
	local gui = parent:FindFirstChild("WL_Notifs")
	if not gui then
		gui = mk("ScreenGui", { Name = "WL_Notifs", IgnoreGuiInset = true, ResetOnSpawn = false, Parent = parent })
	end
	local f = mk("Frame", {
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(math.clamp(#text * 7 + 20, 100, 340), 26),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10 + #gui:GetChildren() * 30),
		Parent = gui,
	})
	outline(f, self.Theme.Border, 2)
	local bar = mk("Frame", { Size = UDim2.new(1, 0, 0, 2), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1), Parent = f })
	mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, self.Theme.Accent1),
			ColorSequenceKeypoint.new(1, self.Theme.Accent2),
		}),
		Parent = bar,
	})
	lbl(f, { Text = text, Size = UDim2.new(1, -10, 1, -2), Position = UDim2.fromOffset(5, 2) })
	task.delay(dur, function() if f.Parent then f:Destroy() end end)
end

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
function Library:CreateWindow(opts)
	opts = opts or {}
	local name = tostring(opts.Name or "wavelength")
	local W = opts.Width or 560
	local H = opts.Height or 400
	local TITLE_H, TAB_H, LINE_H = 22, 26, 2

	local win = setmetatable({
		Tabs = {},
		TabOrder = {},
		Current = nil,
		Library = self,
	}, { __index = {} })

	local gui = mk("ScreenGui", {
		Name = "WL_Menu",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = gethuiparent(),
	})
	win.Gui = gui

	local shell = mk("Frame", {
		Name = "Shell",
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(W, H),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Active = true,
		Parent = gui,
	})
	win.Shell = shell
	outline(shell, self.Theme.Border, 2)

	-- top accent line
	local topLine = mk("Frame", {
		Size = UDim2.new(1, 0, 0, LINE_H),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 5,
		Parent = shell,
	})
	local topGrad = mk("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, self.Theme.Accent1),
			ColorSequenceKeypoint.new(0.5, self.Theme.Accent2),
			ColorSequenceKeypoint.new(1, self.Theme.Accent1),
		}),
		Parent = topLine,
	})
	task.spawn(function()
		while Library.Running and topGrad.Parent do
			topGrad.Offset = Vector2.new((tick() * 0.2 % 2) - 1, 0)
			task.wait(0.03)
		end
	end)

	-- title
	local titleBar = mk("Frame", {
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, TITLE_H),
		Position = UDim2.fromOffset(0, LINE_H),
		Active = true,
		Parent = shell,
	})
	lbl(titleBar, {
		Text = string.lower(name),
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.fromOffset(8, 0),
		TextColor3 = self.Theme.TextDim,
	})

	-- drag
	do
		local drag, origin, start
		titleBar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				drag, origin, start = true, shell.Position, i.Position
				i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then drag = false end
				end)
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - start
				shell.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
			end
		end)
	end

	-- TOP TAB BAR (like reference image)
	local tabBar = mk("Frame", {
		BackgroundColor3 = self.Theme.Background,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, TAB_H),
		Position = UDim2.fromOffset(0, LINE_H + TITLE_H),
		Parent = shell,
	})
	win.TabBar = tabBar
	local tabSep = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		Parent = tabBar,
	})
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabBar,
	})
	mk("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = tabBar })

	-- body
	local bodyY = LINE_H + TITLE_H + TAB_H
	local body = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -bodyY),
		Position = UDim2.fromOffset(0, bodyY),
		ClipsDescendants = true,
		Parent = shell,
	})
	win.Body = body

	-- popup layer
	local popups = mk("Frame", {
		Name = "Popups",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Parent = gui,
	})
	win.Popups = popups

	function win:ClosePopups()
		for _, c in ipairs(self.Popups:GetChildren()) do c:Destroy() end
	end

	function win:SelectTab(id)
		for n, t in pairs(self.Tabs) do
			local on = n == id
			t.Page.Visible = on
			t.Accent.Visible = on
			t.Btn.TextColor3 = on and Library.Theme.Text or Library.Theme.TextDim
		end
		self.Current = id
		self:ClosePopups()
	end

	function win:AddTab(tabName)
		tabName = string.lower(tostring(tabName))
		local tab = { Name = tabName, Window = self }

		local btn = mk("TextButton", {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(72, TAB_H - 1),
			FontFace = Library.Font,
			TextSize = Library.FontSize,
			Text = tabName,
			TextColor3 = Library.Theme.TextDim,
			BorderSizePixel = 0,
			LayoutOrder = #self.TabOrder + 1,
			Parent = self.TabBar,
		})
		tab.Btn = btn

		-- selected accent under tab
		local accent = mk("Frame", {
			BackgroundColor3 = Library.Theme.Text,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -16, 0, 1),
			Position = UDim2.new(0, 8, 1, -1),
			Visible = false,
			ZIndex = 3,
			Parent = btn,
		})
		tab.Accent = accent

		local page = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = self.Body,
		})
		tab.Page = page

		local gap = 6
		local colW = math.floor((W - gap * 3) / 2)

		local function makeCol(x)
			local sf = mk("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(colW, H - bodyY - gap * 2),
				Position = UDim2.fromOffset(x, gap),
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Parent = page,
			})
			mk("UIListLayout", { Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sf })
			return sf
		end
		tab.Left = makeCol(gap)
		tab.Right = makeCol(gap * 2 + colW)

		btn.MouseButton1Click:Connect(function() self:SelectTab(tabName) end)
		self.Tabs[tabName] = tab
		self.TabOrder[#self.TabOrder + 1] = tabName
		if not self.Current then self:SelectTab(tabName) end

		function tab:AddSection(sectionName, side)
			return Library:_Section(self, sectionName, side == 2 and self.Right or self.Left)
		end
		return tab
	end

	function win:AddSettingsTab()
		return Library:_SettingsTab(self)
	end

	function win:Init()
		Library.Flags.MenuKeybind = Library.Flags.MenuKeybind or Enum.KeyCode.RightShift
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
		gui:Destroy()
		local n = gethuiparent():FindFirstChild("WL_Notifs")
		if n then n:Destroy() end
	end

	return win
end

----------------------------------------------------------------
-- Section
----------------------------------------------------------------
function Library:_Section(tab, name, parent)
	name = string.lower(tostring(name))
	local lib = self
	local sec = { _n = 0, Tab = tab }

	local frame = mk("Frame", {
		BackgroundColor3 = lib.Theme.SectionBg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #parent:GetChildren() + 1,
		Parent = parent,
	})
	outline(frame, lib.Theme.SectionBorder, 1)

	-- header line + title centered on it
	local head = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Parent = frame,
	})
	mk("Frame", {
		BackgroundColor3 = lib.Theme.SectionBorder,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -12, 0, 1),
		Position = UDim2.new(0, 6, 0.5, 0),
		Parent = head,
	})
	lbl(head, {
		Text = " " .. name .. " ",
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = lib.Theme.SectionBg,
		BackgroundTransparency = 0,
		TextColor3 = lib.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
	})

	local body = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -12, 0, 0),
		Position = UDim2.fromOffset(6, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	})
	mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
	mk("UIPadding", { PaddingBottom = UDim.new(0, 6), PaddingTop = UDim.new(0, 2), Parent = body })
	sec.Body = body

	function sec:Row(h)
		self._n += 1
		return mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, h or 18),
			LayoutOrder = self._n,
			Parent = self.Body,
		})
	end

	function sec:AddToggle(o) return lib:_Toggle(self, o) end
	function sec:AddSlider(o) return lib:_Slider(self, o) end
	function sec:AddDropdown(o) return lib:_Dropdown(self, o) end
	function sec:AddButton(o) return lib:_Button(self, o) end
	function sec:AddKeybind(o) return lib:_Keybind(self, o) end
	function sec:AddColorpicker(o) return lib:_Colorpicker(self, o) end
	function sec:AddLabel(o)
		local r = self:Row(16)
		lbl(r, { Text = string.lower(tostring(o.Name or "")), Size = UDim2.fromScale(1, 1), TextColor3 = lib.Theme.TextDim })
		return r
	end
	return sec
end

----------------------------------------------------------------
-- Toggle
----------------------------------------------------------------
function Library:_Toggle(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "toggle"))
	local flag = opts.Flag or name
	local on = opts.Default == true
	local cb = opts.Callback
	local lib = self
	lib.Flags[flag] = on

	local row = sec:Row(18)
	local box = mk("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.fromOffset(0, 3),
		BackgroundColor3 = on and lib.Theme.Text or lib.Theme.ToggleOff,
		BorderSizePixel = 0,
		Parent = row,
	})
	outline(box, lib.Theme.Border, 1)
	lbl(row, { Text = name, Size = UDim2.new(1, -18, 1, 0), Position = UDim2.fromOffset(16, 0) })
	local hit = mk("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = row })

	local obj = { Flag = flag, Row = row, _subs = {} }
	local function set(v, silent)
		v = v and true or false
		lib.Flags[flag] = v
		box.BackgroundColor3 = v and lib.Theme.Text or lib.Theme.ToggleOff
		for _, s in ipairs(obj._subs) do s.Visible = v end
		if not silent and cb then pcall(cb, v) end
	end
	lib.Setters[flag] = set
	hit.MouseButton1Click:Connect(function() set(not lib.Flags[flag]) end)

	function obj:AddSub(r)
		table.insert(self._subs, r)
		r.Visible = lib.Flags[flag]
		local p = r:FindFirstChildOfClass("UIPadding") or mk("UIPadding", { Parent = r })
		p.PaddingLeft = UDim.new(0, 12)
		return r
	end
	function obj:AddColorpicker(o) return lib:_AttachPicker(row, o or {}) end
	function obj:AddKeybind(o) return lib:_AttachKeybind(row, o or {}) end
	function obj:AddToggle(o) local x = lib:_Toggle(sec, o); self:AddSub(x.Row); return x end
	function obj:AddSlider(o) local x = lib:_Slider(sec, o); self:AddSub(x.Row); return x end
	function obj:AddDropdown(o) local x = lib:_Dropdown(sec, o); self:AddSub(x.Row); return x end
	return obj
end

----------------------------------------------------------------
-- Slider
----------------------------------------------------------------
function Library:_Slider(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "slider"))
	local flag = opts.Flag or name
	local min, max = opts.Min or 0, opts.Max or 100
	local def, step = opts.Default or min, opts.Increment or 1
	local suffix, cb = opts.Suffix or "", opts.Callback
	local lib = self
	lib.Flags[flag] = def

	local row = sec:Row(30)
	lbl(row, { Text = name, Size = UDim2.new(1, -48, 0, 14) })
	local val = lbl(row, {
		Text = tostring(def) .. suffix,
		Size = UDim2.fromOffset(46, 14),
		Position = UDim2.new(1, 0, 0, 0),
		AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = lib.Theme.TextDim,
	})

	local track = mk("Frame", {
		Size = UDim2.new(1, 0, 0, 5),
		Position = UDim2.fromOffset(0, 18),
		BackgroundColor3 = lib.Theme.SliderBg,
		BorderSizePixel = 0,
		Parent = row,
	})
	outline(track, lib.Theme.Border, 1)

	local fill = mk("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = lib.Theme.Text,
		BorderSizePixel = 0,
		Parent = track,
	})
	-- end cap line (like colorpicker bars) — sits on fill end, doesn't spill past track
	local cap = mk("Frame", {
		Size = UDim2.fromOffset(1, 9),
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
		if step >= 1 then v = math.floor(v / step + 0.5) * step
		else
			local places = #(tostring(step):match("%.(%d+)") or "1")
			v = tonumber(string.format("%." .. places .. "f", math.floor(v / step + 0.5) * step)) or v
		end
		v = clamp(v, min, max)
		lib.Flags[flag] = v
		local pct = (v - min) / math.max(max - min, 1e-6)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		local d = (max >= 1000 and v >= max) and "inf" or v
		val.Text = tostring(d) .. (d == "inf" and "" or suffix)
		if not silent and cb then pcall(cb, v) end
	end
	lib.Setters[flag] = set
	set(def, true)

	local hold = false
	local function at(x)
		local a, z = track.AbsolutePosition.X, track.AbsoluteSize.X
		if z <= 0 then return end
		set(min + (max - min) * clamp((x - a) / z, 0, 1))
	end
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then hold = true; at(i.Position.X) end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then hold = false end
	end)
	UIS.InputChanged:Connect(function(i)
		if hold and i.UserInputType == Enum.UserInputType.MouseMovement then at(i.Position.X) end
	end)
	return obj
end

----------------------------------------------------------------
-- Dropdown
----------------------------------------------------------------
function Library:_Dropdown(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "dropdown"))
	local flag = opts.Flag or name
	local items, multi = opts.Items or {}, opts.Multi == true
	local default, cb = opts.Default, opts.Callback
	local lib = self
	local win = sec.Tab.Window
	if multi then lib.Flags[flag] = type(default) == "table" and default or {}
	else lib.Flags[flag] = default or (items[1] and string.lower(tostring(items[1]))) or "" end

	local row = sec:Row(34)
	lbl(row, { Text = name, Size = UDim2.new(1, 0, 0, 14) })
	local box = mk("TextButton", {
		AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 15),
		BackgroundColor3 = lib.Theme.ControlBg,
		BorderSizePixel = 0,
		Text = "",
		Parent = row,
	})
	outline(box, lib.Theme.Border, 1)
	local boxLbl = lbl(box, {
		Text = multi and table.concat(lib.Flags[flag], ", ") or tostring(lib.Flags[flag]),
		Size = UDim2.new(1, -8, 1, 0),
		Position = UDim2.fromOffset(4, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local obj = { Flag = flag, Row = row }
	local function paint()
		if multi then
			local t = lib.Flags[flag]
			boxLbl.Text = (#t > 0) and table.concat(t, ", ") or "none"
		else boxLbl.Text = tostring(lib.Flags[flag] or "") end
	end
	local function set(v, silent)
		lib.Flags[flag] = v; paint()
		if not silent and cb then pcall(cb, v) end
	end
	lib.Setters[flag] = set

	box.MouseButton1Click:Connect(function()
		local existing = win.Popups:FindFirstChild("DD_" .. flag)
		if existing then win:ClosePopups() return end
		win:ClosePopups()
		local pop = mk("Frame", {
			Name = "DD_" .. flag,
			BackgroundColor3 = lib.Theme.Background,
			BorderSizePixel = 0,
			ZIndex = 100,
			Parent = win.Popups,
		})
		outline(pop, lib.Theme.Border, 2)
		local ap, az = box.AbsolutePosition, box.AbsoluteSize
		pop.Position = UDim2.fromOffset(ap.X, ap.Y + az.Y + 1)
		pop.Size = UDim2.fromOffset(math.max(az.X, 100), math.min(#items * 18 + 4, 140))
		local sc = mk("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1), ScrollBarThickness = 2,
			CanvasSize = UDim2.new(0, 0, 0, #items * 18), Parent = pop,
		})
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = sc })
		for i, it in ipairs(items) do
			local label = string.lower(tostring(it))
			local b = mk("TextButton", {
				AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 18),
				BackgroundColor3 = lib.Theme.SectionBg, BorderSizePixel = 0,
				Text = "  " .. label, FontFace = lib.Font, TextSize = lib.FontSize,
				TextColor3 = lib.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = i, Parent = sc,
			})
			b.MouseEnter:Connect(function() b.BackgroundColor3 = lib.Theme.ControlBg end)
			b.MouseLeave:Connect(function() b.BackgroundColor3 = lib.Theme.SectionBg end)
			b.MouseButton1Click:Connect(function()
				if multi then
					local list = type(lib.Flags[flag]) == "table" and table.clone(lib.Flags[flag]) or {}
					local idx = table.find(list, label)
					if idx then table.remove(list, idx) else table.insert(list, label) end
					set(list)
				else set(label); win:ClosePopups() end
			end)
		end
	end)
	return obj
end

----------------------------------------------------------------
-- Button
----------------------------------------------------------------
function Library:_Button(sec, opts)
	opts = opts or {}
	local name = string.lower(tostring(opts.Name or "button"))
	local cb = opts.Callback
	local lib = self
	local row = sec:Row(20)
	local btn = mk("TextButton", {
		AutoButtonColor = false, Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = lib.Theme.ControlBg, BorderSizePixel = 0,
		Text = name, FontFace = lib.Font, TextSize = lib.FontSize,
		TextColor3 = lib.Theme.Text, Parent = row,
	})
	outline(btn, lib.Theme.Border, 1)
	btn.MouseButton1Click:Connect(function() if cb then pcall(cb) end end)
	return { Row = row, Button = btn }
end

----------------------------------------------------------------
-- Keybind
----------------------------------------------------------------
function Library:_AttachKeybind(row, opts)
	opts = opts or {}
	local flag = opts.Flag or "Key"
	local def = opts.Default or Enum.KeyCode.Unknown
	local cb = opts.Callback
	local lib = self
	lib.Flags[flag] = def
	local pad = row:GetAttribute("RP") or 2
	local function kn(k)
		if typeof(k) ~= "EnumItem" or k == Enum.KeyCode.Unknown then return "..." end
		return k.Name
	end
	local t = lbl(row, {
		Text = "[" .. kn(def) .. "]",
		Size = UDim2.fromOffset(42, 14),
		Position = UDim2.new(1, -pad, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = lib.Theme.TextDim,
		ZIndex = 4,
	})
	row:SetAttribute("RP", pad + 44)
	local listening = false
	local hit = mk("TextButton", {
		Text = "", BackgroundTransparency = 1,
		Size = UDim2.fromOffset(42, 14),
		Position = t.Position, AnchorPoint = Vector2.new(1, 0.5),
		ZIndex = 5, Parent = row,
	})
	local function set(v, silent)
		lib.Flags[flag] = v
		t.Text = "[" .. kn(v) .. "]"
		if not silent and cb then pcall(cb, v) end
	end
	lib.Setters[flag] = set
	hit.MouseButton1Click:Connect(function() listening = true; t.Text = "[...]" end)
	UIS.InputBegan:Connect(function(input, gp)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false; set(input.KeyCode); return
		end
		if gp or listening then return end
		if input.KeyCode == lib.Flags[flag] and lib.Flags[flag] ~= Enum.KeyCode.Unknown then
			if cb then pcall(cb, input.KeyCode, true) end
		end
	end)
	return { Flag = flag }
end

function Library:_Keybind(sec, opts)
	opts = opts or {}
	local row = sec:Row(18)
	lbl(row, { Text = string.lower(tostring(opts.Name or "key")), Size = UDim2.new(1, -48, 1, 0) })
	local k = self:_AttachKeybind(row, opts)
	k.Row = row
	return k
end

----------------------------------------------------------------
-- Colorpicker
----------------------------------------------------------------
function Library:_AttachPicker(row, opts)
	opts = opts or {}
	local flag = opts.Flag or "Color"
	local def = opts.Default or Color3.fromRGB(255, 255, 255)
	local noA = opts.NoAlpha == true
	local title = string.lower(tostring(opts.Name or "color"))
	local cb = opts.Callback
	local lib = self
	lib.Flags[flag] = def
	local aKey = flag .. "Transparency"
	if not noA then lib.Flags[aKey] = opts.Alpha or 0 end

	local pad = row:GetAttribute("RP") or 2
	local sw = mk("TextButton", {
		AutoButtonColor = false, Text = "",
		Size = UDim2.fromOffset(26, 12),
		Position = UDim2.new(1, -pad, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = def, BorderSizePixel = 0, ZIndex = 4, Parent = row,
	})
	outline(sw, def, 1)
	row:SetAttribute("RP", pad + 30)
	local h, s, v = def:ToHSV()

	local function apply(silent)
		local c = Color3.fromHSV(h, s, v)
		lib.Flags[flag] = c
		sw.BackgroundColor3 = c
		local st = sw:FindFirstChildOfClass("UIStroke")
		if st then st.Color = c end
		if not noA then sw.BackgroundTransparency = lib.Flags[aKey] or 0 end
		if not silent and cb then pcall(cb, c, lib.Flags[aKey] or 0) end
	end
	lib.Setters[flag] = function(val)
		if typeof(val) == "Color3" then h, s, v = val:ToHSV(); apply(true) end
	end

	sw.MouseButton1Click:Connect(function()
		local gui = sw:FindFirstAncestorOfClass("ScreenGui")
		local layer = gui and gui:FindFirstChild("Popups")
		if not layer then return end
		if layer:FindFirstChild("CP_" .. flag) then layer:FindFirstChild("CP_" .. flag):Destroy() return end
		for _, c in ipairs(layer:GetChildren()) do c:Destroy() end

		local pop = mk("Frame", {
			Name = "CP_" .. flag, BackgroundColor3 = lib.Theme.Background, BorderSizePixel = 0,
			Size = UDim2.fromOffset(noA and 178 or 178, noA and 168 or 196), ZIndex = 100, Parent = layer,
		})
		outline(pop, lib.Theme.Border, 2)
		pop.Position = UDim2.fromOffset(sw.AbsolutePosition.X - 150, sw.AbsolutePosition.Y + 16)
		lbl(pop, { Text = title, Size = UDim2.new(1, -10, 0, 14), Position = UDim2.fromOffset(6, 4), TextColor3 = lib.Theme.TextDim })

		local map = mk("ImageLabel", {
			Size = UDim2.fromOffset(140, 140), Position = UDim2.fromOffset(8, 20),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
			Image = "rbxassetid://4155801252", Parent = pop,
		})
		outline(map, lib.Theme.Border, 1)
		local cur = mk("Frame", {
			Size = UDim2.fromOffset(5, 5), AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 2, Parent = map,
		})
		outline(cur, Color3.new(0,0,0), 1)

		local hue = mk("Frame", {
			Size = UDim2.fromOffset(12, 140), Position = UDim2.fromOffset(154, 20),
			BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = pop,
		})
		outline(hue, lib.Theme.Border, 1)
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
			Parent = hue,
		})
		local hCap = mk("Frame", {
			Size = UDim2.new(1, 4, 0, 2), Position = UDim2.new(0.5, 0, h, 0),
			AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1,1,1),
			BorderSizePixel = 0, Parent = hue,
		})

		local function refresh()
			cur.Position = UDim2.new(s, 0, 1 - v, 0)
			map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			hCap.Position = UDim2.new(0.5, 0, h, 0)
			apply()
		end
		refresh()

		local function drag(fr, fn)
			local held = false
			fr.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then held = true; fn(i.Position) end
			end)
			UIS.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 then held = false end
			end)
			UIS.InputChanged:Connect(function(i)
				if held and i.UserInputType == Enum.UserInputType.MouseMovement then fn(i.Position) end
			end)
		end
		drag(map, function(pos)
			local a, z = map.AbsolutePosition, map.AbsoluteSize
			s = clamp((pos.X - a.X) / z.X, 0, 1)
			v = 1 - clamp((pos.Y - a.Y) / z.Y, 0, 1)
			refresh()
		end)
		drag(hue, function(pos)
			local a, z = hue.AbsolutePosition, hue.AbsoluteSize
			h = clamp((pos.Y - a.Y) / z.Y, 0, 1)
			refresh()
		end)

		if not noA then
			local aBar = mk("Frame", {
				Size = UDim2.fromOffset(140, 10), Position = UDim2.fromOffset(8, 168),
				BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = pop,
			})
			outline(aBar, lib.Theme.Border, 1)
			mk("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromHSV(h,s,v)), Parent = aBar })
			local aCap = mk("Frame", {
				Size = UDim2.fromOffset(2, 12), Position = UDim2.new(lib.Flags[aKey] or 0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1,1,1),
				BorderSizePixel = 0, Parent = aBar,
			})
			drag(aBar, function(pos)
				local a, z = aBar.AbsolutePosition, aBar.AbsoluteSize
				lib.Flags[aKey] = clamp((pos.X - a.X) / z.X, 0, 1)
				aCap.Position = UDim2.new(lib.Flags[aKey], 0, 0.5, 0)
				apply()
			end)
		end
	end)
	return { Flag = flag, Swatch = sw }
end

function Library:_Colorpicker(sec, opts)
	opts = opts or {}
	local row = sec:Row(18)
	lbl(row, { Text = string.lower(tostring(opts.Name or "color")), Size = UDim2.new(1, -32, 1, 0) })
	local cp = self:_AttachPicker(row, opts)
	cp.Row = row
	return cp
end

----------------------------------------------------------------
-- Settings tab
----------------------------------------------------------------
function Library:_SettingsTab(win)
	local tab = win:AddTab("settings")
	local lib = self
	local FOLDER = "wavelength_configs"

	local function ensure()
		if isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end
	end
	local function list()
		ensure()
		if not listfiles then return {} end
		local o = {}
		for _, f in ipairs(listfiles(FOLDER)) do
			local n = f:match("([^/\\]+)%.json$")
			if n then o[#o+1] = n end
		end
		table.sort(o); return o
	end
	local function serialize()
		local d = {}
		for k, v in pairs(lib.Flags) do
			if typeof(v) == "EnumItem" then d[k] = { __enum = tostring(v) }
			elseif typeof(v) == "Color3" then d[k] = { __color = { v.R, v.G, v.B } }
			else d[k] = v end
		end
		return d
	end
	local function apply(data)
		if type(data) ~= "table" then return end
		for k, v in pairs(data) do
			if type(v) == "table" and v.__color then
				local c = Color3.new(v.__color[1], v.__color[2], v.__color[3])
				lib.Flags[k] = c
				if lib.Setters[k] then lib.Setters[k](c) end
			elseif type(v) == "table" and v.__enum then
				local n = v.__enum:match("KeyCode%.(.+)$") or v.__enum
				local ok, e = pcall(function() return Enum.KeyCode[n] end)
				if ok then lib.Flags[k] = e; if lib.Setters[k] then lib.Setters[k](e) end end
			else
				lib.Flags[k] = v
				if lib.Setters[k] then lib.Setters[k](v) end
			end
		end
	end

	local cfg = tab:AddSection("configs", 1)
	local selected, listBody = nil, nil
	local function refresh()
		if listBody then listBody:Destroy() end
		listBody = mk("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 99, Parent = cfg.Body,
		})
		mk("UIListLayout", { Padding = UDim.new(0, 2), Parent = listBody })
		for _, n in ipairs(list()) do
			local b = mk("TextButton", {
				AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 16),
				BackgroundColor3 = selected == n and lib.Theme.ControlBg or lib.Theme.SectionBg,
				BorderSizePixel = 0, Text = "  " .. n, FontFace = lib.Font, TextSize = lib.FontSize,
				TextColor3 = lib.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = listBody,
			})
			outline(b, lib.Theme.Border, 1)
			b.MouseButton1Click:Connect(function() selected = n; refresh() end)
		end
	end
	local nameBox
	do
		local r = cfg:Row(36)
		lbl(r, { Text = "name", Size = UDim2.new(1, 0, 0, 14) })
		nameBox = mk("TextBox", {
			Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 16),
			BackgroundColor3 = lib.Theme.ControlBg, BorderSizePixel = 0, Text = "",
			PlaceholderText = "config name", FontFace = lib.Font, TextSize = lib.FontSize,
			TextColor3 = lib.Theme.Text, ClearTextOnFocus = false, Parent = r,
		})
		outline(nameBox, lib.Theme.Border, 1)
	end
	cfg:AddButton({
		Name = "save",
		Callback = function()
			local n = nameBox.Text
			if n == "" and selected then n = selected end
			if not n or n == "" then lib:Notify({ Text = "enter a config name", Duration = 2 }) return end
			ensure()
			writefile(FOLDER .. "/" .. n .. ".json", HttpService:JSONEncode(serialize()))
			selected = n; refresh()
			lib:Notify({ Text = 'created "' .. n .. '" main config', Duration = 2 })
		end,
	})
	cfg:AddButton({
		Name = "load",
		Callback = function()
			if not selected then lib:Notify({ Text = "select a config first", Duration = 2 }) return end
			local ok, data = pcall(function()
				return HttpService:JSONDecode(readfile(FOLDER .. "/" .. selected .. ".json"))
			end)
			if ok and type(data) == "table" then
				apply(data)
				lib:Notify({ Text = 'loaded "' .. selected .. '" main config', Duration = 2 })
			else lib:Notify({ Text = "load failed", Duration = 2 }) end
		end,
	})
	cfg:AddButton({
		Name = "delete",
		Callback = function()
			if not selected then return end
			pcall(function() delfile(FOLDER .. "/" .. selected .. ".json") end)
			lib:Notify({ Text = 'deleted "' .. selected .. '" main config', Duration = 2 })
			selected = nil; refresh()
		end,
	})
	refresh()

	local set = tab:AddSection("settings", 2)
	set:AddKeybind({ Name = "menu key", Flag = "MenuKeybind", Default = Enum.KeyCode.RightShift })
	local armed = false
	set:AddButton({
		Name = "unload",
		Callback = function()
			if not armed then
				armed = true
				lib:Notify({ Text = "click unload again to confirm", Duration = 2 })
				task.delay(2, function() armed = false end)
				return
			end
			win:Unload()
		end,
	})
	return tab
end

return Library
