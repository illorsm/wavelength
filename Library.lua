getgenv()._SM = getgenv()._SM or {}
local U = getgenv()._SM

do
	U.Players = game:GetService("Players")
	U.UIS = game:GetService("UserInputService")
	U.Tween = game:GetService("TweenService")
	U.Http = game:GetService("HttpService")
	U.Run = game:GetService("RunService")
	U.Text = game:GetService("TextService")
	U.lp = U.Players.LocalPlayer
end

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
U.themeReg = U.themeReg or { accents = {}, borders = {}, sectionBorders = {}, bgs = {}, tabAccents = {} }

function U.controlStroke(parent, thick)
	thick = thick or 1
	if U.theme.ElementBorder == nil then U.theme.ElementBorder = U.theme.SectionBorder end
	local col = U.theme.ElementBorder
	U.themeReg.elementBorders = U.themeReg.elementBorders or {}
	local function edge(name, size, pos)
		local e = Instance.new("Frame")
		e.Name = name
		e.BorderSizePixel = 0
		e.BackgroundColor3 = col
		e.Size = size
		e.Position = pos
		e.ZIndex = (parent.ZIndex or 1) + 2
		e.Parent = parent
		U.themeReg.elementBorders[#U.themeReg.elementBorders + 1] = e
		return e
	end
	edge("BTop", UDim2.new(1, 0, 0, thick), UDim2.fromOffset(0, 0))
	edge("BBottom", UDim2.new(1, 0, 0, thick), UDim2.new(0, 0, 1, -thick))
	edge("BLeft", UDim2.new(0, thick, 1, 0), UDim2.fromOffset(0, 0))
	edge("BRight", UDim2.new(0, thick, 1, 0), UDim2.new(1, -thick, 0, 0))
end

U.running = true
U.vflags = U.vflags or {
	NotificationPosition = "bottom right",
	MenuKeybind = Enum.KeyCode.RightShift,
}
U.setters = U.setters or {}
U.flagListeners = U.flagListeners or {}
U.pulseReg = U.pulseReg or {}
U.activeNotifs = U.activeNotifs or {}
U.TEXT_SZ = 12
U.LINE_H = 2
U.BODY_W = 560
U.BODY_H = 360
U.TITLE_H = 22
U.SEC_GAP = 8
U.TAB_NAMES = { "combat", "visuals", "misc", "config" }

function U.guiParent()
	if typeof(gethui) == "function" then
		local ok, g = pcall(gethui)
		if ok and g then return g end
	end
	return U.lp:WaitForChild("PlayerGui")
end

function U.loadFont()
	local ok, font = pcall(function()
		local id = "ProggyClean.ttf"
		if not isfile(id) then
			writefile(id, game:HttpGet("https://github.com/i77lhm/storage/raw/refs/heads/main/fonts/ProggyClean.ttf"))
		end
		local fontFile = "ProggyClean_ExampleUI.font"
		if isfile(fontFile) then delfile(fontFile) end
		writefile(fontFile, U.Http:JSONEncode({
			name = "ProggyClean_ExampleUI",
			faces = {{ name = "Normal", weight = 400, style = "Normal", assetId = getcustomasset(id) }},
		}))
		return Font.new(getcustomasset(fontFile), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end)
	if ok and font then return font end
	return Font.fromEnum(Enum.Font.Code)
end

U.font = U.loadFont()

function U.onFlag(name, fn)
	U.flagListeners[name] = U.flagListeners[name] or {}
	table.insert(U.flagListeners[name], fn)
end

function U.fireFlag(name)
	for _, fn in ipairs(U.flagListeners[name] or {}) do
		pcall(fn)
	end
end

function U.setFlag(name, val)
	U.vflags[name] = val
	U.fireFlag(name)
end

function U.accentSequence()
	local a, b = U.theme.Accent1, U.theme.Accent2
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, a),
		ColorSequenceKeypoint.new(0.25, a:Lerp(b, 0.5)),
		ColorSequenceKeypoint.new(0.50, b),
		ColorSequenceKeypoint.new(0.75, b:Lerp(a, 0.5)),
		ColorSequenceKeypoint.new(1.00, a),
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
	while true do
		local c = U.pulseColor()
		for i = #U.pulseReg, 1, -1 do
			local e = U.pulseReg[i]
			if not e.inst or not e.inst.Parent then
				table.remove(U.pulseReg, i)
			elseif e.active() then
				e.inst.BackgroundColor3 = c
			end
		end
		if U.themeReg.tabAccents then
			for i = #U.themeReg.tabAccents, 1, -1 do
				local a = U.themeReg.tabAccents[i]
				if not a or not a.Parent then
					table.remove(U.themeReg.tabAccents, i)
				else
					a.BackgroundColor3 = c
				end
			end
		end
		task.wait(0.03)
	end
end)

U.cycle = U.cycle or { hue = 0, alpha = 0, colorFlags = {}, alphaFlags = {}, step = 0.01 }
function U.setCycleColor(flagKey, on)
	if on then
		U.cycle.colorFlags[flagKey] = true
		local cur = U.vflags[flagKey]
		local s, v = 1, 1
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
function U.setCycleAlpha(flagKey, on)
	local alphaKey = flagKey .. "Transparency"
	if on then
		U.cycle.alphaFlags[flagKey] = true
		U.vflags[alphaKey] = U.cycle.alpha
	else
		U.cycle.alphaFlags[flagKey] = nil
	end
	U.vflags[flagKey .. "CycleAlpha"] = on and true or false
end
task.spawn(function()
	while U.running do
		local anyC = next(U.cycle.colorFlags) ~= nil
		local anyA = next(U.cycle.alphaFlags) ~= nil
		if anyC or anyA then
			if anyC then
				U.cycle.hue = (U.cycle.hue + U.cycle.step) % 1
				for flagKey in pairs(U.cycle.colorFlags) do
					local cur = U.vflags[flagKey]
					local s, v = 1, 1
					if typeof(cur) == "Color3" then
						local _
						_, s, v = cur:ToHSV()
					end
					local nc = Color3.fromHSV(U.cycle.hue, s, v)
					U.vflags[flagKey] = nc
					if U.setters[flagKey] then U.setters[flagKey](nc) end
				end
			end
			if anyA then
				if U.cycle.alphaDir == nil then U.cycle.alphaDir = 1 end
				U.cycle.alpha = U.cycle.alpha + U.cycle.step * U.cycle.alphaDir
				if U.cycle.alpha >= 1 then
					U.cycle.alpha = 1
					U.cycle.alphaDir = -1
				elseif U.cycle.alpha <= 0 then
					U.cycle.alpha = 0
					U.cycle.alphaDir = 1
				end
				for flagKey in pairs(U.cycle.alphaFlags) do
					U.vflags[flagKey .. "Transparency"] = U.cycle.alpha
					if U.setters[flagKey .. "Transparency"] then
						U.setters[flagKey .. "Transparency"](U.cycle.alpha)
					end
					if U.openPickerRefresh and U.openColorPicker and U.openColorPicker:GetAttribute("Flag") == flagKey then
						U.openPickerRefresh()
					end
				end
			end
		end
		task.wait(0.03)
	end
end)

function U.applyTheme()
	for _, g in ipairs(U.themeReg.accents) do
		if g.Parent then g.Color = U.accentSequence() end
	end
	for _, st in ipairs(U.themeReg.borders) do
		if st.Parent then st.Color = U.theme.Border end
	end
	for _, st in ipairs(U.themeReg.sectionBorders) do
		if st and st.Parent then
			if st:IsA("UIStroke") then
				st.Color = U.theme.SectionBorder
			else
				st.BackgroundColor3 = U.theme.SectionBorder
			end
		end
	end
	for _, st in ipairs(U.themeReg.elementBorders or {}) do
		if st and st.Parent then
			st.BackgroundColor3 = U.theme.ElementBorder
		end
	end
	for _, f in ipairs(U.themeReg.bgs) do
		if f.Parent then f.BackgroundColor3 = U.theme.Background end
	end
	if U.refreshMenuTextColors then U.refreshMenuTextColors() end
end

function U.refreshMenuTextColors()
	local c = U.theme.Text
	
	if U.wmText then U.wmText.TextColor3 = c end
	if U.wmGui then
		for _, inst in ipairs(U.wmGui:GetDescendants()) do
			if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
				inst.TextColor3 = c
			end
		end
	end
	if U.gui then
		for _, inst in ipairs(U.gui:GetDescendants()) do
			if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
				inst.TextColor3 = c
			end
		end
	end
end

function U.notifAnchor(pos)
	pos = string.lower(tostring(pos or ""))
	if pos == "top left" then return Vector2.new(0, 0), UDim2.fromOffset(14, 14), 1
	elseif pos == "top right" then return Vector2.new(1, 0), UDim2.new(1, -14, 0, 14), 1
	elseif pos == "bottom left" then return Vector2.new(0, 1), UDim2.new(0, 14, 1, -14), -1
	elseif pos == "center" then return Vector2.new(0.5, 0.5), UDim2.new(0.5, 0, 0.72, 0), 1
	end
	return Vector2.new(1, 1), UDim2.new(1, -14, 1, -14), -1
end

function U.layoutNotifs()
	local pos = U.vflags.NotificationPosition or "bottom right"
	local anchor, base, dir = U.notifAnchor(pos)
	local gap, y = 6, 0
	for i, entry in ipairs(U.activeNotifs) do
		if entry.frame and entry.frame.Parent then
			entry.frame.AnchorPoint = anchor
			if string.lower(tostring(pos)) == "center" then
				entry.frame.Position = UDim2.new(0.5, 0, 0.72, (i - 1) * (entry.h + gap) - (#U.activeNotifs * (entry.h + gap)) / 2)
			else
				entry.frame.Position = UDim2.new(base.X.Scale, base.X.Offset, base.Y.Scale, base.Y.Offset + y * dir)
			end
			y += entry.h + gap
		end
	end
end

function U.pushNotification(opts)
	opts = opts or {}
	local text = opts.text or ""
	local duration = opts.duration or 3
	local nGui = Instance.new("ScreenGui")
	nGui.Name = "SimpleNotif"
	nGui.IgnoreGuiInset = true
	nGui.ResetOnSpawn = false
	nGui.Parent = U.guiParent()

	
	local w, h = 160, 22
	pcall(function()
		local measure = Instance.new("GetTextBoundsParams")
		measure.Text = text
		measure.Font = U.font
		measure.Size = U.TEXT_SZ
		measure.Width = 420
		local bounds = U.Text:GetTextBoundsAsync(measure)
		w = math.max(80, math.ceil(bounds.X) + 16)
		h = 22
	end)

	
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = U.theme.Background
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromOffset(w, h)
	frame.Parent = nGui

	local st = Instance.new("UIStroke")
	st.Thickness = 2
	st.Color = U.theme.Border
	st.LineJoinMode = Enum.LineJoinMode.Miter
	st.Transparency = 1
	st.Parent = frame

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 2)
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BackgroundTransparency = 1
	bar.ZIndex = 2
	bar.Parent = frame
	local grad = Instance.new("UIGradient")
	grad.Color = U.accentSequence()
	grad.Parent = bar
	task.spawn(function()
		while bar.Parent do
			grad.Color = U.accentSequence()
			grad.Offset = Vector2.new((tick() * 0.35 % 2) - 1, 0)
			task.wait(0.03)
		end
	end)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(6, 2)
	label.Size = UDim2.new(1, -12, 1, -2)
	label.FontFace = U.font
	label.TextSize = U.TEXT_SZ
	label.TextColor3 = U.theme.Text
	label.TextTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = frame

	local entry = { frame = frame, gui = nGui, h = h }
	table.insert(U.activeNotifs, entry)
	U.layoutNotifs()

	local fadeIn = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	U.Tween:Create(frame, fadeIn, { BackgroundTransparency = 0 }):Play()
	U.Tween:Create(st, fadeIn, { Transparency = 0 }):Play()
	U.Tween:Create(bar, fadeIn, { BackgroundTransparency = 0 }):Play()
	U.Tween:Create(label, fadeIn, { TextTransparency = 0 }):Play()

	task.delay(duration, function()
		local fadeOut = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local t1 = U.Tween:Create(frame, fadeOut, { BackgroundTransparency = 1 })
		U.Tween:Create(st, fadeOut, { Transparency = 1 }):Play()
		U.Tween:Create(bar, fadeOut, { BackgroundTransparency = 1 }):Play()
		U.Tween:Create(label, fadeOut, { TextTransparency = 1 }):Play()
		t1:Play()
		t1.Completed:Wait()
		for i, e in ipairs(U.activeNotifs) do
			if e == entry then table.remove(U.activeNotifs, i); break end
		end
		if nGui.Parent then nGui:Destroy() end
		U.layoutNotifs()
	end)
end
U.onFlag("NotificationPosition", U.layoutNotifs)

function U.closeColorPicker()
	if U.openColorPicker and U.openColorPicker.Parent then U.openColorPicker:Destroy() end
	U.openColorPicker = nil
end
function U.closeDropdown()
	if U.openDropdown and U.openDropdown.Parent then U.openDropdown:Destroy() end
	U.openDropdown = nil
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
	U._shuttingDown = true
	U.running = false

	
	local F = U.vflags
	if F then
		F.VisualsEnabled = false
		F.NoRecoil = false
		F.NoSpread = false
		F.LeftArmEnabled = false
		F.RightArmEnabled = false
		F.LeftGloveEnabled = false
		F.RightGloveEnabled = false
		F.HideGloveSurfaces = false
		F.RemoveSniperScope = false
		F.LightingAmbientEnabled = false
		F.LightingOutdoorAmbientEnabled = false
		F.LightingGlobalShadows = false
		F.LightingPrioritizeQuality = false
		F.Watermark = false
	end

	pcall(function()
		game:GetService("RunService"):UnbindFromRenderStep("SM_ESP")
	end)

	if type(U._cleanupVisuals) == "function" then
		pcall(U._cleanupVisuals)
	end
	if type(U._cleanupCombat) == "function" then
		pcall(U._cleanupCombat)
	end
	if type(U._cleanupMisc) == "function" then
		pcall(U._cleanupMisc)
	end

	pcall(function() U.closePopups() end)

	for _, name in ipairs({ "SimpleWatermark", "SM_ESP", "SimpleNotifs" }) do
		
	end
	if U.wmGui then pcall(function() U.wmGui:Destroy() end) U.wmGui = nil end
	if U.wm then pcall(function() U.wm:Destroy() end) U.wm = nil end
	if U.gui then pcall(function() U.gui:Destroy() end) U.gui = nil end
	if U.notifGui then pcall(function() U.notifGui:Destroy() end) U.notifGui = nil end

	
	pcall(function()
		local parent = U.guiParent and U.guiParent() or game:GetService("CoreGui")
		for _, n in ipairs({ "SimpleMenu", "SimpleWatermark", "SM_ESP", "SimpleNotifs", "wavelength" }) do
			local g = parent:FindFirstChild(n)
			if g then g:Destroy() end
		end
		
		for _, g in ipairs(parent:GetChildren()) do
			if g:IsA("ScreenGui") and (g.Name == "SM_ESP" or g.Name == "SimpleWatermark") then
				g:Destroy()
			end
		end
	end)

	print("wavelength unloaded")
end

function U.armPopupOpen()
	U.suppressPopupClose = tick() + 0.08
end

function U.objsAtMouse()
	local pos = U.UIS:GetMouseLocation()
	local ok, objs = pcall(function()
		return U.gui:GetGuiObjectsAtPosition(pos.X, pos.Y)
	end)
	if ok and objs then return objs end
	return {}
end

function U.ancestryHas(obj, ancestor)
	local cur = obj
	while cur do
		if cur == ancestor then return true end
		cur = cur.Parent
	end
	return false
end

function U.clickHits(ancestor)
	if not ancestor or not ancestor.Parent then return false end
	for _, o in ipairs(U.objsAtMouse()) do
		if U.ancestryHas(o, ancestor) then return true end
	end
	return false
end

function U.clickHitsNamed(...)
	local names = { ... }
	for _, o in ipairs(U.objsAtMouse()) do
		for _, n in ipairs(names) do
			if o.Name == n then return true end
		end
	end
	return false
end

function U.row(parent, order)
	local r = Instance.new("Frame")
	r.BackgroundTransparency = 1
	r.Size = UDim2.new(1, 0, 0, 18)
	r.LayoutOrder = order or 0
	r.Parent = parent
	return r
end

function U.indentRow(r, px)
	if not r then return r end
	px = px or 12
	
	local pad = r:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.Parent = r
	end
	pad.PaddingLeft = UDim.new(0, px)
	return r
end

function U.subOf(control, parentFlag)
	U.indentRow(control, 12)
	local function sync()
		control.Visible = U.vflags[parentFlag] == true
	end
	U.onFlag(parentFlag, sync)
	sync()
	return control
end

function U.subIf(control, keys, pred)
	U.indentRow(control, 12)
	local function sync()
		control.Visible = pred() and true or false
	end
	for _, k in ipairs(keys) do U.onFlag(k, sync) end
	sync()
	return control
end

function U.section(parent, title, col, row, rows)
	row = row or 1
	rows = rows or 1
	local w = math.floor((U.BODY_W - U.SEC_GAP * 3) / 2)
	local x = (col == 1) and U.SEC_GAP or (U.SEC_GAP * 2 + w)
	local totalH = U.BODY_H - U.SEC_GAP * 2
	local h = math.floor((totalH - U.SEC_GAP * (rows - 1)) / rows)
	local y = U.SEC_GAP + (row - 1) * (h + U.SEC_GAP)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = U.theme.SectionBg
	f.BorderSizePixel = 0
	f.Size = UDim2.fromOffset(w, h)
	f.Position = UDim2.fromOffset(x, y)
	f.Parent = parent

	local secStroke = Instance.new("UIStroke")
	secStroke.Thickness = 2
	secStroke.Color = U.theme.SectionBorder
	secStroke.LineJoinMode = Enum.LineJoinMode.Miter
	secStroke.Parent = f
	U.themeReg.sectionBorders[#U.themeReg.sectionBorders + 1] = secStroke

	
	local hdr = Instance.new("TextLabel")
	hdr.BackgroundTransparency = 1
	hdr.BorderSizePixel = 0
	hdr.FontFace = U.font
	hdr.TextSize = U.TEXT_SZ
	hdr.TextColor3 = U.theme.Text
	hdr.TextXAlignment = Enum.TextXAlignment.Center
	hdr.TextYAlignment = Enum.TextYAlignment.Center
	hdr.Text = tostring(title)
	hdr.AnchorPoint = Vector2.new(0.5, 0.5)
	hdr.Position = UDim2.new(0.5, 0, 0, 0)
	local hdrW = math.max(40, #tostring(title) * 7 + 12)
	hdr.Size = UDim2.fromOffset(hdrW, 14)
	hdr.ZIndex = 5
	hdr.Parent = f

	local content = Instance.new("ScrollingFrame")
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.new(1, -10, 1, -16)
	content.Position = UDim2.fromOffset(5, 12)
	content.ScrollBarThickness = 0
	content.CanvasSize = UDim2.fromOffset(0, 0)
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.ClipsDescendants = true
	content.Parent = f

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = content

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 1)
	pad.PaddingRight = UDim.new(0, 1)
	pad.PaddingTop = UDim.new(0, 1)
	pad.PaddingBottom = UDim.new(0, 2)
	pad.Parent = content
	return content
end

function U.mkToggle(parent, text, flag, order, default, keybindFlag)
	local r = U.row(parent, order)
	local on = default == true
	if flag then U.vflags[flag] = on end

	local rightReserve = keybindFlag and 56 or 0

	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(12, 12)
	box.Position = UDim2.fromOffset(0, 3)
	box.BackgroundColor3 = on and U.pulseColor() or Color3.fromRGB(55, 55, 55)
	box.BorderSizePixel = 0
	box.Parent = r
	U.controlStroke(box, 1)
	U.registerPulse(box, function() return on end)

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -(20 + rightReserve), 1, 0)
	t.Position = UDim2.fromOffset(18, 0)
	t.FontFace = U.font
	t.TextSize = U.TEXT_SZ
	t.TextColor3 = U.theme.Text
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = text
	t.Parent = r

	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.new(1, -rightReserve, 1, 0)
	hit.Text = ""
	hit.ZIndex = 2
	hit.Parent = r
	hit.MouseButton1Click:Connect(function()
		on = not on
		box.BackgroundColor3 = on and U.pulseColor() or Color3.fromRGB(55, 55, 55)
		if flag then U.setFlag(flag, on) end
	end)
	if flag then
		U.setters[flag] = function(v)
			on = v == true
			U.vflags[flag] = on
			box.BackgroundColor3 = on and U.pulseColor() or Color3.fromRGB(55, 55, 55)
			U.fireFlag(flag)
		end
	end

	if keybindFlag then
		U.vflags[keybindFlag] = U.vflags[keybindFlag] or Enum.KeyCode.RightAlt
		local kb = Instance.new("TextButton")
		kb.Name = "KeybindBox"
		kb.AutoButtonColor = false
		kb.BackgroundTransparency = 1
		kb.BorderSizePixel = 0
		kb.AnchorPoint = Vector2.new(1, 0.5)
		kb.Position = UDim2.new(1, 0, 0.5, 0)
		kb.Size = UDim2.fromOffset(50, 14)
		kb.FontFace = U.font
		kb.TextSize = U.TEXT_SZ
		kb.TextColor3 = U.theme.Text
		kb.TextXAlignment = Enum.TextXAlignment.Right
		kb.ZIndex = 5
		kb.Parent = r
		local function keyName(k)
			if typeof(k) == "EnumItem" then return k.Name end
			return "none"
		end
		local function fit(keyTxt)
			local display = "[" .. keyTxt .. "]"
			kb.Text = display
			local w = math.max(24, #display * 7 + 4)
			kb.Size = UDim2.fromOffset(w, 14)
		end
		fit(keyName(U.vflags[keybindFlag]))
		local listening = false
		kb.MouseButton1Click:Connect(function()
			if listening then return end
			listening = true
			fit("...")
			local conn
			conn = U.UIS.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape then
						fit(keyName(U.vflags[keybindFlag]))
					else
						U.vflags[keybindFlag] = input.KeyCode
						fit(keyName(input.KeyCode))
						U.fireFlag(keybindFlag)
					end
					listening = false
					conn:Disconnect()
				end
			end)
		end)
		U.setters[keybindFlag] = function(v)
			U.vflags[keybindFlag] = v
			fit(keyName(v))
			U.fireFlag(keybindFlag)
		end
	end
	return r
end

function U.formatSliderVal(val, step, suffix, maxV, infAt)
	if infAt and val >= maxV then return "inf" end
	local s
	if step >= 1 then
		s = tostring(math.floor(val + 1e-6))
	else
		local decimals = (step < 0.1) and 2 or 1
		local mult = 10 ^ decimals
		s = string.format("%." .. decimals .. "f", math.floor(val * mult + 0.5) / mult)
	end
	return s .. (suffix or "")
end

function U.mkSlider(parent, text, flag, minV, maxV, default, order, step, suffix, infAt)
	step = step or 1
	local r = U.row(parent, order)
	r.Size = UDim2.new(1, 0, 0, 28)
	U.vflags[flag] = default

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, -56, 0, 12)
	name.FontFace = U.font
	name.TextSize = U.TEXT_SZ
	name.TextColor3 = U.theme.Text
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = text
	name.Parent = r

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Size = UDim2.new(0, 52, 0, 12)
	valLbl.Position = UDim2.new(1, -52, 0, 0)
	valLbl.FontFace = U.font
	valLbl.TextSize = U.TEXT_SZ
	valLbl.TextColor3 = U.theme.Text
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Text = U.formatSliderVal(default, step, suffix, maxV, infAt)
	valLbl.Parent = r

	local track = Instance.new("Frame")
	track.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.fromOffset(0, 16)
	track.Parent = r
	U.controlStroke(track, 1)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = U.pulseColor()
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale((default - minV) / math.max(1e-6, maxV - minV), 1)
	fill.Parent = track
	U.registerPulse(fill, function() return true end)
	fill.ZIndex = 3
	do
		local cap = Instance.new("Frame")
		cap.Name = "SliderCap"
		cap.BorderSizePixel = 0
		cap.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
		cap.Size = UDim2.fromOffset(1, 12)
		cap.AnchorPoint = Vector2.new(0.5, 0.5)
		cap.Position = UDim2.new(1, 0, 0.5, 0)
		cap.ZIndex = 5
		cap.Parent = fill
	end

	local dragging = false
	local function setFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		local val = math.floor((minV + (maxV - minV) * rel) / step + 0.5) * step
		val = math.clamp(val, minV, maxV)
		if step >= 1 then val = math.floor(val + 1e-6) end
		U.vflags[flag] = val
		fill.Size = UDim2.fromScale((val - minV) / math.max(1e-6, maxV - minV), 1)
		valLbl.Text = U.formatSliderVal(val, step, suffix, maxV, infAt)
		U.fireFlag(flag)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	U.UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	U.UIS.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setFromX(input.Position.X)
		end
	end)
	U.setters[flag] = function(v)
		local val = math.clamp(tonumber(v) or default, minV, maxV)
		U.vflags[flag] = val
		fill.Size = UDim2.fromScale((val - minV) / math.max(1e-6, maxV - minV), 1)
		valLbl.Text = U.formatSliderVal(val, step, suffix, maxV, infAt)
		U.fireFlag(flag)
	end
	return r
end

function U.mkDoubleSlider(parent, text, flagMin, flagMax, minV, maxV, defMin, defMax, order, step, suffix)
	step = step or 1
	suffix = suffix or ""
	local r = U.row(parent, order)
	r.Size = UDim2.new(1, 0, 0, 28)
	defMin = defMin or minV
	defMax = defMax or maxV
	if defMin > defMax then defMin, defMax = defMax, defMin end
	U.vflags[flagMin] = defMin
	U.vflags[flagMax] = defMax

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, -90, 0, 12)
	name.FontFace = U.font
	name.TextSize = U.TEXT_SZ
	name.TextColor3 = U.theme.Text
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = text
	name.Parent = r

	local valLbl = Instance.new("TextLabel")
	valLbl.BackgroundTransparency = 1
	valLbl.Size = UDim2.fromOffset(88, 12)
	valLbl.Position = UDim2.new(1, -88, 0, 0)
	valLbl.FontFace = U.font
	valLbl.TextSize = U.TEXT_SZ
	valLbl.TextColor3 = U.theme.Text
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = r

	local track = Instance.new("Frame")
	track.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	track.BorderSizePixel = 0
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.fromOffset(0, 16)
	track.Parent = r
	U.controlStroke(track, 1)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = U.pulseColor()
	fill.BorderSizePixel = 0
	fill.ZIndex = 3
	fill.Parent = track
	U.registerPulse(fill, function() return true end)

	local function mkCap()
		local cap = Instance.new("Frame")
		cap.BorderSizePixel = 0
		cap.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
		cap.Size = UDim2.fromOffset(1, 12)
		cap.AnchorPoint = Vector2.new(0.5, 0.5)
		cap.ZIndex = 5
		cap.Parent = track
		return cap
	end
	local capA, capB = mkCap(), mkCap()

	local function snap(v)
		if step >= 1 then return math.floor(v / step + 0.5) * step end
		local places = #(tostring(step):match("%.(%d+)") or "1")
		return tonumber(string.format("%." .. places .. "f", math.floor(v / step + 0.5) * step)) or v
	end

	local function refresh()
		local a = math.clamp(U.vflags[flagMin] or minV, minV, maxV)
		local b = math.clamp(U.vflags[flagMax] or maxV, minV, maxV)
		if a > b then a, b = b, a end
		U.vflags[flagMin], U.vflags[flagMax] = a, b
		local ra = (a - minV) / math.max(1e-6, maxV - minV)
		local rb = (b - minV) / math.max(1e-6, maxV - minV)
		fill.Position = UDim2.new(ra, 0, 0, 0)
		fill.Size = UDim2.new(math.max(0, rb - ra), 0, 1, 0)
		capA.Position = UDim2.new(ra, 0, 0.5, 0)
		capB.Position = UDim2.new(rb, 0, 0.5, 0)
		valLbl.Text = tostring(a) .. suffix .. " - " .. tostring(b) .. suffix
	end
	refresh()

	local drag = nil
	local function at(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
		local v = snap(minV + (maxV - minV) * rel)
		v = math.clamp(v, minV, maxV)
		local a, b = U.vflags[flagMin], U.vflags[flagMax]
		if drag == "min" then
			a = math.min(v, b)
		elseif drag == "max" then
			b = math.max(v, a)
		else
			if math.abs(v - a) <= math.abs(v - b) then a = math.min(v, b) else b = math.max(v, a) end
		end
		U.vflags[flagMin], U.vflags[flagMax] = a, b
		refresh()
		U.fireFlag(flagMin)
		U.fireFlag(flagMax)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local rel = (input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X)
		local a = (U.vflags[flagMin] - minV) / math.max(1e-6, maxV - minV)
		local b = (U.vflags[flagMax] - minV) / math.max(1e-6, maxV - minV)
		drag = (math.abs(rel - a) <= math.abs(rel - b)) and "min" or "max"
		at(input.Position.X)
	end)
	U.UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then drag = nil end
	end)
	U.UIS.InputChanged:Connect(function(input)
		if drag and input.UserInputType == Enum.UserInputType.MouseMovement then at(input.Position.X) end
	end)
	U.setters[flagMin] = function(v) U.vflags[flagMin] = v; refresh(); U.fireFlag(flagMin) end
	U.setters[flagMax] = function(v) U.vflags[flagMax] = v; refresh(); U.fireFlag(flagMax) end
	return r
end

function U.mkDropdown(parent, text, flag, options, default, multi, order)
	local r = U.row(parent, order)
	r.Size = UDim2.new(1, 0, 0, 36)
	options = options or {}
	if multi then
		U.vflags[flag] = type(default) == "table" and default or {}
	else
		U.vflags[flag] = default
	end

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0, 12)
	name.FontFace = U.font
	name.TextSize = U.TEXT_SZ
	name.TextColor3 = U.theme.Text
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = text
	name.Parent = r

	local box = Instance.new("TextButton")
	box.Name = "DropBox"
	box.AutoButtonColor = false
	box.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	box.BorderSizePixel = 0
	box.Size = UDim2.new(1, 0, 0, 16)
	box.Position = UDim2.fromOffset(0, 14)
	box.FontFace = U.font
	box.TextSize = U.TEXT_SZ
	box.TextColor3 = U.theme.Text
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.Parent = r
	U.controlStroke(box, 1)

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
		if multi then
			local t = U.vflags[flag] or {}
			return table.find(t, opt) ~= nil
		end
		return tostring(U.vflags[flag] or "") == tostring(opt)
	end

	box.MouseButton1Click:Connect(function()
		U.closeColorPicker()
		U.closeSettings()
		if U.openDropdown and U.openDropdown.Parent then
			if U.openDropdown:GetAttribute("Flag") == flag then
				U.closeDropdown()
				return
			end
			U.closeDropdown()
		end
		if #options == 0 then return end
		local fullH = math.min(#options * 18, 140)
		local width = math.max(100, box.AbsoluteSize.X)
		local listFrame = Instance.new("Frame")
		listFrame.Name = "DropdownList"
		listFrame:SetAttribute("Flag", flag)
		listFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
		listFrame.BorderSizePixel = 0
		listFrame.ClipsDescendants = true
		listFrame.Size = UDim2.fromOffset(width, 0)
		listFrame.ZIndex = 220
		listFrame.Parent = U.gui

		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Size = UDim2.new(1, 0, 0, fullH)
		holder.ZIndex = 221
		holder.Parent = listFrame
		local lay = Instance.new("UIListLayout")
		lay.SortOrder = Enum.SortOrder.LayoutOrder
		lay.Parent = holder

		local borderCol = U.theme.ElementBorder or U.theme.SectionBorder
		local function edge(nm, size, pos)
			local e = Instance.new("Frame")
			e.Name = nm
			e.BorderSizePixel = 0
			e.BackgroundColor3 = borderCol
			e.Size = size
			e.Position = pos
			e.ZIndex = 223
			e.Parent = listFrame
			U.themeReg.elementBorders = U.themeReg.elementBorders or {}
			U.themeReg.elementBorders[#U.themeReg.elementBorders + 1] = e
		end
		edge("BLeft", UDim2.new(0, 1, 1, 0), UDim2.fromOffset(0, 0))
		edge("BRight", UDim2.new(0, 1, 1, 0), UDim2.new(1, -1, 0, 0))
		edge("BBottom", UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1))

		local abs = box.AbsolutePosition
		local gabs = U.gui.AbsolutePosition
		listFrame.Position = UDim2.fromOffset(abs.X - gabs.X, abs.Y - gabs.Y + box.AbsoluteSize.Y)

		for _, opt in ipairs(options) do
			local b = Instance.new("TextButton")
			b.AutoButtonColor = false
			b.BackgroundColor3 = isSelected(opt) and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(28, 28, 28)
			b.BorderSizePixel = 0
			b.Size = UDim2.new(1, 0, 0, 18)
			b.FontFace = U.font
			b.TextSize = U.TEXT_SZ
			b.TextColor3 = U.theme.Text
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.Text = "  " .. tostring(opt)
			b.ZIndex = 222
			b.Parent = holder
			b.MouseEnter:Connect(function()
				if not isSelected(opt) then b.BackgroundColor3 = Color3.fromRGB(34, 34, 34) end
			end)
			b.MouseLeave:Connect(function()
				b.BackgroundColor3 = isSelected(opt) and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(28, 28, 28)
			end)
			b.MouseButton1Click:Connect(function()
				if multi then
					local cur = type(U.vflags[flag]) == "table" and table.clone(U.vflags[flag]) or {}
					local found = table.find(cur, opt)
					if found then table.remove(cur, found) else table.insert(cur, opt) end
					U.vflags[flag] = cur
					for _, ch in ipairs(holder:GetChildren()) do
						if ch:IsA("TextButton") then
							local o = string.sub(ch.Text, 3)
							ch.BackgroundColor3 = isSelected(o) and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(28, 28, 28)
						end
					end
				else
					U.vflags[flag] = opt
					box.Text = " " .. tostring(opt)
					U.closeDropdown()
				end
				display()
				U.fireFlag(flag)
			end)
		end
		U.openDropdown = listFrame
		U.armPopupOpen()
		listFrame.InputBegan:Connect(function()
			U.armPopupOpen()
		end)
		U.Tween:Create(listFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(width, fullH)
		}):Play()
	end)
	U.setters[flag] = function(v)
		U.vflags[flag] = v
		display()
		U.fireFlag(flag)
	end
	return r
end

function U.mkTextbox(parent, text, flag, placeholder, order)
	local r = U.row(parent, order)
	r.Size = UDim2.new(1, 0, 0, 36)
	U.vflags[flag] = U.vflags[flag] or ""

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, 0, 0, 12)
	name.FontFace = U.font
	name.TextSize = U.TEXT_SZ
	name.TextColor3 = U.theme.Text
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = text
	name.Parent = r

	local box = Instance.new("TextBox")
	box.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	box.BorderSizePixel = 0
	box.Size = UDim2.new(1, 0, 0, 16)
	box.Position = UDim2.fromOffset(0, 14)
	box.FontFace = U.font
	box.TextSize = U.TEXT_SZ
	box.TextColor3 = U.theme.Text
	box.PlaceholderText = placeholder or ""
	box.Text = tostring(U.vflags[flag] or "")
	box.ClearTextOnFocus = false
	box.Parent = r
	U.controlStroke(box, 1)
	box.FocusLost:Connect(function()
		U.setFlag(flag, box.Text)
	end)
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

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.new(1, -60, 1, 0)
	name.FontFace = U.font
	name.TextSize = U.TEXT_SZ
	name.TextColor3 = U.theme.Text
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Text = text
	name.Parent = r

	local box = Instance.new("TextButton")
	box.Name = "KeybindBox"
	box.AutoButtonColor = false
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.FontFace = U.font
	box.TextSize = U.TEXT_SZ
	box.TextColor3 = U.theme.Text
	box.TextXAlignment = Enum.TextXAlignment.Right
	box.Parent = r

	local listening = false
	local function keyName(k)
		if typeof(k) == "EnumItem" then return k.Name end
		return "none"
	end
	local function fitKey(keyTxt)
		local display = "[" .. keyTxt .. "]"
		box.Text = display
		local w = math.max(24, #display * 7 + 4)
		box.Size = UDim2.fromOffset(w, 16)
		box.Position = UDim2.new(1, -w, 0, 1)
		name.Size = UDim2.new(1, -(w + 6), 1, 0)
	end
	fitKey(keyName(default))

	box.MouseButton1Click:Connect(function()
		if listening then return end
		listening = true
		fitKey("...")
		local conn
		conn = U.UIS.InputBegan:Connect(function(input, gp)
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					fitKey(keyName(U.vflags[flag]))
				else
					U.vflags[flag] = input.KeyCode
					fitKey(keyName(input.KeyCode))
					U.fireFlag(flag)
				end
				listening = false
				conn:Disconnect()
			end
		end)
	end)
	U.setters[flag] = function(v)
		U.vflags[flag] = v
		fitKey(keyName(v))
		U.fireFlag(flag)
	end
	return r
end

function U.mkColorRow(parent, text, order)
	local r = U.row(parent, order)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -40, 1, 0)
	t.FontFace = U.font
	t.TextSize = U.TEXT_SZ
	t.TextColor3 = U.theme.Text
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = text
	t.Parent = r
	return r
end

function U.mkButton(parent, text, order)
	local r = U.row(parent, order)
	local btn = Instance.new("TextButton")
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	btn.BorderSizePixel = 0
	btn.Size = UDim2.fromScale(1, 1)
	btn.FontFace = U.font
	btn.TextSize = U.TEXT_SZ
	btn.TextColor3 = U.theme.Text
	btn.Text = text
	btn.Parent = r
	U.controlStroke(btn, 1)
	return btn
end

function U.attachPicker(rowFrame, flagKey, defaultColor, noAlpha, title)
	title = string.lower(tostring(title or "color"))
	local alphaKey = flagKey .. "Transparency"
	U.vflags[flagKey] = defaultColor
	if not noAlpha then U.vflags[alphaKey] = 0 end

	local h, sat, val = defaultColor:ToHSV()
	local rightPad = rowFrame:GetAttribute("RightPad") or 2
	local sw = Instance.new("TextButton")
	sw.Name = "Swatch"
	sw.AutoButtonColor = false
	sw.Text = ""
	sw.Size = UDim2.fromOffset(28, 14)
	sw.AnchorPoint = Vector2.new(1, 0.5)
	sw.Position = UDim2.new(1, -rightPad, 0.5, 0)
	rowFrame:SetAttribute("RightPad", rightPad + 32)
	sw.BackgroundTransparency = 1
	sw.BorderSizePixel = 0
	sw.ZIndex = 12
	sw.Parent = rowFrame
	
	local swRim = Instance.new("Frame")
	swRim.Name = "SwatchRim"
	swRim.BackgroundTransparency = 1
	swRim.BorderSizePixel = 0
	swRim.Size = UDim2.fromScale(1, 1)
	swRim.ZIndex = 12
	swRim.Parent = sw
	local rimParts = {}
	local function addRim(pos, size)
		local e = Instance.new("Frame")
		e.BorderSizePixel = 0
		e.BackgroundColor3 = defaultColor
		e.Position = pos
		e.Size = size
		e.ZIndex = 12
		e.Parent = swRim
		rimParts[#rimParts + 1] = e
	end
	addRim(UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 1)) 
	addRim(UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1)) 
	addRim(UDim2.fromOffset(0, 0), UDim2.new(0, 1, 1, 0)) 
	addRim(UDim2.new(1, -1, 0, 0), UDim2.new(0, 1, 1, 0)) 
	
	local swFill = Instance.new("Frame")
	swFill.Name = "SwatchFill"
	swFill.BorderSizePixel = 0
	swFill.Size = UDim2.fromScale(1, 1)
	swFill.BackgroundColor3 = defaultColor
	swFill.BackgroundTransparency = (not noAlpha) and (U.vflags[alphaKey] or 0) or 0
	swFill.ZIndex = 13
	swFill.Parent = sw

	local function apply()
		local c = Color3.fromHSV(h, sat, val)
		U.vflags[flagKey] = c
		for _, e in ipairs(rimParts) do e.BackgroundColor3 = c end
		swFill.BackgroundColor3 = c
		if not noAlpha then
			swFill.BackgroundTransparency = U.vflags[alphaKey] or 0
		else
			swFill.BackgroundTransparency = 0
		end
		if flagKey == "ThemeText" then
			U.theme.Text = c
			if U.wmText then U.wmText.TextColor3 = c end
			U.refreshMenuTextColors()
		elseif flagKey == "ThemeBorder" then U.theme.Border = c; U.applyTheme()
		elseif flagKey == "ThemeSectionBorder" then U.theme.SectionBorder = c; U.applyTheme()
		elseif flagKey == "ThemeElementBorder" then U.theme.ElementBorder = c; U.applyTheme()
		elseif flagKey == "ThemeAccent1" then U.theme.Accent1 = c; U.applyTheme()
		elseif flagKey == "ThemeAccent2" then U.theme.Accent2 = c; U.applyTheme()
		end
		U.fireFlag(flagKey)
	end

	U.setters[flagKey] = function(v)
		if typeof(v) == "Color3" then
			h, sat, val = v:ToHSV()
			local c = Color3.fromHSV(h, sat, val)
			U.vflags[flagKey] = c
			for _, e in ipairs(rimParts) do e.BackgroundColor3 = c end
			swFill.BackgroundColor3 = c
			if not noAlpha then
				swFill.BackgroundTransparency = U.vflags[alphaKey] or 0
			else
				swFill.BackgroundTransparency = 0
			end
			if flagKey == "ThemeText" then
				U.theme.Text = c
				if U.wmText then U.wmText.TextColor3 = c end
				U.refreshMenuTextColors()
			elseif flagKey == "ThemeBorder" then U.theme.Border = c; U.applyTheme()
			elseif flagKey == "ThemeSectionBorder" then U.theme.SectionBorder = c; U.applyTheme()
			elseif flagKey == "ThemeAccent1" then U.theme.Accent1 = c; U.applyTheme()
			elseif flagKey == "ThemeAccent2" then U.theme.Accent2 = c; U.applyTheme()
			end
			if U.openPickerRefresh and U.openColorPicker and U.openColorPicker:GetAttribute("Flag") == flagKey then
				U.openPickerRefresh()
			end
			U.fireFlag(flagKey)
		end
	end
	if not noAlpha then
		U.setters[alphaKey] = function(a)
			U.vflags[alphaKey] = a
			swFill.BackgroundTransparency = a or 0
			if U.openPickerRefresh and U.openColorPicker and U.openColorPicker:GetAttribute("Flag") == flagKey then
				U.openPickerRefresh()
			end
			U.fireFlag(alphaKey)
		end
	end

	sw.MouseButton1Click:Connect(function()
		U.closeDropdown()
		if U.openColorPicker and U.openColorPicker.Parent then
			if U.openColorPicker:GetAttribute("Flag") == flagKey then
				U.closeColorPicker()
				return
			end
			U.closeColorPicker()
		end

		local MAP, BAR_H, PAD, TITLE_H_POP, TOG, GAP = 120, 12, 8, 16, 14, 6
		local POP_W = PAD + MAP + GAP + TOG + PAD
		local POP_H = PAD + TITLE_H_POP + MAP + 6 + BAR_H + (noAlpha and 0 or (6 + BAR_H)) + PAD

		local pop = Instance.new("Frame")
		pop.Name = "ColorPop"
		pop:SetAttribute("Flag", flagKey)
		pop.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
		pop.BorderSizePixel = 0
		pop.Size = UDim2.fromOffset(POP_W, POP_H)
		pop.ZIndex = 220
		pop.Active = true
		pop.Parent = U.gui
		local pst = Instance.new("UIStroke")
		pst.Color = U.theme.Border
		pst.Thickness = 1
		pst.Parent = pop

		local titleLbl = Instance.new("TextLabel")
		titleLbl.BackgroundTransparency = 1
		titleLbl.Size = UDim2.new(1, -PAD * 2, 0, TITLE_H_POP)
		titleLbl.Position = UDim2.fromOffset(PAD, 4)
		titleLbl.FontFace = U.font
		titleLbl.TextSize = U.TEXT_SZ
		titleLbl.TextColor3 = U.theme.Text
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Text = title
		titleLbl.ZIndex = 221
		titleLbl.Parent = pop

		local mapY = PAD + TITLE_H_POP
		local map = Instance.new("ImageButton")
		map.AutoButtonColor = false
		map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		map.BorderSizePixel = 0
		map.Size = UDim2.fromOffset(MAP, MAP)
		map.Position = UDim2.fromOffset(PAD, mapY)
		map.ZIndex = 221
		map.Parent = pop

		local white = Instance.new("Frame")
		white.BackgroundColor3 = Color3.new(1, 1, 1)
		white.BorderSizePixel = 0
		white.Size = UDim2.fromScale(1, 1)
		white.ZIndex = 222
		white.Parent = map
		local wg = Instance.new("UIGradient")
		wg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		wg.Parent = white

		local black = Instance.new("Frame")
		black.BackgroundColor3 = Color3.new(0, 0, 0)
		black.BorderSizePixel = 0
		black.Size = UDim2.fromScale(1, 1)
		black.ZIndex = 223
		black.Parent = map
		local bg = Instance.new("UIGradient")
		bg.Rotation = 90
		bg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		bg.Parent = black

		local mapDot = Instance.new("Frame")
		mapDot.Size = UDim2.fromOffset(8, 8)
		mapDot.AnchorPoint = Vector2.new(0.5, 0.5)
		mapDot.BackgroundColor3 = Color3.new(1, 1, 1)
		mapDot.BorderSizePixel = 0
		mapDot.ZIndex = 224
		mapDot.Parent = map
		local mds = Instance.new("UIStroke")
		mds.Color = Color3.new(0, 0, 0)
		mds.Parent = mapDot

		local hueBar = Instance.new("ImageButton")
		hueBar.AutoButtonColor = false
		hueBar.BorderSizePixel = 0
		hueBar.Size = UDim2.fromOffset(MAP, BAR_H)
		hueBar.Position = UDim2.fromOffset(PAD, mapY + MAP + 6)
		hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
		hueBar.ZIndex = 221
		hueBar.Parent = pop
		local hg = Instance.new("UIGradient")
		hg.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
		})
		hg.Parent = hueBar
		local hueDot = Instance.new("Frame")
		hueDot.Size = UDim2.fromOffset(2, BAR_H + 4)
		hueDot.AnchorPoint = Vector2.new(0.5, 0.5)
		hueDot.Position = UDim2.new(h, 0, 0.5, 0)
		hueDot.BackgroundColor3 = Color3.new(1, 1, 1)
		hueDot.BorderSizePixel = 0
		hueDot.ZIndex = 223
		hueDot.Parent = hueBar
		local hds = Instance.new("UIStroke")
		hds.Color = Color3.new(0, 0, 0)
		hds.Thickness = 1
		hds.Parent = hueDot

		local refreshUI
		local colorTog = Instance.new("TextButton")
		colorTog.Name = "CycleColor"
		colorTog.AutoButtonColor = false
		colorTog.Text = ""
		colorTog.Size = UDim2.fromOffset(TOG, TOG)
		colorTog.Position = UDim2.fromOffset(PAD + MAP + GAP, mapY + MAP + 6 + (BAR_H - TOG) / 2)
		colorTog.BackgroundColor3 = U.vflags[flagKey .. "CycleColor"] and U.pulseColor() or Color3.fromRGB(55, 55, 55)
		colorTog.BorderSizePixel = 0
		colorTog.ZIndex = 221
		colorTog.Parent = pop
		U.registerPulse(colorTog, function() return U.vflags[flagKey .. "CycleColor"] == true end)
		colorTog.MouseButton1Click:Connect(function()
			local on = not (U.vflags[flagKey .. "CycleColor"] == true)
			U.setCycleColor(flagKey, on)
			colorTog.BackgroundColor3 = on and U.pulseColor() or Color3.fromRGB(55, 55, 55)
			if on then
				h = U.cycle.hue
				apply()
			end
			if refreshUI then refreshUI() end
		end)

		local alphaBar, alphaDot
		if not noAlpha then
			alphaBar = Instance.new("ImageButton")
			alphaBar.AutoButtonColor = false
			alphaBar.BorderSizePixel = 0
			alphaBar.Size = UDim2.fromOffset(MAP, BAR_H)
			alphaBar.Position = UDim2.fromOffset(PAD, mapY + MAP + 6 + BAR_H + 6)
			alphaBar.BackgroundColor3 = Color3.fromHSV(h, sat, val)
			alphaBar.ZIndex = 221
			alphaBar.Parent = pop
			local ag = Instance.new("UIGradient")
			ag.Rotation = 0
			ag.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			ag.Parent = alphaBar
			alphaDot = Instance.new("Frame")
			alphaDot.Size = UDim2.fromOffset(2, BAR_H + 4)
			alphaDot.AnchorPoint = Vector2.new(0.5, 0.5)
			alphaDot.Position = UDim2.new(U.vflags[alphaKey] or 0, 0, 0.5, 0)
			alphaDot.BackgroundColor3 = Color3.new(1, 1, 1)
			alphaDot.BorderSizePixel = 0
			alphaDot.ZIndex = 223
			alphaDot.Parent = alphaBar
			local ads = Instance.new("UIStroke")
			ads.Color = Color3.new(0, 0, 0)
			ads.Thickness = 1
			ads.Parent = alphaDot

			local alphaTog = Instance.new("TextButton")
			alphaTog.Name = "CycleAlpha"
			alphaTog.AutoButtonColor = false
			alphaTog.Text = ""
			alphaTog.Size = UDim2.fromOffset(TOG, TOG)
			alphaTog.Position = UDim2.fromOffset(PAD + MAP + GAP, mapY + MAP + 6 + BAR_H + 6 + (BAR_H - TOG) / 2)
			alphaTog.BackgroundColor3 = U.vflags[flagKey .. "CycleAlpha"] and U.pulseColor() or Color3.fromRGB(55, 55, 55)
			alphaTog.BorderSizePixel = 0
			alphaTog.ZIndex = 221
			alphaTog.Parent = pop
			U.registerPulse(alphaTog, function() return U.vflags[flagKey .. "CycleAlpha"] == true end)
			alphaTog.MouseButton1Click:Connect(function()
				local on = not (U.vflags[flagKey .. "CycleAlpha"] == true)
				U.setCycleAlpha(flagKey, on)
				alphaTog.BackgroundColor3 = on and U.pulseColor() or Color3.fromRGB(55, 55, 55)
				if on then
					U.vflags[alphaKey] = U.cycle.alpha
				end
				if refreshUI then refreshUI() end
			end)

		end

		refreshUI = function()
			map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			mapDot.Position = UDim2.fromScale(sat, 1 - val)
			hueDot.Position = UDim2.new(h, 0, 0.5, 0)
			if alphaBar then
				alphaBar.BackgroundColor3 = Color3.fromHSV(h, sat, val)
				alphaDot.Position = UDim2.new(U.vflags[alphaKey] or 0, 0, 0.5, 0)
			end
		end
		U.openPickerRefresh = refreshUI
		pop.Destroying:Connect(function()
			if U.openPickerRefresh == refreshUI then U.openPickerRefresh = nil end
		end)

		local drag = nil
		local function move(pos)
			if drag == "map" then
				sat = math.clamp((pos.X - map.AbsolutePosition.X) / math.max(map.AbsoluteSize.X, 1), 0, 1)
				val = 1 - math.clamp((pos.Y - map.AbsolutePosition.Y) / math.max(map.AbsoluteSize.Y, 1), 0, 1)
				apply(); refreshUI()
			elseif drag == "hue" then
				h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
				apply(); refreshUI()
			elseif drag == "alpha" and alphaBar then
				U.vflags[alphaKey] = math.clamp((pos.X - alphaBar.AbsolutePosition.X) / math.max(alphaBar.AbsoluteSize.X, 1), 0, 1)
				apply(); refreshUI()
			end
		end
		local function beginDrag(which, input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			U.armPopupOpen()
			drag = which
			move(input.Position)
		end
		map.InputBegan:Connect(function(input) beginDrag("map", input) end)
		hueBar.InputBegan:Connect(function(input) beginDrag("hue", input) end)
		if alphaBar then
			alphaBar.InputBegan:Connect(function(input) beginDrag("alpha", input) end)
		end
		local c1 = U.UIS.InputChanged:Connect(function(i)
			if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				move(i.Position)
			end
		end)
		local c2 = U.UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = nil
			end
		end)
		pop.Destroying:Connect(function()
			c1:Disconnect(); c2:Disconnect()
		end)

		local a = sw.AbsolutePosition
		local origin = U.gui.AbsolutePosition
		local px = a.X - origin.X + sw.AbsoluteSize.X + 6
		local py = a.Y - origin.Y
		if U.gui.AbsoluteSize.X > 0 and px + POP_W > U.gui.AbsoluteSize.X then
			px = a.X - origin.X - POP_W - 6
		end
		pop.Position = UDim2.fromOffset(px, py)
		if U.vflags[flagKey .. "CycleColor"] then
			h = U.cycle.hue
			apply()
		end
		if U.vflags[flagKey .. "CycleAlpha"] then
			U.vflags[alphaKey] = U.cycle.alpha
		end
		U.openColorPicker = pop
		U.armPopupOpen()
		refreshUI()
	end)

	return sw
end

function U.buildShell()
	local nTabs = math.max(1, #U.TAB_NAMES)
	local TAB_W = math.floor(U.BODY_W / nTabs)
	local TAB_H = 22
	U.TAB_W, U.TAB_H = TAB_W, TAB_H

	U.gui = Instance.new("ScreenGui")
	U.gui.Name = "SimpleMenuExample"
	U.gui.ResetOnSpawn = false
	U.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	U.gui.IgnoreGuiInset = true
	U.gui.Parent = U.guiParent()

	U.shell = Instance.new("Frame")
	U.shell.Name = "Shell"
	U.shell.BackgroundColor3 = U.theme.Background
	U.shell.BorderSizePixel = 0
	U.shell.ClipsDescendants = true
	U.shell.Active = true
	U.shell.Size = UDim2.fromOffset(U.BODY_W, U.TITLE_H + U.BODY_H + U.LINE_H)
	U.shell.Position = UDim2.new(0.5, -U.BODY_W / 2, 0.5, -(U.TITLE_H + U.BODY_H) / 2)
	U.shell.Parent = U.gui
	U.themeReg.bgs[#U.themeReg.bgs + 1] = U.shell

	local shellStroke = Instance.new("UIStroke")
	shellStroke.Thickness = 2
	shellStroke.Color = U.theme.Border
	shellStroke.LineJoinMode = Enum.LineJoinMode.Miter
	shellStroke.Parent = U.shell
	U.themeReg.borders[#U.themeReg.borders + 1] = shellStroke

	U.accent = Instance.new("Frame")
	U.accent.Name = "Accent"
	U.accent.BackgroundColor3 = Color3.new(1, 1, 1)
	U.accent.BorderSizePixel = 0
	U.accent.Size = UDim2.new(1, 0, 0, U.LINE_H)
	U.accent.ZIndex = 5
	U.accent.Parent = U.shell
	local accentGrad = Instance.new("UIGradient")
	accentGrad.Color = U.accentSequence()
	accentGrad.Parent = U.accent
	U.themeReg.accents[#U.themeReg.accents + 1] = accentGrad
	task.spawn(function()
		while U.accent and U.accent.Parent do
			accentGrad.Offset = Vector2.new((tick() * 0.35 % 2) - 1, 0)
			task.wait(0.03)
		end
	end)

	U.titleBar = Instance.new("Frame")
	U.titleBar.BackgroundColor3 = U.theme.Background
	U.titleBar.BorderSizePixel = 0
	U.titleBar.Active = true
	U.themeReg.bgs[#U.themeReg.bgs + 1] = U.titleBar
	U.titleBar.Size = UDim2.new(1, 0, 0, U.TITLE_H)
	U.titleBar.Position = UDim2.fromOffset(0, U.LINE_H)
	U.titleBar.Parent = U.shell

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, -12, 1, 0)
	titleLabel.Position = UDim2.fromOffset(8, 0)
	titleLabel.FontFace = U.font
	titleLabel.TextSize = U.TEXT_SZ
	titleLabel.TextColor3 = U.theme.Text
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "wavelength"
	titleLabel.Parent = U.titleBar

	U.body = Instance.new("Frame")
	U.body.Name = "Body"
	U.body.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
	U.body.BorderSizePixel = 0
	U.body.Size = UDim2.fromOffset(U.BODY_W, U.BODY_H)
	U.body.Position = UDim2.fromOffset(0, U.TITLE_H + U.LINE_H)
	U.body.ClipsDescendants = true
	U.body.Active = true
	U.body.Parent = U.shell

	U.pages = Instance.new("Frame")
	U.pages.BackgroundTransparency = 1
	U.pages.Size = UDim2.fromScale(1, 1)
	U.pages.Parent = U.body

	U.pages.ClipsDescendants = true
	U.pageFrames = {}
	for _, n in ipairs(U.TAB_NAMES) do
		local p = Instance.new("Frame")
		p.Name = n
		p.BackgroundTransparency = 1
		p.Size = UDim2.fromScale(1, 1)
		p.Position = UDim2.fromScale(0, 0)
		p.Visible = false
		p.Parent = U.pages
		U.pageFrames[n] = p
	end
	if U.pageFrames.combat then
		U.pageFrames.combat.Visible = true
	elseif U.TAB_NAMES[1] and U.pageFrames[U.TAB_NAMES[1]] then
		U.pageFrames[U.TAB_NAMES[1]].Visible = true
		U.currentTab = U.TAB_NAMES[1]
	end
end

function U.buildConfig()
	local CONFIG_FOLDER = "SimpleMenuConfigs"
	local selectedConfig = nil
	local configListFrame

	local function ensureFolder()
		if isfolder and not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
	end
	local function listConfigs()
		ensureFolder()
		local out = {}
		if listfiles then
			for _, f in ipairs(listfiles(CONFIG_FOLDER)) do
				local name = f:match("([^/\\]+)%.json$")
				if name then out[#out + 1] = name end
			end
		end
		table.sort(out)
		return out
	end
	local function refreshConfigList()
		if not configListFrame then return end
		for _, c in ipairs(configListFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		for i, name in ipairs(listConfigs()) do
			local b = Instance.new("TextButton")
			b.AutoButtonColor = false
			b.BackgroundColor3 = (selectedConfig == name) and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(28, 28, 28)
			b.BorderSizePixel = 0
			b.Size = UDim2.new(1, 0, 0, 18)
			b.FontFace = U.font
			b.TextSize = U.TEXT_SZ
			b.TextColor3 = U.theme.Text
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.Text = "  " .. name
			b.LayoutOrder = i
			b.Parent = configListFrame
			b.MouseButton1Click:Connect(function()
				selectedConfig = name
				refreshConfigList()
			end)
		end
	end
	local function serializeFlags()
		local data = {}
		for k, v in pairs(U.vflags) do
			if typeof(v) == "EnumItem" then data[k] = { __enum = tostring(v) }
			elseif typeof(v) == "Color3" then data[k] = { __color = { v.R, v.G, v.B } }
			else data[k] = v end
		end
		data.__theme = {
			Text = { U.theme.Text.R, U.theme.Text.G, U.theme.Text.B },
			Border = { U.theme.Border.R, U.theme.Border.G, U.theme.Border.B },
			Accent1 = { U.theme.Accent1.R, U.theme.Accent1.G, U.theme.Accent1.B },
			Accent2 = { U.theme.Accent2.R, U.theme.Accent2.G, U.theme.Accent2.B },
			Background = { U.theme.Background.R, U.theme.Background.G, U.theme.Background.B },
		}
		return data
	end
	local function applySerialized(data)
		if type(data) ~= "table" then return end
		for k, v in pairs(data) do
			if k == "__theme" and type(v) == "table" then
				for tk, tv in pairs(v) do
					if type(tv) == "table" and U.theme[tk] then
						U.theme[tk] = Color3.new(tv[1], tv[2], tv[3])
					end
				end
			elseif type(v) == "table" and v.__color then
				local col = Color3.new(v.__color[1], v.__color[2], v.__color[3])
				U.vflags[k] = col
				if U.setters[k] then U.setters[k](col) end
			elseif type(v) == "table" and v.__enum then
				local name = v.__enum:match("KeyCode%.(.+)$") or v.__enum
				local ok, enum = pcall(function() return Enum.KeyCode[name] end)
				if ok then U.vflags[k] = enum end
			elseif k ~= "__theme" then
				U.vflags[k] = v
				if U.setters[k] then U.setters[k](v) end
			end
		end
		
		U.cycle.colorFlags = {}
		U.cycle.alphaFlags = {}
		for k, v in pairs(U.vflags) do
			if type(k) == "string" and v == true then
				if k:sub(-10) == "CycleColor" then
					local flagKey = k:sub(1, -11)
					U.setCycleColor(flagKey, true)
				elseif k:sub(-10) == "CycleAlpha" then
					local flagKey = k:sub(1, -11)
					U.setCycleAlpha(flagKey, true)
				end
			end
		end
		U.applyTheme()
		U.shell.BackgroundColor3 = U.theme.Background
		U.titleBar.BackgroundColor3 = U.theme.Background
		U.refreshMenuTextColors()
	end

	local p = U.pageFrames.config
	local configsSec = U.section(p, "configs", 1)
	local settingsSec = U.section(p, "settings", 2)

	U.mkTextbox(configsSec, "name", "ConfigName", "config name", 1)
	local createBtn = U.mkButton(configsSec, "create / save", 2)
	createBtn.MouseButton1Click:Connect(function()
		local name = tostring(U.vflags.ConfigName or ""):gsub("[^%w%-%_ ]", "")
		if name == "" then U.pushNotification({ text = "enter a config name", duration = 2 }); return end
		ensureFolder()
		local ok, err = pcall(function()
			writefile(CONFIG_FOLDER .. "/" .. name .. ".json", U.Http:JSONEncode(serializeFlags()))
		end)
		if ok then
			selectedConfig = name
			refreshConfigList()
			U.pushNotification({ text = 'created "' .. name .. '" main config', duration = 2 })
		else
			U.pushNotification({ text = "save failed: " .. tostring(err), duration = 3 })
		end
	end)
	local loadBtn = U.mkButton(configsSec, "load", 3)
	loadBtn.MouseButton1Click:Connect(function()
		if not selectedConfig then U.pushNotification({ text = "select a config first", duration = 2 }); return end
		local ok, data = pcall(function()
			return U.Http:JSONDecode(readfile(CONFIG_FOLDER .. "/" .. selectedConfig .. ".json"))
		end)
		if ok and type(data) == "table" then
			applySerialized(data)
			U.pushNotification({ text = 'loaded "' .. selectedConfig .. '" main config', duration = 2 })
		else
			U.pushNotification({ text = "load failed", duration = 2 })
		end
	end)
	local delBtn = U.mkButton(configsSec, "delete", 4)
	delBtn.MouseButton1Click:Connect(function()
		if not selectedConfig then U.pushNotification({ text = "select a config first", duration = 2 }); return end
		local name = selectedConfig
		pcall(function() delfile(CONFIG_FOLDER .. "/" .. name .. ".json") end)
		selectedConfig = nil
		refreshConfigList()
		U.pushNotification({ text = 'deleted "' .. name .. '" main config', duration = 2 })
	end)

	do
		local listLabel = Instance.new("TextLabel")
		listLabel.BackgroundTransparency = 1
		listLabel.Size = UDim2.new(1, 0, 0, 14)
		listLabel.FontFace = U.font
		listLabel.TextSize = U.TEXT_SZ
		listLabel.TextColor3 = U.theme.Text
		listLabel.TextXAlignment = Enum.TextXAlignment.Left
		listLabel.Text = "saved"
		listLabel.LayoutOrder = 5
		listLabel.Parent = configsSec
		configListFrame = Instance.new("Frame")
		configListFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
		configListFrame.BorderSizePixel = 0
		configListFrame.Size = UDim2.new(1, 0, 0, 120)
		configListFrame.LayoutOrder = 6
		configListFrame.Parent = configsSec
		local listLay = Instance.new("UIListLayout")
		listLay.SortOrder = Enum.SortOrder.LayoutOrder
		listLay.Parent = configListFrame
		refreshConfigList()
	end

	local o = 0
	local function nextOrder() o += 1; return o end

	U.attachPicker(U.mkColorRow(settingsSec, "text", nextOrder()), "ThemeText", U.theme.Text, true, "text color")
	U.attachPicker(U.mkColorRow(settingsSec, "border", nextOrder()), "ThemeBorder", U.theme.Border, true, "border color")
	U.attachPicker(U.mkColorRow(settingsSec, "section border", nextOrder()), "ThemeSectionBorder", U.theme.SectionBorder, true, "section border")
	U.attachPicker(U.mkColorRow(settingsSec, "element border", nextOrder()), "ThemeElementBorder", U.theme.ElementBorder or U.theme.SectionBorder, true, "element border")
	do
		local accentRow = U.mkColorRow(settingsSec, "accent", nextOrder())
		U.attachPicker(accentRow, "ThemeAccent1", U.theme.Accent1, true, "accent a")
		U.attachPicker(accentRow, "ThemeAccent2", U.theme.Accent2, true, "accent b")
	end
	U.mkKeybind(settingsSec, "menu keybind", "MenuKeybind", Enum.KeyCode.RightShift, nextOrder())
	U.mkDropdown(settingsSec, "notification position", "NotificationPosition",
		{ "top left", "top right", "bottom left", "bottom right", "center" }, "bottom right", false, nextOrder())

	U.mkToggle(settingsSec, "watermark", "Watermark", nextOrder(), false)
	U.subOf(U.mkDropdown(settingsSec, "items", "WatermarkItems", { "ping", "fps", "message" }, { "ping", "fps" }, true, nextOrder()), "Watermark")
	do
		local msgBox = U.mkTextbox(settingsSec, "message", "WatermarkMessage", "message", nextOrder())
		U.indentRow(msgBox, 12)
		local function syncMsg()
			local has = false
			for _, it in ipairs(U.vflags.WatermarkItems or {}) do
				if it == "message" then has = true; break end
			end
			msgBox.Visible = (U.vflags.Watermark == true) and has
		end
		U.onFlag("Watermark", syncMsg)
		U.onFlag("WatermarkItems", syncMsg)
		syncMsg()
	end

	do
		local wgui = Instance.new("ScreenGui")
		wgui.Name = "SimpleWatermark"
		wgui.ResetOnSpawn = false
		wgui.IgnoreGuiInset = true
		wgui.Parent = U.guiParent()
		U.wmGui = wgui
		local wm = Instance.new("Frame")
		wm.BackgroundColor3 = U.theme.Background
		wm.BorderSizePixel = 0
		wm.Position = UDim2.fromScale(0.5, 0.5)
		wm.AnchorPoint = Vector2.new(0.5, 0.5)
		wm.Size = UDim2.fromOffset(160, 22)
		wm.Active = true
		wm.Parent = wgui
		U.wm = wm
		U.themeReg.bgs[#U.themeReg.bgs + 1] = wm
		local wst = Instance.new("UIStroke")
		wst.Thickness = 2
		wst.Color = U.theme.Border
		wst.LineJoinMode = Enum.LineJoinMode.Miter
		wst.Parent = wm
		U.themeReg.borders[#U.themeReg.borders + 1] = wst
		local wbar = Instance.new("Frame")
		wbar.Size = UDim2.new(1, 0, 0, 2)
		wbar.BorderSizePixel = 0
		wbar.BackgroundColor3 = Color3.new(1, 1, 1)
		wbar.ZIndex = 2
		wbar.Parent = wm
		local wg = Instance.new("UIGradient")
		wg.Color = U.accentSequence()
		wg.Parent = wbar
		U.themeReg.accents[#U.themeReg.accents + 1] = wg
		task.spawn(function()
			while wbar.Parent do
				wg.Offset = Vector2.new((tick() * 0.35 % 2) - 1, 0)
				task.wait(0.03)
			end
		end)
		local wtxt = Instance.new("TextLabel")
		U.wmText = wtxt
		wtxt.BackgroundTransparency = 1
		wtxt.Position = UDim2.fromOffset(6, 2)
		wtxt.Size = UDim2.new(1, -12, 1, -2)
		wtxt.FontFace = U.font
		wtxt.TextSize = U.TEXT_SZ
		wtxt.TextColor3 = U.theme.Text
		wtxt.TextXAlignment = Enum.TextXAlignment.Left
		wtxt.Text = ""
		wtxt.Parent = wm

		local fps = 60
		task.spawn(function()
			local frames = 0
			U.Run.RenderStepped:Connect(function() if U.running then frames += 1 end end)
			while U.running do task.wait(1); fps = frames; frames = 0 end
		end)

		local Stats = game:GetService("Stats")
		local function getRobloxPing()
			local ok, v = pcall(function()
				return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			return ok and v or 0
		end
		local function getRobloxFps()
			local ok, v = pcall(function()
				return math.floor(workspace:GetRealPhysicsFPS())
			end)
			if ok and v and v > 0 then return v end
			return fps
		end

		local function refreshWm()
			local on = U.vflags.Watermark == true
			wm.Visible = on
			if not on then return end
			local parts = {}
			for _, item in ipairs(U.vflags.WatermarkItems or {}) do
				if item == "message" then parts[#parts + 1] = tostring(U.vflags.WatermarkMessage or "")
				elseif item == "fps" then parts[#parts + 1] = "fps: " .. tostring(getRobloxFps())
				elseif item == "ping" then parts[#parts + 1] = "ping: " .. tostring(getRobloxPing())
				end
			end
			local out = table.concat(parts, " | ")
			wtxt.Text = out
			wtxt.TextColor3 = U.theme.Text
			wm.Size = UDim2.fromOffset(math.max(80, #out * 7 + 16), 22)
		end
		U.onFlag("Watermark", refreshWm)
		U.onFlag("WatermarkItems", refreshWm)
		U.onFlag("WatermarkMessage", refreshWm)
		task.spawn(function()
			while U.running do task.wait(0.1); refreshWm() end
		end)
		refreshWm()

		do
			local dragging, d0, p0
			wm.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					d0 = input.Position
					local abs = wm.AbsolutePosition
					wm.AnchorPoint = Vector2.new(0, 0)
					wm.Position = UDim2.fromOffset(abs.X, abs.Y)
					p0 = wm.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then dragging = false end
					end)
				end
			end)
			U.UIS.InputChanged:Connect(function(input)
				if not dragging then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					local d = input.Position - d0
					wm.Position = UDim2.fromOffset(p0.X.Offset + d.X, p0.Y.Offset + d.Y)
				end
			end)
		end
	end

	local unloadBtn = U.mkButton(settingsSec, "unload", nextOrder())
	local unloadArmed = false
	unloadBtn.MouseButton1Click:Connect(function()
		if not unloadArmed then
			unloadArmed = true
			unloadBtn.Text = "are you sure?"
			task.delay(2, function()
				if unloadBtn.Parent then unloadArmed = false; unloadBtn.Text = "unload" end
			end)
			return
		end
		U.shutdown()
	end)
end

function U.buildTabs()
	U.tabRail = Instance.new("Frame")
	U.tabRail.Name = "TabRail"
	U.tabRail.BackgroundColor3 = U.theme.Background
	U.tabRail.BorderSizePixel = 0
	U.tabRail.Active = true
	U.tabRail.Size = UDim2.new(1, 0, 0, U.TAB_H)
	U.tabRail.Position = UDim2.fromOffset(0, U.TITLE_H + U.LINE_H + U.BODY_H)
	U.tabRail.Parent = U.shell

	U.tabButtons = {}
	U.currentTab = "combat"

	local tabIndex = {}
	for i, n in ipairs(U.TAB_NAMES) do tabIndex[n] = i end
	local swiping = false

	local function selectTab(name)
		if name == U.currentTab or swiping then return end
		U.closePopups()
		local from, to = U.currentTab, name
		local dir = (tabIndex[to] or 0) > (tabIndex[from] or 0) and 1 or -1
		local oldPage = U.pageFrames[from]
		local newPage = U.pageFrames[to]
		U.currentTab = name
		for n, btn in pairs(U.tabButtons) do
			btn.BackgroundColor3 = (n == name) and Color3.fromRGB(28, 28, 28) or U.theme.Background
			btn.TextColor3 = U.theme.Text
			local acc = btn:FindFirstChild("TabAccent")
			if acc then acc.Visible = (n == name) end
		end
		if not oldPage or not newPage then
			for n, p in pairs(U.pageFrames) do
				p.Visible = (n == name)
				p.Position = UDim2.fromScale(0, 0)
			end
			return
		end
		swiping = true
		newPage.Visible = true
		newPage.Position = UDim2.fromScale(dir, 0)
		oldPage.Position = UDim2.fromScale(0, 0)
		local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		U.Tween:Create(oldPage, info, { Position = UDim2.fromScale(-dir, 0) }):Play()
		local tw = U.Tween:Create(newPage, info, { Position = UDim2.fromScale(0, 0) })
		tw:Play()
		tw.Completed:Connect(function()
			oldPage.Visible = false
			oldPage.Position = UDim2.fromScale(0, 0)
			swiping = false
		end)
	end

	for i, name in ipairs(U.TAB_NAMES) do
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.AutoButtonColor = false
		btn.BackgroundColor3 = (name == U.currentTab) and Color3.fromRGB(28, 28, 28) or U.theme.Background
		btn.BorderSizePixel = 0
		btn.Size = UDim2.fromOffset(U.TAB_W, U.TAB_H)
		btn.Position = UDim2.fromOffset((i - 1) * U.TAB_W, 0)
		btn.FontFace = U.font
		btn.TextSize = U.TEXT_SZ
		btn.TextColor3 = U.theme.Text
		btn.Text = name
		btn.Parent = U.tabRail
		local tabAcc = Instance.new("Frame")
		tabAcc.Name = "TabAccent"
		tabAcc.BorderSizePixel = 0
		tabAcc.Size = UDim2.new(1, 0, 0, 2)
		tabAcc.Position = UDim2.new(0, 0, 1, -2)
		tabAcc.BackgroundColor3 = U.theme.Accent1
		tabAcc.Visible = (name == U.currentTab)
		tabAcc.ZIndex = 3
		tabAcc.Parent = btn
		U.themeReg.tabAccents = U.themeReg.tabAccents or {}
		U.themeReg.tabAccents[#U.themeReg.tabAccents + 1] = tabAcc
		U.tabButtons[name] = btn
		btn.MouseButton1Click:Connect(function() selectTab(name) end)
	end

	local tabExpanded = false
	local baseH = U.TITLE_H + U.LINE_H + U.BODY_H
	local expandedH = baseH + U.TAB_H
	U.shell.Size = UDim2.fromOffset(U.BODY_W, baseH)

	local function setTabsExpanded(open)
		if tabExpanded == open then return end
		tabExpanded = open
		U.Tween:Create(U.shell, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(U.BODY_W, open and expandedH or baseH),
		}):Play()
	end

	local hoverZone = Instance.new("Frame")
	hoverZone.Name = "TabHoverZone"
	hoverZone.BackgroundTransparency = 1
	hoverZone.BorderSizePixel = 0
	hoverZone.Size = UDim2.new(1, 0, 0, 16)
	hoverZone.Position = UDim2.new(0, 0, 1, -16)
	hoverZone.ZIndex = 20
	hoverZone.Parent = U.body

	local tabHoverScore, closeToken = 0, 0
	local function tabEnter()
		tabHoverScore += 1
		setTabsExpanded(true)
	end
	local function tabLeave()
		tabHoverScore = math.max(0, tabHoverScore - 1)
		closeToken += 1
		local token = closeToken
		task.delay(0.12, function()
			if token ~= closeToken then return end
			if tabHoverScore <= 0 then setTabsExpanded(false) end
		end)
	end
	hoverZone.MouseEnter:Connect(tabEnter)
	hoverZone.MouseLeave:Connect(tabLeave)
	U.tabRail.MouseEnter:Connect(tabEnter)
	U.tabRail.MouseLeave:Connect(tabLeave)
	for _, btn in pairs(U.tabButtons) do
		btn.MouseEnter:Connect(tabEnter)
		btn.MouseLeave:Connect(tabLeave)
	end
end

function U.bindInput()
	U.UIS.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if U.clickHitsNamed("Swatch", "Gear", "DropBox", "CycleColor", "CycleAlpha", "KeybindBox") then return end
		task.defer(function()
			if tick() < (U.suppressPopupClose or 0) then return end
			if U.openColorPicker and not U.clickHits(U.openColorPicker) then U.closeColorPicker() end
			if U.openDropdown and not U.clickHits(U.openDropdown) then U.closeDropdown() end
			if U.openSettings and not U.clickHits(U.openSettings) and not U.clickHits(U.openDropdown) and not U.clickHits(U.openColorPicker) then
				U.closeSettings()
			end
		end)
	end)

	do
		local dragging, dragStart, startPos
		local function beginDrag(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			U.closePopups()
			dragging = true
			dragStart = input.Position
			startPos = U.shell.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
		U.titleBar.InputBegan:Connect(beginDrag)
		U.accent.InputBegan:Connect(beginDrag)
		U.UIS.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				local d = input.Position - dragStart
				U.shell.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + d.X,
					startPos.Y.Scale, startPos.Y.Offset + d.Y
				)
			end
		end)
	end

	U.menuOpen = true
	U.UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		local key = U.vflags.MenuKeybind or Enum.KeyCode.RightShift
		if input.KeyCode == key then
			U.menuOpen = not U.menuOpen
			U.gui.Enabled = U.menuOpen
			if not U.menuOpen then U.closePopups() end
		end
		local vKey = U.vflags.VisualsKeybind
		if vKey and input.KeyCode == vKey then
			local cur = U.vflags.VisualsEnabled == true
			if U.setters.VisualsEnabled then
				U.setters.VisualsEnabled(not cur)
			else
				U.setFlag("VisualsEnabled", not cur)
			end
		end
		local eKey = U.vflags.ExpanderKeybind
		if eKey and input.KeyCode == eKey then
			local cur = U.vflags.ExpanderEnabled == true
			if U.setters.ExpanderEnabled then
				U.setters.ExpanderEnabled(not cur)
			else
				U.setFlag("ExpanderEnabled", not cur)
			end
		end
	end)
end

local Library = {}
Library.__index = Library
Library.Flags = U.vflags
Library.Setters = U.setters

function Library:GetFlag(name) return U.vflags[name] end
function Library:SetFlag(name, val)
	if U.setters[name] then U.setters[name](val)
	else U.setFlag(name, val) end
end
function Library:OnFlag(name, fn) U.onFlag(name, fn) end
function Library:Notify(opts)
	if type(opts) == "string" then opts = { text = opts } end
	U.pushNotification({ text = opts.text or opts.Text or "", duration = opts.duration or opts.Duration or 3 })
end

function Library:CreateWindow(opts)
	opts = opts or {}
	local name = tostring(opts.Name or "wavelength")
	if opts.Width then U.BODY_W = opts.Width end
	if opts.Height then U.BODY_H = opts.Height end
	if type(opts.Tabs) == "table" and #opts.Tabs > 0 then
		U.TAB_NAMES = {}
		for _, t in ipairs(opts.Tabs) do
			U.TAB_NAMES[#U.TAB_NAMES + 1] = string.lower(tostring(t))
		end
	end

	
	if U.gui then pcall(function() U.gui:Destroy() end) end
	U.buildShell()
	if U.titleBar then
		for _, ch in ipairs(U.titleBar:GetChildren()) do
			if ch:IsA("TextLabel") then ch.Text = string.lower(name) end
		end
	end

	local win = setmetatable({
		_pages = {},
		_sections = {},
		_order = {},
	}, { __index = Library })

	for _, n in ipairs(U.TAB_NAMES) do
		win._pages[n] = U.pageFrames[n]
		win._order[n] = 0
	end

	function win:AddTab(tabName)
		tabName = string.lower(tostring(tabName))
		if not U.pageFrames[tabName] then
			
			U.TAB_NAMES[#U.TAB_NAMES + 1] = tabName
			local p = Instance.new("Frame")
			p.Name = tabName
			p.BackgroundTransparency = 1
			p.Size = UDim2.fromScale(1, 1)
			p.Position = UDim2.fromScale(0, 0)
			p.Visible = false
			p.Parent = U.pages
			U.pageFrames[tabName] = p
			if not U.currentTab then
				U.currentTab = tabName
				p.Visible = true
			end
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
				local w = math.floor((U.BODY_W - U.SEC_GAP * 3) / 2)
				local x = (side == 1) and U.SEC_GAP or (U.SEC_GAP * 2 + w)
				local totalH = U.BODY_H - U.SEC_GAP * 2
				local h = math.floor((totalH - U.SEC_GAP * (rows - 1)) / rows)
				local idx = 0
				for _, ch in ipairs(parent:GetChildren()) do
					if ch:IsA("Frame") and ch.BackgroundTransparency < 1 then
						
						local pos = ch.Position
						if pos.X.Offset == x then
							idx += 1
							local y = U.SEC_GAP + (idx - 1) * (h + U.SEC_GAP)
							ch.Size = UDim2.fromOffset(w, h)
							ch.Position = UDim2.fromOffset(x, y)
						end
					end
				end
			end
			local sec = { _content = content, _n = 0, Tab = tab }
			local function nextOrder()
				sec._n += 1
				return sec._n
			end
			function sec:AddToggle(o)
				o = o or {}
				local flag = o.Flag or o.Name
				local t = U.mkToggle(content, string.lower(tostring(o.Name or "toggle")), flag, nextOrder(), o.Default == true, o.KeybindFlag)
				if o.Callback then
					U.onFlag(flag, function() pcall(o.Callback, U.vflags[flag]) end)
				end
				local obj = { Flag = flag, Row = t, _parent = content }
				function obj:AddColorpicker(co)
					co = co or {}
					U.attachPicker(t, co.Flag or (flag .. "Color"), co.Default or Color3.fromRGB(255,255,255), co.NoAlpha == true, co.Name or "color")
					return obj
				end
				function obj:AddKeybind(ko)
					ko = ko or {}
					
					if ko.Flag then
						local kb = U.mkKeybind(content, "", ko.Flag, ko.Default or Enum.KeyCode.Unknown, nextOrder())
						U.subOf(kb, flag)
					end
					return obj
				end
				function obj:AddToggle(so)
					so = so or {}
					local child = U.mkToggle(content, string.lower(tostring(so.Name or "toggle")), so.Flag or so.Name, nextOrder(), so.Default == true)
					U.subOf(child, flag)
					if so.Callback then U.onFlag(so.Flag or so.Name, function() pcall(so.Callback, U.vflags[so.Flag or so.Name]) end) end
					return sec 
				end
				function obj:AddSlider(so)
					so = so or {}
					local child = U.mkSlider(content, string.lower(tostring(so.Name or "slider")), so.Flag or so.Name, so.Min or 0, so.Max or 100, so.Default or 0, nextOrder(), so.Increment or 1, so.Suffix or "", so.InfAt)
					U.subOf(child, flag)
					return obj
				end
				function obj:AddDropdown(so)
					so = so or {}
					local child = U.mkDropdown(content, string.lower(tostring(so.Name or "dropdown")), so.Flag or so.Name, so.Items or {}, so.Default, so.Multi == true, nextOrder())
					U.subOf(child, flag)
					return obj
				end
				return obj
			end
			function sec:AddSlider(o)
				o = o or {}
				local r = U.mkSlider(content, string.lower(tostring(o.Name or "slider")), o.Flag or o.Name, o.Min or 0, o.Max or 100, o.Default or 0, nextOrder(), o.Increment or 1, o.Suffix or "", o.InfAt)
				return { Row = r, Flag = o.Flag or o.Name }
			end
			function sec:AddDoubleSlider(o)
				o = o or {}
				local r = U.mkDoubleSlider(content, string.lower(tostring(o.Name or "range")), o.FlagMin or (o.Flag or "Min"), o.FlagMax or "Max", o.Min or 0, o.Max or 100, o.DefaultMin or o.Min or 0, o.DefaultMax or o.Max or 100, nextOrder(), o.Increment or 1, o.Suffix or "")
				return { Row = r, FlagMin = o.FlagMin, FlagMax = o.FlagMax }
			end
			function sec:AddDropdown(o)
				o = o or {}
				local r = U.mkDropdown(content, string.lower(tostring(o.Name or "dropdown")), o.Flag or o.Name, o.Items or {}, o.Default, o.Multi == true, nextOrder())
				return { Row = r, Flag = o.Flag or o.Name }
			end
			function sec:AddButton(o)
				o = o or {}
				local btn = U.mkButton(content, string.lower(tostring(o.Name or "button")), nextOrder())
				if o.Callback then btn.MouseButton1Click:Connect(function() pcall(o.Callback) end) end
				return { Button = btn }
			end
			function sec:AddKeybind(o)
				o = o or {}
				local r = U.mkKeybind(content, string.lower(tostring(o.Name or "key")), o.Flag or o.Name, o.Default or Enum.KeyCode.Unknown, nextOrder())
				return { Row = r, Flag = o.Flag or o.Name }
			end
			function sec:AddColorpicker(o)
				o = o or {}
				local r = U.row(content, nextOrder())
				local lab = Instance.new("TextLabel")
				lab.BackgroundTransparency = 1
				lab.Size = UDim2.new(1, -36, 1, 0)
				lab.FontFace = U.font
				lab.TextSize = U.TEXT_SZ
				lab.TextColor3 = U.theme.Text
				lab.TextXAlignment = Enum.TextXAlignment.Left
				lab.Text = string.lower(tostring(o.Name or "color"))
				lab.Parent = r
				U.attachPicker(r, o.Flag or o.Name, o.Default or Color3.fromRGB(255,255,255), o.NoAlpha == true, o.Name or "color")
				return { Row = r }
			end
			function sec:AddLabel(o)
				o = o or {}
				local r = U.row(content, nextOrder())
				local lab = Instance.new("TextLabel")
				lab.BackgroundTransparency = 1
				lab.Size = UDim2.fromScale(1, 1)
				lab.FontFace = U.font
				lab.TextSize = U.TEXT_SZ
				lab.TextColor3 = U.theme.Text
				lab.TextXAlignment = Enum.TextXAlignment.Left
				lab.Text = string.lower(tostring(o.Name or ""))
				lab.Parent = r
				return { Row = r }
			end
			function sec:AddTextbox(o)
				o = o or {}
				local r = U.mkTextbox(content, string.lower(tostring(o.Name or "text")), o.Flag or o.Name, o.Placeholder or "", nextOrder())
				return { Row = r, Flag = o.Flag or o.Name }
			end
			return sec
		end
		return tab
	end

	function win:AddSettingsTab()
		
		if not U.pageFrames["config"] then
			self:AddTab("config")
		end
		
		if U.buildConfig then
			U.buildConfig()
		end
		return self
	end

	function win:Init()
		U.buildTabs()
		U.bindInput()
		print("wavelength library window ready")
	end

	function win:Unload()
		U.shutdown()
	end

	return win
end

return Library
