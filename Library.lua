local env = (typeof(getgenv) == "function" and getgenv()) or _G
env._SM = env._SM or {}
local U = env._SM
U._ver = (U._ver or 0) + 1 
local ver = U._ver
local function alive() return U._ver == ver end

for k, s in pairs({ Players = "Players", UIS = "UserInputService", Tween = "TweenService", Http = "HttpService", Run = "RunService", Text = "TextService" }) do
	U[k] = game:GetService(s)
end
U.lp = U.Players.LocalPlayer

U.theme = U.theme or {
	Text = Color3.fromRGB(220, 220, 220),
	Border = Color3.fromRGB(0, 0, 0),
	SectionBorder = Color3.fromRGB(0, 0, 0),
	ElementBorder = Color3.fromRGB(0, 0, 0),
	Accent1 = Color3.fromRGB(255, 255, 255),
	Accent2 = Color3.fromRGB(0, 0, 0),
	Background = Color3.fromRGB(16, 16, 16),
	SectionBg = Color3.fromRGB(10, 10, 10),
}
U.theme.ElementBorder = U.theme.ElementBorder or U.theme.SectionBorder
U.THEME_KEYS = {
	ThemeText = "Text", ThemeBorder = "Border", ThemeSectionBorder = "SectionBorder", ThemeElementBorder = "ElementBorder",
	ThemeBackground = "Background", ThemeSectionBg = "SectionBg", ThemeAccent1 = "Accent1", ThemeAccent2 = "Accent2",
}

function U.newReg()
	return { accents = {}, borders = {}, sectionBorders = {}, elementBorders = {}, sectionBgs = {}, bodyBgs = {}, tabAccents = {}, labels = {} }
end
U.themeReg = U.themeReg or U.newReg()
U.themeReg.labels = U.themeReg.labels or {}
U.vflags = U.vflags or {}
if U.vflags.Tooltips == nil then U.vflags.Tooltips = true end
if U.vflags.NotificationPosition == nil then U.vflags.NotificationPosition = "center" end
U.setters = U.setters or {}
U.flagListeners = U.flagListeners or {}
U.pulseReg = U.pulseReg or {}
U.activeNotifs = U.activeNotifs or {}
U.keybindListEntries = U.keybindListEntries or {}
U.keybindTargets = U.keybindTargets or {}
U._kbListen = U._kbListen or {}
U.wmDocked, U.kbDocked = true, true
U.running = true

U.ELEMENT_BORDER = 1
U.TEXT_SZ = 12
U.LINE_H = 2 
U.PAD = 6 
U.dockGap = 6
U.BODY_W, U.BODY_H, U.TITLE_H, U.SEC_GAP = 400, 520, 28, 8
U.BOTTOM_BAR_H = 18
U.bottomBarOn = false
U.bottomBarText = ""
U.MIN_W, U.MIN_H = 320, 400
U.TAB_NAMES = { "main", "config" }
U.GRAY_TEXT = Color3.fromRGB(90, 90, 90)
U.OFF = Color3.fromRGB(55, 55, 55)

function U.new(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end

function U.label(parent, text, props)
	local l = U.new("TextLabel", {
		BackgroundTransparency = 1, FontFace = U.font, TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left, Text = text,
	})
	for k, v in pairs(props or {}) do l[k] = v end
	l.Parent = parent
	return l
end

function U.stroke(parent, kind, noReg)
	local s = U.new("UIStroke", { Thickness = 2, Color = U.theme[kind], LineJoinMode = Enum.LineJoinMode.Miter }, parent)
	if not noReg then
		local reg = U.themeReg[kind == "Border" and "borders" or "sectionBorders"]
		reg[#reg + 1] = s
	end
	return s
end

function U.edges(parent, thick, outward, z, noTop)
	thick = math.max(1, math.floor(tonumber(thick) or 1))
	local o = outward and thick or 0
	local function edge(name, size, pos)
		local e = U.new("Frame", {
			Name = name, BorderSizePixel = 0, BackgroundColor3 = U.theme.ElementBorder, Size = size, Position = pos, ZIndex = z or (parent.ZIndex + 2),
		}, parent)
		U.themeReg.elementBorders[#U.themeReg.elementBorders + 1] = e
	end
	if not noTop then edge("BTop", UDim2.new(1, o * 2, 0, thick), UDim2.fromOffset(-o, -o)) end
	edge("BBottom", UDim2.new(1, o * 2, 0, thick), outward and UDim2.new(0, -o, 1, 0) or UDim2.new(0, 0, 1, -thick))
	-- extend left/right through corners when outward so no missing pixels
	if outward then
		edge("BLeft", UDim2.new(0, thick, 1, o * 2), UDim2.fromOffset(-o, -o))
		edge("BRight", UDim2.new(0, thick, 1, o * 2), UDim2.new(1, 0, 0, -o))
	else
		edge("BLeft", UDim2.new(0, thick, 1, 0), UDim2.fromOffset(0, 0))
		edge("BRight", UDim2.new(0, thick, 1, 0), UDim2.new(1, -thick, 0, 0))
	end
end

function U.controlStroke(parent, thick)
	parent.ClipsDescendants = false
	U.edges(parent, thick or U.ELEMENT_BORDER, true)
end

function U.track(c)
	U._conns = U._conns or {}
	U._conns[#U._conns + 1] = c
	return c
end

function U.guiParent()
	if typeof(gethui) == "function" then
		local ok, g = pcall(gethui)
		if ok and g then return g end
	end
	return U.lp:WaitForChild("PlayerGui")
end

function U.loadFont()
	local ok, font = pcall(function()
		local id, fontFile = "ProggyClean.ttf", "ProggyClean_ExampleUI.font"
		if not isfile(id) then
			writefile(id, game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf"))
		end
		if isfile(fontFile) then delfile(fontFile) end
		writefile(fontFile, U.Http:JSONEncode({
			name = "ProggyClean_ExampleUI",
			faces = { { name = "Normal", weight = 400, style = "Normal", assetId = getcustomasset(id) } },
		}))
		return Font.new(getcustomasset(fontFile), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end)
	return (ok and font) or Font.fromEnum(Enum.Font.Code)
end
U.font = U.loadFont()

function U.textW(lbl)
	local text = typeof(lbl) == "Instance" and lbl.Text or tostring(lbl or "")
	local w = 0
	if typeof(lbl) == "Instance" and lbl.TextBounds and lbl.TextBounds.X > 0 then
		w = lbl.TextBounds.X
	end
	if text ~= "" then
		local ok, b = pcall(function()
			local p = Instance.new("GetTextBoundsParams")
			p.Text, p.Font, p.Size, p.Width = text, U.font, U.TEXT_SZ, 1e4
			return U.Text:GetTextBoundsAsync(p).X
		end)
		if ok and b and b > w then w = b end
	end
	if w <= 0 and text ~= "" then w = #text * 7 end
	return math.max(1, math.ceil(w))
end

function U.ensureTooltip()
	if U.tooltipGui and U.tooltipGui.Parent and U.tooltipFrame and U.tooltipFrame.Parent then return end
	U.tooltipGui = U.new("ScreenGui", {
		Name = "wavelength_tooltip", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 200, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, U.guiParent())
	local f = U.new("Frame", { Name = "Tooltip", BackgroundColor3 = U.theme.Background, BorderSizePixel = 0, Visible = false, ZIndex = 250 }, U.tooltipGui)
	U.controlStroke(f)
	table.insert(U.themeReg.bodyBgs, f)
	U.tooltipLabel = U.label(f, "", { Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -12, 1, -4), TextYAlignment = Enum.TextYAlignment.Center })
	U.tooltipFrame = f
end

function U.hideTooltip()
	if U.tooltipFrame then U.tooltipFrame.Visible = false end
end

function U.updateTooltipPos()
	if U.tooltipFrame and U.tooltipFrame.Visible then
		local p = U.UIS:GetMouseLocation()
		U.tooltipFrame.Position = UDim2.fromOffset(p.X + 14, p.Y + 16)
	end
end

function U.showTooltip(text)
	if U.vflags.Tooltips == false or type(text) ~= "string" or text == "" then return U.hideTooltip() end
	U.ensureTooltip()
	local f, l = U.tooltipFrame, U.tooltipLabel
	l.Text, l.TextColor3, f.BackgroundColor3 = text, U.theme.Text, U.theme.Background
	f.Visible = true
	f.Size = UDim2.fromOffset(U.textW(l) + 12, 20)
	U.updateTooltipPos()
end

function U.bindTooltip(obj, text)
	if typeof(obj) ~= "Instance" or type(text) ~= "string" or text == "" then return end
	obj.MouseEnter:Connect(function() U.showTooltip(text) end)
	obj.MouseLeave:Connect(U.hideTooltip)
end

function U.onFlag(name, fn)
	U.flagListeners[name] = U.flagListeners[name] or {}
	table.insert(U.flagListeners[name], fn)
end

function U.fireFlag(name)
	for _, fn in ipairs(U.flagListeners[name] or {}) do pcall(fn) end
end

function U.setFlag(name, val)
	U.vflags[name] = val
	U.fireFlag(name)
end

function U.accentSequence()
	local a, b = U.theme.Accent1, U.theme.Accent2
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.25, a:Lerp(b, 0.5)), ColorSequenceKeypoint.new(0.5, b),
		ColorSequenceKeypoint.new(0.75, b:Lerp(a, 0.5)), ColorSequenceKeypoint.new(1, a),
	})
end

function U.pulseColor()
	local t = (tick() * 0.12) % 1
	return U.theme.Accent1:Lerp(U.theme.Accent2, 0.5 + 0.5 * math.sin(t * math.pi * 2))
end

function U.registerPulse(inst, isActive)
	U.pulseReg[#U.pulseReg + 1] = { inst = inst, active = isActive }
end

task.spawn(function()
	while alive() do
		local c, off = U.pulseColor(), Vector2.new((tick() * 0.35 % 2) - 1, 0)
		for i = #U.pulseReg, 1, -1 do
			local e = U.pulseReg[i]
			if not e.inst or not e.inst.Parent then table.remove(U.pulseReg, i) elseif e.active() then e.inst.BackgroundColor3 = c end
		end
		for _, key in ipairs({ "accents", "tabAccents" }) do
			local reg = U.themeReg[key]
			for i = #reg, 1, -1 do
				local g = reg[i]
				if not g.Parent then table.remove(reg, i)
				elseif key == "accents" then g.Offset = off
				else g.BackgroundColor3 = c end
			end
		end
		task.wait(0.03)
	end
end)

function U.bindTooltipFollow()
	if U._tipFollow then pcall(function() U._tipFollow:Disconnect() end) end
	U._tipFollow = U.UIS.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
			and U.tooltipFrame and U.tooltipFrame.Visible then
			U.updateTooltipPos()
		end
	end)
	U.track(U._tipFollow)
end
U.bindTooltipFollow()

U.cycle = U.cycle or { hue = 0, colorFlags = {}, step = 0.01 }

function U.setCycleColor(flagKey, on)
	if on then
		U.cycle.colorFlags[flagKey] = true
		local cur, s, v = U.vflags[flagKey], 1, 1
		if typeof(cur) == "Color3" then
			local _
			_, s, v = cur:ToHSV()
			if s < 0.05 then s = 1 end
			if v < 0.05 then v = 1 end
		end
		local nc = Color3.fromHSV(U.cycle.hue, s, v)
		U.vflags[flagKey] = nc
		if U.setters[flagKey] then U.setters[flagKey](nc) end
	else
		U.cycle.colorFlags[flagKey] = nil
	end
	U.vflags[flagKey .. "CycleColor"] = on and true or false
end

task.spawn(function()
	local c = U.cycle
	while alive() do
		if next(c.colorFlags) ~= nil then
			c.hue = (c.hue + c.step) % 1
			local needTheme = false
			for flagKey in pairs(c.colorFlags) do
				local cur, s, v = U.vflags[flagKey], 1, 1
				if typeof(cur) == "Color3" then
					local _
					_, s, v = cur:ToHSV()
					if s < 0.05 then s = 1 end
					if v < 0.05 then v = 1 end
				end
				local nc = Color3.fromHSV(c.hue, s, v)
				U.vflags[flagKey] = nc
				if U.setters[flagKey] then U.setters[flagKey](nc) end
				local tk = U.THEME_KEYS[flagKey]
				if tk then U.theme[tk] = nc needTheme = true end
			end
			if needTheme then U.applyTheme() end
		end
		task.wait(0.03)
	end
end)

function U.applyTheme()
	local R, T = U.themeReg, U.theme
	for _, g in ipairs(R.accents) do if g.Parent then g.Color = U.accentSequence() end end
	for _, s in ipairs(R.borders) do if s.Parent then s.Color = T.Border end end
	for _, s in ipairs(R.sectionBorders) do if s.Parent then s.Color = T.SectionBorder end end
	for _, s in ipairs(R.elementBorders) do if s.Parent then s.BackgroundColor3 = T.ElementBorder end end
	for _, f in ipairs(R.bodyBgs) do if f.Parent then f.BackgroundColor3 = T.Background end end
	for _, f in ipairs(R.sectionBgs) do if f.Parent then f.BackgroundColor3 = T.SectionBg end end
	if U.wm and U.wm.Parent then U.wm.BackgroundColor3 = T.Background end
	if U.kbPanel and U.kbPanel.Parent then U.kbPanel.BackgroundColor3 = T.Background end
	for _, l in ipairs(R.labels or {}) do
		if l and l.Parent then l.TextColor3 = T.Text end
	end
	U.refreshMenuTextColors()
	U.refreshKeybindList()
end

function U.refreshMenuTextColors()
	local c, gray = U.theme.Text, U.GRAY_TEXT
	if U.kbPanel then
		for _, i in ipairs(U.kbPanel:GetDescendants()) do
			if i:IsA("TextLabel") then i.TextColor3 = (i:GetAttribute("KbActive") == false) and gray or c end
		end
	end
	if U.gui then
		for _, i in ipairs(U.gui:GetDescendants()) do
			if i.Name == "WavelengthCredit" or i:GetAttribute("FixedGray") == true then
				i.TextColor3 = gray
			elseif not (U.kbPanel and i:IsDescendantOf(U.kbPanel)) and (i:IsA("TextLabel") or i:IsA("TextButton") or i:IsA("TextBox")) then
				i.TextColor3 = c
			end
		end
	end
end

function U.mkPanel(parent, name, z, noReg)
	local f = U.new("Frame", { Name = name, BackgroundColor3 = U.theme.Background, BorderSizePixel = 0, ZIndex = z }, parent)
	local st = U.stroke(f, "Border", noReg)
	local bar = U.new("Frame", { Size = UDim2.new(1, 0, 0, U.LINE_H), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = z + 1 }, f)
	local g = U.new("UIGradient", { Color = U.accentSequence() }, bar)
	table.insert(U.themeReg.accents, g)
	return f, st, bar
end

function U.panelSize(textW, rows)
	local rowH, gap = U.TEXT_SZ, 2
	return UDim2.fromOffset(textW + U.PAD * 2, U.LINE_H + U.PAD * 2 + rows * rowH + (rows - 1) * gap)
end

function U.notifAnchor(pos)
	pos = string.lower(tostring(pos or ""))
	if pos == "top left" then return Vector2.new(0, 0), UDim2.fromOffset(14, 14), 1
	elseif pos == "top right" then return Vector2.new(1, 0), UDim2.new(1, -14, 0, 14), 1
	elseif pos == "bottom left" then return Vector2.new(0, 1), UDim2.new(0, 14, 1, -14), -1
	elseif pos == "center" then return Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.72, 0), 1 end
	return Vector2.new(1, 1), UDim2.new(1, -14, 1, -14), -1
end

function U.layoutNotifs()
	local pos = U.vflags.NotificationPosition or "center"
	local anchor, base, dir = U.notifAnchor(pos)
	local center, gap, total = string.lower(tostring(pos)) == "center", 6, 0
	for _, e in ipairs(U.activeNotifs) do total += e.h + gap end
	local y = 0
	for _, e in ipairs(U.activeNotifs) do
		if e.frame.Parent then
			e.frame.AnchorPoint = anchor
			e.frame.Position = center and UDim2.new(0.5, 0, 0.72, y - total / 2) or UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + y * dir)
			y += e.h + gap
		end
	end
end

function U.pushNotification(opts)
	opts = opts or {}
	local text = tostring(opts.text or opts.Text or "")
	local dur = opts.time or opts.Time or opts.duration or opts.Duration or 3
	local nGui = U.new("ScreenGui", { Name = "wavelength_notif", IgnoreGuiInset = true, ResetOnSpawn = false }, U.guiParent())
	local frame, st, bar = U.mkPanel(nGui, "Notif", 1, true)
	local tw = U.textW(text)
	if tw < 8 then tw = math.max(8, #text * 7) end
	local label = U.label(frame, text, {
		Position = UDim2.fromOffset(U.PAD, U.LINE_H + U.PAD),
		Size = UDim2.fromOffset(tw, U.TEXT_SZ),
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.None,
	})
	frame.Size = UDim2.fromOffset(tw + U.PAD * 2, U.LINE_H + U.PAD * 2 + U.TEXT_SZ)

	local parts = { { frame, "BackgroundTransparency" }, { st, "Transparency" }, { bar, "BackgroundTransparency" }, { label, "TextTransparency" } }
	local function fade(info, to)
		local first
		for _, p in ipairs(parts) do
			local t = U.Tween:Create(p[1], info, { [p[2]] = to })
			first = first or t
			t:Play()
		end
		return first
	end
	for _, p in ipairs(parts) do p[1][p[2]] = 1 end

	local entry = { frame = frame, gui = nGui, h = frame.Size.Y.Offset }
	table.insert(U.activeNotifs, entry)
	U.layoutNotifs()
	fade(TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 0)

	task.delay(dur, function()
		fade(TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 1).Completed:Wait()
		local i = table.find(U.activeNotifs, entry)
		if i then table.remove(U.activeNotifs, i) end
		if nGui.Parent then nGui:Destroy() end
		U.layoutNotifs()
	end)
end

function U.closeColorPicker()
	if U.openColorPicker and U.openColorPicker.Parent then U.openColorPicker:Destroy() end
	U.openColorPicker = nil
end

function U.closeDropdown()
	local d, box = U.openDropdown, U.openDropdownBox
	U.openDropdown, U.openDropdownBox = nil, nil
	local function restore()
		local bb = box and box:FindFirstChild("BBottom")
		if bb then bb.Visible = true end
	end
	if not d or not d.Parent then return restore() end
	local w = d.AbsoluteSize.X
	if w < 1 then w = d.Size.X.Offset end
	if w < 1 then w = 100 end
	local tw = U.Tween:Create(d, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.fromOffset(w, 0) })
	tw:Play()
	tw.Completed:Connect(function()
		pcall(function() d:Destroy() end)
		restore()
	end)
end

function U.closeSettings()
	if U.openSettings and U.openSettings.Parent then U.openSettings:Destroy() end
	U.openSettings = nil
end

function U.closePopups()
	U.closeColorPicker()
	U.closeDropdown()
	U.closeSettings()
end

function U.shutdown()
	if U._shuttingDown then return end
	U._shuttingDown, U.running = true, false
	for _, k in ipairs({
		"VisualsEnabled", "NoRecoil", "NoSpread", "LeftArmEnabled", "RightArmEnabled", "LeftGloveEnabled", "RightGloveEnabled", "HideGloveSurfaces",
		"RemoveSniperScope", "LightingAmbientEnabled", "LightingOutdoorAmbientEnabled", "LightingGlobalShadows", "LightingPrioritizeQuality", "Watermark",
	}) do
		U.vflags[k] = false
	end
	pcall(U.closePopups)
	for _, c in ipairs(U._conns or {}) do pcall(function() c:Disconnect() end) end
	U._conns = {}
	for _, k in ipairs({ "tooltipGui", "gui", "notifGui" }) do
		if U[k] then pcall(function() U[k]:Destroy() end) U[k] = nil end
	end
	U.tooltipFrame, U.wm, U.kbPanel = nil, nil, nil
	U.keybindListEntries, U._kbListen, U.keybindTargets = {}, {}, {}
	pcall(function()
		local kill = { wavelength = true, wavelength_wm = true, SM_ESP = true, wavelength_notifs = true }
		for _, g in ipairs(U.guiParent():GetChildren()) do
			if kill[g.Name] then g:Destroy() end
		end
	end)
end

function U.armPopupOpen() U.suppressPopupClose = tick() + 0.25 end

function U.objsAtMouse()
	local p = U.UIS:GetMouseLocation()
	local ok, objs = pcall(function() return U.gui:GetGuiObjectsAtPosition(p.X, p.Y) end)
	return ok and objs or {}
end

function U.clickHits(anc)
	if not anc or not anc.Parent then return false end
	for _, o in ipairs(U.objsAtMouse()) do
		if o == anc or o:IsDescendantOf(anc) then return true end
	end
	return false
end

function U.clickHitsNamed(...)
	local names = { ... }
	for _, o in ipairs(U.objsAtMouse()) do
		if table.find(names, o.Name) then return true end
	end
	return false
end

function U.row(parent, order)
	return U.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = order or 0 }, parent)
end

function U.indentRow(r, px)
	local pad = r:FindFirstChildOfClass("UIPadding") or U.new("UIPadding", {}, r)
	pad.PaddingLeft = UDim.new(0, px or 12)
	return r
end

U.subGroups = U.subGroups or {}
U.toggleRows = U.toggleRows or {}
U.subBusy = U.subBusy or {}
U.subPending = U.subPending or {}

function U.hasSubItems(flag)
	local g = U.subGroups[flag]
	return g and g.children and #g.children > 0
end

function U.beginSubAnim(flag)
	if not flag then return end
	U.subBusy[flag] = true
	U.subPending[flag] = (U.subPending[flag] or 0) + 1
end

function U.endSubAnim(flag)
	if not flag then return end
	local n = (U.subPending[flag] or 1) - 1
	if n <= 0 then
		U.subPending[flag] = 0
		U.subBusy[flag] = false
	else
		U.subPending[flag] = n
	end
end

function U.isGuiShown(inst)
	while inst do
		if inst:IsA("GuiObject") and inst.Visible == false then return false end
		inst = inst.Parent
	end
	return true
end

function U.updateSubLine(flag)
	local g = U.subGroups[flag]
	if not g or not g.line or not g.parentRow or not g.parentRow.Parent then return end
	local line = g.line
	local host = g.host or g.line.Parent
	if not host then return end
	-- hide when parent toggle / tab content is not visible (multi-tab sections)
	if not U.isGuiShown(g.parentRow) then
		line.Visible = false
		return
	end
	local kids = {}
	for _, c in ipairs(g.children) do
		if c.Parent and c.Visible and c.AbsoluteSize.Y > 0.5 and U.isGuiShown(c) then kids[#kids + 1] = c end
	end
	if #kids == 0 then
		line.Visible = false
		return
	end
	local last = kids[#kids]
	local origin = host.AbsolutePosition
	local y0 = g.parentRow.AbsolutePosition.Y + g.parentRow.AbsoluteSize.Y - origin.Y
	local y1 = last.AbsolutePosition.Y + last.AbsoluteSize.Y - origin.Y
	local x = g.parentRow.AbsolutePosition.X - origin.X + 5
	line.Position = UDim2.fromOffset(x, y0)
	line.Size = UDim2.fromOffset(1, math.max(0, y1 - y0))
	line.Visible = y1 > y0
	line.BackgroundColor3 = U.pulseColor()
end

function U.updateAllSubLines()
	for flag in pairs(U.subGroups or {}) do
		U.updateSubLine(flag)
	end
end

function U.ensureSubGroup(flag, parentRow)
	local g = U.subGroups[flag]
	if g then
		if parentRow then g.parentRow = parentRow end
		return g
	end
	g = { parentRow = parentRow, children = {}, line = nil }
	U.subGroups[flag] = g
	if parentRow and parentRow.Parent then
		-- MUST NOT parent under UIListLayout (would push rows down). Prefer Pages frame.
		local host = parentRow.Parent
		local climb = host
		while climb do
			if climb.Name == "Pages" then
				host = climb
				break
			end
			climb = climb.Parent
		end
		local line = U.new("Frame", {
			Name = "SubLine", BorderSizePixel = 0, BackgroundColor3 = U.pulseColor(),
			Size = UDim2.fromOffset(1, 0), Position = UDim2.fromOffset(6, 0), ZIndex = 8, Visible = false,
		}, host)
		U.registerPulse(line, function()
			local gg = U.subGroups[flag]
			return gg and gg.line and gg.line.Visible
		end)
		g.line = line
		g.host = host
		U.track(parentRow:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			U.updateSubLine(flag)
		end))
		U.track(parentRow:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			U.updateSubLine(flag)
		end))
		-- scroll moves AbsolutePosition of rows
		local scroll = parentRow.Parent
		if scroll and scroll:IsA("ScrollingFrame") then
			U.track(scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
				U.updateSubLine(flag)
			end))
		end
	end
	return g
end

function U.subFullHeight(control)
	local h = control:GetAttribute("FullHeight")
	if typeof(h) == "number" and h > 0 then return h end
	h = control.Size.Y.Offset
	if h < 2 then h = control.AbsoluteSize.Y end
	if h < 2 then h = 16 end
	control:SetAttribute("FullHeight", h)
	return h
end

-- Wrap a control so height animation clips/reveals without squashing children.
function U.ensureSubWrap(control)
	if control:GetAttribute("SubWrapped") then
		return control.Parent or control
	end
	local parent = control.Parent
	if not parent then return control end
	local fullH = U.subFullHeight(control)
	local order = control.LayoutOrder
	local wrap = U.new("Frame", {
		Name = "SubWrap",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		Size = UDim2.new(1, 0, 0, fullH),
		LayoutOrder = order,
	}, parent)
	control.Parent = wrap
	control.LayoutOrder = 0
	control.Size = UDim2.new(1, 0, 0, fullH)
	control.Position = UDim2.fromOffset(0, 0)
	control:SetAttribute("SubWrapped", true)
	control:SetAttribute("FullHeight", fullH)
	wrap:SetAttribute("FullHeight", fullH)
	return wrap
end

function U.cacheSubFade(control)
	if control:GetAttribute("FadeCached") then return end
	local list = {}
	local function add(obj, prop)
		if not obj then return end
		list[#list + 1] = { obj = obj, prop = prop, goal = obj[prop] }
	end
	add(control, "BackgroundTransparency")
	for _, d in ipairs(control:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			add(d, "TextTransparency")
			add(d, "BackgroundTransparency")
		elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
			add(d, "ImageTransparency")
			add(d, "BackgroundTransparency")
		elseif d:IsA("Frame") then
			add(d, "BackgroundTransparency")
		elseif d:IsA("UIStroke") then
			add(d, "Transparency")
		end
	end
	U._subFade = U._subFade or {}
	U._subFade[control] = list
	control:SetAttribute("FadeCached", true)
end

function U.subFadeTargets(control)
	U.cacheSubFade(control)
	return (U._subFade and U._subFade[control]) or {}
end

function U.setFadeTargets(targets, value)
	for _, t in ipairs(targets) do
		pcall(function() t.obj[t.prop] = value end)
	end
end

function U.tweenFadeTargets(targets, toHidden, duration)
	local info = TweenInfo.new(duration or 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local last
	for _, t in ipairs(targets) do
		local goal = toHidden and 1 or t.goal
		local ok, tw = pcall(function()
			return U.Tween:Create(t.obj, info, { [t.prop] = goal })
		end)
		if ok and tw then
			tw:Play()
			last = tw
		end
	end
	return last
end

function U.animateSub(control, show)
	local wrap = U.ensureSubWrap(control)
	local fullH = wrap:GetAttribute("FullHeight") or U.subFullHeight(control)
	local parentFlag = control:GetAttribute("ParentFlag")
	local targets = U.subFadeTargets(control)

	U.beginSubAnim(parentFlag)
	if show then
		wrap.Visible = true
		control.Visible = true
		wrap.Size = UDim2.new(1, 0, 0, fullH)
		control.Size = UDim2.new(1, 0, 0, fullH)
		control.Position = UDim2.fromOffset(0, 0)
		for _, t in ipairs(targets) do
			pcall(function() t.obj[t.prop] = t.goal end)
		end
	else
		U.setFadeTargets(targets, 1)
		control.Visible = false
		wrap.Size = UDim2.new(1, 0, 0, 0)
		wrap.Visible = false
	end
	if parentFlag then U.updateSubLine(parentFlag) end
	U.endSubAnim(parentFlag)
	task.defer(U.updateAllSubLines)
end

function U.subIf(control, keys, pred)
	U.indentRow(control, 12)
	local fullH = control.Size.Y.Offset
	if fullH < 2 then fullH = 16 end
	control:SetAttribute("FullHeight", fullH)
	-- capture visible fade goals once, before first hide
	U.cacheSubFade(control)
	local wrap = U.ensureSubWrap(control)
	local parentFlag = keys and keys[1]
	if parentFlag then
		control:SetAttribute("ParentFlag", parentFlag)
		wrap:SetAttribute("ParentFlag", parentFlag)
		local g = U.ensureSubGroup(parentFlag, U.toggleRows[parentFlag])
		g.children[#g.children + 1] = wrap
	end
	local function isOpen()
		return wrap.Visible and wrap.Size.Y.Offset > 1
	end
	local function sync()
		local vis = pred() and true or false
		if vis and not isOpen() then
			U.animateSub(control, true)
			if U.closeDropdown then U.closeDropdown() end
			if U.closeColorPicker then U.closeColorPicker() end
		elseif not vis and (wrap.Visible or isOpen() or wrap.Size.Y.Offset > 0) then
			U.animateSub(control, false)
			if U.closeDropdown then U.closeDropdown() end
			if U.closeColorPicker then U.closeColorPicker() end
		end
		if parentFlag then
			task.defer(function() U.updateSubLine(parentFlag) end)
		end
	end
	for _, k in ipairs(keys) do U.onFlag(k, sync) end
	local vis = pred() and true or false
	control.Size = UDim2.new(1, 0, 0, fullH)
	control.Position = UDim2.fromOffset(0, 0)
	if vis then
		wrap.Visible = true
		control.Visible = true
		wrap.Size = UDim2.new(1, 0, 0, fullH)
		U.setFadeTargets(U.subFadeTargets(control), 0)
	else
		wrap.Visible = false
		control.Visible = false
		wrap.Size = UDim2.new(1, 0, 0, 0)
		U.setFadeTargets(U.subFadeTargets(control), 1)
	end
	return control
end

function U.subOf(control, parentFlag)
	return U.subIf(control, { parentFlag }, function() return U.vflags[parentFlag] == true end)
end

function U.secGeom(col, row, rows)
	local gap = U.SEC_GAP
	local topPad = 7 -- only section-tab overhang; no extra gap under title
	local bottomPad = gap
	local w = math.floor((U.BODY_W - gap * 3) / 2)
	local x = (col == 1) and gap or (gap * 2 + w)
	rows = math.max(1, math.floor(tonumber(rows) or 1))
	row = math.clamp(math.floor(tonumber(row) or 1), 1, rows)
	local usable = U.BODY_H - topPad - bottomPad - gap * (rows - 1)
	local h = math.floor(usable / rows)
	local y = topPad + (row - 1) * (h + gap)
	if row == rows then
		h = math.max(1, U.BODY_H - bottomPad - y)
	end
	return x, y, w, h
end

function U.updateConfigListHeight()
	local box = U.configListBox
	local scroll = U.configListScroll
	if not box or not box.Parent or not scroll then return end
	local viewH = scroll.AbsoluteSize.Y
	if viewH < 2 then return end
	local layout = scroll:FindFirstChildOfClass("UIListLayout")
	local gap = layout and layout.Padding.Offset or 4
	local used = 0
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("GuiObject") and ch ~= box and ch.Visible then
			used += ch.AbsoluteSize.Y + gap
		end
	end
	local pad = scroll:FindFirstChildOfClass("UIPadding")
	if pad then
		used += (pad.PaddingTop.Offset or 0) + (pad.PaddingBottom.Offset or 0)
	end
	-- sit flush at bottom of section content with a small edge gap
	local h = math.max(60, math.floor(viewH - used - 2))
	if math.abs((box.Size.Y.Offset or 0) - h) > 0 then
		box.Size = UDim2.new(1, 0, 0, h)
	end
end

function U.relayoutColumn(page, side)
	if not page then return end
	side = side or 1
	local frames = {}
	for _, ch in ipairs(page:GetChildren()) do
		if ch:IsA("Frame") and ch:GetAttribute("SectionCol") == side then
			frames[#frames + 1] = ch
		end
	end
	table.sort(frames, function(a, b)
		return (a:GetAttribute("SectionRow") or 0) < (b:GetAttribute("SectionRow") or 0)
	end)
	local n = #frames
	for i, ch in ipairs(frames) do
		local x, y, w, h = U.secGeom(side, i, n)
		ch.Size = UDim2.fromOffset(w, h)
		ch.Position = UDim2.fromOffset(x, y)
		ch:SetAttribute("SectionRow", i)
	end
	for _, sec in ipairs(U.sectionObjs or {}) do
		if sec._frame and sec._frame.Parent == page and sec.layoutTabs then
			sec.layoutTabs()
		end
	end
	task.defer(function()
		for flag in pairs(U.subGroups or {}) do
			U.updateSubLine(flag)
		end
		for _, fn in ipairs(U.sliderLayouts or {}) do
			pcall(fn)
		end
	end)
end

function U.section(parent, col, row, rows)
	local function lname(o, default)
		if type(o) == "table" then return string.lower(tostring(o.Name or default)) end
		return string.lower(tostring(default))
	end
	local function tip(o)
		return o and (o.Tooltip or o.tooltip) or nil
	end
	local function keybindOf(o, name)
		if not o or o.Keybind ~= true then return nil end
		return { key = o.Key or o.KeyCode, text = o.KeybindText or o.ListText or o.Text or name }
	end

	local x, y, w, h = U.secGeom(col, row or 1, rows or 1)
	local f = U.new("Frame", { BackgroundColor3 = U.theme.SectionBg, BorderSizePixel = 0, Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y) }, parent)
	f:SetAttribute("SectionCol", col or 1)
	f:SetAttribute("SectionRow", row or 1)
	table.insert(U.themeReg.sectionBgs, f)
	U.stroke(f, "SectionBorder")

	local header = U.new("Frame", {
		Name = "SectionTabs", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 14), Position = UDim2.fromOffset(0, -7), ZIndex = 5,
	}, f)

	local pages = U.new("Frame", {
		Name = "Pages", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, -10, 1, -12), Position = UDim2.fromOffset(5, 8), ClipsDescendants = true,
	}, f)

	local sec = {
		_frame = f,
		_header = header,
		_pages = pages,
		_tabs = {},
		_buttons = {},
		_current = nil,
		_w = w,
	}
	U.sectionObjs = U.sectionObjs or {}
	U.sectionObjs[#U.sectionObjs + 1] = sec

	local function paintTabs()
		for name, btn in pairs(sec._buttons) do
			local selected = sec._current == name
			btn.TextColor3 = selected and U.theme.Text or U.GRAY_TEXT
			btn:SetAttribute("FixedGray", not selected)
		end
	end

	local function layoutTabs()
		local n = #sec._tabs
		if n == 0 then return end
		for _, ch in ipairs(header:GetChildren()) do ch:Destroy() end
		sec._buttons = {}
		local gap = 6
		local totalGap = gap * (n + 1)
		local sw = sec._frame.Size.X.Offset
		if sw < 2 then sw = sec._frame.AbsoluteSize.X end
		if sw < 2 then sw = w end
		local btnW = math.floor((sw - totalGap) / n)
		for i, t in ipairs(sec._tabs) do
			local bx = gap + (i - 1) * (btnW + gap)
			local selected = sec._current == t.name
			local btn = U.new("TextButton", {
				Name = "SectionTab",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromOffset(btnW, 14),
				Position = UDim2.fromOffset(bx, 0),
				FontFace = U.font,
				TextSize = U.TEXT_SZ,
				TextColor3 = selected and U.theme.Text or U.GRAY_TEXT,
				Text = t.name,
				ZIndex = 6,
			}, header)
			btn:SetAttribute("FixedGray", not selected)
			sec._buttons[t.name] = btn
			if n > 1 then
				local tabName = t.name
				btn.MouseButton1Click:Connect(function()
					sec:SelectTab(tabName)
				end)
			end
		end
	end
	sec.layoutTabs = layoutTabs

	function sec:SelectTab(name)
		if sec._current == name then return end
		sec._current = name
		for _, t in ipairs(sec._tabs) do
			t.content.Visible = t.name == name
		end
		paintTabs()
		if U.closeDropdown then U.closeDropdown() end
		if U.closeColorPicker then U.closeColorPicker() end
		task.defer(U.updateAllSubLines)
	end

	function sec:AddTab(name)
		name = string.lower(tostring(name or ("tab" .. (#sec._tabs + 1))))
		if #sec._tabs >= 3 then
			return sec._tabs[#sec._tabs].api
		end
		for _, t in ipairs(sec._tabs) do
			if t.name == name then return t.api end
		end

		local content = U.new("ScrollingFrame", {
			Name = name,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ClipsDescendants = true,
			Visible = #sec._tabs == 0,
		}, pages)
		local listLayout = U.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, content)
		U.new("UIPadding", { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, content)
		content:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if U.closeDropdown then U.closeDropdown() end
			if U.closeColorPicker then U.closeColorPicker() end
		end)
		-- reflow section heights when items change
		listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			local pg = content.Parent and content.Parent.Parent
			if pg and U.layoutPage then
				task.defer(function() U.layoutPage(pg, false) end)
			end
		end)

		local api = { _content = content, _n = 0, Section = sec }
		local function nextOrder()
			api._n += 1
			return api._n
		end
		local function slider(o, parentFlag)
			o = o or {}
			local c = U.mkSlider(content, lname(o, "slider"), o.Flag or o.Name, o.Min or 0, o.Max or 100, o.Default or 0, nextOrder(), o.Increment or 1, o.Suffix or "", o.InfAtMax == true or o.InfAt == true, tip(o))
			return parentFlag and U.subOf(c, parentFlag) or c
		end
		local function dropdown(o, parentFlag)
			o = o or {}
			local limit = o.Limit
			if limit == nil then limit = o.Amount end
			if limit == nil then limit = 1 end
			local c = U.mkDropdown(content, lname(o, "dropdown"), o.Flag or o.Name, o.Items or {}, o.Default, false, nextOrder(), limit, tip(o))
			return parentFlag and U.subOf(c, parentFlag) or c
		end
		local function toggle(o)
			o = o or {}
			local flag = o.Flag or o.Name
			local row = U.mkToggle(content, lname(o, "toggle"), flag, nextOrder(), o.Default == true, keybindOf(o, lname(o, "toggle")), tip(o))
			if o.Callback then U.onFlag(flag, function() pcall(o.Callback, U.vflags[flag]) end) end
			return row, flag
		end

		function api:AddToggle(o)
			o = o or {}
			local t, flag = toggle(o)
			local obj = { Flag = flag, Row = t, _parent = content }
			function obj:AddColorpicker(co)
				co = co or {}
				U.attachPicker(t, co.Flag or (flag .. "Color"), co.Default or Color3.new(1, 1, 1), co.Transparency == true, co.Name or "color")
				return obj
			end
			function obj:AddToggle(so)
				local child = toggle(so or {})
				U.subOf(child, flag)
				return api
			end
			function obj:AddSlider(so) slider(so or {}, flag) return obj end
			function obj:AddDropdown(so) dropdown(so or {}, flag) return obj end
			function obj:AddPlayerDropdown(so)
				so = so or {}
				so = table.clone(so)
				local c = api:AddPlayerDropdown(so)
				if c and c.Row then U.subOf(c.Row, flag) end
				return obj
			end
			return obj
		end
		function api:AddSlider(o)
			o = o or {}
			return { Row = slider(o), Flag = o.Flag or o.Name }
		end
		function api:AddDoubleSlider(o)
			o = o or {}
			local r = U.mkDoubleSlider(content, lname(o, "range"), o.FlagMin or (o.Flag or "Min"), o.FlagMax or "Max", o.Min or 0, o.Max or 100, o.DefaultMin or o.Min or 0, o.DefaultMax or o.Max or 100, nextOrder(), o.Increment or 1, o.Suffix or "", tip(o), o.InfAtMax == true or o.InfAt == true)
			return { Row = r, FlagMin = o.FlagMin, FlagMax = o.FlagMax }
		end
		function api:AddDropdown(o)
			o = o or {}
			return { Row = dropdown(o), Flag = o.Flag or o.Name }
		end
		function api:AddPlayerDropdown(o)
			o = o or {}
			local limit = o.Limit
			if limit == nil then limit = o.Amount end
			if limit == nil then limit = 1 end
			local flag = o.Flag or o.Name
			local excludeSelf = o.ExcludeSelf == true
			local names = {}
			local function fill()
				for i = #names, 1, -1 do names[i] = nil end
				local selfName = U.lp and U.lp.Name
				for _, plr in ipairs(U.Players:GetPlayers()) do
					if not (excludeSelf and selfName and plr.Name == selfName) then
						names[#names + 1] = plr.Name
					end
				end
				table.sort(names)
			end
			fill()
			local row, _, prune, display = U.mkDropdown(content, lname(o, "players"), flag, names, o.Default, false, nextOrder(), limit, tip(o))
			local function onRoster()
				fill()
				if prune then prune() end
				if display then display() end
				-- keep open list; next open rebuilds from live names. avoid random closes on join/leave.
			end
			U.track(U.Players.PlayerAdded:Connect(onRoster))
			U.track(U.Players.PlayerRemoving:Connect(function()
				task.defer(onRoster)
			end))
			if parentFlag then
				-- not used here; parentFlag only on nested dropdown helper
			end
			return { Row = row, Flag = flag }
		end
		function api:AddButton(o)
			o = o or {}
			local btn = U.mkButton(content, lname(o, "button"), nextOrder(), o.Confirm == true)
			if o.Callback then U.bindButton(btn, o.Callback) end
			U.bindTooltip(btn, tip(o))
			return { Button = btn }
		end
		function api:AddColorpicker(o)
			o = o or {}
			local r = U.row(content, nextOrder())
			U.label(r, lname(o, "color"), { Size = UDim2.new(1, -36, 1, 0) })
			U.attachPicker(r, o.Flag or o.Name, o.Default or Color3.new(1, 1, 1), o.Transparency == true, o.Name or "color")
			return { Row = r, Flag = o.Flag or o.Name }
		end
		function api:AddLabel(o)
			o = o or {}
			local r = U.row(content, nextOrder())
			local lab = U.label(r, lname(o, "label"), { Size = UDim2.fromScale(1, 1) })
			local obj = { Row = r, Label = lab }
			function obj:AddColorpicker(co)
				co = co or {}
				U.attachPicker(r, co.Flag or ((o.Flag or o.Name or "Label") .. "Color"), co.Default or Color3.new(1, 1, 1), co.Transparency == true, co.Name or "color")
				return obj
			end
			return obj
		end
		function api:AddTextbox(o)
			o = o or {}
			local r = U.mkTextbox(content, lname(o, "textbox"), o.Flag or o.Name, o.Placeholder or "", nextOrder())
			U.bindTooltip(r, tip(o))
			return { Row = r, Flag = o.Flag or o.Name }
		end
		function api:AddKeybind(o)
			o = o or {}
			local r = U.mkKeybind(content, lname(o, "keybind"), o.Flag or o.Name, o.Default or Enum.KeyCode.Unknown, nextOrder())
			U.bindTooltip(r, tip(o))
			return { Row = r, Flag = o.Flag or o.Name }
		end

		sec._tabs[#sec._tabs + 1] = { name = name, content = content, api = api }
		if not sec._current then
			sec._current = name
		else
			content.Visible = false
		end
		layoutTabs()
		return api
	end

	return sec
end

function U.parseKeyCode(v)
	if typeof(v) == "EnumItem" then return v end
	if type(v) == "string" then
		local name = v:gsub("%s+", "")
		for _, n in ipairs({ name, name:upper(), name:sub(1, 1):upper() .. name:sub(2):lower() }) do
			local ok, k = pcall(function() return Enum.KeyCode[n] end)
			if ok and typeof(k) == "EnumItem" then return k end
		end
	end
	return Enum.KeyCode.Unknown
end

function U.keyNameOf(k)
	if typeof(k) == "EnumItem" and k ~= Enum.KeyCode.Unknown then return k.Name end
	return type(k) == "string" and k or "none"
end

function U.refreshKeybindList() end 

function U.registerKeybindList(listText, keyFlag, toggleFlag)
	if not listText or listText == "" then return end
	for _, e in ipairs(U.keybindListEntries) do
		if e.keyFlag == keyFlag then
			e.listText, e.toggleFlag = listText, toggleFlag
			return U.refreshKeybindList()
		end
	end
	table.insert(U.keybindListEntries, { listText = listText, keyFlag = keyFlag, toggleFlag = toggleFlag })
	for _, f in ipairs({ keyFlag, toggleFlag }) do
		if not U._kbListen[f] then
			U._kbListen[f] = true
			U.onFlag(f, function() U.refreshKeybindList() end)
		end
	end
	U.refreshKeybindList()
end

function U.attachKeybind(row, toggleFlag, key, listText)
	local kFlag = toggleFlag .. "Key"
	U.keybindTargets[kFlag] = toggleFlag
	U.vflags[kFlag] = U.vflags[kFlag] or U.parseKeyCode(key)

	local kb = U.new("TextButton", {
		Name = "KeybindBox", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0), FontFace = U.font, TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5,
	}, row)
	local listening = false
	local function fit(name)
		kb.Text = "[" .. name .. "]"
		kb.Size = UDim2.fromOffset(math.max(28, #kb.Text * 7 + 6), 14)
	end
	local function show() fit(U.keyNameOf(U.vflags[kFlag])) end
	show()

	U.setters[kFlag] = function(v)
		U.vflags[kFlag] = U.parseKeyCode(v)
		if not listening then show() end
		U.fireFlag(kFlag)
	end
	kb.MouseButton1Click:Connect(function()
		if listening then return end
		listening, U.kbBinding = true, true
		fit("...")
		local conn
		conn = U.UIS.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			conn:Disconnect()
			listening = false
			if input.KeyCode == Enum.KeyCode.Escape then show() else U.setters[kFlag](input.KeyCode) end
			task.defer(function() U.kbBinding = false end)
		end)
	end)
	U.registerKeybindList(listText, kFlag, toggleFlag)
	return kb
end

function U.mkToggle(parent, text, flag, order, default, kb, tooltip)
	local r = U.row(parent, order)
	U.bindTooltip(r, tooltip)
	local on, reserve = default == true, kb and 56 or 0
	if flag then U.vflags[flag] = on end
	local function col() return on and U.pulseColor() or U.OFF end

	local box = U.new("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = col(), BorderSizePixel = 0 }, r)
	U.controlStroke(box)
	U.registerPulse(box, function() return on end)
	U.label(r, text, { Size = UDim2.new(1, -(20 + reserve), 1, 0), Position = UDim2.fromOffset(18, 0) })

	local function set(v)
		if flag and U.hasSubItems(flag) and U.subBusy[flag] then
			return
		end
		on = v == true
		box.BackgroundColor3 = col()
		if flag then U.setFlag(flag, on) end
	end
	U.new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, -reserve, 1, 0), Text = "", ZIndex = 2 }, r).MouseButton1Click:Connect(function()
		if flag and U.hasSubItems(flag) and U.subBusy[flag] then return end
		set(not on)
	end)
	if flag then
		U.setters[flag] = set
		if kb then U.attachKeybind(r, flag, kb.key, kb.text ~= "" and kb.text or text) end
	end
	U.toggleRows[flag] = r
	U.ensureSubGroup(flag, r)
	return r
end

function U.formatSliderVal(val, step, suffix, maxV, infAtMax)
	if infAtMax and val >= maxV then return "inf" end
	step = tonumber(step) or 1
	local s
	if step >= 1 then
		s = tostring(math.floor(val + 1e-6))
	else
		local decimals = #(tostring(step):match("%.(%d+)") or "1")
		if step < 0.1 then decimals = math.max(decimals, 2) end
		local mult = 10 ^ decimals
		s = string.format("%." .. decimals .. "f", math.floor(val * mult + 0.5) / mult)
	end
	return s .. (suffix or "")
end

function U.sliderFrame(parent, text, order, tooltip, vw)
	local r = U.row(parent, order)
	U.bindTooltip(r, tooltip)
	r.Size = UDim2.new(1, 0, 0, 20)
	U.label(r, text, { Size = UDim2.new(1, -(vw + 4), 0, 12) })
	local val = U.label(r, "", { Size = UDim2.fromOffset(vw, 12), Position = UDim2.new(1, -vw, 0, 0), TextXAlignment = Enum.TextXAlignment.Right })
	local track = U.new("Frame", { BackgroundColor3 = U.OFF, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 6), Position = UDim2.fromOffset(0, 14) }, r)
	U.controlStroke(track)
	local fill = U.new("Frame", { BackgroundColor3 = U.pulseColor(), BorderSizePixel = 0, ZIndex = 3 }, track)
	U.registerPulse(fill, function() return true end)
	local function cap(name)
		return nil
	end
	return r, val, track, fill, cap
end

local function relX(track, x) return math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1) end

function U.mkSlider(parent, text, flag, minV, maxV, default, order, step, suffix, infAt, tooltip)
	step = step or 1
	local r, val, track, fill = U.sliderFrame(parent, text, order, tooltip, 52)
	local span = math.max(1e-6, maxV - minV)
	U.vflags[flag] = default

	local function layout(v)
		local t = math.clamp((v - minV) / span, 0, 1)
		fill.Position = UDim2.new(0, 0, 0, 0)
		fill.Size = UDim2.new(t, 0, 1, 0)
	end
	local function set(v)
		v = math.clamp(v, minV, maxV)
		U.vflags[flag] = v
		layout(v)
		val.Text = U.formatSliderVal(v, step, suffix, maxV, infAt)
		U.fireFlag(flag)
	end
	val.Text = U.formatSliderVal(default, step, suffix, maxV, infAt)
	layout(default)
	task.defer(function() layout(U.vflags[flag] or default) end)
	U.sliderLayouts = U.sliderLayouts or {}
	U.sliderLayouts[#U.sliderLayouts + 1] = function() layout(U.vflags[flag] or default) end

	local function fromX(x)
		local v = math.clamp(math.floor((minV + (maxV - minV) * relX(track, x)) / step + 0.5) * step, minV, maxV)
		set(step >= 1 and math.floor(v + 1e-6) or v)
	end
	local dragging = false
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true fromX(i.Position.X) end
	end)
	U.track(U.UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end))
	U.track(U.UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
	end))
	U.setters[flag] = function(v) set(tonumber(v) or default) end
	return r
end

function U.mkDoubleSlider(parent, text, flagMin, flagMax, minV, maxV, defMin, defMax, order, step, suffix, tooltip, infAtMax)
	step, suffix, infAtMax = step or 1, suffix or "", infAtMax == true
	local r, val, track, fill = U.sliderFrame(parent, text, order, tooltip, 88)
	defMin, defMax = defMin or minV, defMax or maxV
	if defMin > defMax then defMin, defMax = defMax, defMin end
	U.vflags[flagMin], U.vflags[flagMax] = defMin, defMax
	local span = math.max(1e-6, maxV - minV)

	local function snap(v)
		if step >= 1 then return math.floor(v / step + 0.5) * step end
		local places = #(tostring(step):match("%.(%d+)") or "1")
		return tonumber(string.format("%." .. places .. "f", math.floor(v / step + 0.5) * step)) or v
	end
	local function refresh()
		local a, b = math.clamp(U.vflags[flagMin] or minV, minV, maxV), math.clamp(U.vflags[flagMax] or maxV, minV, maxV)
		if a > b then a, b = b, a end
		U.vflags[flagMin], U.vflags[flagMax] = a, b
		local t0 = (a - minV) / span
		local t1 = (b - minV) / span
		fill.Position = UDim2.new(t0, 0, 0, 0)
		fill.Size = UDim2.new(math.max(0, t1 - t0), 0, 1, 0)
		val.Text = U.formatSliderVal(a, step, "", maxV, false) .. " - " .. U.formatSliderVal(b, step, suffix, maxV, infAtMax)
	end
	refresh()
	U.sliderLayouts = U.sliderLayouts or {}
	U.sliderLayouts[#U.sliderLayouts + 1] = refresh

	local drag
	local function at(x)
		local v = math.clamp(snap(minV + (maxV - minV) * relX(track, x)), minV, maxV)
		local a, b = U.vflags[flagMin], U.vflags[flagMax]
		if drag == "min" or (not drag and math.abs(v - a) <= math.abs(v - b)) then a = math.min(v, b) else b = math.max(v, a) end
		U.vflags[flagMin], U.vflags[flagMax] = a, b
		refresh()
		U.fireFlag(flagMin)
		U.fireFlag(flagMax)
	end
	track.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local rel = relX(track, i.Position.X)
		local a, b = (U.vflags[flagMin] - minV) / span, (U.vflags[flagMax] - minV) / span
		drag = (math.abs(rel - a) <= math.abs(rel - b)) and "min" or "max"
		at(i.Position.X)
	end)
	U.track(U.UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = nil end
	end))
	U.track(U.UIS.InputChanged:Connect(function(i)
		if drag and i.UserInputType == Enum.UserInputType.MouseMovement then at(i.Position.X) end
	end))
	for _, f in ipairs({ flagMin, flagMax }) do
		U.setters[f] = function(v) U.vflags[f] = v refresh() U.fireFlag(f) end
	end
	return r
end

local DD_BG, DD_SEL, DD_HOV = Color3.fromRGB(32, 32, 32), Color3.fromRGB(40, 40, 40), Color3.fromRGB(36, 36, 36)

function U.mkDropdown(parent, text, flag, options, default, multi, order, limit, tooltip)
	local r = U.row(parent, order)
	U.bindTooltip(r, tooltip)
	r.Size = UDim2.new(1, 0, 0, 30)
	options = options or {}
	-- Limit: 1 = single (closes on select), 0 = unlimited multi, >1 = multi with that cap
	local lim = tonumber(limit)
	if lim == nil then
		if multi == true then lim = 0 else lim = 1 end
	end
	lim = math.floor(lim)
	if lim < 0 then lim = 0 end
	local unlimited = lim == 0
	multi = unlimited or lim > 1
	local maxCount = unlimited and 1e9 or lim
	if multi then
		local d = type(default) == "table" and default or (default ~= nil and { default } or {})
		while #d > maxCount do table.remove(d, 1) end
		U.vflags[flag] = d
	else
		U.vflags[flag] = type(default) == "table" and default[1] or default
	end

	U.label(r, text, { Size = UDim2.new(1, 0, 0, 12) })
	local box = U.new("TextButton", {
		Name = "DropBox", AutoButtonColor = false, BackgroundColor3 = DD_BG, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 14), FontFace = U.font, TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, r)
	U.controlStroke(box)

	local function display()
		if multi then
			local t = U.vflags[flag] or {}
			box.Text = #t > 0 and (" " .. table.concat(t, ", ")) or " none"
		else
			box.Text = " " .. tostring(U.vflags[flag] or "")
		end
	end
	display()
	local function isSelected(opt)
		if multi then return table.find(U.vflags[flag] or {}, opt) ~= nil end
		return tostring(U.vflags[flag] or "") == tostring(opt)
	end

	local function pruneSelection()
		if not multi then
			local cur = U.vflags[flag]
			if cur ~= nil and not table.find(options, cur) then
				U.vflags[flag] = nil
				display()
				U.fireFlag(flag)
			end
			return
		end
		local cur = type(U.vflags[flag]) == "table" and U.vflags[flag] or {}
		local kept = {}
		for _, v in ipairs(cur) do
			if table.find(options, v) then kept[#kept + 1] = v end
		end
		if #kept ~= #cur then
			U.vflags[flag] = kept
			display()
			U.fireFlag(flag)
		end
	end

	box.MouseButton1Click:Connect(function()
		U.closeColorPicker()
		U.closeSettings()
		if U.openDropdown and U.openDropdown.Parent then
			local same = U.openDropdown:GetAttribute("Flag") == flag
			U.closeDropdown()
			if same then return end
		end
		if #options == 0 then return end

		local eb = U.ELEMENT_BORDER
		local rowH = 18
		local maxH = 144 -- exact multiple of rowH so nothing is half-clipped
		local contentH = #options * rowH
		local fullH = math.min(contentH, maxH)
		local boxW = math.floor(box.AbsoluteSize.X + 0.5)
		local ebPx = math.floor(eb + 0.5)
		local width = boxW + ebPx * 2
		local px = math.floor(box.AbsolutePosition.X - U.gui.AbsolutePosition.X + 0.5) - ebPx
		local py = math.floor(box.AbsolutePosition.Y - U.gui.AbsolutePosition.Y + box.AbsoluteSize.Y + 0.5)
		local bb = box:FindFirstChild("BBottom")
		if bb then bb.Visible = false end

		-- list is fullH + bottom border so BBottom does not cover the last option
		local listH = fullH + ebPx
		local list = U.new("Frame", {
			Name = "DropdownList", BackgroundColor3 = DD_BG, BorderSizePixel = 0, ClipsDescendants = true,
			Size = UDim2.fromOffset(width, 0), Position = UDim2.fromOffset(px, py), ZIndex = 220,
		}, U.gui)
		list:SetAttribute("Flag", flag)
		U.edges(list, eb, false, 224, true)

		local scroll = U.new("ScrollingFrame", {
			Name = "DropScroll", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.fromOffset(width, fullH), Position = UDim2.fromOffset(0, 0),
			CanvasSize = UDim2.fromOffset(0, contentH), AutomaticCanvasSize = Enum.AutomaticSize.None,
			ScrollBarThickness = 0, ScrollBarImageTransparency = 1, ClipsDescendants = true,
			ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 221,
		}, list)
		local holder = U.new("Frame", {
			BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = false,
			Size = UDim2.fromOffset(width, contentH), Position = UDim2.fromOffset(0, 0), ZIndex = 222,
		}, scroll)
		U.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, holder)

		for _, opt in ipairs(options) do
			local b = U.new("TextButton", {
				AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, rowH), FontFace = U.font, TextSize = U.TEXT_SZ,
				TextColor3 = U.theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(opt), ZIndex = 223,
			}, holder)
			U.new("UIPadding", { PaddingLeft = UDim.new(0, 7) }, b)
			b.BackgroundColor3 = isSelected(opt) and DD_SEL or DD_BG
			b.MouseEnter:Connect(function() if not isSelected(opt) then b.BackgroundColor3 = DD_HOV end end)
			b.MouseLeave:Connect(function() b.BackgroundColor3 = isSelected(opt) and DD_SEL or DD_BG end)
			b.MouseButton1Click:Connect(function()
				if multi then
					local cur = type(U.vflags[flag]) == "table" and table.clone(U.vflags[flag]) or {}
					local at = table.find(cur, opt)
					if at then
						table.remove(cur, at)
					else
						table.insert(cur, opt)
						while #cur > maxCount do table.remove(cur, 1) end
					end
					U.vflags[flag] = cur
					for _, ch in ipairs(holder:GetChildren()) do
						if ch:IsA("TextButton") then ch.BackgroundColor3 = isSelected(ch.Text) and DD_SEL or DD_BG end
					end
				else
					U.vflags[flag] = opt
					U.closeDropdown()
				end
				display()
				U.fireFlag(flag)
			end)
		end
		U.openDropdown, U.openDropdownBox = list, box
		U.armPopupOpen()
		list.InputBegan:Connect(U.armPopupOpen)
		scroll.InputBegan:Connect(U.armPopupOpen)
		U.Tween:Create(list, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(width, listH) }):Play()
	end)
	U.setters[flag] = function(v)
		if multi and type(v) == "table" then
			v = table.clone(v)
			while #v > maxCount do table.remove(v, 1) end
		end
		U.vflags[flag] = v
		display()
		U.fireFlag(flag)
	end
	return r, options, pruneSelection, display
end

function U.mkTextbox(parent, text, flag, placeholder, order, tooltip)
	local r = U.row(parent, order)
	U.bindTooltip(r, tooltip)
	r.Size = UDim2.new(1, 0, 0, 30)
	U.vflags[flag] = U.vflags[flag] or ""
	U.label(r, text, { Size = UDim2.new(1, 0, 0, 12) })
	local box = U.new("TextBox", {
		BackgroundColor3 = DD_BG, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 16), Position = UDim2.fromOffset(0, 14), FontFace = U.font,
		TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text, PlaceholderText = placeholder or "", Text = tostring(U.vflags[flag]), ClearTextOnFocus = false,
	}, r)
	U.controlStroke(box)
	box.FocusLost:Connect(function() U.setFlag(flag, box.Text) end)
	U.setters[flag] = function(v)
		U.vflags[flag] = v
		box.Text = tostring(v or "")
		U.fireFlag(flag)
	end
	return r
end

function U.mkKeybind(parent, text, flag, default, order)
	local r = U.row(parent, order)
	U.vflags[flag] = default
	local name = U.label(r, text, { Size = UDim2.new(1, -60, 1, 0) })
	local box = U.new("TextButton", {
		Name = "KeybindBox", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, FontFace = U.font, TextSize = U.TEXT_SZ,
		TextColor3 = U.theme.Text, TextXAlignment = Enum.TextXAlignment.Right,
	}, r)
	local listening = false
	local function fit(txt)
		box.Text = "[" .. txt .. "]"
		local w = math.max(24, #box.Text * 7 + 4)
		box.Size, box.Position, name.Size = UDim2.fromOffset(w, 16), UDim2.new(1, -w, 0, 1), UDim2.new(1, -(w + 6), 1, 0)
	end
	fit(U.keyNameOf(default))
	U.setters[flag] = function(v)
		U.vflags[flag] = v
		fit(U.keyNameOf(v))
		U.fireFlag(flag)
	end
	box.MouseButton1Click:Connect(function()
		if listening then return end
		listening, U.kbBinding = true, true
		fit("...")
		local conn
		conn = U.UIS.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			conn:Disconnect()
			listening = false
			if input.KeyCode == Enum.KeyCode.Escape then fit(U.keyNameOf(U.vflags[flag])) else U.setters[flag](input.KeyCode) end
			task.defer(function() U.kbBinding = false end)
		end)
	end)
	return r
end

function U.mkColorRow(parent, text, order)
	local r = U.row(parent, order)
	U.label(r, text, { Size = UDim2.new(1, -40, 1, 0) })
	return r
end

function U.mkButton(parent, text, order, confirm)
	local r = U.row(parent, order)
	local btn = U.new("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = DD_SEL, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), FontFace = U.font,
		TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text, Text = text,
	}, r)
	U.controlStroke(btn)
	if order == 1 then
		local top = btn:FindFirstChild("BTop")
		if top then top.Position = UDim2.fromOffset(0, 0) end
	end
	btn:SetAttribute("Confirm", confirm == true)
	btn:SetAttribute("Label", text)
	return btn
end

function U.bindButton(btn, callback, delay)
	if not btn or not callback then return end
	local armed, label, confirm = false, btn:GetAttribute("Label") or btn.Text, btn:GetAttribute("Confirm") == true
	btn.MouseButton1Click:Connect(function()
		if confirm and not armed then
			armed = true
			btn.Text = "are you sure?"
			task.delay(delay or 3, function()
				if btn.Parent and armed then armed, btn.Text = false, label end
			end)
			return
		end
		armed, btn.Text = false, label
		pcall(callback)
	end)
end

function U.parseColorDefault(v)
	if typeof(v) == "Color3" then
		return v, 0
	end
	if type(v) == "table" then
		if typeof(v[1]) == "Color3" then
			return v[1], math.clamp(tonumber(v[2] or v.a or v.A or v.Transparency) or 0, 0, 1)
		end
		if typeof(v.Color) == "Color3" then
			return v.Color, math.clamp(tonumber(v.Transparency or v.a or v.A or v[2]) or 0, 0, 1)
		end
		-- Color3-like (0-1 components) with optional A
		if typeof(v.R) == "number" and typeof(v.G) == "number" and typeof(v.B) == "number" then
			local a = tonumber(v.A or v.a or v.Transparency or v[4]) or 0
			return Color3.new(v.R, v.G, v.B), math.clamp(a, 0, 1)
		end
		local r = tonumber(v[1] or v.r)
		local g = tonumber(v[2] or v.g)
		local b = tonumber(v[3] or v.b)
		local a = tonumber(v[4] or v.a or v.A or v.Transparency) or 0
		if r and g and b then
			if r > 1 or g > 1 or b > 1 then
				return Color3.fromRGB(r, g, b), math.clamp(a, 0, 1)
			end
			return Color3.new(r, g, b), math.clamp(a, 0, 1)
		end
	end
	return Color3.new(1, 1, 1), 0
end

function U.attachPicker(rowFrame, flagKey, defaultVal, showTransparency, title)
	title = string.lower(tostring(title or "color"))
	showTransparency = showTransparency == true
	local alphaKey = flagKey .. "Transparency"
	local defaultColor, defaultAlpha = U.parseColorDefault(defaultVal)
	U.vflags[flagKey] = defaultColor
	if showTransparency then
		U.vflags[alphaKey] = defaultAlpha
	else
		U.vflags[alphaKey] = 0
	end
	local h, sat, val = defaultColor:ToHSV()

	local rightPad = rowFrame:GetAttribute("RightPad") or 2
	rowFrame:SetAttribute("RightPad", rightPad + 24 + 4 + 2)
	local sw = U.new("TextButton", {
		Name = "Swatch", AutoButtonColor = false, Text = "", Size = UDim2.fromOffset(24, 12), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -rightPad, 0.5, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12,
	}, rowFrame)
	U.controlStroke(sw)
	local swFill = U.new("Frame", {
		Name = "SwatchFill", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), BackgroundColor3 = defaultColor, ZIndex = 13,
		BackgroundTransparency = showTransparency and (U.vflags[alphaKey] or 0) or 0,
	}, sw)

	local function refreshOpen()
		if U.openPickerRefresh and U.openColorPicker and U.openColorPicker:GetAttribute("Flag") == flagKey then U.openPickerRefresh() end
	end
	local function paint()
		local c = Color3.fromHSV(h, sat, val)
		U.vflags[flagKey], swFill.BackgroundColor3 = c, c
		swFill.BackgroundTransparency = showTransparency and (U.vflags[alphaKey] or 0) or 0
		local tk = U.THEME_KEYS[flagKey]
		if tk then U.theme[tk] = c U.applyTheme() end
	end
	local function apply()
		paint()
		U.fireFlag(flagKey)
	end
	U.setters[flagKey] = function(v)
		local c, a = U.parseColorDefault(v)
		if typeof(v) == "Color3" then
			c = v
		end
		h, sat, val = c:ToHSV()
		U.vflags[flagKey] = c
		if showTransparency and type(v) == "table" then
			U.vflags[alphaKey] = a
		end
		paint()
		refreshOpen()
		U.fireFlag(flagKey)
	end
	if showTransparency then
		U.setters[alphaKey] = function(a)
			U.vflags[alphaKey] = a
			swFill.BackgroundTransparency = a or 0
			refreshOpen()
			U.fireFlag(alphaKey)
		end
	end

	sw.MouseButton1Click:Connect(function()
		U.closeDropdown()
		if U.openColorPicker and U.openColorPicker.Parent then
			local same = U.openColorPicker:GetAttribute("Flag") == flagKey
			U.closeColorPicker()
			if same then return end
		end

		local MAP, TOG, PAD, TITLE, GAP = 120, 14, 8, 16, 6
		local BAR = TOG
		local mapY = PAD + TITLE
		local hueY = mapY + MAP + GAP
		local alphaX = PAD + MAP + GAP
		local hasAlpha = showTransparency
		local rightW = hasAlpha and BAR or TOG
		local POP_W = PAD + MAP + GAP + rightW + PAD
		local RGB_H = 16
		local botY = hueY + BAR + GAP
		local POP_H = botY + RGB_H + PAD

		local pop = U.new("Frame", {
			Name = "ColorPop", BackgroundColor3 = Color3.fromRGB(24, 24, 24), BorderSizePixel = 0, Size = UDim2.fromOffset(POP_W, POP_H), ZIndex = 220, Active = true,
		}, U.gui)
		pop:SetAttribute("Flag", flagKey)
		do local st = U.new("UIStroke", { Color = U.theme.Border, Thickness = 2, LineJoinMode = Enum.LineJoinMode.Miter }, pop); U.themeReg.borders[#U.themeReg.borders+1] = st end
		U.label(pop, title, { Size = UDim2.new(1, -PAD * 2, 0, TITLE), Position = UDim2.fromOffset(PAD, 4), ZIndex = 221 })

		local function btn(class, props)
			props.AutoButtonColor, props.BorderSizePixel, props.ZIndex = false, 0, 221
			return U.new(class, props, pop)
		end
		local function marker(parent, size, z, pos)
			local m = U.new("Frame", { Size = size, AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z }, parent)
			U.new("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 }, m)
			return m
		end
		local function overlay(parent, color, z, rot, a, b)
			local f = U.new("Frame", { BackgroundColor3 = color, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z }, parent)
			U.new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) }) }, f)
		end

		local map = btn("ImageButton", { BackgroundColor3 = Color3.fromHSV(h, 1, 1), Size = UDim2.fromOffset(MAP, MAP), Position = UDim2.fromOffset(PAD, mapY) })
		U.controlStroke(map)
		overlay(map, Color3.new(1, 1, 1), 222, 0, 0, 1)
		overlay(map, Color3.new(0, 0, 0), 223, 90, 1, 0)
		local mapDot = marker(map, UDim2.fromOffset(8, 8), 224, UDim2.new())

		local alphaBar, alphaDot
		if hasAlpha then
			alphaBar = btn("ImageButton", {
				Size = UDim2.fromOffset(BAR, MAP), Position = UDim2.fromOffset(alphaX, mapY),
				BackgroundColor3 = Color3.fromHSV(h, sat, val),
			})
			U.controlStroke(alphaBar)
			U.new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
			}, alphaBar)
			alphaDot = marker(alphaBar, UDim2.fromOffset(BAR + 4, 2), 223, UDim2.new(0.5, 0, U.vflags[alphaKey] or 0, 0))
		end

		local hueBar = btn("ImageButton", { Size = UDim2.fromOffset(MAP, BAR), Position = UDim2.fromOffset(PAD, hueY), BackgroundColor3 = Color3.new(1, 1, 1) })
		U.controlStroke(hueBar)
		local hueKeys = {}
		for i, c in ipairs({ { 0, 0 }, { 0.17, 60 }, { 0.33, 120 }, { 0.5, 180 }, { 0.67, 240 }, { 0.83, 300 }, { 1, 0 } }) do
			hueKeys[i] = ColorSequenceKeypoint.new(c[1], Color3.fromHSV(c[2] / 360, 1, 1))
		end
		U.new("UIGradient", { Color = ColorSequence.new(hueKeys) }, hueBar)
		local hueDot = marker(hueBar, UDim2.fromOffset(2, BAR + 4), 223, UDim2.new(h, 0, 0.5, 0))

		local cycleX = alphaX + math.floor((rightW - TOG) / 2)
		local cycleY = hueY + math.floor((BAR - TOG) / 2)
		local refreshUI
		local cycleB = btn("TextButton", {
			Name = "CycleColor", Text = "", Size = UDim2.fromOffset(TOG, TOG),
			Position = UDim2.fromOffset(cycleX, cycleY),
			BackgroundColor3 = U.vflags[flagKey .. "CycleColor"] and U.pulseColor() or U.OFF,
		})
		U.controlStroke(cycleB)
		U.registerPulse(cycleB, function() return U.vflags[flagKey .. "CycleColor"] == true end)
		cycleB.MouseButton1Click:Connect(function()
			local on = U.vflags[flagKey .. "CycleColor"] ~= true
			U.setCycleColor(flagKey, on)
			if on then h = U.cycle.hue apply() end
			cycleB.BackgroundColor3 = on and U.pulseColor() or U.OFF
			refreshUI()
		end)

		local rgbW = (cycleX + TOG) - PAD
		local rgbBox = U.new("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 18, 18), BorderSizePixel = 0,
			Size = UDim2.fromOffset(rgbW, RGB_H), Position = UDim2.fromOffset(PAD, botY), ZIndex = 221,
		}, pop)
		U.controlStroke(rgbBox)
		local rgbText = U.label(rgbBox, "", {
			Position = UDim2.fromOffset(3, 0), Size = UDim2.new(1, -6, 1, 0),
			TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 222,
		})
		local function syncRgbText()
			local c = Color3.fromHSV(h, sat, val)
			local r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
			if not hasAlpha then
				rgbText.Text = string.format("%d, %d, %d", r, g, b)
			else
				local a = U.vflags[alphaKey] or 0
				rgbText.Text = string.format("%d, %d, %d, %.2f", r, g, b, a)
			end
		end
		refreshUI = function()
			map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			mapDot.Position = UDim2.fromScale(sat, 1 - val)
			hueDot.Position = UDim2.new(h, 0, 0.5, 0)
			if alphaBar then
				alphaBar.BackgroundColor3 = Color3.fromHSV(h, sat, val)
				alphaDot.Position = UDim2.new(0.5, 0, U.vflags[alphaKey] or 0, 0)
			end
			cycleB.BackgroundColor3 = U.vflags[flagKey .. "CycleColor"] and U.pulseColor() or U.OFF
			syncRgbText()
		end
		U.openPickerRefresh = refreshUI
		pop.Destroying:Connect(function()
			if U.openPickerRefresh == refreshUI then U.openPickerRefresh = nil end
		end)

		local drag
		local function move(pos)
			if drag == "map" then
				sat = math.clamp((pos.X - map.AbsolutePosition.X) / math.max(map.AbsoluteSize.X, 1), 0, 1)
				val = 1 - math.clamp((pos.Y - map.AbsolutePosition.Y) / math.max(map.AbsoluteSize.Y, 1), 0, 1)
			elseif drag == "hue" then
				h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
			elseif drag == "alpha" and alphaBar then
				U.vflags[alphaKey] = math.clamp((pos.Y - alphaBar.AbsolutePosition.Y) / math.max(alphaBar.AbsoluteSize.Y, 1), 0, 1)
			else
				return
			end
			apply()
			refreshUI()
		end
		local function onDown(which)
			return function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				U.armPopupOpen()
				drag = which
				move(input.Position)
			end
		end
		map.InputBegan:Connect(onDown("map"))
		hueBar.InputBegan:Connect(onDown("hue"))
		if alphaBar then alphaBar.InputBegan:Connect(onDown("alpha")) end
		local c1 = U.UIS.InputChanged:Connect(function(i)
			if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then move(i.Position) end
		end)
		local c2 = U.UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = nil end
		end)
		pop.Destroying:Connect(function() c1:Disconnect() c2:Disconnect() end)

		local a, origin = sw.AbsolutePosition, U.gui.AbsolutePosition
		local px = a.X - origin.X + sw.AbsoluteSize.X + 6
		if U.gui.AbsoluteSize.X > 0 and px + POP_W > U.gui.AbsoluteSize.X then px = a.X - origin.X - POP_W - 6 end
		pop.Position = UDim2.fromOffset(px, a.Y - origin.Y)
		if U.vflags[flagKey .. "CycleColor"] then h = U.cycle.hue apply() end
		U.openColorPicker = pop
		U.armPopupOpen()
		refreshUI()
	end)
	return sw
end


function U.shellHeight()
	local h = U.LINE_H + U.TITLE_H + U.BODY_H + U.TAB_H
	if U.bottomBarOn then
		h = h + (U.BOTTOM_BAR_H or 18) + U.SEC_GAP
	end
	return h
end

function U.layoutBottomBar()
	if not U.bottomBar then return end
	local gap = U.SEC_GAP
	U.bottomBar.Visible = U.bottomBarOn == true
	if not U.bottomBarOn then return end
	U.bottomBar.Size = UDim2.new(1, -gap * 2, 0, U.BOTTOM_BAR_H or 18)
	U.bottomBar.Position = UDim2.new(0, gap, 1, -(gap + (U.BOTTOM_BAR_H or 18)))
	if U.bottomBarLabel then
		U.bottomBarLabel.Text = tostring(U.bottomBarText or "")
	end
end

function U.setBottomBar(on, text)
	U.bottomBarOn = on == true
	if text ~= nil then U.bottomBarText = tostring(text) end
	if U.shell then
		U.shell.Size = UDim2.fromOffset(U.BODY_W, U.shellHeight())
		U.layoutBottomBar()
		U.applyBodyLayout(true)
	end
end

function U.buildShell()
	local TAB_W = math.floor(U.BODY_W / math.max(1, #U.TAB_NAMES))
	U.TAB_W, U.TAB_H = TAB_W, 26
	U.gui = U.new("ScreenGui", { Name = "wavelength", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true }, U.guiParent())

	local shell = U.new("Frame", {
		Name = "Shell", BackgroundColor3 = U.theme.Background, BorderSizePixel = 0, ClipsDescendants = true, Active = true,
		Size = UDim2.fromOffset(U.BODY_W, U.shellHeight()), Position = UDim2.new(0.5, -U.BODY_W / 2, 0.5, -U.shellHeight() / 2),
	}, U.gui)
	U.shell = shell
	U.stroke(shell, "Border")
	table.insert(U.themeReg.bodyBgs, shell)

	U.accent = U.new("Frame", { Name = "Accent", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, U.LINE_H), ZIndex = 5 }, shell)
	table.insert(U.themeReg.accents, U.new("UIGradient", { Color = U.accentSequence() }, U.accent))

	U.titleBar = U.new("Frame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Active = true,
		Size = UDim2.new(1, 0, 0, U.TITLE_H),
		Position = UDim2.fromOffset(0, U.LINE_H),
		ZIndex = 6,
	}, shell)
	-- Center between UI top (y=0) and section border (LINE_H + TITLE_H + 7).
	-- 7 matches section topPad (tab overhang only; section headers unchanged).
	local bandBottom = U.LINE_H + U.TITLE_H + 7
	local titleY = math.floor(bandBottom / 2 - U.TEXT_SZ / 2 + 0.5) - U.LINE_H
	U.titleLabel = U.new("TextLabel", {
		Name = "TitleLabel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = U.font,
		TextSize = U.TEXT_SZ,
		TextColor3 = U.theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = tostring(U.windowTitle or "wavelength"),
		Position = UDim2.fromOffset(6, titleY),
		Size = UDim2.new(1, -12, 0, U.TEXT_SZ),
		ZIndex = 7,
	}, U.titleBar)
	table.insert(U.themeReg.labels, U.titleLabel)

	U.body = U.new("Frame", {
		Name = "Body", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(U.BODY_W, U.BODY_H),
		Position = UDim2.fromOffset(0, U.LINE_H + U.TITLE_H + U.TAB_H), ClipsDescendants = true, Active = true,
	}, shell)
	table.insert(U.themeReg.bodyBgs, U.body)
	U.pages = U.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, U.body)

	U.pageFrames = {}
	for i, n in ipairs(U.TAB_NAMES) do
		U.pageFrames[n] = U.new("Frame", { Name = n, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = i == 1 }, U.pages)
	end
	U.currentTab = U.TAB_NAMES[1]

	-- bottom bar (optional, controlled via CreateWindow / SetBottomBar)
	U.bottomBar = U.new("Frame", {
		Name = "BottomBar",
		BackgroundColor3 = U.theme.SectionBg,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 6,
	}, U.shell)
	table.insert(U.themeReg.sectionBgs, U.bottomBar)
	U.stroke(U.bottomBar, "SectionBorder")
	U.bottomBarLabel = U.label(U.bottomBar, "", {
		Name = "BottomBarText",
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.fromOffset(5, 0),
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 7,
	})
	U.layoutBottomBar()
end

local function panelOf(kind)
	if kind == "wm" then return U.wm end
	if kind == "kb" then return U.kbPanel end
	return nil
end
local function flagOf(kind)
	if kind == "wm" then return "Watermark" end
	if kind == "kb" then return "KeybindsList" end
	return ""
end

function U.dockPos(kind, h)
	local sp, sw = U.shell.Position, U.shell.Size.X.Offset
	if sw < 2 then sw = U.BODY_W end
	local right = kind == "kb"
	return Vector2.new(right and 1 or 0, 0), UDim2.new(sp.X.Scale, sp.X.Offset + (right and sw or 0), sp.Y.Scale, sp.Y.Offset - h - U.dockGap)
end

local function panelH(f)
	local h = f.Size.Y.Offset
	return h < 2 and 26 or h
end

function U.dock(kind)
	local f = panelOf(kind)
	if not U[kind .. "Docked"] or not f or not f.Parent or not U.shell then return end
	local fl = flagOf(kind)
	if fl ~= "" and U.vflags[fl] == false then return end
	f.AnchorPoint, f.Position = U.dockPos(kind, panelH(f))
end
function U.dockWatermark() U.dock("wm") end
function U.dockKeybinds() U.dock("kb") end

function U.ensureSnapGhosts()
	if not U.gui then return end
	for _, kind in ipairs({ "wm", "kb" }) do
		local key = kind .. "SnapGhost"
		if not U[key] or not U[key].Parent then
			local g = U.new("Frame", { Name = (kind == "wm" and "Wm" or "Kb") .. "SnapGhost", BorderSizePixel = 0, Visible = false, ZIndex = 40 }, U.gui)
			table.insert(U.themeReg.borders, U.stroke(g, "Border", true))
			table.insert(U.themeReg.bodyBgs, g)
			U[key] = g
		end
		U[key].BackgroundColor3, U[key].BackgroundTransparency = U.theme.Background, 0.35
	end
end

function U.showSnapGhost(kind)
	if U.menuOpen == false then
		U.hideSnapGhost("wm"); U.hideSnapGhost("kb")
		return
	end
	U.ensureSnapGhosts()
	local f, g = panelOf(kind), U[kind .. "SnapGhost"]
	if not U.shell or not f then return end
	local h = panelH(f)
	g.Size = UDim2.fromOffset(math.max(2, f.Size.X.Offset), h)
	g.AnchorPoint, g.Position = U.dockPos(kind, h)
	g.Visible = true
end

function U.hideSnapGhost(kind)
	if U[kind .. "SnapGhost"] then U[kind .. "SnapGhost"].Visible = false end
end

function U.overlapsSnap(kind, frame)
	if U.menuOpen == false or not frame or not U.shell then return false end
	local g = U[kind .. "SnapGhost"]
	if not g or not g.Visible then return false end
	local gp, gs, fp, fs = g.AbsolutePosition, g.AbsoluteSize, frame.AbsolutePosition, frame.AbsoluteSize
	local cx = fp.X + fs.X * 0.5
	local cy = fp.Y + fs.Y * 0.5
	local pad = 12
	return cx >= gp.X - pad and cx <= gp.X + gs.X + pad and cy >= gp.Y - pad and cy <= gp.Y + gs.Y + pad
end

function U.syncFloatingVisibility()
	local menuOn = U.menuOpen ~= false
	if U.shell then U.shell.Visible = menuOn end
	for _, kind in ipairs({ "wm", "kb" }) do
		local f = panelOf(kind)
		if not f then continue end
		local on = U.vflags[flagOf(kind)] == true and (menuOn or not U[kind .. "Docked"])
		f.Visible = on == true
	end
end

function U.dragPanel(f, kind)
	local dragging, ds, sp
	f.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging, ds, sp = true, input.Position, f.Position
		U[kind .. "Docked"] = false
		U.showSnapGhost(kind)
		input.Changed:Connect(function()
			if input.UserInputState ~= Enum.UserInputState.End then return end
			dragging = false
			if U.overlapsSnap(kind, f) then
				U[kind .. "Docked"] = true
				U.dock(kind)
			end
			U.hideSnapGhost(kind)
			U.syncFloatingVisibility()
		end)
	end)
	U.track(U.UIS.InputChanged:Connect(function(input)
		if not dragging or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
		local d = input.Position - ds
		f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		U.showSnapGhost(kind)
	end))
end

function U.buildFloaters()
	local gen, P = U.gen, U.PAD
	local textPos, textSize = UDim2.fromOffset(P, U.LINE_H + P), UDim2.new(1, -P * 2, 0, U.TEXT_SZ)

	
	local wm = U.mkPanel(U.gui, "Watermark", 50)
	wm.Size, wm.Active, wm.Visible = U.panelSize(80, 1), true, false
	U.wm, U.wmGui = wm, U.gui
	local wtxt = U.label(wm, "", { Position = textPos, Size = textSize, TextYAlignment = Enum.TextYAlignment.Center })
	U.wmText = wtxt

	local frames, fps = 0, 60
	U.track(U.Run.RenderStepped:Connect(function() frames += 1 end))
	task.spawn(function()
		while U.running and U.gen == gen do
			task.wait(1)
			fps, frames = frames, 0
		end
	end)
	local function ping()
		local ok, v = pcall(function()
			if U.lp and U.lp.GetNetworkPing then
				return math.floor(U.lp:GetNetworkPing() * 1000 + 0.5)
			end
			return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		return ok and v or 0
	end
	local function refreshWm()
		local on = U.vflags.Watermark == true
		wm.Visible = on
		if not on then return end
		local parts = {}
		for _, item in ipairs(U.vflags.WatermarkItems or {}) do
			if item == "message" then
				local msg = tostring(U.vflags.WatermarkMessage or "")
				if msg ~= "" then parts[#parts + 1] = msg end
			elseif item == "fps" then parts[#parts + 1] = "fps: " .. fps
			elseif item == "ping" then parts[#parts + 1] = "ping: " .. ping() end
		end
		wtxt.Text = #parts > 0 and table.concat(parts, " | ") or "wavelength"
		wtxt.TextColor3 = U.theme.Text
		wm.Size = U.panelSize(U.textW(wtxt), 1)
		U.dock("wm")
		U.syncFloatingVisibility()
	end
	U.onFlag("Watermark", function() refreshWm() U.syncFloatingVisibility() end)
	U.onFlag("WatermarkItems", refreshWm)
	U.onFlag("WatermarkMessage", refreshWm)
	task.spawn(function()
		while U.running and U.gen == gen do
			task.wait(0.25)
			if U.vflags.Watermark then refreshWm() end
		end
	end)
	refreshWm()
	U.dragPanel(wm, "wm")

	
	local kb = U.mkPanel(U.gui, "KeybindsPanel", 50)
	kb.Size, kb.Active, kb.Visible = U.panelSize(40, 1), true, false
	U.kbPanel = kb
	local list = U.new("Frame", { Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = textPos, Size = UDim2.new(1, -P * 2, 1, -(U.LINE_H + P * 2)) }, kb)
	U.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, list)

	local function build()
		if U.vflags.KeybindsList ~= true then kb.Visible = false return end
		kb.Visible = true 
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		local maxW, count = 40, 0
		for i, e in ipairs(U.keybindListEntries) do
			local on = U.vflags[e.toggleFlag] == true
			local row = U.label(list, e.listText .. " [" .. U.keyNameOf(U.vflags[e.keyFlag]) .. "]", {
				Size = UDim2.new(1, 0, 0, U.TEXT_SZ), LayoutOrder = i, TextColor3 = on and U.theme.Text or U.GRAY_TEXT, TextYAlignment = Enum.TextYAlignment.Center,
			})
			row:SetAttribute("KbActive", on)
			maxW = math.max(maxW, U.textW(row))
			count += 1
		end
		kb.Size = U.panelSize(maxW, math.max(count, 1))
		U.dock("kb")
		U.syncFloatingVisibility()
	end
	function U.refreshKeybindList()
		if U._kbRefreshing then U._kbDirty = true return end
		U._kbRefreshing = true
		repeat
			U._kbDirty = false
			pcall(build)
		until not U._kbDirty
		U._kbRefreshing = false
	end
	U.onFlag("KeybindsList", function() U.refreshKeybindList() end)
	
	U.dragPanel(kb, "kb")


end
function U.buildConfig()

	local FOLDER, selected, listFrame = "zwavelength", nil, nil
	local function ensureFolder() if isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end end
	local function listConfigs()
		ensureFolder()
		local out = {}
		for _, f in ipairs(listfiles and listfiles(FOLDER) or {}) do
			local n = f:match("([^/\\]+)%.json$")
			if n then out[#out + 1] = n end
		end
		table.sort(out)
		return out
	end
	local function refreshList()
		if not listFrame then return end
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for i, name in ipairs(listConfigs()) do
			U.new("TextButton", {
				AutoButtonColor = false, BackgroundColor3 = selected == name and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(28, 28, 28), BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 18), FontFace = U.font, TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
				Text = "  " .. name, LayoutOrder = i,
			}, listFrame).MouseButton1Click:Connect(function()
				selected = name
				refreshList()
			end)
		end
	end
	local function posOf(f)
		local p = f.Position
		return { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
	end
	local function restorePos(f, p)
		if type(p) ~= "table" or not f then return end
		f.AnchorPoint = Vector2.new(0, 0)
		f.Position = #p >= 4 and UDim2.new(tonumber(p[1]) or 0, tonumber(p[2]) or 0, tonumber(p[3]) or 0, tonumber(p[4]) or 0)
			or UDim2.fromOffset(tonumber(p[1]) or 0, tonumber(p[2]) or 0)
	end
	local function serialize()
		local data = { __theme = {} }
		for k, v in pairs(U.vflags) do
			if typeof(v) == "EnumItem" then data[k] = { __enum = tostring(v) }
			elseif typeof(v) == "Color3" then data[k] = { __color = { v.R, v.G, v.B } }
			else data[k] = v end
		end
		for k, c in pairs(U.theme) do data.__theme[k] = { c.R, c.G, c.B } end
		data.__wmDocked, data.__kbDocked = U.wmDocked == true, U.kbDocked == true
		if U.wm and U.wm.Parent then data.__wmPos = posOf(U.wm) end
		if U.kbPanel and U.kbPanel.Parent then data.__kbPos = posOf(U.kbPanel) end
			return data
	end
	local function applyData(data)
		if type(data) ~= "table" then return end
		for k, v in pairs(data) do
			if k == "__theme" and type(v) == "table" then
				for tk, tv in pairs(v) do
					if type(tv) == "table" and U.theme[tk] then U.theme[tk] = Color3.new(tv[1], tv[2], tv[3]) end
				end
			elseif type(v) == "table" and v.__color then
				local col = Color3.new(v.__color[1], v.__color[2], v.__color[3])
				U.vflags[k] = col
				if U.setters[k] then U.setters[k](col) end
			elseif type(v) == "table" and v.__enum then
				local ok, enum = pcall(function() return Enum.KeyCode[v.__enum:match("KeyCode%.(.+)$") or v.__enum] end)
				if ok then
					if U.setters[k] then U.setters[k](enum) else U.vflags[k] = enum end
				end
			elseif k:sub(1, 2) ~= "__" then
				U.vflags[k] = v
				if U.setters[k] then U.setters[k](v) end
			end
		end
		if data.__wmDocked ~= nil then U.wmDocked = data.__wmDocked == true end
		if data.__kbDocked ~= nil then U.kbDocked = data.__kbDocked == true end
		restorePos(U.wm, data.__wmPos)
		restorePos(U.kbPanel, data.__kbPos)
		U.cycle.colorFlags = {}
		for k, v in pairs(U.vflags) do
			if type(k) == "string" and v == true and k:sub(-10) == "CycleColor" then
				U.setCycleColor(k:sub(1, -11), true)
			end
		end
		U.applyTheme()
		U.dock("wm")
		U.dock("kb")
		U.syncFloatingVisibility()
		U.refreshKeybindList()
	end

	local p = U.pageFrames.config
	local configsSec = U.section(p, 1):AddTab("configs")
	local settingsSec = U.section(p, 2):AddTab("settings")
	local configsContent, settingsContent = configsSec._content, settingsSec._content
	local function note(t) U.pushNotification({ text = t, time = 2 }) end
	local path = function(n) return FOLDER .. "/" .. n .. ".json" end

	U.mkTextbox(configsContent, "name", "ConfigName", "config name", 1)
	U.mkButton(configsContent, "create / save", 2).MouseButton1Click:Connect(function()
		local name = tostring(U.vflags.ConfigName or ""):gsub("[^%w%-%_ ]", "")
		if name == "" then return note("enter a config name") end
		ensureFolder()
		local ok, err = pcall(function() writefile(path(name), U.Http:JSONEncode(serialize())) end)
		if ok then
			selected = name
			refreshList()
			note('created "' .. name .. '" config')
		else
			U.pushNotification({ text = "save failed: " .. tostring(err), time = 3 })
		end
	end)
	U.mkButton(configsContent, "load", 3).MouseButton1Click:Connect(function()
		if not selected then return note("select a config first") end
		local ok, data = pcall(function() return U.Http:JSONDecode(readfile(path(selected))) end)
		if ok and type(data) == "table" then
			applyData(data)
			note('loaded "' .. selected .. '" config')
		else
			note("load failed")
		end
	end)
	U.mkButton(configsContent, "delete", 4).MouseButton1Click:Connect(function()
		if not selected then return note("select a config first") end
		local name = selected
		pcall(function() delfile(path(name)) end)
		selected = nil
		refreshList()
		note('deleted "' .. name .. '" config')
	end)

	U.label(configsContent, "saved", { Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 5 })
	local listBox = U.new("Frame", { Name = "SavedList", BackgroundColor3 = Color3.fromRGB(14, 14, 14), BorderSizePixel = 0, ClipsDescendants = false, Size = UDim2.new(1, 0, 0, 120), LayoutOrder = 6 }, configsContent)
	U.edges(listBox, U.ELEMENT_BORDER, true, 3)
	listFrame = U.new("ScrollingFrame", {
		Name = "Inner", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2),
		ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
	}, listBox)
	U.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)
	U.configListBox = listBox
	U.configListScroll = configsContent
	refreshList()
	task.defer(function()
		if U.updateConfigListHeight then U.updateConfigListHeight() end
	end)

	local o = 0
	local function nextOrder() o += 1 return o end
	local function themeRow(label, flag, key, title)
		return U.attachPicker(U.mkColorRow(settingsContent, label, nextOrder()), flag, U.theme[key], false, title or label)
	end
	themeRow("text", "ThemeText", "Text", "text color")
	themeRow("border", "ThemeBorder", "Border", "border color")
	themeRow("section border", "ThemeSectionBorder", "SectionBorder")
	themeRow("element border", "ThemeElementBorder", "ElementBorder")
	themeRow("section background", "ThemeSectionBg", "SectionBg")
	themeRow("background", "ThemeBackground", "Background")
	local accentRow = U.mkColorRow(settingsContent, "accent", nextOrder())
	U.attachPicker(accentRow, "ThemeAccent1", U.theme.Accent1, false, "accent a")
	U.attachPicker(accentRow, "ThemeAccent2", U.theme.Accent2, false, "accent b")
	U.mkKeybind(settingsContent, "menu keybind", "MenuKeybind", Enum.KeyCode.RightShift, nextOrder())
	U.mkDropdown(settingsContent, "notification position", "NotificationPosition", { "top left", "top right", "bottom left", "bottom right", "center" }, "center", false, nextOrder())

	U.mkToggle(settingsContent, "watermark", "Watermark", nextOrder(), false)
	U.subOf(U.mkDropdown(settingsContent, "items", "WatermarkItems", { "ping", "fps", "message" }, { "ping", "fps" }, true, nextOrder()), "Watermark")
	U.subOf(U.mkTextbox(settingsContent, "message", "WatermarkMessage", "message", nextOrder()), "Watermark")
	U.mkToggle(settingsContent, "keybinds", "KeybindsList", nextOrder(), false)
	U.mkToggle(settingsContent, "tooltips", "Tooltips", nextOrder(), true)
	U.onFlag("Tooltips", function() if U.vflags.Tooltips == false then U.hideTooltip() end end)

	U.mkToggle(settingsContent, "explorer", "Explorer", nextOrder(), false)
	U.onFlag("Explorer", function()
		if U._setExplorerVisible then
			U._setExplorerVisible(U.vflags.Explorer == true)
		elseif U.vflags.Explorer == true then
			U.buildExplorer()
			if U._setExplorerVisible then U._setExplorerVisible(true) end
		elseif U.explorerPanel then
			U.explorerPanel.Visible = false
		end
	end)

	U.buildFloaters()
	-- floating explorer window (settings toggle)
	pcall(function() U.buildExplorer() end)

	local function teleportTo(jobId)
		local ts = game:GetService("TeleportService")
		pcall(function()
			ts:TeleportToPlaceInstance(game.PlaceId, jobId, U.lp)
		end)
	end

	local rejoin = U.mkButton(settingsContent, "rejoin", nextOrder(), true)
	U.bindButton(rejoin, function()
		teleportTo(game.JobId)
	end, 2)

	local hop = U.mkButton(settingsContent, "server hop", nextOrder(), true)
	U.bindButton(hop, function()
		local ok, body = pcall(function()
			return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
		end)
		if not ok or type(body) ~= "string" then
			U.pushNotification({ text = "server hop failed", time = 2 })
			return
		end
		local decOk, data = pcall(function() return U.Http:JSONDecode(body) end)
		if not decOk or type(data) ~= "table" or type(data.data) ~= "table" then
			U.pushNotification({ text = "server hop failed", time = 2 })
			return
		end
		local candidates = {}
		for _, server in ipairs(data.data) do
			if server.id and server.id ~= game.JobId and (server.playing or 0) < (server.maxPlayers or 0) then
				candidates[#candidates + 1] = server.id
			end
		end
		if #candidates == 0 then
			U.pushNotification({ text = "no servers found", time = 2 })
			return
		end
		teleportTo(candidates[math.random(1, #candidates)])
	end, 2)

	local unload = U.mkButton(settingsContent, "unload", nextOrder(), true)
	U.bindButton(unload, U.shutdown, 2)

end

function U.buildTabs()
	local rail = U.new("Frame", {
		Name = "TabRail", BackgroundColor3 = U.theme.Background, BorderSizePixel = 0, Active = true, Size = UDim2.new(1, 0, 0, U.TAB_H),
		Position = UDim2.fromOffset(0, U.LINE_H + U.TITLE_H),
	}, U.shell)
	table.insert(U.themeReg.bodyBgs, rail)
	U.tabRail, U.tabButtons = rail, {}
	U.currentTab = U.TAB_NAMES[1] or "combat"
	local tabIndex, swiping = {}, false
	for i, n in ipairs(U.TAB_NAMES) do tabIndex[n] = i end

	local function selectTab(name)
		if name == U.currentTab or swiping then return end
		U.closePopups()
		local from = U.currentTab
		local dir = (tabIndex[name] or 0) > (tabIndex[from] or 0) and 1 or -1
		local oldPage, newPage = U.pageFrames[from], U.pageFrames[name]
		U.currentTab = name
		for _, fn in ipairs(U._tabListeners or {}) do pcall(fn, name) end
		U.syncFloatingVisibility()
			for n, b in pairs(U.tabButtons) do
			b.BackgroundColor3 = U.theme.Background
			b.TextColor3 = U.theme.Text
			local acc = b:FindFirstChild("TabAccent")
			if acc then acc.Visible = n == name end
		end
		if not oldPage or not newPage then
			for n, p in pairs(U.pageFrames) do p.Visible, p.Position = n == name, UDim2.new() end
			return
		end
		swiping = true
		newPage.Visible, newPage.Position, oldPage.Position = true, UDim2.fromScale(dir, 0), UDim2.new()
		local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		U.Tween:Create(oldPage, info, { Position = UDim2.fromScale(-dir, 0) }):Play()
		local tw = U.Tween:Create(newPage, info, { Position = UDim2.new() })
		tw:Play()
		tw.Completed:Connect(function()
			oldPage.Visible, oldPage.Position, swiping = false, UDim2.new(), false
		end)
	end

	for i, name in ipairs(U.TAB_NAMES) do
		local b = U.new("TextButton", {
			Name = name, AutoButtonColor = false, BackgroundColor3 = U.theme.Background, BorderSizePixel = 0,
			Size = UDim2.fromOffset((i == #U.TAB_NAMES) and (U.BODY_W - (i - 1) * U.TAB_W) or U.TAB_W, U.TAB_H), Position = UDim2.fromOffset((i - 1) * U.TAB_W, 0),
			FontFace = U.font, TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text, Text = name,
		}, rail)
		table.insert(U.themeReg.bodyBgs, b)
		local acc = U.new("Frame", {
			Name = "TabAccent", BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = U.theme.Accent1,
			Visible = name == U.currentTab, ZIndex = 3,
		}, b)
		table.insert(U.themeReg.tabAccents, acc)
		U.tabButtons[name] = b
		b.MouseButton1Click:Connect(function() selectTab(name) end)
	end
	U.shell.Size = UDim2.fromOffset(U.BODY_W, U.shellHeight())
	U.bindResize()
end

function U.applyShellSize(w, h, anchorRight, anchorBottom)
	w = math.clamp(math.floor(w), U.MIN_W or 320, 1200)
	h = math.clamp(math.floor(h), U.MIN_H or 400, 1000)
	local oldW, oldH = U.BODY_W, U.BODY_H
	local shell = U.shell
	if not shell then
		U.BODY_W, U.BODY_H = w, h
		return
	end
	local pos = shell.Position
	local dx = (anchorRight and (oldW - w) or 0)
	local dy = (anchorBottom and (oldH - h) or 0)
	U.BODY_W, U.BODY_H = w, h
	U.TAB_W = math.floor(U.BODY_W / math.max(1, #U.TAB_NAMES))
	shell.Size = UDim2.fromOffset(U.BODY_W, U.shellHeight())
	shell.Position = UDim2.new(pos.X.Scale, pos.X.Offset + dx, pos.Y.Scale, pos.Y.Offset + dy)
	if U.body then
		U.body.Size = UDim2.fromOffset(U.BODY_W, U.BODY_H)
		U.body.Position = UDim2.fromOffset(0, U.LINE_H + U.TITLE_H + U.TAB_H)
	end
	if U.titleBar then
		U.titleBar.Size = UDim2.new(1, 0, 0, U.TITLE_H)
		U.titleBar.Position = UDim2.fromOffset(0, U.LINE_H)
	end
	if U.tabRail then
		U.tabRail.Position = UDim2.fromOffset(0, U.LINE_H + U.TITLE_H)
		U.tabRail.Size = UDim2.new(1, 0, 0, U.TAB_H)
		for i, name in ipairs(U.TAB_NAMES) do
			local b = U.tabButtons and U.tabButtons[name]
			if b then
				b.Size = UDim2.fromOffset((i == #U.TAB_NAMES) and (U.BODY_W - (i - 1) * U.TAB_W) or U.TAB_W, U.TAB_H)
				b.Position = UDim2.fromOffset((i - 1) * U.TAB_W, 0)
			end
		end
	end
	if U.layoutBottomBar then U.layoutBottomBar() end
end

function U.sectionContentHeight(ch)
	local padY = 6 -- equal top/bottom padding inside section
	local headerH = 14
	local contentH = 8
	local pages = ch:FindFirstChild("Pages")
	if pages then
		for _, p in ipairs(pages:GetChildren()) do
			if p:IsA("ScrollingFrame") and p.Visible then
				local layout = p:FindFirstChildOfClass("UIListLayout")
				if layout then
					contentH = math.max(contentH, layout.AbsoluteContentSize.Y)
				else
					local sum = 0
					for _, c in ipairs(p:GetChildren()) do
						if c:IsA("GuiObject") and c.Visible then
							sum = sum + c.AbsoluteSize.Y
						end
					end
					contentH = math.max(contentH, sum)
				end
			end
		end
	end
	return headerH + padY * 2 + contentH
end

function U.layoutPage(page, full)
	if not page then return end
	local gap = U.SEC_GAP
	local topPad = 7
	local bottomReserve = gap
	if U.bottomBarOn then
		bottomReserve = bottomReserve + (U.BOTTOM_BAR_H or 18) + gap
	end
	for side = 1, 2 do
		local frames = {}
		for _, ch in ipairs(page:GetChildren()) do
			if ch:IsA("Frame") and ch:GetAttribute("SectionCol") == side then
				frames[#frames + 1] = ch
			end
		end
		table.sort(frames, function(a, b)
			return (a:GetAttribute("SectionRow") or 0) < (b:GetAttribute("SectionRow") or 0)
		end)
		local w = math.floor((U.BODY_W - gap * 3) / 2)
		local x = (side == 1) and gap or (gap * 2 + w)
		local y = topPad
		for i, ch in ipairs(frames) do
			local h = U.sectionContentHeight(ch)
			ch.Size = UDim2.fromOffset(w, h)
			ch.Position = UDim2.fromOffset(x, y)
			ch:SetAttribute("SectionRow", i)
			y = y + h + gap
		end
	end
	for _, sec in ipairs(U.sectionObjs or {}) do
		if sec._frame and sec._frame.Parent == page and sec.layoutTabs then
			sec.layoutTabs()
		end
	end
	if full then
		for flag in pairs(U.subGroups or {}) do
			U.updateSubLine(flag)
		end
		for _, fn in ipairs(U.sliderLayouts or {}) do
			pcall(fn)
		end
	end
	if U.updateConfigListHeight then
		U.updateConfigListHeight()
	end
	if U.layoutBottomBar then U.layoutBottomBar() end
end

function U.applyBodyLayout(full)
	local page = U.pageFrames and U.pageFrames[U.currentTab]
	U.layoutPage(page, full == true)
	if U.wmDocked then U.dock("wm") end
	if U.kbDocked then U.dock("kb") end
end

function U.applyBodySize(w, h, anchorRight, anchorBottom)
	U.applyShellSize(w, h, anchorRight, anchorBottom)
	U.applyBodyLayout(true)
end

function U.bindResize()
	U.MIN_W, U.MIN_H = U.MIN_W or 320, U.MIN_H or 400
	if not U.shell then return end
	local function handle(name, size, pos, cursor)
		local h = U.new("Frame", {
			Name = "ResizeHandle", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = size, Position = pos, ZIndex = 50, Active = true,
		}, U.shell)
		h:SetAttribute("Cursor", cursor)
		return h
	end
	local edge = 12
	local right = handle("Right", UDim2.new(0, edge, 1, -U.TAB_H), UDim2.new(1, -math.floor(edge / 2), 0, 0), "Right")
	local left = handle("Left", UDim2.new(0, edge, 1, -U.TAB_H), UDim2.fromOffset(-math.floor(edge / 2), 0), "Left")
	local bottom = handle("Bottom", UDim2.new(1, 0, 0, edge), UDim2.new(0, 0, 1, -math.floor(edge / 2)), "Bottom")
	local function bind(edgeObj, mode)
		edgeObj.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			U.closePopups()
			local start = input.Position
			local startW, startH = U.BODY_W, U.BODY_H
			local moving = true
			local c1, c2
			local lastLayout = 0
			c1 = U.UIS.InputChanged:Connect(function(i)
				if not moving then return end
				if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
				local d = i.Position - start
				if mode == "right" then
					U.applyShellSize(startW + d.X, startH, false, false)
				elseif mode == "left" then
					U.applyShellSize(startW - d.X, startH, true, false)
				elseif mode == "bottom" then
					U.applyShellSize(startW, startH + d.Y, false, false)
				end
				-- throttle expensive layout while resizing
				local now = os.clock()
				if now - lastLayout >= 0.05 then
					lastLayout = now
					U.applyBodyLayout(false)
				end
			end)
			c2 = U.UIS.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					moving = false
					c1:Disconnect()
					c2:Disconnect()
					U.applyBodyLayout(true)
					for name, p in pairs(U.pageFrames or {}) do
						if name ~= U.currentTab then
							U.layoutPage(p, true)
						end
					end
				end
			end)
			U.track(c1)
			U.track(c2)
		end)
	end
	bind(right, "right")
	bind(left, "left")
	bind(bottom, "bottom")
end

function U.bindInput()
	U.track(U.UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if U.clickHitsNamed("Swatch", "Gear", "DropBox", "CycleColor", "KeybindBox", "ResizeHandle", "DropdownList", "DropScroll") then return end
		task.defer(function()
			if tick() < (U.suppressPopupClose or 0) then return end
			if U.openColorPicker and not U.clickHits(U.openColorPicker) then U.closeColorPicker() end
			if U.openDropdown and not U.clickHits(U.openDropdown) then U.closeDropdown() end
			if U.openSettings and not U.clickHits(U.openSettings) and not U.clickHits(U.openDropdown) and not U.clickHits(U.openColorPicker) then U.closeSettings() end
		end)
	end))

	local dragging, ds, sp
	local function isUiDragSurface(obj)
		if not obj then return false end
		-- header + true UI background only (not section frames / slider tracks / rows)
		if obj == U.shell or obj == U.body or obj == U.titleBar or obj == U.accent or obj == U.titleLabel or obj == U.pages or obj == U.tabRail then
			return true
		end
		if U.pageFrames then
			for _, pf in pairs(U.pageFrames) do
				if obj == pf then return true end
			end
		end
		return false
	end
	local function beginDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if not U.shell or not U.shell.Parent then return end
		local objs = U.objsAtMouse()
		if #objs == 0 then return end
		if not isUiDragSurface(objs[1]) then return end
		U.closePopups()
		dragging, ds, sp = true, input.Position, U.shell.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if U.wmDocked then U.dock("wm") end
				if U.kbDocked then U.dock("kb") end
			end
		end)
	end
	U.track(U.UIS.InputBegan:Connect(beginDrag))
	U.track(U.UIS.InputChanged:Connect(function(input)
		if not dragging or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
		local d = input.Position - ds
		U.shell.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
	end))
	-- snap docks once when drag ends (handled via input.Changed on beginDrag end)

	U.menuOpen = true
	task.defer(function()
		U.dock("wm")
		U.dock("kb")
		end)

	U.track(U.UIS.InputBegan:Connect(function(input, gp)
		if gp or U.kbBinding then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			if U._kbModePopup and not input:IsDescendantOf(U._kbModePopup) then
				-- close handled after click targets
			end
		end
		if input.KeyCode == (U.vflags.MenuKeybind or Enum.KeyCode.RightShift) then
			U.menuOpen = not U.menuOpen
			if not U.menuOpen then
				U.closePopups()
				U.hideSnapGhost("wm")
				U.hideSnapGhost("kb")
				U.hideTooltip()
			end
			U.syncFloatingVisibility()
			if U.menuOpen then
				U.dock("wm")
				U.dock("kb")
			end
		end

		for kFlag, tFlag in pairs(U.keybindTargets) do
			local k = U.vflags[kFlag]
			if typeof(k) == "EnumItem" and k ~= Enum.KeyCode.Unknown and input.KeyCode == k then
				local on = U.vflags[tFlag] ~= true
				if U.setters[tFlag] then U.setters[tFlag](on) else U.setFlag(tFlag, on) end
			end
		end
	end))
end

local Library = {}
Library.__index = Library
Library.Flags = U.vflags
Library.Setters = U.setters

function Library:GetFlag(name) return U.vflags[name] end
function Library:SetFlag(name, val)
	if U.setters[name] then U.setters[name](val) else U.setFlag(name, val) end
end
function Library:OnFlag(name, fn) U.onFlag(name, fn) end
function Library:Notify(opts)
	if type(opts) == "string" then opts = { text = opts } end
	U.pushNotification({ text = opts.text or opts.Text or "", time = opts.time or opts.Time or opts.duration or opts.Duration or 3 })
end
function Library:GetShell() return U.shell end
function Library:GetGui() return U.gui end
function Library:GetTheme() return U.theme end
function Library:IsMenuOpen() return U.menuOpen ~= false end
function Library:GetCurrentTab() return U.currentTab end
function Library:OnTabChanged(fn)
	U._tabListeners = U._tabListeners or {}
	table.insert(U._tabListeners, fn)
end
function Library:_U() return U end

local function lname(o, default) return string.lower(tostring(o.Name or default)) end
local function tip(o) return o.Tooltip or o.tooltip end

local function keybindOf(o, name)
	if o.Keybind ~= true then return nil end
	return { key = o.Key or o.KeyCode, text = o.KeybindText or o.ListText or o.Text or name }
end


function U.buildExplorer()
	-- floating explorer window (not a main-tab page)
	if U.explorerPanel and U.explorerPanel.Parent then
		pcall(function() U.explorerPanel:Destroy() end)
	end
	local panel = U.new("Frame", {
		Name = "ExplorerPanel",
		BackgroundColor3 = U.theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Active = true,
		Size = UDim2.fromOffset(300, 420),
		Position = UDim2.fromOffset(24, 80),
		Visible = false,
		ZIndex = 40,
	}, U.gui)
	U.stroke(panel, "Border")
	table.insert(U.themeReg.bodyBgs, panel)
	U.explorerPanel = panel
	-- accent bar like main UI
	local expAccent = U.new("Frame", {
		Name = "Accent", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, U.LINE_H), ZIndex = 42,
	}, panel)
	table.insert(U.themeReg.accents, U.new("UIGradient", { Color = U.accentSequence() }, expAccent))
	U.label(panel, "dex explorer", {
		Name = "ExplorerTitle",
		Size = UDim2.new(1, -12, 0, 18),
		Position = UDim2.fromOffset(6, U.LINE_H + 2),
		ZIndex = 41,
	})
	local page = U.new("Frame", {
		Name = "explorer",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -(U.LINE_H + 22)),
		Position = UDim2.fromOffset(0, U.LINE_H + 20),
		ZIndex = 41,
	}, panel)
	-- drag explorer by panel
	do
		local dragging, ds, sp
		local function begin(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local objs = U.objsAtMouse()
			if objs[1] and (objs[1]:IsA("TextButton") or objs[1]:IsA("TextBox") or objs[1].Name == "ResizeHandle") then return end
			dragging, ds, sp = true, input.Position, panel.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
		panel.InputBegan:Connect(begin)
		U.track(U.UIS.InputChanged:Connect(function(input)
			if not dragging or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
			if not panel.Parent then return end
			local d = input.Position - ds
			panel.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end))
	end
	-- resize handles
	do
		local edge = 10
		local function rh(sz, pos)
			return U.new("Frame", {
				Name = "ResizeHandle", BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = sz, Position = pos, ZIndex = 50, Active = true,
			}, panel)
		end
		local right = rh(UDim2.new(0, edge, 1, 0), UDim2.new(1, -math.floor(edge / 2), 0, 0))
		local bottom = rh(UDim2.new(1, 0, 0, edge), UDim2.new(0, 0, 1, -math.floor(edge / 2)))
		local function bind(obj, mode)
			obj.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
				local start, sw, sh = input.Position, panel.AbsoluteSize.X, panel.AbsoluteSize.Y
				local moving = true
				local c1, c2
				c1 = U.UIS.InputChanged:Connect(function(i)
					if not moving then return end
					if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
					local d = i.Position - start
					local nw, nh = sw, sh
					if mode == "right" then nw = math.clamp(sw + d.X, 220, 700) end
					if mode == "bottom" then nh = math.clamp(sh + d.Y, 280, 800) end
					panel.Size = UDim2.fromOffset(math.floor(nw), math.floor(nh))
				end)
				c2 = U.UIS.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						moving = false
						c1:Disconnect()
						c2:Disconnect()
					end
				end)
			end)
		end
		bind(right, "right")
		bind(bottom, "bottom")
	end

		local RMD={["Accessory"]={o=30,i=32},["AccessoryDescription"]={o=22,i=104},["Accoutrement"]={o=20,i=32},["Actor"]={o=10,i=113},["AdGui"]={o=200,i=145},["AdPlacement"]={o=200,i=0},["AdPortal"]={o=200,i=146},["AirController"]={o=20,i=0},["AlignOrientation"]={o=30,i=100},["AlignPosition"]={o=30,i=99},["AnalyticsService"]={o=9999,i=0},["AngularVelocity"]={o=30,i=103},["Animation"]={o=220,i=60},["AnimationConstraint"]={o=30,i=0},["AnimationController"]={o=220,i=60},["AnimationTrack"]={o=220,i=60},["Animator"]={o=220,i=60},["ArcHandles"]={o=200,i=56},["AssetService"]={o=9999,i=0},["Atmosphere"]={o=5,i=28},["AtmosphereSensor"]={o=20,i=0},["Attachment"]={o=30,i=81},["AudioAnalyzer"]={o=10,i=11},["AudioChannelMixer"]={o=10,i=11},["AudioChannelSplitter"]={o=10,i=11},["AudioChorus"]={o=10,i=11},["AudioCompressor"]={o=10,i=11},["AudioDeviceInput"]={o=10,i=11},["AudioDeviceOutput"]={o=10,i=11},["AudioDistortion"]={o=10,i=11},["AudioEcho"]={o=10,i=11},["AudioEmitter"]={o=10,i=11},["AudioEqualizer"]={o=10,i=11},["AudioFDNReverb"]={o=10,i=11},["AudioFader"]={o=10,i=11},["AudioFilter"]={o=10,i=11},["AudioFlanger"]={o=10,i=11},["AudioGate"]={o=10,i=11},["AudioLimiter"]={o=10,i=11},["AudioListener"]={o=10,i=11},["AudioPitchShifter"]={o=10,i=11},["AudioPlayer"]={o=10,i=11},["AudioRecorder"]={o=10,i=11},["AudioReverb"]={o=10,i=11},["AudioSpeechToText"]={o=10,i=11},["AudioStreamReader"]={o=10,i=11},["AudioStreamWriter"]={o=10,i=11},["AudioTextToSpeech"]={o=10,i=11},["AudioTremolo"]={o=10,i=11},["AudioWindSynthesizer"]={o=10,i=11},["AuroraScript"]={o=50,i=76},["AvatarAccessoryRules"]={o=20,i=0},["AvatarAnimationRules"]={o=20,i=0},["AvatarBodyRules"]={o=20,i=0},["AvatarClothingRules"]={o=20,i=0},["AvatarCollisionRules"]={o=20,i=0},["AvatarRules"]={o=20,i=0},["Backpack"]={o=30,i=20},["BackpackItem"]={o=20,i=0},["BadgeService"]={o=9999,i=0},["BallSocketConstraint"]={o=30,i=86},["BasePart"]={o=3,i=0},["Beam"]={o=30,i=96},["BevelMesh"]={o=9999,i=0},["BillboardGui"]={o=140,i=64},["BindableEvent"]={o=50,i=67},["BindableFunction"]={o=40,i=66},["BlockMesh"]={o=30,i=8},["BloomEffect"]={o=20,i=83},["BlurEffect"]={o=20,i=83},["BodyAngularVelocity"]={o=140,i=14},["BodyColors"]={o=20,i=0},["BodyForce"]={o=140,i=14},["BodyGyro"]={o=140,i=14},["BodyPartDescription"]={o=22,i=104},["BodyPosition"]={o=140,i=14},["BodyThrust"]={o=140,i=14},["BodyVelocity"]={o=140,i=14},["Bone"]={o=30,i=114},["BoolValue"]={o=30,i=4},["BoxHandleAdornment"]={o=205,i=111},["BrickColorValue"]={o=30,i=4},["BubbleChatConfiguration"]={o=13,i=0},["BuoyancySensor"]={o=20,i=0},["CFrameValue"]={o=30,i=4},["Camera"]={o=5,i=5},["CanvasGroup"]={o=200,i=48},["ChangeHistoryService"]={o=9999,i=0},["ChannelTabsConfiguration"]={o=12,i=141},["CharacterMesh"]={o=220,i=60},["Chat"]={o=510,i=33},["ChatInputBarConfiguration"]={o=11,i=142},["ChatService"]={o=510,i=33},["ChatWindowConfiguration"]={o=10,i=141},["ChorusSoundEffect"]={o=20,i=84},["ClickDetector"]={o=30,i=41},["ClimbController"]={o=20,i=0},["Clothing"]={o=20,i=0},["Clouds"]={o=5,i=28},["CollectionService"]={o=9999,i=0},["Color3Value"]={o=30,i=4},["ColorCorrectionEffect"]={o=20,i=83},["ColorGradingEffect"]={o=20,i=83},["CompressorSoundEffect"]={o=20,i=84},["ConeHandleAdornment"]={o=205,i=110},["Configuration"]={o=220,i=58},["Constraint"]={o=30,i=86},["ContextActionService"]={o=9999,i=0},["ControlState"]={o=31,i=0},["ControllerManager"]={o=20,i=0},["ControllerPartSensor"]={o=20,i=0},["CoreGui"]={o=30,i=46},["CorePackages"]={o=30,i=20},["CornerWedgePart"]={o=120,i=1},["CustomEvent"]={o=30,i=4},["CustomEventReceiver"]={o=30,i=4},["CylinderHandleAdornment"]={o=205,i=109},["CylinderMesh"]={o=30,i=8},["CylindricalConstraint"]={o=30,i=95},["DataModel"]={o=9999,i=0},["DataModelMesh"]={o=9999,i=0},["DataStoreService"]={o=9999,i=0},["Debris"]={o=9999,i=30},["DebugSettings"]={o=20,i=0},["DebuggerBreakpoint"]={o=9999,i=0},["DebuggerManager"]={o=9999,i=0},["DebuggerWatch"]={o=9999,i=0},["Decal"]={o=40,i=7},["DepthOfFieldEffect"]={o=20,i=83},["Dialog"]={o=220,i=62},["DialogChoice"]={o=220,i=63},["DistortionSoundEffect"]={o=20,i=84},["DoubleConstrainedValue"]={o=30,i=4},["DragDetector"]={o=30,i=41},["EchoSoundEffect"]={o=20,i=84},["EditableMesh"]={o=9999,i=0},["EqualizerSoundEffect"]={o=20,i=84},["Explosion"]={o=30,i=36},["FaceControls"]={o=105,i=129},["FaceInstance"]={o=9999,i=0},["Feature"]={o=20,i=0},["FileMesh"]={o=9999,i=0},["Fire"]={o=30,i=61},["Flag"]={o=30,i=38},["FlagStand"]={o=30,i=39},["FlangeSoundEffect"]={o=20,i=84},["FloorWire"]={o=30,i=4},["FluidForceSensor"]={o=20,i=0},["Folder"]={o=10,i=77},["ForceField"]={o=30,i=37},["Frame"]={o=150,i=48},["FunctionalTest"]={o=10,i=0},["GameSettings"]={o=20,i=0},["GeneratedFolder"]={o=10,i=77},["GlobalDataStore"]={o=-1,i=0},["GlobalSettings"]={o=20,i=0},["Glue"]={o=9999,i=0},["GroundController"]={o=20,i=0},["GuiBase2d"]={o=9999,i=0},["GuiButton"]={o=160,i=52},["GuiMain"]={o=140,i=47},["GuiObject"]={o=9999,i=0},["GuiService"]={o=9999,i=0},["HandRigDescription"]={o=222,i=53},["Handles"]={o=190,i=53},["HapticEffect"]={o=100,i=0},["Hat"]={o=30,i=45},["Highlight"]={o=20,i=133},["HingeConstraint"]={o=30,i=87},["Hint"]={o=110,i=33},["Hole"]={o=20,i=0},["Hopper"]={o=20,i=0},["HopperBin"]={o=240,i=22},["HttpService"]={o=9999,i=0},["Humanoid"]={o=30,i=9},["HumanoidDescription"]={o=22,i=104},["HumanoidRigDescription"]={o=220,i=53},["IKControl"]={o=220,i=53},["ImageButton"]={o=160,i=52},["ImageHandleAdornment"]={o=205,i=108},["ImageLabel"]={o=180,i=49},["InputAction"]={o=31,i=0},["InputActionLabel"]={o=185,i=0},["InputBinding"]={o=31,i=0},["InputContext"]={o=31,i=0},["InputObject"]={o=9999,i=0},["InsertService"]={o=9999,i=0},["Instance"]={o=9999,i=0},["IntConstrainedValue"]={o=30,i=4},["IntValue"]={o=30,i=4},["Item"]={o=20,i=0},["JointInstance"]={o=200,i=34},["JointsService"]={o=9999,i=0},["Keyframe"]={o=220,i=60},["KeyframeMarker"]={o=220,i=60},["LayerCollector"]={o=9999,i=0},["Light"]={o=30,i=13},["Lighting"]={o=30,i=13},["LineForce"]={o=30,i=101},["LineHandleAdornment"]={o=205,i=107},["LinearVelocity"]={o=30,i=132},["LocalBackpack"]={o=9999,i=0},["LocalBackpackItem"]={o=9999,i=0},["LocalScript"]={o=40,i=18},["LocalizationService"]={o=530,i=92},["LocalizationTable"]={o=30,i=97},["LogService"]={o=9999,i=0},["LuaSourceContainer"]={o=9999,i=0},["MakeupDescription"]={o=22,i=104},["MarketplaceService"]={o=9999,i=46},["MaterialService"]={o=30,i=131},["MaterialVariant"]={o=41,i=130},["MeshPart"]={o=105,i=73},["Message"]={o=110,i=33},["Model"]={o=100,i=2},["ModuleScript"]={o=50,i=76},["Motor"]={o=20,i=0},["Motor6D"]={o=200,i=106},["MotorFeature"]={o=9999,i=0},["Mouse"]={o=9999,i=0},["NegateOperation"]={o=104,i=72},["NetworkClient"]={o=30,i=16},["NetworkMarker"]={o=9999,i=0},["NetworkPeer"]={o=9999,i=0},["NetworkReplicator"]={o=30,i=29},["NetworkServer"]={o=30,i=15},["NetworkSettings"]={o=20,i=0},["NoCollisionConstraint"]={o=30,i=105},["NumberPose"]={o=220,i=60},["NumberValue"]={o=30,i=4},["ObjectValue"]={o=30,i=4},["OrderedDataStore"]={o=-1,i=0},["PVInstance"]={o=9999,i=0},["PackageLink"]={o=1,i=98},["Packages"]={o=9999,i=0},["Pants"]={o=20,i=44},["ParallelRampPart"]={o=120,i=1},["Part"]={o=110,i=1},["PartPairLasso"]={o=220,i=57},["ParticleEmitter"]={o=30,i=80},["ParticleEmitter2D"]={o=30,i=80},["Path2D"]={o=31,i=0},["PathfindingLink"]={o=210,i=137},["PathfindingModifier"]={o=210,i=128},["PhysicsActivitySensor"]={o=20,i=0},["PitchShiftSoundEffect"]={o=20,i=84},["Plane"]={o=30,i=134},["PlaneConstraint"]={o=30,i=134},["Platform"]={o=30,i=35},["PlatformLibraries"]={o=30,i=46},["Player"]={o=10,i=12},["PlayerGui"]={o=130,i=46},["PlayerScripts"]={o=130,i=78},["Players"]={o=20,i=21},["Plugin"]={o=30,i=86},["PluginCapabilities"]={o=30,i=0},["PluginDebugService"]={o=30,i=46},["PluginGuiService"]={o=30,i=46},["PluginManager"]={o=9999,i=0},["PluginManagerInterface"]={o=9999,i=0},["PluginMouse"]={o=9999,i=0},["PointLight"]={o=30,i=13},["PointsService"]={o=9999,i=0},["Pose"]={o=220,i=60},["PoseBase"]={o=220,i=60},["Preloaded"]={o=30,i=70},["PrismPart"]={o=120,i=1},["PrismaticConstraint"]={o=30,i=88},["ProceduralModel"]={o=100,i=0},["ProfilingItem"]={o=9999,i=0},["ProximityPrompt"]={o=30,i=124},["ProximityPromptService"]={o=9999,i=0},["PyramidHandleAdornment"]={o=205,i=0},["PyramidPart"]={o=120,i=1},["RayValue"]={o=30,i=4},["RemoteEvent"]={o=50,i=75},["RemoteFunction"]={o=40,i=74},["RenderSettings"]={o=20,i=0},["RenderingTest"]={o=40,i=5},["ReplicatedFirst"]={o=30,i=70},["ReplicatedStorage"]={o=30,i=70},["ReverbSoundEffect"]={o=20,i=84},["RightAngleRampPart"]={o=120,i=1},["RigidConstraint"]={o=30,i=135},["RobloxPluginGuiService"]={o=30,i=46},["RobloxReplicatedStorage"]={o=9999,i=0},["RocketPropulsion"]={o=140,i=14},["RodConstraint"]={o=30,i=90},["RootInstance"]={o=9999,i=0},["RopeConstraint"]={o=30,i=89},["RotateP"]={o=9999,i=0},["RotateV"]={o=9999,i=0},["RunService"]={o=9999,i=0},["ScreenGui"]={o=140,i=47},["Script"]={o=30,i=6},["ScriptContext"]={o=9999,i=0},["ScriptDebugger"]={o=9999,i=0},["ScrollingFrame"]={o=150,i=48},["Seat"]={o=30,i=35},["Selection"]={o=9999,i=0},["SelectionBox"]={o=210,i=54},["SelectionPartLasso"]={o=220,i=57},["SelectionPointLasso"]={o=220,i=57},["SelectionSphere"]={o=210,i=54},["ServerScriptService"]={o=30,i=71},["ServerStorage"]={o=30,i=69},["ServiceProvider"]={o=9999,i=0},["Shirt"]={o=20,i=43},["ShirtGraphic"]={o=20,i=40},["SkateboardPlatform"]={o=30,i=35},["Skin"]={o=20,i=0},["Sky"]={o=5,i=28},["SlidingBallConstraint"]={o=30,i=88},["Smoke"]={o=30,i=59},["Snap"]={o=200,i=34},["Sound"]={o=10,i=11},["SoundGroup"]={o=20,i=85},["SoundService"]={o=500,i=31},["Sparkles"]={o=30,i=42},["SpawnLocation"]={o=30,i=25},["SpecialMesh"]={o=30,i=8},["SphereHandleAdornment"]={o=205,i=112},["SpotLight"]={o=30,i=13},["SpringConstraint"]={o=30,i=91},["StandalonePluginScripts"]={o=130,i=78},["StarterCharacterScripts"]={o=130,i=78},["StarterGear"]={o=30,i=20},["StarterGui"]={o=30,i=46},["StarterPack"]={o=30,i=20},["StarterPlayer"]={o=30,i=79},["StarterPlayerScripts"]={o=130,i=78},["StatsItem"]={o=9999,i=0},["Status"]={o=100,i=2},["StockSound"]={o=-1,i=0},["StringValue"]={o=30,i=4},["Studio"]={o=9999,i=0},["StudioService"]={o=9999,i=0},["StyleBase"]={o=200,i=0},["StyleDerive"]={o=200,i=0},["StyleLink"]={o=200,i=0},["StyleQuery"]={o=200,i=0},["StyleRule"]={o=200,i=0},["StyleSheet"]={o=200,i=0},["SunRaysEffect"]={o=20,i=83},["SurfaceAppearance"]={o=40,i=10},["SurfaceGui"]={o=140,i=64},["SurfaceGuiBase"]={o=140,i=64},["SurfaceLight"]={o=30,i=13},["SurfaceSelection"]={o=210,i=55},["SwimController"]={o=20,i=0},["TaskScheduler"]={o=9999,i=0},["Team"]={o=10,i=24},["Teams"]={o=140,i=23},["TeleportService"]={o=9999,i=0},["Terrain"]={o=5,i=65},["TerrainDetail"]={o=42,i=144},["TerrainRegion"]={o=20,i=65},["TestService"]={o=1000,i=68},["TextBox"]={o=170,i=51},["TextButton"]={o=170,i=51},["TextChannel"]={o=14,i=140},["TextChannelWindow"]={o=16,i=0},["TextChatCommand"]={o=15,i=138},["TextChatService"]={o=511,i=143},["TextDocument"]={o=55,i=6},["TextLabel"]={o=190,i=50},["TextSource"]={o=10,i=139},["Texture"]={o=40,i=10},["Tool"]={o=30,i=17},["Torque"]={o=30,i=103},["TorsionSpringConstraint"]={o=30,i=125},["TouchTransmitter"]={o=30,i=37},["Trail"]={o=30,i=93},["TremoloSoundEffect"]={o=20,i=84},["TriangleMeshPart"]={o=9999,i=0},["TrussPart"]={o=120,i=1},["Tween"]={o=9999,i=0},["TweenBase"]={o=9999,i=0},["TweenService"]={o=9999,i=0},["UIAspectRatioConstraint"]={o=30,i=26},["UICorner"]={o=30,i=26},["UIDragDetector"]={o=30,i=41},["UIFlexItem"]={o=130,i=26},["UIGradient"]={o=30,i=26},["UIGridLayout"]={o=30,i=26},["UIGridStyleLayout"]={o=9999,i=0},["UIListLayout"]={o=30,i=26},["UIPadding"]={o=30,i=26},["UIPageLayout"]={o=30,i=26},["UIScale"]={o=30,i=26},["UIShadow"]={o=30,i=26},["UISizeConstraint"]={o=30,i=26},["UIStroke"]={o=30,i=26},["UITableLayout"]={o=30,i=26},["UITextSizeConstraint"]={o=30,i=26},["UnionOperation"]={o=105,i=73},["UniversalConstraint"]={o=30,i=123},["UnreliableRemoteEvent"]={o=51,i=75},["UserInputService"]={o=9999,i=0},["VRService"]={o=1000,i=0},["ValueBase"]={o=30,i=4},["Vector3Value"]={o=30,i=4},["VectorForce"]={o=30,i=102},["VehicleSeat"]={o=30,i=35},["VelocityMotor"]={o=9999,i=0},["VideoDisplay"]={o=10,i=11},["VideoFrame"]={o=18,i=120},["VideoPlayer"]={o=10,i=11},["ViewportCamera"]={o=5,i=0},["ViewportFrame"]={o=30,i=52},["VoiceChatInternal"]={o=9999,i=0},["VoiceChatService"]={o=520,i=136},["WedgePart"]={o=120,i=1},["Weld"]={o=200,i=34},["WeldConstraint"]={o=30,i=94},["Wire"]={o=10,i=11},["WireframeHandleAdornment"]={o=205,i=113},["Workspace"]={o=5,i=19},["WorldModel"]={o=22,i=19},["WrapDeformer"]={o=32,i=127},["WrapLayer"]={o=32,i=126},["WrapTarget"]={o=32,i=127},["WrapTextureTransfer"]={o=33,i=0},}

		local explorerOn = false
		local selected = nil
		local expanded = { [game] = true }

		local treeConns = {}
		local rowOf = {}

		local function classOrder(className)
			local e = RMD[className]
			return e and e.o or 9999
		end

		-- Dex Vanilla3 class icons (rbxassetid://114851699900089)
		-- 32x32 tiles, 25 columns. Icons dict is 1-based; Display uses 0-based index.
		local ICON_MAP_ID = "rbxassetid://114851699900089"
		local ICON_SIZE = 32
		local ICON_COLS = 25
		local CLASS_ICONS = {["Accessory"]=1,["Accoutrement"]=2,["Actor"]=3,["AdGui"]=4,["AdPortal"]=5,["AdService"]=6,["AdvancedDragger"]=7,["AirController"]=8,["AlignOrientation"]=9,["AlignPosition"]=10,["AnalysticsService"]=11,["AnalysticsSettings"]=12,["AnalyticsService"]=13,["AngularVelocity"]=14,["Animation"]=15,["AnimationClip"]=16,["AnimationClipProvider"]=17,["AnimationController"]=18,["AnimationFromVideoCreatorService"]=19,["AnimationFromVideoCreatorStudioService"]=20,["AnimationRigData"]=21,["AnimationStreamTrack"]=22,["AnimationTrack"]=23,["Animator"]=24,["AppStorageService"]=25,["AppUpdateService"]=26,["ArcHandles"]=27,["AssetCounterService"]=28,["AssetDeliveryProxy"]=29,["AssetImportService"]=30,["AssetImportSession"]=31,["AssetManagerService"]=32,["AssetService"]=33,["AssetSoundEffect"]=34,["Atmosphere"]=35,["Attachment"]=36,["AvatarEditorService"]=37,["AvatarImportService"]=38,["Backpack"]=39,["BackpackItem"]=40,["BadgeService"]=41,["BallSocketConstraint"]=42,["BasePart"]=43,["BasePlayerGui"]=44,["BaseScript"]=45,["BaseWrap"]=46,["Beam"]=47,["BevelMesh"]=48,["BillboardGui"]=49,["BinaryStringValue"]=50,["BindableEvent"]=51,["BindableFunction"]=52,["BlockMesh"]=53,["BloomEffect"]=54,["BlurEffect"]=55,["BodyAngularVelocity"]=56,["BodyColors"]=57,["BodyForce"]=58,["BodyGyro"]=59,["BodyMover"]=60,["BodyPosition"]=61,["BodyThrust"]=62,["BodyVelocity"]=63,["Bone"]=64,["BoolValue"]=65,["BoxHandleAdornment"]=66,["Breakpoint"]=67,["BreakpointManager"]=68,["BrickColorValue"]=69,["BrowserService"]=70,["BubbleChatConfiguration"]=71,["BulkImportService"]=72,["CFrameValue"]=78,["CSGDictionaryService"]=116,["CacheableContentProvider"]=73,["CalloutService"]=74,["Camera"]=75,["CanvasGroup"]=76,["CatalogPages"]=77,["ChangeHistoryService"]=79,["ChannelSelectorSoundEffect"]=80,["CharacterAppearance"]=81,["CharacterMesh"]=82,["Chat"]=83,["ChatInputBarConfiguration"]=84,["ChatWindowConfiguration"]=85,["ChorusSoundEffect"]=86,["ClickDetector"]=87,["ClientReplicator"]=88,["ClimbController"]=89,["Clothing"]=90,["Clouds"]=91,["ClusterPacketCache"]=92,["CollectionService"]=93,["Color3Value"]=94,["ColorCorrectionEffect"]=95,["CommandInstance"]=96,["CommandService"]=97,["CompressorSoundEffect"]=98,["ConeHandleAdornment"]=99,["Configuration"]=100,["ConfigureServerService"]=101,["Constraint"]=102,["ContentProvider"]=103,["ContextActionService"]=104,["Controller"]=105,["ControllerBase"]=106,["ControllerManager"]=107,["ControllerService"]=108,["CookiesService"]=109,["CoreGui"]=110,["CorePackages"]=111,["CoreScript"]=112,["CoreScriptSyncService"]=113,["CornerWedgePart"]=114,["CrossDMScriptChangeListener"]=115,["CurveAnimation"]=117,["CustomEvent"]=118,["CustomEventReceiver"]=119,["CustomSoundEffect"]=120,["CylinderHandleAdornment"]=121,["CylinderMesh"]=122,["CylindricalConstraint"]=123,["DataModel"]=124,["DataModelMesh"]=125,["DataModelPatchService"]=126,["DataModelSession"]=127,["DataStore"]=128,["DataStoreIncrementOptions"]=129,["DataStoreInfo"]=130,["DataStoreKey"]=131,["DataStoreKeyInfo"]=132,["DataStoreKeyPages"]=133,["DataStoreListingPages"]=134,["DataStoreObjectVersionInfo"]=135,["DataStoreOptions"]=136,["DataStorePages"]=137,["DataStoreService"]=138,["DataStoreSetOptions"]=139,["DataStoreVersionPages"]=140,["Debris"]=141,["DebugSettings"]=151,["DebuggablePluginWatcher"]=142,["DebuggerBreakpoint"]=143,["DebuggerConnection"]=144,["DebuggerConnectionManager"]=145,["DebuggerLuaResponse"]=146,["DebuggerManager"]=147,["DebuggerUIService"]=148,["DebuggerVariable"]=149,["DebuggerWatch"]=150,["Decal"]=152,["DepthOfFieldEffect"]=153,["DeviceIdService"]=154,["Dialog"]=155,["DialogChoice"]=156,["DistortionSoundEffect"]=157,["DockWidgetPluginGui"]=158,["DoubleConstrainedValue"]=159,["DraftsService"]=160,["Dragger"]=161,["DraggerService"]=162,["DynamicRotate"]=163,["EchoSoundEffect"]=164,["EmotesPages"]=165,["EqualizerSoundEffect"]=166,["EulerRotationCurve"]=167,["EventIngestService"]=168,["Explosion"]=169,["FaceAnimatorService"]=170,["FaceControls"]=171,["FaceInstance"]=172,["FacialAnimationRecordingService"]=173,["FacialAnimationStreamingService"]=174,["Feature"]=175,["File"]=176,["FileMesh"]=177,["Fire"]=178,["Flag"]=179,["FlagStand"]=180,["FlagStandService"]=181,["FlangeSoundEffect"]=182,["FloatCurve"]=183,["FloorWire"]=184,["FlyweightService"]=185,["Folder"]=186,["ForceField"]=187,["FormFactorPart"]=188,["Frame"]=189,["FriendPages"]=190,["FriendService"]=191,["FunctionalTest"]=192,["GamePassService"]=194,["GameSettings"]=195,["GamepadService"]=193,["GenericSettings"]=196,["Geometry"]=197,["GetTextBoundsParams"]=198,["GlobalDataStore"]=199,["GlobalSettings"]=200,["Glue"]=201,["GoogleAnalyticsConfiguration"]=202,["GroundController"]=203,["GroupService"]=204,["GuiBase"]=205,["GuiBase2d"]=206,["GuiBase3d"]=207,["GuiButton"]=208,["GuiLabel"]=210,["GuiMain"]=211,["GuiObject"]=212,["GuiService"]=213,["GuidRegistryService"]=209,["HSRDataContentProvider"]=227,["HandleAdornment"]=214,["Handles"]=215,["HandlesBase"]=216,["HapticService"]=217,["Hat"]=218,["HeightmapImporterService"]=219,["HiddenSurfaceRemovalAsset"]=220,["Highlight"]=221,["HingeConstraint"]=222,["Hint"]=223,["Hole"]=224,["Hopper"]=225,["HopperBin"]=226,["HttpRbxApiService"]=228,["HttpRequest"]=229,["HttpService"]=230,["Humanoid"]=231,["HumanoidController"]=232,["HumanoidDescription"]=233,["IKControl"]=234,["ILegacyStudioBridge"]=235,["IXPService"]=255,["ImageButton"]=236,["ImageHandleAdornment"]=237,["ImageLabel"]=238,["ImporterAnimationSettings"]=239,["ImporterBaseSettings"]=240,["ImporterFacsSettings"]=241,["ImporterGroupSettings"]=242,["ImporterJointSettings"]=243,["ImporterMaterialSettings"]=244,["ImporterMeshSettings"]=245,["ImporterRootSettings"]=246,["IncrementalPatchBuilder"]=247,["InputObject"]=248,["InsertService"]=249,["Instance"]=250,["InstanceAdornment"]=251,["IntConstrainedValue"]=252,["IntValue"]=253,["InventoryPages"]=254,["JointInstance"]=256,["JointsService"]=257,["KeyboardService"]=258,["Keyframe"]=259,["KeyframeMarker"]=260,["KeyframeSequence"]=261,["KeyframeSequenceProvider"]=262,["LSPFileSyncService"]=280,["LanguageService"]=263,["LayerCollector"]=264,["LegacyStudioBridge"]=265,["Light"]=266,["Lighting"]=267,["LineForce"]=269,["LineHandleAdornment"]=270,["LinearVelocity"]=268,["LocalDebuggerConnection"]=271,["LocalScript"]=274,["LocalStorageService"]=275,["LocalizationService"]=272,["LocalizationTable"]=273,["LodDataEntity"]=276,["LodDataService"]=277,["LogService"]=279,["LoginService"]=278,["LuaSettings"]=281,["LuaSourceContainer"]=282,["LuaWebService"]=284,["LuauScriptAnalyzerService"]=283,["ManualGlue"]=285,["ManualSurfaceJointInstance"]=286,["ManualWeld"]=287,["MarkerCurve"]=288,["MarketplaceService"]=289,["MaterialService"]=290,["MaterialVariant"]=291,["MemStorageConnection"]=295,["MemStorageService"]=296,["MemoryStoreQueue"]=292,["MemoryStoreService"]=293,["MemoryStoreSortedMap"]=294,["MeshContentProvider"]=297,["MeshPart"]=298,["Message"]=299,["MessageBusConnection"]=300,["MessageBusService"]=301,["MessagingService"]=302,["MetaBreakpoint"]=303,["MetaBreakpointContext"]=304,["MetaBreakpointManager"]=305,["Model"]=306,["ModuleScript"]=307,["Motor"]=308,["Motor6D"]=309,["MotorFeature"]=310,["Mouse"]=311,["MouseService"]=312,["MultipleDocumentInterfaceInstance"]=313,["NegateOperation"]=314,["NetworkClient"]=315,["NetworkMarker"]=316,["NetworkPeer"]=317,["NetworkReplicator"]=318,["NetworkServer"]=319,["NetworkSettings"]=320,["NoCollisionConstraint"]=321,["NonReplicatedCSGDictionaryService"]=322,["NotificationService"]=323,["NumberPose"]=324,["NumberValue"]=325,["ObjectValue"]=326,["OrderedDataStore"]=327,["OutfitPages"]=328,["PVAdornment"]=386,["PVInstance"]=387,["PackageLink"]=329,["PackageService"]=330,["PackageUIService"]=331,["Pages"]=332,["Pants"]=333,["ParabolaAdornment"]=334,["Part"]=335,["PartAdornment"]=336,["PartOperation"]=338,["PartOperationAsset"]=339,["ParticleEmitter"]=337,["PatchMapping"]=340,["Path"]=341,["PathfindingLink"]=342,["PathfindingModifier"]=343,["PathfindingService"]=344,["PausedState"]=345,["PausedStateBreakpoint"]=346,["PausedStateException"]=347,["PermissionsService"]=348,["PhysicsService"]=349,["PhysicsSettings"]=350,["PitchShiftSoundEffect"]=351,["Plane"]=352,["PlaneConstraint"]=353,["Platform"]=354,["Player"]=355,["PlayerEmulatorService"]=356,["PlayerGui"]=357,["PlayerMouse"]=358,["PlayerScripts"]=360,["Players"]=359,["Plugin"]=361,["PluginAction"]=362,["PluginDebugService"]=363,["PluginDragEvent"]=364,["PluginGui"]=365,["PluginGuiService"]=366,["PluginManagementService"]=367,["PluginManager"]=368,["PluginManagerInterface"]=369,["PluginMenu"]=370,["PluginMouse"]=371,["PluginPolicyService"]=372,["PluginToolbar"]=373,["PluginToolbarButton"]=374,["PointLight"]=375,["PointsService"]=376,["PolicyService"]=377,["Pose"]=378,["PoseBase"]=379,["PostEffect"]=380,["PrismaticConstraint"]=381,["ProcessInstancePhysicsService"]=382,["ProximityPrompt"]=383,["ProximityPromptService"]=384,["PublishService"]=385,["QWidgetPluginGui"]=388,["RayValue"]=389,["RbxAnalyticsService"]=390,["ReflectionMetadata"]=391,["ReflectionMetadataCallbacks"]=392,["ReflectionMetadataClass"]=393,["ReflectionMetadataClasses"]=394,["ReflectionMetadataEnum"]=395,["ReflectionMetadataEnumItem"]=396,["ReflectionMetadataEnums"]=397,["ReflectionMetadataEvents"]=398,["ReflectionMetadataFunctions"]=399,["ReflectionMetadataItem"]=400,["ReflectionMetadataMember"]=401,["ReflectionMetadataProperties"]=402,["ReflectionMetadataYieldFunctions"]=403,["RemoteDebuggerServer"]=404,["RemoteEvent"]=405,["RemoteFunction"]=406,["RenderSettings"]=408,["RenderingTest"]=407,["ReplicatedFirst"]=409,["ReplicatedStorage"]=410,["ReverbSoundEffect"]=411,["RigidConstraint"]=412,["RobloxPluginGuiService"]=413,["RobloxReplicatedStorage"]=414,["RocketPropulsion"]=415,["RodConstraint"]=416,["RopeConstraint"]=417,["Rotate"]=418,["RotateP"]=419,["RotateV"]=420,["RotationCurve"]=421,["RtMessagingService"]=422,["RunService"]=426,["RunningAverageItemDouble"]=423,["RunningAverageItemInt"]=424,["RunningAverageTimeIntervalItem"]=425,["RuntimeScriptService"]=427,["ScreenGui"]=428,["ScreenshotHud"]=429,["Script"]=430,["ScriptChangeService"]=431,["ScriptCloneWatcher"]=432,["ScriptCloneWatcherHelper"]=433,["ScriptContext"]=434,["ScriptDebugger"]=435,["ScriptDocument"]=436,["ScriptEditorService"]=437,["ScriptRegistrationService"]=438,["ScriptService"]=439,["ScrollingFrame"]=440,["Seat"]=441,["Selection"]=442,["SelectionBox"]=443,["SelectionLasso"]=444,["SelectionPartLasso"]=445,["SelectionPointLasso"]=446,["SelectionSphere"]=447,["ServerReplicator"]=448,["ServerScriptService"]=449,["ServerStorage"]=450,["ServiceProvider"]=451,["SessionService"]=452,["Shirt"]=453,["ShirtGraphic"]=454,["SkateboardController"]=455,["SkateboardPlatform"]=456,["Skin"]=457,["Sky"]=458,["SlidingBallConstraint"]=459,["Smoke"]=460,["Snap"]=461,["SnippetService"]=462,["SocialService"]=463,["SolidModelContentProvider"]=464,["Sound"]=465,["SoundEffect"]=466,["SoundGroup"]=467,["SoundService"]=468,["Sparkles"]=469,["SpawnLocation"]=471,["SpawnerService"]=470,["Speaker"]=472,["SpecialMesh"]=473,["SphereHandleAdornment"]=474,["SpotLight"]=475,["SpringConstraint"]=476,["StackFrame"]=477,["StandalonePluginScripts"]=478,["StandardPages"]=479,["StarterCharacterScripts"]=480,["StarterGear"]=481,["StarterGui"]=482,["StarterPack"]=483,["StarterPlayer"]=484,["StarterPlayerScripts"]=485,["Stats"]=486,["StatsItem"]=487,["Status"]=488,["StopWatchReporter"]=489,["StringValue"]=490,["Studio"]=491,["StudioAssetService"]=492,["StudioData"]=493,["StudioDeviceEmulatorService"]=494,["StudioHighDpiService"]=495,["StudioPublishService"]=496,["StudioScriptDebugEventListener"]=497,["StudioService"]=498,["StudioTheme"]=499,["SunRaysEffect"]=500,["SurfaceAppearance"]=501,["SurfaceGui"]=502,["SurfaceGuiBase"]=503,["SurfaceLight"]=504,["SurfaceSelection"]=505,["SwimController"]=506,["TaskScheduler"]=507,["Team"]=508,["TeamCreateService"]=509,["Teams"]=510,["TeleportAsyncResult"]=511,["TeleportOptions"]=512,["TeleportService"]=513,["TemporaryCageMeshProvider"]=514,["TemporaryScriptService"]=515,["Terrain"]=516,["TerrainDetail"]=517,["TerrainRegion"]=518,["TestService"]=519,["TextBox"]=520,["TextBoxService"]=521,["TextButton"]=522,["TextChannel"]=523,["TextChatCommand"]=524,["TextChatConfigurations"]=525,["TextChatMessage"]=526,["TextChatMessageProperties"]=527,["TextChatService"]=528,["TextFilterResult"]=529,["TextLabel"]=530,["TextService"]=531,["TextSource"]=532,["Texture"]=533,["ThirdPartyUserService"]=534,["ThreadState"]=535,["TimerService"]=536,["ToastNotificationService"]=537,["Tool"]=538,["ToolboxService"]=539,["Torque"]=540,["TorsionSpringConstraint"]=541,["TotalCountTimeIntervalItem"]=542,["TouchInputService"]=543,["TouchTransmitter"]=544,["TracerService"]=545,["TrackerStreamAnimation"]=546,["Trail"]=547,["Translator"]=548,["TremoloSoundEffect"]=549,["TriangleMeshPart"]=550,["TrussPart"]=551,["Tween"]=552,["TweenBase"]=553,["TweenService"]=554,["UGCValidationService"]=555,["UIAspectRatioConstraint"]=556,["UIBase"]=557,["UIComponent"]=558,["UIConstraint"]=559,["UICorner"]=560,["UIGradient"]=561,["UIGridLayout"]=562,["UIGridStyleLayout"]=563,["UILayout"]=564,["UIListLayout"]=565,["UIPadding"]=566,["UIPageLayout"]=567,["UIScale"]=568,["UISizeConstraint"]=569,["UIStroke"]=570,["UITableLayout"]=571,["UITextSizeConstraint"]=572,["UnionOperation"]=573,["UniversalConstraint"]=574,["UnvalidatedAssetService"]=575,["UserGameSettings"]=576,["U.UIS"]=577,["UserService"]=578,["UserSettings"]=579,["UserStorageService"]=580,["VRService"]=600,["ValueBase"]=581,["Vector3Curve"]=582,["Vector3Value"]=583,["VectorForce"]=584,["VehicleController"]=585,["VehicleSeat"]=586,["VelocityMotor"]=587,["VersionControlService"]=588,["VideoCaptureService"]=589,["VideoFrame"]=590,["ViewportFrame"]=591,["VirtualInputManager"]=592,["VirtualUser"]=593,["VisibilityService"]=594,["Visit"]=595,["VoiceChannel"]=596,["VoiceChatInternal"]=597,["VoiceChatService"]=598,["VoiceSource"]=599,["WedgePart"]=601,["Weld"]=602,["WeldConstraint"]=603,["WireframeHandleAdornment"]=604,["Workspace"]=605,["WorldModel"]=606,["WorldRoot"]=607,["WrapLayer"]=608,["WrapTarget"]=609}
		local function applyClassIcon(imageLabel, className)
			local raw = CLASS_ICONS[className]
			if not raw then
				-- try RMD explorer image index as linear fallback on ClassImages
				local e = RMD[className]
				if e and e.i then
					imageLabel.Image = "rbxasset://textures/ClassImages.PNG"
					imageLabel.ImageRectSize = Vector2.new(16, 16)
					imageLabel.ImageRectOffset = Vector2.new(16 * e.i, 0)
					return
				end
				raw = CLASS_ICONS.Folder or 1
			end
			local index = math.max(0, (tonumber(raw) or 1) - 1)
			local col = index % ICON_COLS
			local row = math.floor(index / ICON_COLS)
			-- set rect before and after image to avoid full-sheet flash
			imageLabel.ImageRectSize = Vector2.new(ICON_SIZE, ICON_SIZE)
			imageLabel.ImageRectOffset = Vector2.new(ICON_SIZE * col, ICON_SIZE * row)
			imageLabel.Image = ICON_MAP_ID
			imageLabel.ImageRectSize = Vector2.new(ICON_SIZE, ICON_SIZE)
			imageLabel.ImageRectOffset = Vector2.new(ICON_SIZE * col, ICON_SIZE * row)
		end

		local function nodeSorter(a, b)
			local ao, bo = classOrder(a.ClassName), classOrder(b.ClassName)
			if ao ~= bo then return ao < bo end
			return a.Name:lower() < b.Name:lower()
		end

		local function childrenOf(inst)
			local ok, ch = pcall(function() return inst:GetChildren() end)
			if not ok then return {} end
			table.sort(ch, nodeSorter)
			return ch
		end

		local explList = U.section(page, 1, 1, 2):AddTab("explorer")._content
		local propList = U.section(page, 1, 2, 2):AddTab("properties")._content
		explList.ScrollBarThickness = 0
		explList.ScrollBarImageTransparency = 1
		propList.ScrollBarThickness = 0
		propList.ScrollBarImageTransparency = 1

		local function layoutExplorer()
			if not page or not page.Parent then return end
			local gap = 8
			local topPad = 4
			local frames = {}
			for _, ch in ipairs(page:GetChildren()) do
				if ch:IsA("Frame") and ch:GetAttribute("SectionCol") then
					frames[#frames + 1] = ch
				end
			end
			table.sort(frames, function(a, b)
				return (a:GetAttribute("SectionRow") or 0) < (b:GetAttribute("SectionRow") or 0)
			end)
			local pw = math.max(page.AbsoluteSize.X, panel.AbsoluteSize.X - 4, 200)
			local ph = math.max(page.AbsoluteSize.Y, panel.AbsoluteSize.Y - (U.LINE_H + 24), 200)
			local n = math.max(1, #frames)
			local usable = ph - topPad - gap - gap * (n - 1)
			local h = math.floor(usable / n)
			local y = topPad
			local w = math.max(1, pw - gap * 2)
			for i, ch in ipairs(frames) do
				local hh = h
				if i == n then hh = math.max(1, ph - gap - y) end
				ch.Size = UDim2.fromOffset(w, hh)
				ch.Position = UDim2.fromOffset(gap, y)
				y = y + hh + gap
			end
		end
		task.defer(layoutExplorer)
		panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutExplorer)

		-- clear default padding gap a bit
		for _, list in ipairs({ explList, propList }) do
			for _, ch in ipairs(list:GetChildren()) do
				if ch:IsA("UIPadding") then
					ch.PaddingTop = UDim.new(0, 0)
					ch.PaddingBottom = UDim.new(0, 0)
				elseif ch:IsA("UIListLayout") then
					ch.Padding = UDim.new(0, 0)
				end
			end
		end

		local function disconnectTree(inst)
			local cns = treeConns[inst]
			if cns then
				for _, x in ipairs(cns) do pcall(function() x:Disconnect() end) end
				treeConns[inst] = nil
			end
		end

		local function clearExplorer()
			for inst, row in pairs(rowOf) do
				disconnectTree(inst)
				if row then pcall(function() row:Destroy() end) end
			end
			rowOf = {}
		end

		local function fmt(v)
			local t = typeof(v)
			if t == "Instance" then
				local ok, n = pcall(function() return v:GetFullName() end)
				return ok and n or tostring(v)
			elseif t == "Color3" then
				return string.format("%d, %d, %d", math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5))
			elseif t == "Vector3" then
				return string.format("%.3f, %.3f, %.3f", v.X, v.Y, v.Z)
			elseif t == "Vector2" then
				return string.format("%.3f, %.3f", v.X, v.Y)
			elseif t == "CFrame" then
				local p = v.Position
				return string.format("%.3f, %.3f, %.3f", p.X, p.Y, p.Z)
			elseif t == "UDim2" then
				return string.format("{%.3f, %d}, {%.3f, %d}", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
			elseif t == "UDim" then
				return string.format("%.3f, %d", v.Scale, v.Offset)
			elseif t == "EnumItem" then
				return v.Name
			elseif t == "BrickColor" then
				return v.Name
			elseif t == "boolean" or t == "number" or t == "string" then
				return tostring(v)
			elseif t == "nil" then
				return "nil"
			end
			local ok, s = pcall(tostring, v)
			return ok and s or t
		end

		local function refreshProps()
			for _, ch in ipairs(propList:GetChildren()) do
				if ch:IsA("Frame") or ch:IsA("TextLabel") or ch:IsA("TextButton") then
					ch:Destroy()
				end
			end
			if not selected then return end
			local okAlive, className = pcall(function() return selected.ClassName end)
			if not okAlive then selected = nil return end

			local entries = {}
			local seen = {}
			local function add(k, v)
				if seen[k] then return end
				seen[k] = true
				entries[#entries + 1] = { k, v }
			end

			add("Name", selected.Name)
			add("ClassName", className)
			pcall(function()
				add("Parent", selected.Parent and selected.Parent:GetFullName() or "nil")
			end)

			local got = false
			if type(getproperties) == "function" then
				local ok, list = pcall(getproperties, selected)
				if ok and type(list) == "table" then
					got = true
					local n = 0
					for k, v in pairs(list) do
						local key = tostring(k)
						if key ~= "Name" and key ~= "ClassName" and key ~= "Parent" then
							add(key, v)
							n += 1
							if n > 300 then break end
						end
					end
				end
			end
			if not got then
				for _, n in ipairs({
					"Archivable", "Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow", "Transparency",
					"Reflectance", "Material", "Color", "BrickColor", "Size", "Position", "Orientation", "CFrame",
					"Velocity", "RotVelocity", "Enabled", "Value", "Text", "TextColor3", "TextSize",
					"Image", "ImageColor3", "Visible", "ZIndex", "BackgroundColor3", "BackgroundTransparency",
					"BorderSizePixel", "LayoutOrder", "Health", "MaxHealth", "WalkSpeed", "JumpPower",
					"JumpHeight", "HipHeight", "DisplayName", "UserId", "Brightness", "ClockTime", "Ambient",
					"OutdoorAmbient", "FogEnd", "FogStart", "Volume", "PlaybackSpeed", "Playing",
					"FillColor", "OutlineColor", "FillTransparency", "OutlineTransparency", "DepthMode",
					"Adornee", "AlwaysOnTop", "PrimaryPart", "Massless", "WorldPivot", "MeshId", "TextureId",
					"SoundId", "Source", "Locked", "Shape", "TopSurface", "BottomSurface",
				}) do
					pcall(function()
						local v = selected[n]
						if v ~= nil then add(n, v) end
					end)
				end
			end
			pcall(function()
				for a, v in pairs(selected:GetAttributes()) do
					add("@" .. tostring(a), v)
				end
			end)

			table.sort(entries, function(a, b) return a[1]:lower() < b[1]:lower() end)

			for i, e in ipairs(entries) do
				local row = Instance.new("Frame")
				row.Name = "Prop"
				row.BackgroundTransparency = 1
				row.BorderSizePixel = 0
				row.Size = UDim2.new(1, 0, 0, 15)
				row.LayoutOrder = i
				row.Parent = propList
				local k = Instance.new("TextLabel")
				k.BackgroundTransparency = 1
				k.Size = UDim2.new(0.42, -2, 1, 0)
				k.Position = UDim2.fromOffset(2, 0)
				k.FontFace = U.font
				k.TextSize = U.TEXT_SZ
				k.TextColor3 = Color3.fromRGB(150, 150, 150)
				k.TextXAlignment = Enum.TextXAlignment.Left
				k.TextTruncate = Enum.TextTruncate.AtEnd
				k.Text = e[1]
				k.Parent = row
				local v = Instance.new("TextLabel")
				v.BackgroundTransparency = 1
				v.Size = UDim2.new(0.58, -4, 1, 0)
				v.Position = UDim2.new(0.42, 0, 0, 0)
				v.FontFace = U.font
				v.TextSize = U.TEXT_SZ
				v.TextColor3 = U.theme.Text
				v.TextXAlignment = Enum.TextXAlignment.Left
				v.TextTruncate = Enum.TextTruncate.AtEnd
				v.Text = fmt(e[2])
				v.Parent = row
			end
		end

		local listOrder = 0
		local function buildRow(inst, depth)
			listOrder += 1
			local btn = Instance.new("TextButton")
			btn.AutoButtonColor = false
			btn.BackgroundColor3 = Color3.fromRGB(55, 55, 80)
			btn.BackgroundTransparency = (selected == inst) and 0.45 or 1
			btn.BorderSizePixel = 0
			btn.Size = UDim2.new(1, 0, 0, 16)
			btn.Text = ""
			btn.LayoutOrder = listOrder
			btn.Parent = explList
			rowOf[inst] = btn

			local pad = 2 + depth * 10
			local kids = childrenOf(inst)
			local hasKids = #kids > 0
			local open = expanded[inst] == true

			local arrow = Instance.new("TextLabel")
			arrow.BackgroundTransparency = 1
			arrow.Size = UDim2.fromOffset(10, 16)
			arrow.Position = UDim2.fromOffset(pad, 0)
			arrow.FontFace = U.font
			arrow.TextSize = 10
			arrow.TextColor3 = U.theme.Text
			arrow.Text = hasKids and (open and "-" or "+") or " "
			arrow.Parent = btn

			local icon = Instance.new("ImageLabel")
			icon.BackgroundColor3 = Color3.new(1, 1, 1)
			icon.BackgroundTransparency = 1
			icon.BorderSizePixel = 0
			icon.Size = UDim2.fromOffset(16, 16)
			icon.Position = UDim2.fromOffset(pad + 10, 0)
			icon.ScaleType = Enum.ScaleType.Fit
			icon.ResampleMode = Enum.ResamplerMode.Pixelated
			icon.Parent = btn
			applyClassIcon(icon, inst.ClassName)

			local lab = Instance.new("TextLabel")
			lab.BackgroundTransparency = 1
			lab.Size = UDim2.new(1, -(pad + 28), 1, 0)
			lab.Position = UDim2.fromOffset(pad + 28, 0)
			lab.FontFace = U.font
			lab.TextSize = U.TEXT_SZ
			lab.TextColor3 = U.theme.Text
			lab.TextXAlignment = Enum.TextXAlignment.Left
			lab.TextTruncate = Enum.TextTruncate.AtEnd
			lab.Text = inst.Name
			lab.Parent = btn

			btn.MouseButton1Click:Connect(function()
				if hasKids then
					expanded[inst] = not open
				end
				selected = inst
				rebuildVisible()
				refreshProps()
			end)

			
			if open and hasKids then
				local conns = {}
				conns[#conns + 1] = inst.ChildAdded:Connect(function()
					if explorerOn and expanded[inst] then rebuildVisible() end
				end)
				conns[#conns + 1] = inst.ChildRemoved:Connect(function()
					if explorerOn and expanded[inst] then rebuildVisible() end
				end)
				treeConns[inst] = conns
				for _, ch in ipairs(kids) do
					buildRow(ch, depth + 1)
				end
			end
		end

		function rebuildVisible()
			if not explorerOn then return end
			clearExplorer()
			listOrder = 0
			buildRow(game, 0)
		end

		U._setExplorerVisible = function(on)
			explorerOn = on == true
			if U.explorerPanel then
				U.explorerPanel.Visible = explorerOn
			end
			if explorerOn then
				rebuildVisible()
				if selected then refreshProps() end
			else
				for inst in pairs(treeConns) do disconnectTree(inst) end
				clearExplorer()
			end
		end
		-- honor current flag if settings already created the toggle
		if U.vflags and U.vflags.Explorer == true then
			U._setExplorerVisible(true)
		end
end

function Library:CreateWindow(opts)
	opts = opts or {}
	local name = tostring(opts.Name or "wavelength")
	U.windowTitle = name
	if opts.Width then U.BODY_W = opts.Width end
	if opts.Height then U.BODY_H = opts.Height end
	U.bottomBarOn = opts.BottomBar == true
	if opts.BottomBarText ~= nil then
		U.bottomBarText = tostring(opts.BottomBarText)
	end
	if type(opts.Tabs) == "table" and #opts.Tabs > 0 then
		U.TAB_NAMES = {}
		for _, t in ipairs(opts.Tabs) do
			local n = string.lower(tostring(t))
			if n ~= "explorer" then
				U.TAB_NAMES[#U.TAB_NAMES + 1] = n
			end
		end
	end

	U._shuttingDown, U.running, U.menuOpen = false, true, true
	U.gen = (U.gen or 0) + 1
	U.hideTooltip()
	if U.tooltipGui then pcall(function() U.tooltipGui:Destroy() end) U.tooltipGui, U.tooltipFrame = nil, nil end
	for _, c in ipairs(U._conns or {}) do pcall(function() c:Disconnect() end) end
	U._conns = {}
	if U.bindTooltipFollow then U.bindTooltipFollow() end
	if U.kbPanel then pcall(function() U.kbPanel:Destroy() end) end
	U.keybindTargets, U.keybindListEntries, U._kbListen, U.flagListeners, U.setters, U.pulseReg = {}, {}, {}, {}, {}, {}
	U.subGroups, U.toggleRows, U._subFade, U.subBusy, U.subPending, U._subAnimConns = {}, {}, {}, {}, {}, {}
	U.themeReg = U.newReg()
	U.openColorPicker, U.openDropdown, U.openDropdownBox, U.openSettings = nil, nil, nil, nil
	U.wm, U.kbPanel, U.wmSnapGhost, U.kbSnapGhost = nil, nil, nil, nil
	U.wmDocked, U.kbDocked = true, true
	Library.Setters = U.setters

	if U.gui then pcall(function() U.gui:Destroy() end) U.gui = nil end
	U.buildShell()
	local win = setmetatable({ _pages = {}, _sections = {}, _order = {} }, { __index = Library })
	for _, n in ipairs(U.TAB_NAMES) do
		win._pages[n] = U.pageFrames[n]
		win._order[n] = 0
	end

	function win:AddTab(tabName)
		tabName = string.lower(tostring(tabName))
		if not U.pageFrames[tabName] then
			U.TAB_NAMES[#U.TAB_NAMES + 1] = tabName
			U.pageFrames[tabName] = U.new("Frame", { Name = tabName, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = not U.currentTab }, U.pages)
			U.currentTab = U.currentTab or tabName
		end
		self._pages[tabName] = U.pageFrames[tabName]
		self._order[tabName] = self._order[tabName] or 0

		local tab = { Name = tabName, Window = self }
		function tab:AddSection(a, b, c, d)
			local sectionName, side, row, rows
			if type(a) == "number" then
				side, row, rows = a, b, c
			else
				sectionName, side, row, rows = a, b, c, d
			end
			side = side or 1
			self._colCount = self._colCount or { [1] = 0, [2] = 0 }
			if not row then
				self._colCount[side] = (self._colCount[side] or 0) + 1
				row = self._colCount[side]
			else
				self._colCount[side] = math.max(self._colCount[side] or 0, row)
			end
			rows = rows or self._colCount[side]

			local parent = U.pageFrames[tabName]
			local sec = U.section(parent, side, row, rows)
			U.relayoutColumn(parent, side)

			if sectionName then
				return sec:AddTab(string.lower(tostring(sectionName)))
			end
			return sec
		end
		return tab
	end

	function win:AddSettingsTab()
		if not U.pageFrames.config then self:AddTab("config") end
		U.buildConfig()
		return self
	end
	function win:AddExplorerTab()
		-- explorer is a floating window toggled from settings; keep API for compatibility
		U.buildExplorer()
		return self
	end
	function win:SetBottomBar(on, text)
		U.setBottomBar(on, text)
		return self
	end
	function win:Init()
		U.buildTabs()
		U.bindInput()
		U.layoutBottomBar()
	end
	function win:Unload() U.shutdown() end
	return win
end

return Library
