local Library = (function()
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
	Text = Color3.fromRGB(235, 235, 235),
	Border = Color3.fromRGB(0, 0, 0),
	SectionBorder = Color3.fromRGB(0, 0, 0),
	ElementBorder = Color3.fromRGB(0, 0, 0),
	Accent1 = Color3.fromRGB(255, 255, 255),
	Accent2 = Color3.fromRGB(0, 0, 0),
	Background = Color3.fromRGB(36, 36, 36),
	SectionBg = Color3.fromRGB(18, 18, 18),
}
U.theme.ElementBorder = U.theme.ElementBorder or U.theme.SectionBorder
U.THEME_KEYS = {
	ThemeText = "Text", ThemeBorder = "Border", ThemeSectionBorder = "SectionBorder", ThemeElementBorder = "ElementBorder",
	ThemeBackground = "Background", ThemeSectionBg = "SectionBg", ThemeAccent1 = "Accent1", ThemeAccent2 = "Accent2",
}

function U.newReg()
	return { accents = {}, borders = {}, sectionBorders = {}, elementBorders = {}, sectionBgs = {}, bodyBgs = {}, tabAccents = {} }
end
U.themeReg = U.themeReg or U.newReg()
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
U.BODY_W, U.BODY_H, U.TITLE_H, U.SEC_GAP = 560, 360, 22, 8
U.TAB_NAMES = { "combat", "visuals", "misc", "config" }
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
	local o = outward and thick or 0
	local function edge(name, size, pos)
		local e = U.new("Frame", {
			Name = name, BorderSizePixel = 0, BackgroundColor3 = U.theme.ElementBorder, Size = size, Position = pos, ZIndex = z or (parent.ZIndex + 2),
		}, parent)
		local reg = U.themeReg.elementBorders
		reg[#reg + 1] = e
	end
	if not noTop then edge("BTop", UDim2.new(1, o * 2, 0, thick), UDim2.fromOffset(-o, -o)) end
	edge("BBottom", UDim2.new(1, o * 2, 0, thick), outward and UDim2.new(0, -o, 1, 0) or UDim2.new(0, 0, 1, -thick))
	edge("BLeft", UDim2.new(0, thick, 1, 0), UDim2.fromOffset(-o, 0))
	edge("BRight", UDim2.new(0, thick, 1, 0), outward and UDim2.new(1, 0, 0, 0) or UDim2.new(1, -thick, 0, 0))
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

U.cycle = U.cycle or { hue = 0, alpha = 0, colorFlags = {}, alphaFlags = {}, step = 0.01, alphaBreak = nil, alphaBreakMarkers = {} }

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

function U.setAlphaBreak(rel)
	local c = U.cycle
	c.alphaBreak = rel ~= nil and math.clamp(tonumber(rel) or 0, 0, 1) or nil
	for i = #c.alphaBreakMarkers, 1, -1 do
		local m = c.alphaBreakMarkers[i]
		if not m.Parent then
			table.remove(c.alphaBreakMarkers, i)
		else
			m.Visible = c.alphaBreak ~= nil
			if m.Visible then m.Position = UDim2.new(c.alphaBreak, 0, 0.5, 0) end
		end
	end
end

function U.registerAlphaBreakMarker(marker)
	table.insert(U.cycle.alphaBreakMarkers, marker)
	U.setAlphaBreak(U.cycle.alphaBreak)
end

function U.setCycleAlpha(flagKey, on)
	U.cycle.alphaFlags[flagKey] = on or nil
	if on then U.vflags[flagKey .. "Transparency"] = U.cycle.alpha end
	U.vflags[flagKey .. "CycleAlpha"] = on and true or false
end

task.spawn(function()
	local c = U.cycle
	while alive() do
		local anyC, anyA = next(c.colorFlags) ~= nil, next(c.alphaFlags) ~= nil
		if anyC then
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
		if anyA then
			c.alphaDir = c.alphaDir or 1
			local maxA = math.clamp(typeof(c.alphaBreak) == "number" and c.alphaBreak or 1, 0.05, 1)
			c.alpha += c.step * c.alphaDir
			if c.alpha >= maxA then c.alpha, c.alphaDir = maxA, -1
			elseif c.alpha <= 0 then c.alpha, c.alphaDir = 0, 1 end
			for flagKey in pairs(c.alphaFlags) do
				local k = flagKey .. "Transparency"
				U.vflags[k] = c.alpha
				if U.setters[k] then U.setters[k](c.alpha) end
				if U.openPickerRefresh and U.openColorPicker and U.openColorPicker:GetAttribute("Flag") == flagKey then U.openPickerRefresh() end
			end
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
			if i.Name == "WavelengthCredit" then i.TextColor3 = gray
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
	pcall(function() U.Run:UnbindFromRenderStep("SM_ESP") end)
	for _, fn in ipairs({ "_cleanupVisuals", "_cleanupCombat", "_cleanupMisc" }) do
		if type(U[fn]) == "function" then pcall(U[fn]) end
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

function U.armPopupOpen() U.suppressPopupClose = tick() + 0.08 end

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
	return U.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = order or 0 }, parent)
end

function U.indentRow(r, px)
	local pad = r:FindFirstChildOfClass("UIPadding") or U.new("UIPadding", {}, r)
	pad.PaddingLeft = UDim.new(0, px or 12)
	return r
end

function U.subIf(control, keys, pred)
	U.indentRow(control, 12)
	local function sync()
		local vis = pred() and true or false
		if control.Visible ~= vis then
			control.Visible = vis
			if U.closeDropdown then U.closeDropdown() end
			if U.closeColorPicker then U.closeColorPicker() end
		else
			control.Visible = vis
		end
	end
	for _, k in ipairs(keys) do U.onFlag(k, sync) end
	sync()
	return control
end

function U.subOf(control, parentFlag)
	return U.subIf(control, { parentFlag }, function() return U.vflags[parentFlag] == true end)
end

function U.secGeom(col, row, rows)
	local w = math.floor((U.BODY_W - U.SEC_GAP * 3) / 2)
	local x = (col == 1) and U.SEC_GAP or (U.SEC_GAP * 2 + w)
	local h = math.floor((U.BODY_H - U.SEC_GAP * 2 - U.SEC_GAP * (rows - 1)) / rows)
	return x, U.SEC_GAP + (row - 1) * (h + U.SEC_GAP), w, h
end

function U.section(parent, title, col, row, rows)
	local x, y, w, h = U.secGeom(col, row or 1, rows or 1)
	local f = U.new("Frame", { BackgroundColor3 = U.theme.SectionBg, BorderSizePixel = 0, Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y) }, parent)
	table.insert(U.themeReg.sectionBgs, f)
	U.stroke(f, "SectionBorder")
	title = tostring(title)
	U.label(f, title, {
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(math.max(40, #title * 7 + 12), 14), ZIndex = 5,
	})
	local content = U.new("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -10, 1, -16), Position = UDim2.fromOffset(5, 12), ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
	}, f)
	U.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, content)
	U.new("UIPadding", { PaddingLeft = UDim.new(0, 1), PaddingRight = UDim.new(0, 1), PaddingTop = UDim.new(0, 1), PaddingBottom = UDim.new(0, 2) }, content)
	content:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if U.closeDropdown then U.closeDropdown() end
		if U.closeColorPicker then U.closeColorPicker() end
	end)
	return content
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

	local box = U.new("Frame", { Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(0, 3), BackgroundColor3 = col(), BorderSizePixel = 0 }, r)
	U.controlStroke(box)
	U.registerPulse(box, function() return on end)
	U.label(r, text, { Size = UDim2.new(1, -(20 + reserve), 1, 0), Position = UDim2.fromOffset(18, 0) })

	local function set(v)
		on = v == true
		box.BackgroundColor3 = col()
		if flag then U.setFlag(flag, on) end
	end
	U.new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, -reserve, 1, 0), Text = "", ZIndex = 2 }, r).MouseButton1Click:Connect(function() set(not on) end)
	if flag then
		U.setters[flag] = set
		if kb then U.attachKeybind(r, flag, kb.key, kb.text ~= "" and kb.text or text) end
	end
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
	r.Size = UDim2.new(1, 0, 0, 30)
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
		local w, h = math.max(2, track.AbsoluteSize.X), math.max(2, track.AbsoluteSize.Y)
		local fw = math.floor(w * t + 0.5)
		fill.Position = UDim2.fromOffset(0, 0)
		fill.Size = UDim2.fromOffset(fw, h)
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
		local w, h = math.max(2, track.AbsoluteSize.X), math.max(2, track.AbsoluteSize.Y)
		local x0, x1 = math.floor(w * (a - minV) / span + 0.5), math.floor(w * (b - minV) / span + 0.5)
		fill.Position, fill.Size = UDim2.fromOffset(x0, 0), UDim2.fromOffset(math.max(0, x1 - x0), h)
		val.Text = U.formatSliderVal(a, step, "", maxV, false) .. " - " .. U.formatSliderVal(b, step, suffix, maxV, infAtMax)
	end
	refresh()

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
	r.Size = UDim2.new(1, 0, 0, 36)
	options = options or {}
	limit = math.max(1, math.floor(tonumber(limit or (multi and 999 or 1)) or 1))
	multi = limit > 1
	if multi then
		local d = type(default) == "table" and default or (default ~= nil and { default } or {})
		while #d > limit do table.remove(d, 1) end
		U.vflags[flag] = d
	else
		U.vflags[flag] = type(default) == "table" and default[1] or default
	end

	U.label(r, text, { Size = UDim2.new(1, 0, 0, 12) })
	local box = U.new("TextButton", {
		Name = "DropBox", AutoButtonColor = false, BackgroundColor3 = DD_BG, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 14), FontFace = U.font, TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
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
		local fullH = math.min(#options * 18, 140)
		local boxW = math.floor(box.AbsoluteSize.X + 0.5)
		local ebPx = math.floor(eb + 0.5)
		local width = boxW + ebPx * 2
		local px = math.floor(box.AbsolutePosition.X - U.gui.AbsolutePosition.X + 0.5) - ebPx
		local py = math.floor(box.AbsolutePosition.Y - U.gui.AbsolutePosition.Y + box.AbsoluteSize.Y + 0.5)
		local bb = box:FindFirstChild("BBottom")
		if bb then bb.Visible = false end

		local list = U.new("Frame", {
			Name = "DropdownList", BackgroundColor3 = DD_BG, BorderSizePixel = 0, ClipsDescendants = true,
			Size = UDim2.fromOffset(width, 0), Position = UDim2.fromOffset(px, py), ZIndex = 220,
		}, U.gui)
		list:SetAttribute("Flag", flag)
		local holder = U.new("Frame", {
			BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = false,
			Size = UDim2.fromOffset(width, fullH), Position = UDim2.fromOffset(0, 0), ZIndex = 221,
		}, list)
		U.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, holder)
		U.edges(list, eb, false, 223, true)

		for _, opt in ipairs(options) do
			local b = U.new("TextButton", {
				AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 18), FontFace = U.font, TextSize = U.TEXT_SZ,
				TextColor3 = U.theme.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(opt), ZIndex = 222,
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
						while #cur > limit do table.remove(cur, 1) end
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
		U.Tween:Create(list, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(width, fullH) }):Play()
	end)
	U.setters[flag] = function(v)
		if multi and type(v) == "table" then
			v = table.clone(v)
			while #v > limit do table.remove(v, 1) end
		end
		U.vflags[flag] = v
		display()
		U.fireFlag(flag)
	end
	return r
end

function U.mkTextbox(parent, text, flag, placeholder, order, tooltip)
	local r = U.row(parent, order)
	U.bindTooltip(r, tooltip)
	r.Size = UDim2.new(1, 0, 0, 36)
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

function U.attachPicker(rowFrame, flagKey, defaultColor, noAlpha, title)
	title = string.lower(tostring(title or "color"))
	local alphaKey = flagKey .. "Transparency"
	U.vflags[flagKey] = defaultColor
	if not noAlpha then U.vflags[alphaKey] = 0 end
	local h, sat, val = defaultColor:ToHSV()

	local rightPad = rowFrame:GetAttribute("RightPad") or 2
	rowFrame:SetAttribute("RightPad", rightPad + 26 + 4 + 2)
	local sw = U.new("TextButton", {
		Name = "Swatch", AutoButtonColor = false, Text = "", Size = UDim2.fromOffset(26, 13), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -rightPad, 0.5, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12,
	}, rowFrame)
	U.controlStroke(sw)
	local swFill = U.new("Frame", {
		Name = "SwatchFill", BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), BackgroundColor3 = defaultColor, ZIndex = 13,
		BackgroundTransparency = noAlpha and 0 or (U.vflags[alphaKey] or 0),
	}, sw)

	local function refreshOpen()
		if U.openPickerRefresh and U.openColorPicker and U.openColorPicker:GetAttribute("Flag") == flagKey then U.openPickerRefresh() end
	end
	local function paint()
		local c = Color3.fromHSV(h, sat, val)
		U.vflags[flagKey], swFill.BackgroundColor3 = c, c
		swFill.BackgroundTransparency = noAlpha and 0 or (U.vflags[alphaKey] or 0)
		local tk = U.THEME_KEYS[flagKey]
		if tk then U.theme[tk] = c U.applyTheme() end
	end
	local function apply()
		paint()
		U.fireFlag(flagKey)
	end
	U.setters[flagKey] = function(v)
		if typeof(v) ~= "Color3" then return end
		h, sat, val = v:ToHSV()
		paint()
		refreshOpen()
		U.fireFlag(flagKey)
	end
	if not noAlpha then
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

		local MAP, BAR_H, PAD, TITLE, TOG, GAP = 120, 12, 8, 16, 14, 6
		local mapY = PAD + TITLE
		local hueY = mapY + MAP + 6
		local alphaY = hueY + BAR_H + 6
		local POP_W = PAD + MAP + GAP + TOG + PAD
		local RGB_H = 16
		local POP_H = PAD + TITLE + MAP + 6 + BAR_H + (noAlpha and 0 or (6 + BAR_H)) + 6 + RGB_H + PAD

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

		local hueBar = btn("ImageButton", { Size = UDim2.fromOffset(MAP, BAR_H), Position = UDim2.fromOffset(PAD, hueY), BackgroundColor3 = Color3.new(1, 1, 1) })
		U.controlStroke(hueBar)
		local hueKeys = {}
		for i, c in ipairs({ { 0, 0 }, { 0.17, 60 }, { 0.33, 120 }, { 0.5, 180 }, { 0.67, 240 }, { 0.83, 300 }, { 1, 0 } }) do
			hueKeys[i] = ColorSequenceKeypoint.new(c[1], Color3.fromHSV(c[2] / 360, 1, 1))
		end
		U.new("UIGradient", { Color = ColorSequence.new(hueKeys) }, hueBar)
		local hueDot = marker(hueBar, UDim2.fromOffset(2, BAR_H + 4), 223, UDim2.new(h, 0, 0.5, 0))

		local refreshUI
		local function cycleBtn(name, key, y, onToggle)
			local b = btn("TextButton", {
				Name = name, Text = "", Size = UDim2.fromOffset(TOG, TOG), Position = UDim2.fromOffset(PAD + MAP + GAP, y + (BAR_H - TOG) / 2),
				BackgroundColor3 = U.vflags[flagKey .. key] and U.pulseColor() or U.OFF,
			})
			U.controlStroke(b)
			U.registerPulse(b, function() return U.vflags[flagKey .. key] == true end)
			b.MouseButton1Click:Connect(function()
				local on = U.vflags[flagKey .. key] ~= true
				onToggle(on)
				b.BackgroundColor3 = on and U.pulseColor() or U.OFF
				refreshUI()
			end)
		end
		cycleBtn("CycleColor", "CycleColor", hueY, function(on)
			U.setCycleColor(flagKey, on)
			if on then h = U.cycle.hue apply() end
		end)

		local alphaBar, alphaDot
		if not noAlpha then
			alphaBar = btn("ImageButton", { Size = UDim2.fromOffset(MAP, BAR_H), Position = UDim2.fromOffset(PAD, alphaY), BackgroundColor3 = Color3.fromHSV(h, sat, val) })
			U.controlStroke(alphaBar)
			U.new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, alphaBar)
			alphaDot = marker(alphaBar, UDim2.fromOffset(2, BAR_H + 4), 223, UDim2.new(U.vflags[alphaKey] or 0, 0, 0.5, 0))
			local breakLine = U.new("Frame", {
				Name = "AlphaBreak", Size = UDim2.fromOffset(2, BAR_H + 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(U.cycle.alphaBreak or 0, 0, 0.5, 0),
				BackgroundColor3 = Color3.fromRGB(220, 40, 40), BorderSizePixel = 0, ZIndex = 224, Visible = U.cycle.alphaBreak ~= nil,
			}, alphaBar)
			U.registerAlphaBreakMarker(breakLine)
			alphaBar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton2 then
					U.setAlphaBreak(U.cycle.alphaBreak == nil and relX(alphaBar, input.Position.X) or nil)
				end
			end)
			cycleBtn("CycleAlpha", "CycleAlpha", alphaY, function(on)
				U.setCycleAlpha(flagKey, on)
				if on then U.vflags[alphaKey] = U.cycle.alpha end
			end)
		end

		local rgbY = (noAlpha and hueY or alphaY) + BAR_H + 6
		local rgbW = MAP + GAP + TOG
		local rgbBox = U.new("Frame", {
			BackgroundColor3 = Color3.fromRGB(18, 18, 18), BorderSizePixel = 0,
			Size = UDim2.fromOffset(rgbW, RGB_H), Position = UDim2.fromOffset(PAD, rgbY), ZIndex = 221,
		}, pop)
		U.controlStroke(rgbBox)
		local rgbText = U.label(rgbBox, "", {
			Position = UDim2.fromOffset(4, 0), Size = UDim2.new(1, -6, 1, 0),
			TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 222,
		})
		local function syncRgbText()
			local c = Color3.fromHSV(h, sat, val)
			local r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
			if noAlpha then
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
				alphaDot.Position = UDim2.new(U.vflags[alphaKey] or 0, 0, 0.5, 0)
			end
			syncRgbText()
		end
		U.openPickerRefresh = refreshUI
		pop.Destroying:Connect(function()
			if U.openPickerRefresh == refreshUI then U.openPickerRefresh = nil end
		end)

		local drag
		local function move(pos)
			if drag == "map" then
				sat = relX(map, pos.X)
				val = 1 - math.clamp((pos.Y - map.AbsolutePosition.Y) / math.max(map.AbsoluteSize.Y, 1), 0, 1)
			elseif drag == "hue" then
				h = relX(hueBar, pos.X)
			elseif drag == "alpha" and alphaBar then
				U.vflags[alphaKey] = relX(alphaBar, pos.X)
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
		if U.vflags[flagKey .. "CycleAlpha"] then U.vflags[alphaKey] = U.cycle.alpha end
		U.openColorPicker = pop
		U.armPopupOpen()
		refreshUI()
	end)
	return sw
end

function U.buildShell()
	local TAB_W = math.floor(U.BODY_W / math.max(1, #U.TAB_NAMES))
	U.TAB_W, U.TAB_H = TAB_W, 32
	U.gui = U.new("ScreenGui", { Name = "wavelength", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true }, U.guiParent())

	local shell = U.new("Frame", {
		Name = "Shell", BackgroundColor3 = Color3.fromRGB(28, 28, 28), BorderSizePixel = 0, ClipsDescendants = true, Active = true,
		Size = UDim2.fromOffset(U.BODY_W, U.TITLE_H + U.BODY_H + U.LINE_H), Position = UDim2.new(0.5, -U.BODY_W / 2, 0.5, -(U.TITLE_H + U.BODY_H) / 2),
	}, U.gui)
	U.shell = shell
	U.stroke(shell, "Border")

	U.accent = U.new("Frame", { Name = "Accent", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, U.LINE_H), ZIndex = 5 }, shell)
	table.insert(U.themeReg.accents, U.new("UIGradient", { Color = U.accentSequence() }, U.accent))

	U.titleBar = U.new("Frame", {
		BackgroundColor3 = Color3.fromRGB(28, 28, 28), BorderSizePixel = 0, Active = true, Size = UDim2.new(1, 0, 0, U.TITLE_H), Position = UDim2.fromOffset(0, U.LINE_H),
	}, shell)
	U.label(U.titleBar, "wavelength", { Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(8, 0) })

	U.body = U.new("Frame", {
		Name = "Body", BackgroundColor3 = U.theme.Background, BorderSizePixel = 0, Size = UDim2.fromOffset(U.BODY_W, U.BODY_H),
		Position = UDim2.fromOffset(0, U.TITLE_H + U.LINE_H), ClipsDescendants = true, Active = true,
	}, shell)
	table.insert(U.themeReg.bodyBgs, U.body)
	U.pages = U.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, U.body)

	U.pageFrames = {}
	for i, n in ipairs(U.TAB_NAMES) do
		U.pageFrames[n] = U.new("Frame", { Name = n, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = i == 1 }, U.pages)
	end
	U.currentTab = U.TAB_NAMES[1]
end

local function panelOf(kind) return kind == "wm" and U.wm or U.kbPanel end
local function flagOf(kind) return kind == "wm" and "Watermark" or "KeybindsList" end

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
	if not U[kind .. "Docked"] or not f or not f.Parent or not U.shell or U.vflags[flagOf(kind)] ~= true then return end
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
	if U.menuOpen == false then return U.hideSnapGhost("wm"), U.hideSnapGhost("kb") end
	U.ensureSnapGhosts()
	local f, g = panelOf(kind), U[kind .. "SnapGhost"]
	if not U.shell or not f then return end
	g.Size = UDim2.fromOffset(math.max(2, f.Size.X.Offset), panelH(f))
	g.AnchorPoint, g.Position = U.dockPos(kind, panelH(f))
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
	local cx, cy = fp.X + fs.X * 0.5, fp.Y + fs.Y * 0.5
	return cx >= gp.X and cx <= gp.X + gs.X and cy >= gp.Y and cy <= gp.Y + gs.Y
end

function U.syncFloatingVisibility()
	local menuOn = U.menuOpen ~= false
	if U.shell then U.shell.Visible = menuOn end
	for _, kind in ipairs({ "wm", "kb" }) do
		local f = panelOf(kind)
		if f then f.Visible = U.vflags[flagOf(kind)] == true and (menuOn or not U[kind .. "Docked"]) end
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
		local ok, v = pcall(function() return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
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
		data.__alphaBreak = U.cycle.alphaBreak or false
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
		if type(data.__alphaBreak) == "number" then U.setAlphaBreak(data.__alphaBreak)
		elseif data.__alphaBreak == false then U.setAlphaBreak(nil) end

		U.cycle.colorFlags, U.cycle.alphaFlags = {}, {}
		for k, v in pairs(U.vflags) do
			if type(k) == "string" and v == true then
				if k:sub(-10) == "CycleColor" then U.setCycleColor(k:sub(1, -11), true)
				elseif k:sub(-10) == "CycleAlpha" then U.setCycleAlpha(k:sub(1, -11), true) end
			end
		end
		U.applyTheme()
		U.dock("wm")
		U.dock("kb")
		U.syncFloatingVisibility()
		U.refreshKeybindList()
	end

	local p = U.pageFrames.config
	local configsSec, settingsSec = U.section(p, "configs", 1), U.section(p, "settings", 2)
	local function note(t) U.pushNotification({ text = t, time = 2 }) end
	local path = function(n) return FOLDER .. "/" .. n .. ".json" end

	U.mkTextbox(configsSec, "name", "ConfigName", "config name", 1)
	U.mkButton(configsSec, "create / save", 2).MouseButton1Click:Connect(function()
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
	U.mkButton(configsSec, "load", 3).MouseButton1Click:Connect(function()
		if not selected then return note("select a config first") end
		local ok, data = pcall(function() return U.Http:JSONDecode(readfile(path(selected))) end)
		if ok and type(data) == "table" then
			applyData(data)
			note('loaded "' .. selected .. '" config')
		else
			note("load failed")
		end
	end)
	U.mkButton(configsSec, "delete", 4).MouseButton1Click:Connect(function()
		if not selected then return note("select a config first") end
		local name = selected
		pcall(function() delfile(path(name)) end)
		selected = nil
		refreshList()
		note('deleted "' .. name .. '" config')
	end)

	U.label(configsSec, "saved", { Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 5 })
	local listBox = U.new("Frame", { BackgroundColor3 = Color3.fromRGB(14, 14, 14), BorderSizePixel = 0, ClipsDescendants = true, Size = UDim2.new(1, 0, 0, 120), LayoutOrder = 6 }, configsSec)
	U.edges(listBox, U.ELEMENT_BORDER, false, 3)
	listFrame = U.new("ScrollingFrame", {
		Name = "Inner", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -4, 1, -4), Position = UDim2.fromOffset(2, 2),
		ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ClipsDescendants = true,
	}, listBox)
	U.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, listFrame)
	refreshList()

	local o = 0
	local function nextOrder() o += 1 return o end
	local function themeRow(label, flag, key, title)
		return U.attachPicker(U.mkColorRow(settingsSec, label, nextOrder()), flag, U.theme[key], true, title or label)
	end
	themeRow("text", "ThemeText", "Text", "text color")
	themeRow("border", "ThemeBorder", "Border", "border color")
	themeRow("section border", "ThemeSectionBorder", "SectionBorder")
	themeRow("element border", "ThemeElementBorder", "ElementBorder")
	themeRow("section background", "ThemeSectionBg", "SectionBg")
	themeRow("background", "ThemeBackground", "Background")
	local accentRow = U.mkColorRow(settingsSec, "accent", nextOrder())
	U.attachPicker(accentRow, "ThemeAccent1", U.theme.Accent1, true, "accent a")
	U.attachPicker(accentRow, "ThemeAccent2", U.theme.Accent2, true, "accent b")
	U.mkKeybind(settingsSec, "menu keybind", "MenuKeybind", Enum.KeyCode.RightShift, nextOrder())
	U.mkDropdown(settingsSec, "notification position", "NotificationPosition", { "top left", "top right", "bottom left", "bottom right", "center" }, "center", false, nextOrder())

	U.mkToggle(settingsSec, "watermark", "Watermark", nextOrder(), false)
	U.subOf(U.mkDropdown(settingsSec, "items", "WatermarkItems", { "ping", "fps", "message" }, { "ping", "fps" }, true, nextOrder()), "Watermark")
	local msgBox = U.mkTextbox(settingsSec, "message", "WatermarkMessage", "message", nextOrder())
	U.indentRow(msgBox, 12)
	local function syncMsg()
		msgBox.Visible = U.vflags.Watermark == true and table.find(U.vflags.WatermarkItems or {}, "message") ~= nil
	end
	U.onFlag("Watermark", syncMsg)
	U.onFlag("WatermarkItems", syncMsg)
	syncMsg()
	U.mkToggle(settingsSec, "keybinds", "KeybindsList", nextOrder(), false)
	U.mkToggle(settingsSec, "tooltips", "Tooltips", nextOrder(), true)
	U.onFlag("Tooltips", function() if U.vflags.Tooltips == false then U.hideTooltip() end end)
	U.mkToggle(settingsSec, "preview", "Preview", nextOrder(), true)

	U.buildFloaters()

	local unload = U.mkButton(settingsSec, "unload", nextOrder(), true)
	U.bindButton(unload, U.shutdown, 2)

	local credit = U.label(configsSec.Parent, "wavelength ui by @illorsm", {
		Name = "WavelengthCredit", Size = UDim2.new(1, -8, 0, 14), Position = UDim2.new(0, 4, 1, -16), TextColor3 = U.GRAY_TEXT,
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5,
	})
end

function U.buildTabs()
	local rail = U.new("Frame", {
		Name = "TabRail", BackgroundColor3 = Color3.fromRGB(28, 28, 28), BorderSizePixel = 0, Active = true, Size = UDim2.new(1, 0, 0, U.TAB_H),
		Position = UDim2.fromOffset(0, U.TITLE_H + U.LINE_H + U.BODY_H),
	}, U.shell)
	U.tabRail, U.tabButtons = rail, {}
	U.currentTab = U.TAB_NAMES[1] or "combat"
	local tabIndex, swiping = {}, false
	for i, n in ipairs(U.TAB_NAMES) do tabIndex[n] = i end
	local ON, OFF = Color3.fromRGB(36, 36, 36), Color3.fromRGB(28, 28, 28)

	local function selectTab(name)
		if name == U.currentTab or swiping then return end
		U.closePopups()
		local from = U.currentTab
		local dir = (tabIndex[name] or 0) > (tabIndex[from] or 0) and 1 or -1
		local oldPage, newPage = U.pageFrames[from], U.pageFrames[name]
		U.currentTab = name
		for _, fn in ipairs(U._tabListeners or {}) do pcall(fn, name) end
		for n, b in pairs(U.tabButtons) do
			b.BackgroundColor3, b.TextColor3 = (n == name) and ON or OFF, U.theme.Text
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
			Name = name, AutoButtonColor = false, BackgroundColor3 = (name == U.currentTab) and ON or OFF, BorderSizePixel = 0,
			Size = UDim2.fromOffset((i == #U.TAB_NAMES) and (U.BODY_W - (i - 1) * U.TAB_W) or U.TAB_W, U.TAB_H), Position = UDim2.fromOffset((i - 1) * U.TAB_W, 0),
			FontFace = U.font, TextSize = U.TEXT_SZ, TextColor3 = U.theme.Text, Text = name,
		}, rail)
		local acc = U.new("Frame", {
			Name = "TabAccent", BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2), BackgroundColor3 = U.theme.Accent1,
			Visible = name == U.currentTab, ZIndex = 3,
		}, b)
		table.insert(U.themeReg.tabAccents, acc)
		U.tabButtons[name] = b
		b.MouseButton1Click:Connect(function() selectTab(name) end)
	end
	U.shell.Size = UDim2.fromOffset(U.BODY_W, U.TITLE_H + U.LINE_H + U.BODY_H + U.TAB_H)
end

function U.bindInput()
	U.track(U.UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if U.clickHitsNamed("Swatch", "Gear", "DropBox", "CycleColor", "CycleAlpha", "KeybindBox") then return end
		task.defer(function()
			if tick() < (U.suppressPopupClose or 0) then return end
			if U.openColorPicker and not U.clickHits(U.openColorPicker) then U.closeColorPicker() end
			if U.openDropdown and not U.clickHits(U.openDropdown) then U.closeDropdown() end
			if U.openSettings and not U.clickHits(U.openSettings) and not U.clickHits(U.openDropdown) and not U.clickHits(U.openColorPicker) then U.closeSettings() end
		end)
	end))

	local dragging, ds, sp
	local function beginDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		U.closePopups()
		dragging, ds, sp = true, input.Position, U.shell.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
	U.track(U.titleBar.InputBegan:Connect(beginDrag))
	U.track(U.accent.InputBegan:Connect(beginDrag))
	U.track(U.UIS.InputChanged:Connect(function(input)
		if not dragging or (input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch) then return end
		local d = input.Position - ds
		U.shell.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		U.hideSnapGhost("wm")
		U.hideSnapGhost("kb")
		if U.wmDocked then U.dock("wm") end
		if U.kbDocked then U.dock("kb") end
	end))

	U.menuOpen = true
	task.defer(function()
		U.dock("wm")
		U.dock("kb")
	end)

	U.track(U.UIS.InputBegan:Connect(function(input, gp)
		if gp or U.kbBinding then return end
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

local function lname(o, default) return string.lower(tostring(o.Name or default)) end
local function tip(o) return o.Tooltip or o.tooltip end

local function keybindOf(o, name)
	if o.Keybind ~= true then return nil end
	return { key = o.Key or o.KeyCode, text = o.KeybindText or o.ListText or o.Text or name }
end

function Library:CreateWindow(opts)
	opts = opts or {}
	local name = tostring(opts.Name or "wavelength")
	if opts.Width then U.BODY_W = opts.Width end
	if opts.Height then U.BODY_H = opts.Height end
	if type(opts.Tabs) == "table" and #opts.Tabs > 0 then
		U.TAB_NAMES = {}
		for _, t in ipairs(opts.Tabs) do U.TAB_NAMES[#U.TAB_NAMES + 1] = string.lower(tostring(t)) end
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
	U.themeReg = U.newReg()
	U.openColorPicker, U.openDropdown, U.openDropdownBox, U.openSettings = nil, nil, nil, nil
	U.wm, U.kbPanel, U.wmSnapGhost, U.kbSnapGhost = nil, nil, nil, nil
	U.wmDocked, U.kbDocked = true, true
	Library.Setters = U.setters

	if U.gui then pcall(function() U.gui:Destroy() end) U.gui = nil end
	U.buildShell()
	for _, ch in ipairs(U.titleBar:GetChildren()) do
		if ch:IsA("TextLabel") then ch.Text = string.lower(name) end
	end

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
		function tab:AddSection(sectionName, side, row, rows)
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
			local content = U.section(parent, string.lower(tostring(sectionName)), side, row, rows)
			if rows > 1 then 
				local x, _, w, h = U.secGeom(side, 1, rows)
				local idx = 0
				for _, ch in ipairs(parent:GetChildren()) do
					if ch:IsA("Frame") and ch.BackgroundTransparency < 1 and ch.Position.X.Offset == x then
						idx += 1
						ch.Size = UDim2.fromOffset(w, h)
						ch.Position = UDim2.fromOffset(x, U.SEC_GAP + (idx - 1) * (h + U.SEC_GAP))
					end
				end
			end

			local sec = { _content = content, _n = 0, Tab = tab }
			local function nextOrder()
				sec._n += 1
				return sec._n
			end
			local function slider(o, parentFlag)
				local c = U.mkSlider(content, lname(o, "slider"), o.Flag or o.Name, o.Min or 0, o.Max or 100, o.Default or 0, nextOrder(), o.Increment or 1, o.Suffix or "", o.InfAtMax == true or o.InfAt == true, tip(o))
				return parentFlag and U.subOf(c, parentFlag) or c
			end
			local function dropdown(o, parentFlag)
				local limit = o.Limit or o.Amount
				if limit == nil then limit = (o.Multi == true) and 999 or 1 end
				local c = U.mkDropdown(content, lname(o, "dropdown"), o.Flag or o.Name, o.Items or {}, o.Default, o.Multi == true or (tonumber(limit) or 1) > 1, nextOrder(), limit, tip(o))
				return parentFlag and U.subOf(c, parentFlag) or c
			end
			local function toggle(o)
				local flag = o.Flag or o.Name
				local row = U.mkToggle(content, lname(o, "toggle"), flag, nextOrder(), o.Default == true, keybindOf(o, lname(o, "toggle")), tip(o))
				if o.Callback then U.onFlag(flag, function() pcall(o.Callback, U.vflags[flag]) end) end
				return row, flag
			end

			function sec:AddToggle(o)
				o = o or {}
				local t, flag = toggle(o)
				local obj = { Flag = flag, Row = t, _parent = content }
				function obj:AddColorpicker(co)
					co = co or {}
					U.attachPicker(t, co.Flag or (flag .. "Color"), co.Default or Color3.new(1, 1, 1), co.NoAlpha == true, co.Name or "color")
					return obj
				end
				function obj:AddToggle(so)
					local child = toggle(so or {})
					U.subOf(child, flag)
					return sec
				end
				function obj:AddSlider(so) slider(so or {}, flag) return obj end
				function obj:AddDropdown(so) dropdown(so or {}, flag) return obj end
				return obj
			end
			function sec:AddSlider(o)
				o = o or {}
				return { Row = slider(o), Flag = o.Flag or o.Name }
			end
			function sec:AddDoubleSlider(o)
				o = o or {}
				local r = U.mkDoubleSlider(content, lname(o, "range"), o.FlagMin or (o.Flag or "Min"), o.FlagMax or "Max", o.Min or 0, o.Max or 100, o.DefaultMin or o.Min or 0, o.DefaultMax or o.Max or 100, nextOrder(), o.Increment or 1, o.Suffix or "", tip(o), o.InfAtMax == true or o.InfAt == true)
				return { Row = r, FlagMin = o.FlagMin, FlagMax = o.FlagMax }
			end
			function sec:AddDropdown(o)
				o = o or {}
				return { Row = dropdown(o), Flag = o.Flag or o.Name }
			end
			function sec:AddButton(o)
				o = o or {}
				local btn = U.mkButton(content, lname(o, "button"), nextOrder(), o.Confirm == true)
				if o.Callback then U.bindButton(btn, o.Callback) end
				U.bindTooltip(btn, tip(o))
				return { Button = btn }
			end
			function sec:AddColorpicker(o)
				o = o or {}
				local r = U.row(content, nextOrder())
				U.label(r, lname(o, "color"), { Size = UDim2.new(1, -36, 1, 0) })
				U.attachPicker(r, o.Flag or o.Name, o.Default or Color3.new(1, 1, 1), o.NoAlpha == true, o.Name or "color")
				U.bindTooltip(r, tip(o))
				return { Row = r }
			end
			function sec:AddLabel(o)
				o = o or {}
				local r = U.row(content, nextOrder())
				U.label(r, string.lower(tostring(o.Name or "")), { Size = UDim2.new(1, -36, 1, 0) })
				U.bindTooltip(r, tip(o))
				local obj = { Row = r }
				function obj:AddColorpicker(co)
					co = co or {}
					U.attachPicker(r, co.Flag or ((o.Flag or o.Name or "label") .. "Color"), co.Default or Color3.new(1, 1, 1), co.NoAlpha == true, co.Name or "color")
					return obj
				end
				return obj
			end
			function sec:AddTextbox(o)
				o = o or {}
				return { Row = U.mkTextbox(content, lname(o, "text"), o.Flag or o.Name, o.Placeholder or "", nextOrder(), tip(o)), Flag = o.Flag or o.Name }
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
	function win:Init()
		U.buildTabs()
		U.bindInput()
	end
	function win:Unload() U.shutdown() end
	return win
end
	return Library

end)()

--[[
	wavelength universal — visuals + config (+ preview)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/illorsm/wavelength/main/universal.lua"))()
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera


local Window = Library:CreateWindow({
	Name = "wavelength",
	Tabs = { "visuals", "dex", "config" },
})

local vis = Window:AddTab("visuals")
local control = vis:AddSection("control", 1)
control:AddToggle({
	Name = "enable",
	Flag = "VisEnable",
	Default = true,
	Keybind = true,
	Key = "RightAlt",
	KeybindText = "Visuals",
})
control:AddToggle({ Name = "ignore team", Flag = "VisIgnoreTeam", Default = false })
control:AddToggle({ Name = "ignore self", Flag = "VisIgnoreSelf", Default = true })
control:AddSlider({
	Name = "render distance",
	Flag = "VisDistance",
	Min = 0,
	Max = 2000,
	Default = 1000,
	Increment = 1,
	Suffix = "st",
	InfAtMax = true,
})

local players = vis:AddSection("players", 2)
local boxT = players:AddToggle({ Name = "box", Flag = "VisBox", Default = true })
boxT:AddColorpicker({ Flag = "VisBoxColor", Default = Color3.fromRGB(255, 255, 255), NoAlpha = true, Name = "box" })
boxT:AddDropdown({ Name = "type", Flag = "VisBoxType", Items = { "full", "corner" }, Default = "full", Limit = 1 })
boxT:AddSlider({ Name = "length", Flag = "VisBoxLength", Min = 0, Max = 100, Default = 33, Increment = 1, Suffix = "%" })

local fillT = players:AddToggle({ Name = "box fill", Flag = "VisBoxFill", Default = false })
fillT:AddColorpicker({ Flag = "VisBoxFillColor", Default = Color3.fromRGB(255, 255, 255), Name = "fill" })

local hbT = players:AddToggle({ Name = "health bar", Flag = "VisHealthBar", Default = true })
hbT:AddColorpicker({ Flag = "VisHBHigh", Default = Color3.fromRGB(0, 255, 0), NoAlpha = true, Name = "high" })
hbT:AddColorpicker({ Flag = "VisHBLow", Default = Color3.fromRGB(255, 0, 0), NoAlpha = true, Name = "low" })

local htT = players:AddToggle({ Name = "health", Flag = "VisHealthText", Default = false })
htT:AddColorpicker({ Flag = "VisHTHigh", Default = Color3.fromRGB(0, 255, 0), NoAlpha = true, Name = "high" })
htT:AddColorpicker({ Flag = "VisHTLow", Default = Color3.fromRGB(255, 0, 0), NoAlpha = true, Name = "low" })

local nameT = players:AddToggle({ Name = "name", Flag = "VisName", Default = true })
nameT:AddColorpicker({ Flag = "VisNameColor", Default = Color3.fromRGB(255, 255, 255), NoAlpha = true, Name = "name" })

local distT = players:AddToggle({ Name = "distance", Flag = "VisDistanceText", Default = false })
distT:AddColorpicker({ Flag = "VisDistColor", Default = Color3.fromRGB(200, 200, 200), NoAlpha = true, Name = "distance" })

local skT = players:AddToggle({ Name = "skeleton", Flag = "VisSkeleton", Default = false })
skT:AddColorpicker({ Flag = "VisSkelColor", Default = Color3.fromRGB(255, 255, 255), NoAlpha = true, Name = "skeleton" })
skT:AddSlider({ Name = "thickness", Flag = "VisSkelThick", Min = 1, Max = 3, Default = 1, Increment = 0.1 })

local hlT = players:AddToggle({ Name = "highlight", Flag = "VisHighlight", Default = false })
hlT:AddColorpicker({ Flag = "VisHLFill", Default = Color3.fromRGB(255, 255, 255), Name = "fill" })
hlT:AddColorpicker({ Flag = "VisHLOutline", Default = Color3.fromRGB(0, 0, 0), Name = "outline" })

Window:AddTab("dex")
Window:AddSettingsTab()
Window:Init()

local F = Library.Flags
local function flag(n, d)
	local v = Library:GetFlag(n)
	if v == nil then return d end
	return v
end

local function getHealth(char)
	if not char then return 100, 100 end
	for _, key in ipairs({ "Health", "health", "HP", "hp" }) do
		local a = char:GetAttribute(key)
		if typeof(a) == "number" then
			local maxA = char:GetAttribute("MaxHealth") or char:GetAttribute("maxHealth") or 100
			return a, typeof(maxA) == "number" and maxA or 100
		end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then return hum.Health, hum.MaxHealth end
	return 100, 100
end

local function sameTeam(p)
	if not flag("VisIgnoreTeam", false) then return false end
	if not lp.Team or not p.Team then return false end
	return lp.Team == p.Team
end

local bones = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "UpperTorso", "RightUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "RightLowerLeg", "RightFoot" },
}

local function w2s(v3)
	local v, on = cam:WorldToViewportPoint(v3)
	return Vector2.new(v.X, v.Y), on, v.Z
end

local function boxOf(char)
	local parts = {}
	for _, n in ipairs({ "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then parts[#parts + 1] = p end
	end
	if #parts == 0 then
		for _, d in ipairs(char:GetChildren()) do
			if d:IsA("BasePart") then parts[#parts + 1] = d end
		end
	end
	if #parts == 0 then return end
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	local any = false
	for _, p in ipairs(parts) do
		local cf, size = p.CFrame, p.Size
		for _, ox in ipairs({ -0.5, 0.5 }) do
			for _, oy in ipairs({ -0.5, 0.5 }) do
				for _, oz in ipairs({ -0.5, 0.5 }) do
					local wp = (cf * CFrame.new(size.X * ox, size.Y * oy, size.Z * oz)).Position
					local s, on = w2s(wp)
					if on then
						any = true
						minX, minY = math.min(minX, s.X), math.min(minY, s.Y)
						maxX, maxY = math.max(maxX, s.X), math.max(maxY, s.Y)
					end
				end
			end
		end
	end
	if not any then return end
	local pad = 2
	return minX - pad, minY - pad, maxX + pad, maxY + pad
end

local drawings = {}
local function getDraw(key, class)
	local t = drawings[key]
	if t and t.ClassName == class then return t end
	if t then pcall(function() t:Remove() end) end
	local d = Drawing.new(class)
	drawings[key] = d
	return d
end

local function hideAll()
	for _, d in pairs(drawings) do
		pcall(function() d.Visible = false end)
	end
end

local highlights = {}
local function setHighlight(char, on)
	local existing = highlights[char]
	if not on then
		if existing then existing:Destroy() highlights[char] = nil end
		return
	end
	local h = existing or char:FindFirstChildOfClass("Highlight")
	if not h then
		h = Instance.new("Highlight")
		h.Parent = char
	end
	highlights[char] = h
	local fc = flag("VisHLFill", Color3.new(1, 1, 1))
	local oc = flag("VisHLOutline", Color3.new(0, 0, 0))
	local ft = Library:GetFlag("VisHLFillTransparency") or 0.5
	local ot = Library:GetFlag("VisHLOutlineTransparency") or 0
	h.FillColor = fc
	h.OutlineColor = oc
	h.FillTransparency = typeof(ft) == "number" and ft or 0.5
	h.OutlineTransparency = typeof(ot) == "number" and ot or 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

local function lerpColor(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function drawPlayer(p, char, idx)
	local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char.PrimaryPart
	if not hrp then return end
	local dist = (cam.CFrame.Position - hrp.Position).Magnitude
	local maxD = flag("VisDistance", 1000)
	if maxD < 2000 and dist > maxD then return end

	local x1, y1, x2, y2 = boxOf(char)
	if not x1 then return end
	local w, h = x2 - x1, y2 - y1
	local hp, maxHp = getHealth(char)
	local ratio = maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 1

	if flag("VisBoxFill", false) then
		local f = getDraw(idx .. "_fill", "Square")
		f.Filled = true
		f.Color = flag("VisBoxFillColor", Color3.new(1, 1, 1))
		f.Transparency = 1 - (Library:GetFlag("VisBoxFillColorTransparency") or 0.7)
		f.Size = Vector2.new(w, h)
		f.Position = Vector2.new(x1, y1)
		f.Visible = true
	end

	if flag("VisBox", true) then
		local col = flag("VisBoxColor", Color3.new(1, 1, 1))
		local typ = flag("VisBoxType", "full")
		if typ == "corner" then
			local len = math.clamp((flag("VisBoxLength", 33) / 100) * math.min(w, h), 2, math.min(w, h) / 2)
			local segs = {
				{ x1, y1, x1 + len, y1 }, { x1, y1, x1, y1 + len },
				{ x2 - len, y1, x2, y1 }, { x2, y1, x2, y1 + len },
				{ x1, y2, x1 + len, y2 }, { x1, y2 - len, x1, y2 },
				{ x2 - len, y2, x2, y2 }, { x2, y2 - len, x2, y2 },
			}
			for i, s in ipairs(segs) do
				local l = getDraw(idx .. "_bc" .. i, "Line")
				l.From, l.To, l.Color, l.Thickness, l.Visible = Vector2.new(s[1], s[2]), Vector2.new(s[3], s[4]), col, 1, true
			end
		else
			local box = getDraw(idx .. "_box", "Square")
			box.Filled = false
			box.Thickness = 1
			box.Color = col
			box.Size = Vector2.new(w, h)
			box.Position = Vector2.new(x1, y1)
			box.Visible = true
		end
	end

	if flag("VisHealthBar", true) then
		local barW = 2
		local outline = getDraw(idx .. "_hbo", "Square")
		outline.Filled = true
		outline.Color = Color3.new(0, 0, 0)
		outline.Size = Vector2.new(barW + 2, h + 2)
		outline.Position = Vector2.new(x1 - barW - 4, y1 - 1)
		outline.Visible = true
		local bar = getDraw(idx .. "_hb", "Square")
		bar.Filled = true
		bar.Color = lerpColor(flag("VisHBLow", Color3.new(1, 0, 0)), flag("VisHBHigh", Color3.new(0, 1, 0)), ratio)
		local bh = h * ratio
		bar.Size = Vector2.new(barW, bh)
		bar.Position = Vector2.new(x1 - barW - 3, y1 + (h - bh))
		bar.Visible = true
	end

	if flag("VisHealthText", false) then
		local t = getDraw(idx .. "_ht", "Text")
		t.Text = tostring(math.floor(hp + 0.5))
		t.Size = 12
		t.Center = false
		t.Outline = true
		t.Color = lerpColor(flag("VisHTLow", Color3.new(1, 0, 0)), flag("VisHTHigh", Color3.new(0, 1, 0)), ratio)
		t.Position = Vector2.new(x1 - 28, y1)
		t.Visible = true
	end

	local textY = y1 - 14
	if flag("VisName", true) then
		local t = getDraw(idx .. "_name", "Text")
		t.Text = p.DisplayName or p.Name
		t.Size = 12
		t.Center = true
		t.Outline = true
		t.Color = flag("VisNameColor", Color3.new(1, 1, 1))
		t.Position = Vector2.new(x1 + w / 2, textY)
		t.Visible = true
		textY += 12
	end
	if flag("VisDistanceText", false) then
		local t = getDraw(idx .. "_dist", "Text")
		t.Text = math.floor(dist) .. "st"
		t.Size = 12
		t.Center = true
		t.Outline = true
		t.Color = flag("VisDistColor", Color3.new(0.8, 0.8, 0.8))
		t.Position = Vector2.new(x1 + w / 2, y2 + 2)
		t.Visible = true
	end

	if flag("VisSkeleton", false) then
		local thick = flag("VisSkelThick", 1)
		local col = flag("VisSkelColor", Color3.new(1, 1, 1))
		for i, pair in ipairs(bones) do
			local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
			if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
				local s1, o1 = w2s(a.Position)
				local s2, o2 = w2s(b.Position)
				if o1 and o2 then
					local l = getDraw(idx .. "_sk" .. i, "Line")
					l.From, l.To, l.Color, l.Thickness, l.Visible = s1, s2, col, thick, true
				end
			end
		end
	end

	setHighlight(char, flag("VisHighlight", false))
end

RunService.RenderStepped:Connect(function()
	hideAll()
	if not flag("VisEnable", true) then
		for char in pairs(highlights) do setHighlight(char, false) end
		return
	end
	local i = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if flag("VisIgnoreSelf", true) and p == lp then continue end
		if sameTeam(p) then continue end
		local char = p.Character
		if not char then continue end
		i += 1
		drawPlayer(p, char, i)
	end
end)

do
	local BODY_W, TITLE_H, LINE_H = 560, 22, 2
	local PRE_W = math.floor(BODY_W / 2)
	local shellH

	local function guiParent()
		if typeof(gethui) == "function" then
			local ok, g = pcall(gethui)
			if ok and g then return g end
		end
		return lp:WaitForChild("PlayerGui")
	end

	local previewGui = Instance.new("ScreenGui")
	previewGui.Name = "wavelength_preview"
	previewGui.ResetOnSpawn = false
	previewGui.IgnoreGuiInset = true
	previewGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	previewGui.Parent = guiParent()

	local panel = Instance.new("Frame")
	panel.Name = "PreviewPanel"
	panel.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	panel.BorderSizePixel = 0
	panel.Active = true
	panel.Visible = false
	panel.ZIndex = 50
	panel.Parent = previewGui

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.Parent = panel

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(1, 0, 0, 2)
	accent.BorderSizePixel = 0
	accent.BackgroundColor3 = Color3.new(1, 1, 1)
	accent.ZIndex = 2
	accent.Parent = panel
	local ag = Instance.new("UIGradient")
	ag.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.new(0, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})
	ag.Parent = accent
	task.spawn(function()
		while accent.Parent do
			ag.Offset = Vector2.new((tick() * 0.35 % 2) - 1, 0)
			task.wait(0.03)
		end
	end)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Text = "preview"
	title.TextColor3 = Color3.fromRGB(235, 235, 235)
	title.TextSize = 12
	title.Font = Enum.Font.Code
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, -12, 0, 22)
	title.Position = UDim2.fromOffset(6, 2)
	title.Parent = panel

	local section = Instance.new("Frame")
	section.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	section.BorderSizePixel = 0
	section.Position = UDim2.fromOffset(8, 28)
	section.Size = UDim2.new(1, -16, 1, -36)
	section.ClipsDescendants = true
	section.Parent = panel
	local ss = Instance.new("UIStroke")
	ss.Thickness = 2
	ss.Color = Color3.new(0, 0, 0)
	ss.Parent = section

	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	viewport.BorderSizePixel = 0
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Parent = section

	local world = Instance.new("WorldModel")
	world.Parent = viewport

	local function makeChar()
		local desc = Instance.new("HumanoidDescription")
		local white = Color3.fromRGB(255, 255, 255)
		desc.HeadColor, desc.TorsoColor = white, white
		desc.LeftArmColor, desc.RightArmColor = white, white
		desc.LeftLegColor, desc.RightLegColor = white, white
		desc.Shirt, desc.Pants, desc.GraphicTShirt = 0, 0, 0
		desc.Face = 86487766
		local ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		if not ok or not model then return nil end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.Color = white
				d.Material = Enum.Material.SmoothPlastic
			elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Clothing") or d:IsA("Accessory") then
				d:Destroy()
			end
		end
		local hrp = model:FindFirstChild("HumanoidRootPart")
		if hrp then
			model.PrimaryPart = hrp
			hrp.Transparency = 1
			model:PivotTo(CFrame.new(0, 3, 0))
		end
		model.Parent = world
		return model
	end

	local model = makeChar()
	local vcam = Instance.new("Camera")
	vcam.Parent = viewport
	viewport.CurrentCamera = vcam

	local yaw, pitch, distScale = 0.55, 0.2, 1
	local baseDist, focus = 6, Vector3.new(0, 3, 0)
	if model then
		local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
		if ok and cf then
			focus = cf.Position
			baseDist = math.max(size.X, size.Y, size.Z) * 1.15
		end
	end

	local function updateCam()
		local distance = baseDist * distScale
		local cf = CFrame.new(focus) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-pitch, 0, 0) * CFrame.new(0, 0, distance)
		vcam.CFrame = CFrame.lookAt(cf.Position, focus)
	end
	updateCam()

	local overlay = Instance.new("Frame")
	overlay.BackgroundTransparency = 1
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = 5
	overlay.Parent = section

	local function proj(worldPos)
		local v, onScreen = vcam:WorldToViewportPoint(worldPos)
		local vs = viewport.AbsoluteSize
		return Vector2.new(v.X, v.Y), onScreen and v.Z > 0, v.Z
	end

	local function boxModel()
		if not model then return end
		local parts = {}
		for _, n in ipairs({ "Head", "UpperTorso", "LowerTorso", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }) do
			local p = model:FindFirstChild(n)
			if p then parts[#parts + 1] = p end
		end
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
		local any = false
		for _, p in ipairs(parts) do
			local cf, size = p.CFrame, p.Size
			for _, ox in ipairs({ -0.5, 0.5 }) do
				for _, oy in ipairs({ -0.5, 0.5 }) do
					for _, oz in ipairs({ -0.5, 0.5 }) do
						local s, on = proj((cf * CFrame.new(size * Vector3.new(ox, oy, oz))).Position)
						if on then
							any = true
							minX, minY = math.min(minX, s.X), math.min(minY, s.Y)
							maxX, maxY = math.max(maxX, s.X), math.max(maxY, s.Y)
						end
					end
				end
			end
		end
		if not any then return end
		return minX, minY, maxX, maxY
	end

	local prevDraws = {}
	local function pd(key, class)
		local d = prevDraws[key]
		if d and d.ClassName == class then return d end
		if d then pcall(function() d:Remove() end) end
		d = Drawing.new(class)
		prevDraws[key] = d
		return d
	end
	local function hidePrev()
		for _, d in pairs(prevDraws) do pcall(function() d.Visible = false end) end
	end

	local function drawPreviewESP()
		hidePrev()
		if not panel.Visible or not model then return end
		local ap = viewport.AbsolutePosition
		local x1, y1, x2, y2 = boxModel()
		if not x1 then return end
		x1, y1, x2, y2 = x1 + ap.X, y1 + ap.Y, x2 + ap.X, y2 + ap.Y
		local w, h = x2 - x1, y2 - y1
		local hpRatio = 0.75

		if flag("VisBoxFill", false) then
			local f = pd("fill", "Square")
			f.Filled, f.Visible = true, true
			f.Color = flag("VisBoxFillColor", Color3.new(1, 1, 1))
			f.Transparency = 0.3
			f.Size = Vector2.new(w, h)
			f.Position = Vector2.new(x1, y1)
		end
		if flag("VisBox", true) then
			local b = pd("box", "Square")
			b.Filled, b.Thickness, b.Visible = false, 1, true
			b.Color = flag("VisBoxColor", Color3.new(1, 1, 1))
			b.Size = Vector2.new(w, h)
			b.Position = Vector2.new(x1, y1)
		end
		if flag("VisHealthBar", true) then
			local o = pd("hbo", "Square")
			o.Filled, o.Visible = true, true
			o.Color = Color3.new(0, 0, 0)
			o.Size = Vector2.new(4, h + 2)
			o.Position = Vector2.new(x1 - 6, y1 - 1)
			local bar = pd("hb", "Square")
			bar.Filled, bar.Visible = true, true
			bar.Color = lerpColor(flag("VisHBLow", Color3.new(1, 0, 0)), flag("VisHBHigh", Color3.new(0, 1, 0)), hpRatio)
			local bh = h * hpRatio
			bar.Size = Vector2.new(2, bh)
			bar.Position = Vector2.new(x1 - 5, y1 + (h - bh))
		end
		if flag("VisName", true) then
			local t = pd("name", "Text")
			t.Text, t.Size, t.Center, t.Outline, t.Visible = "preview", 12, true, true, true
			t.Color = flag("VisNameColor", Color3.new(1, 1, 1))
			t.Position = Vector2.new(x1 + w / 2, y1 - 14)
		end
		if flag("VisSkeleton", false) then
			local col = flag("VisSkelColor", Color3.new(1, 1, 1))
			local thick = flag("VisSkelThick", 1)
			for i, pair in ipairs(bones) do
				local a, b = model:FindFirstChild(pair[1]), model:FindFirstChild(pair[2])
				if a and b then
					local s1, o1 = proj(a.Position)
					local s2, o2 = proj(b.Position)
					if o1 and o2 then
						local l = pd("sk" .. i, "Line")
						l.From = s1 + ap
						l.To = s2 + ap
						l.Color, l.Thickness, l.Visible = col, thick, true
					end
				end
			end
		end
		if flag("VisHighlight", false) then
			local h = model:FindFirstChildOfClass("Highlight") or Instance.new("Highlight")
			h.Parent = model
			h.FillColor = flag("VisHLFill", Color3.new(1, 1, 1))
			h.OutlineColor = flag("VisHLOutline", Color3.new(0, 0, 0))
			h.FillTransparency = 0.5
		else
			local h = model:FindFirstChildOfClass("Highlight")
			if h then h:Destroy() end
		end
	end

	local docked = true
	local gap = 6
	local ghost = Instance.new("Frame")
	ghost.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	ghost.BackgroundTransparency = 0.35
	ghost.BorderSizePixel = 0
	ghost.Visible = false
	ghost.ZIndex = 40
	ghost.Parent = previewGui
	local gs = Instance.new("UIStroke")
	gs.Thickness = 2
	gs.Color = Color3.new(0, 0, 0)
	gs.Parent = ghost

	local function shellFrame()
		return Library:GetShell()
	end

	local function dockPos()
		local sh = shellFrame()
		if not sh then return end
		shellH = sh.AbsoluteSize.Y
		panel.Size = UDim2.fromOffset(PRE_W, shellH)
		if docked then
			local sp = sh.AbsolutePosition
			local ss = sh.AbsoluteSize
			panel.Position = UDim2.fromOffset(sp.X + ss.X + gap, sp.Y)
		end
	end

	local function shouldShow()
		return flag("Preview", true)
			and Library:GetCurrentTab() == "visuals"
			and (Library:IsMenuOpen() or not docked)
	end

	local function refreshVis()
		panel.Visible = shouldShow()
		if panel.Visible and docked then dockPos() end
		if not panel.Visible then hidePrev() end
	end

	Library:OnFlag("Preview", refreshVis)
	Library:OnTabChanged(function()
		refreshVis()
	end)

	task.spawn(function()
		while true do
			task.wait(0.05)
			refreshVis()
			if panel.Visible and docked then dockPos() end
		end
	end)

	RunService.RenderStepped:Connect(function()
		if panel.Visible then
			drawPreviewESP()
		else
			hidePrev()
		end
	end)

	local dragging, last
	UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local ap, as = viewport.AbsolutePosition, viewport.AbsoluteSize
		local p = input.Position
		if p.X >= ap.X and p.X <= ap.X + as.X and p.Y >= ap.Y and p.Y <= ap.Y + as.Y then
			dragging, last = true, p
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - last
			last = input.Position
			yaw -= d.X * 0.01
			pitch = math.clamp(pitch + d.Y * 0.01, -1.2, 1.2)
			updateCam()
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
		if not panel.Visible then return end
		local ap, as = viewport.AbsolutePosition, viewport.AbsoluteSize
		local m = UIS:GetMouseLocation()
		if m.X < ap.X or m.X > ap.X + as.X or m.Y < ap.Y or m.Y > ap.Y + as.Y then return end
		distScale = math.clamp(distScale - input.Position.Z * 0.1, 0.4, 3)
		updateCam()
	end)

	do
		local drag, start, origin
		panel.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local rel = input.Position.Y - panel.AbsolutePosition.Y
			if rel > 26 then return end
			drag, start, origin = true, input.Position, panel.Position
			docked = false
			local sh = shellFrame()
			if sh then
				ghost.Size = UDim2.fromOffset(PRE_W, sh.AbsoluteSize.Y)
				ghost.Position = UDim2.fromOffset(sh.AbsolutePosition.X + sh.AbsoluteSize.X + gap, sh.AbsolutePosition.Y)
				ghost.Visible = Library:IsMenuOpen()
			end
			input.Changed:Connect(function()
				if input.UserInputState ~= Enum.UserInputState.End then return end
				drag = false
				if ghost.Visible then
					local gp, gs_, pp, ps = ghost.AbsolutePosition, ghost.AbsoluteSize, panel.AbsolutePosition, panel.AbsoluteSize
					local cx, cy = pp.X + ps.X * 0.5, pp.Y + ps.Y * 0.5
					if cx >= gp.X and cx <= gp.X + gs_.X and cy >= gp.Y and cy <= gp.Y + gs_.Y then
						docked = true
						dockPos()
					end
				end
				ghost.Visible = false
				refreshVis()
			end)
		end)
		UIS.InputChanged:Connect(function(input)
			if not drag then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local d = input.Position - start
			panel.Position = UDim2.fromOffset(origin.X.Offset + d.X, origin.Y.Offset + d.Y)
			local sh = shellFrame()
			if sh and Library:IsMenuOpen() then
				ghost.Position = UDim2.fromOffset(sh.AbsolutePosition.X + sh.AbsoluteSize.X + gap, sh.AbsolutePosition.Y)
				ghost.Size = UDim2.fromOffset(PRE_W, sh.AbsoluteSize.Y)
				ghost.Visible = true
			end
		end)
	end

	refreshVis()
end

Library:Notify({ text = "wavelength universal loaded", time = 2 })
