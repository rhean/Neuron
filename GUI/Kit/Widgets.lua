-- Neuron is a World of Warcraft® user interface addon.
-- Copyright (c) 2026 Linus Olsson
-- This code is licensed under the MIT license (see LICENSE for details)

local _, addonTable = ...

-----------------------------------------------------------------------------
-------------------------------- Widgets ------------------------------------
-----------------------------------------------------------------------------
--plain frames in the flat style, no AceGUI and no Blizzard templates so they
--work the same on Retail and Forever. menus use MenuUtil, which both have.

local UI = addonTable.ui
local Style = UI.Style

---frames made on demand and hidden, not destroyed, when released
---@param create fun(): Frame
function UI.Pool(create)
	local pool = {free = {}, used = {}}

	function pool:Acquire()
		local frame = table.remove(self.free) or create()
		table.insert(self.used, frame)
		frame:Show()
		return frame
	end

	function pool:ReleaseAll()
		for i = #self.used, 1, -1 do
			local frame = self.used[i]
			frame:Hide()
			frame:ClearAllPoints()
			table.insert(self.free, frame)
			self.used[i] = nil
		end
	end

	return pool
end

---a fontstring in the kit's colors
---@param font? string @Style.font when left out
---@param color? table @Style.text when left out
function UI.Text(parent, font, color)
	local text = parent:CreateFontString(nil, "OVERLAY", font or Style.font)
	text:SetTextColor(unpack(color or Style.text))
	text:SetJustifyH("LEFT")
	return text
end

---@param onClick? fun(button: Button)
---blizzard's red panel button
function UI.Button(parent, text, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetHeight(Style.rowHeight)

	for _, texture in ipairs({button.Left, button.Middle, button.Right, button:GetHighlightTexture()}) do
		texture:SetDesaturation(0.7)
	end

	button:SetScript("OnClick", onClick)

	---sets the text and widens the button to fit it
	function button:SetLabel(value)
		self:SetText(value)
		self:SetWidth(math.max(80, self:GetTextWidth() + 24))
	end
	button:SetLabel(text or "")

	return button
end

---the X in a corner
---@param onClick fun()
function UI.CloseButton(parent, onClick)
	local button = CreateFrame("Button", nil, parent)
	button:SetSize(20, 20)
	for _, angle in ipairs({45, -45}) do
		local line = button:CreateTexture(nil, "ARTWORK")
		line:SetColorTexture(unpack(Style.dim))
		line:SetSize(12, 1.5)
		line:SetPoint("CENTER")
		line:SetRotation(math.rad(angle))
		button[angle] = line
	end
	button:SetScript("OnEnter", function(self)
		self[45]:SetColorTexture(unpack(Style.text))
		self[-45]:SetColorTexture(unpack(Style.text))
	end)
	button:SetScript("OnLeave", function(self)
		self[45]:SetColorTexture(unpack(Style.dim))
		self[-45]:SetColorTexture(unpack(Style.dim))
	end)
	button:SetScript("OnClick", onClick)
	return button
end

---an edit box keeps the keyboard until enter or escape, even hidden.
---this lets go when it hides or on a click outside area (the box when left out)
local function letGoOfKeyboard(box, area)
	area = area or box
	box:HookScript("OnHide", box.ClearFocus)
	box:HookScript("OnEditFocusGained", function(self)
		pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN")
	end)
	box:HookScript("OnEditFocusLost", function(self)
		pcall(self.UnregisterEvent, self, "GLOBAL_MOUSE_DOWN")
	end)
	box:HookScript("OnEvent", function(self, event)
		if event == "GLOBAL_MOUSE_DOWN" and not area:IsMouseOver() then
			self:ClearFocus()
		end
	end)
end

---a single line. onChange only runs on typing, not on SetText
---@param onChange? fun(text: string)
function UI.EditBox(parent, onChange)
	--blizzard's own input box
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetHeight(Style.rowHeight)
	box:SetAutoFocus(false)
	box:SetFontObject(Style.font)
	--its end caps hang 5px outside it, keep them inside so it fills its slot like other widgets
	if box.Left and box.Right then
		box.Left:ClearAllPoints()
		box.Left:SetPoint("LEFT")
		box.Right:ClearAllPoints()
		box.Right:SetPoint("RIGHT")
	end
	box:SetTextInsets(6, 6, 0, 0)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", box.ClearFocus)
	letGoOfKeyboard(box)

	--grayed text while the box is empty
	box.placeholder = UI.Text(box, nil, Style.placeholder)
	box.placeholder:SetPoint("LEFT", 6, 0)
	box.placeholder:SetPoint("RIGHT", -6, 0)
	box.placeholder:SetWordWrap(false)

	function box:SetPlaceholder(text)
		self.placeholder:SetText(text or "")
		self.placeholder:SetShown(self:GetText() == "")
	end

	box:SetScript("OnTextChanged", function(self, userInput)
		self.placeholder:SetShown(self:GetText() == "")
		if userInput and self.onChange then
			self.onChange(self:GetText())
		end
	end)
	box.onChange = onChange
	return box
end

---several lines that scroll inside a fixed height. onChange only runs on typing.
---the edit box itself is .editBox
---@param lines number @how many lines tall
---@param onChange? fun(text: string)
function UI.MultiLineEditBox(parent, lines, onChange)
	local frame = CreateFrame("Frame", nil, parent)
	Style.Flat(frame, Style.field)

	local scroll = CreateFrame("ScrollFrame", nil, frame)
	scroll:SetPoint("TOPLEFT", 6, -4)
	scroll:SetPoint("BOTTOMRIGHT", -6, 4)

	local box = CreateFrame("EditBox", nil, scroll)
	box:SetMultiLine(true)
	box:SetAutoFocus(false)
	box:SetFontObject(Style.font)
	box:SetWidth(1)
	scroll:SetScrollChild(box)
	frame.editBox = box
	--the whole field, not just the box
	letGoOfKeyboard(box, frame)

	local _, fontSize = box:GetFont()
	local lineHeight = math.ceil(fontSize or 12) + 2
	frame:SetHeight(lines * lineHeight + 8)

	scroll:SetScript("OnSizeChanged", function(_, width)
		box:SetWidth(width)
	end)

	--the box is only as tall as its text, so clicks below it focus it too
	frame:EnableMouse(true)
	frame:SetScript("OnMouseDown", function()
		box:SetFocus()
		box:SetCursorPosition(#box:GetText())
	end)

	--keeps the cursor in view. y is from the top, and negative
	box:SetScript("OnCursorChanged", function(_, _, y, _, height)
		local top, view = scroll:GetVerticalScroll(), scroll:GetHeight()
		y = -y
		if y < top then
			scroll:SetVerticalScroll(y)
		elseif y + height > top + view then
			scroll:SetVerticalScroll(y + height - view)
		end
	end)

	--at either end the wheel goes on to a kit ScrollArea around it
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local current, range = self:GetVerticalScroll(), self:GetVerticalScrollRange()
		if (delta > 0 and current <= 0) or (delta < 0 and current >= range) then
			UI.ForwardWheel(frame, delta)
			return
		end
		self:SetVerticalScroll(math.max(0, math.min(range, current - delta * lineHeight * 2)))
	end)

	box:SetScript("OnEscapePressed", box.ClearFocus)

	--grayed text while the box is empty
	local placeholder = UI.Text(frame, nil, Style.placeholder)
	placeholder:SetPoint("TOPLEFT", scroll)
	placeholder:SetPoint("TOPRIGHT", scroll)
	placeholder:SetJustifyV("TOP")
	placeholder:SetMaxLines(lines)

	function frame:SetPlaceholder(text)
		placeholder:SetText(text or "")
		placeholder:SetShown(box:GetText() == "")
	end

	box:SetScript("OnTextChanged", function(self, userInput)
		placeholder:SetShown(self:GetText() == "")
		if userInput and frame.onChange then
			frame.onChange(self:GetText())
		end
	end)
	frame.onChange = onChange
	box:HookScript("OnEditFocusGained", function()
		Style.SetBorder(frame, Style.focus)
	end)
	box:HookScript("OnEditFocusLost", function()
		Style.SetBorder(frame, Style.border)
	end)

	function frame:SetText(text)
		box:SetText(text)
		scroll:SetVerticalScroll(0)
	end

	function frame:GetText()
		return box:GetText()
	end

	return frame
end

--blizzard's own dropdown button from 11.0, nil on a client without it
local function blizzardDropdown(parent)
	local ok, dropdown = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	if ok and dropdown and dropdown.SetupMenu then
		return dropdown
	end
	if ok and dropdown then
		dropdown:Hide()
	end
end

---a button that opens a menu. build gets MenuUtil's root description.
---blizzard's dropdown where the client has it, a flat one otherwise
---@param build fun(root: table)
function UI.MenuButton(parent, text, build)
	local dropdown = blizzardDropdown(parent)
	if dropdown then
		dropdown:SetDefaultText(text)
		dropdown:SetupMenu(function(_, root)
			build(root)
		end)
		local label = dropdown.Text
		dropdown:SetWidth(math.max(80, (label and label:GetStringWidth() or 0) + 40))
		return dropdown
	end

	local button = UI.Button(parent, text, function(self)
		MenuUtil.CreateContextMenu(self, function(_, root)
			build(root)
		end)
	end)

	local label = button:GetFontString()
	label:ClearAllPoints()
	label:SetPoint("LEFT", 8, 0)
	label:SetPoint("RIGHT", -22, 0)
	button:SetWidth(math.max(80, label:GetStringWidth() + 40))

	local arrow = button:CreateTexture(nil, "ARTWORK")
	arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
	arrow:SetDesaturated(true)
	arrow:SetVertexColor(unpack(Style.dim))
	arrow:SetSize(14, 14)
	arrow:SetPoint("RIGHT", -6, -3)

	return button
end

---shows the chosen item and lists them all on click
---@param onSelect fun(value: any)
function UI.Dropdown(parent, onSelect)
	local dropdown

	--the flat one shows the chosen item's text itself, blizzard's shows the ticked radio
	local function showValue()
		if dropdown.GenerateMenu then
			dropdown:GenerateMenu()
			return
		end
		local text = ""
		for _, item in ipairs(dropdown.items) do
			if item.value == dropdown.value then
				text = item.text
			end
		end
		dropdown:SetText(text)
	end

	--blizzard's builds the menu once while it is made, before there are items
	dropdown = UI.MenuButton(parent, "", function(root)
		for _, item in ipairs(dropdown and dropdown.items or {}) do
			root:CreateRadio(item.text, function()
				return item.value == dropdown.value
			end, function()
				dropdown.value = item.value
				if not dropdown.GenerateMenu then
					showValue()
				end
				onSelect(item.value)
			end)
		end
	end)
	dropdown.items = {}

	---@param items {value: any, text: string}[]
	function dropdown:SetItems(items)
		self.items = items
	end

	---shows a value, without onSelect
	function dropdown:SetValue(value)
		self.value = value
		showValue()
	end

	return dropdown
end

---a box to tick with its label to the right. onChange gets the new state, only on clicks
---@param onChange? fun(checked: boolean)
function UI.Checkbox(parent, onChange)
	local check = CreateFrame("Button", nil, parent)
	check:SetHeight(Style.rowHeight)

	check.box = CreateFrame("Frame", nil, check)
	Style.Flat(check.box, Style.strip)
	check.box:SetSize(16, 16)
	check.box:SetPoint("LEFT")

	--a tick of two gold lines: short down to the corner, then long up to the right.
	--{center x, center y from the top left, length, angle}
	check.mark = CreateFrame("Frame", nil, check.box)
	check.mark:SetAllPoints()
	for _, line in ipairs({{5.5, 9.8, 5, -42}, {9.5, 8, 9, 52}}) do
		local stroke = check.mark:CreateTexture(nil, "ARTWORK")
		stroke:SetColorTexture(unpack(Style.accent))
		stroke:SetSize(line[3], 2)
		stroke:SetPoint("CENTER", check.box, "TOPLEFT", line[1], -line[2])
		stroke:SetRotation(math.rad(line[4]))
	end

	local hover = check:CreateTexture(nil, "HIGHLIGHT")
	hover:SetAllPoints(check.box)
	hover:SetColorTexture(unpack(Style.hover))

	check.label = UI.Text(check)
	check.label:SetPoint("LEFT", check.box, "RIGHT", Style.gap, 0)
	check.label:SetPoint("RIGHT")
	check.label:SetWordWrap(false)

	check:SetScript("OnClick", function(self)
		self:SetChecked(not self.checked)
		if self.onChange then
			self.onChange(self.checked)
		end
	end)
	check.onChange = onChange

	function check:SetChecked(value)
		self.checked = not not value
		self.mark:SetShown(self.checked)
	end

	function check:SetLabel(text)
		self.label:SetText(text)
	end

	function check:SetDisabled(disabled)
		self:SetEnabled(not disabled)
		self.label:SetTextColor(unpack(disabled and Style.dim or Style.text))
		self.mark:SetAlpha(disabled and 0.4 or 1)
	end

	return check
end

--blizzard's options slider track, the same one AceGUI's slider uses
local SLIDER_BACKDROP = {
	bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
	edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
	tile = true, tileSize = 8, edgeSize = 8,
	insets = {left = 3, right = 3, top = 6, bottom = 6},
}

---a slider in a light box with its name and a value that can be typed in.
---.dragging is true while the thumb is held, onRelease runs when it is let go
---@param onChange? fun(value: number)
function UI.Slider(parent, onChange)
	local inset = Style.lightInset
	local frame = CreateFrame("Frame", nil, parent)
	Style.Flat(frame, Style.panelLight)
	frame.naturalHeight = inset.top + 18 + 4 + 17 + inset.bottom
	frame:SetHeight(frame.naturalHeight)
	frame.onChange = onChange

	frame.label = UI.Text(frame)
	frame.label:SetPoint("TOPLEFT", inset.left, -inset.top - 2)
	frame.label:SetPoint("TOPRIGHT", -inset.right - 58, -inset.top - 2)
	frame.label:SetWordWrap(false)

	local valueBox = UI.EditBox(frame)
	valueBox:SetSize(52, 18)
	valueBox:SetPoint("TOPRIGHT", -inset.right, -inset.top)
	valueBox:SetJustifyH("RIGHT")
	valueBox:SetTextInsets(4, 4, 0, 0)
	frame.valueBox = valueBox

	local track = CreateFrame("Slider", nil, frame, "BackdropTemplate")
	track:SetBackdrop(SLIDER_BACKDROP)
	track:SetPoint("BOTTOMLEFT", inset.left, inset.bottom)
	track:SetPoint("BOTTOMRIGHT", -inset.right, inset.bottom)
	track:SetHeight(17)
	track:SetOrientation("HORIZONTAL")
	track:SetHitRectInsets(0, 0, -6, -6)
	track:EnableMouse(true)
	track:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	track:GetThumbTexture():SetSize(32, 32)

	local min, max, step, percent = 0, 1, 0, false
	local updating

	local function format(value)
		if percent then
			return math.floor(value * 100 + 0.5).."%"
		elseif step >= 1 then
			return tostring(math.floor(value + 0.5))
		end
		return (string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", ""))
	end

	--onto the step, within min and max. typed values may go past the slider's soft end
	local function snap(value)
		value = math.max(min, math.min(max, value))
		if step > 0 then
			value = min + math.floor((value - min) / step + 0.5) * step
			value = math.floor(value * 1e6 + 0.5) / 1e6
		end
		return value
	end

	local function changed(value)
		frame.value = value
		valueBox:SetText(format(value))
		if frame.onChange then
			frame.onChange(value)
		end
	end

	track:SetScript("OnValueChanged", function(_, value)
		if updating then
			return
		end
		value = snap(value)
		if value ~= frame.value then
			changed(value)
		end
	end)
	track:SetScript("OnMouseDown", function()
		frame.dragging = true
	end)
	track:SetScript("OnMouseUp", function()
		frame.dragging = false
		if frame.onRelease then
			frame.onRelease()
		end
	end)

	valueBox:SetScript("OnEnterPressed", function(self)
		local number = tonumber((self:GetText():gsub("%%", "")))
		if number then
			if percent then
				number = number / 100
			end
			number = snap(number)
			frame:SetValue(number)
			changed(number)
		else
			self:SetText(format(frame.value or min))
		end
		self:ClearFocus()
	end)
	valueBox:SetScript("OnEscapePressed", function(self)
		self:SetText(format(frame.value or min))
		self:ClearFocus()
	end)

	function frame:SetLabel(text)
		self.label:SetText(text)
	end

	---softMax is where the slider ends, values up to max can still be typed
	function frame:SetRange(newMin, newMax, newStep, softMax, isPercent)
		min, max, step, percent = newMin, newMax, newStep or 0, not not isPercent
		updating = true
		track:SetMinMaxValues(min, softMax or max)
		track:SetValueStep(step > 0 and step or 0.001)
		updating = false
	end

	---shows a value, without onChange
	function frame:SetValue(value)
		self.value = value
		updating = true
		track:SetValue(value)
		updating = false
		valueBox:SetText(format(value))
	end

	function frame:SetDisabled(disabled)
		track:EnableMouse(not disabled)
		valueBox:SetEnabled(not disabled)
		self:SetAlpha(disabled and 0.5 or 1)
	end

	return frame
end

--blizzard's color picker changed in 10.2.5, this takes either
local function openColorPicker(r, g, b, onPick)
	ColorPickerFrame:Hide()
	ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	ColorPickerFrame:SetClampedToScreen(true)

	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow({
			r = r, g = g, b = b,
			hasOpacity = false,
			swatchFunc = function()
				onPick(ColorPickerFrame:GetColorRGB())
			end,
			cancelFunc = function()
				onPick(r, g, b)
			end,
		})
	else
		ColorPickerFrame.hasOpacity = false
		ColorPickerFrame.func = function()
			onPick(ColorPickerFrame:GetColorRGB())
		end
		ColorPickerFrame.cancelFunc = function()
			onPick(r, g, b)
		end
		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame:Show()
	end
end

---a color square on its own, opening blizzard's color picker.
---onChange gets every color the picker shows, and the old one again on cancel
---@param onChange? fun(r: number, g: number, b: number, a: number)
function UI.ColorSwatch(parent, onChange)
	local button = CreateFrame("Button", nil, parent)
	button:SetHeight(Style.rowHeight)
	button.onChange = onChange

	button.swatch = CreateFrame("Frame", nil, button)
	Style.Flat(button.swatch, Style.field)
	button.swatch:SetSize(14, 14)
	button.swatch:SetPoint("LEFT")
	button.color = button.swatch:CreateTexture(nil, "ARTWORK")
	button.color:SetPoint("TOPLEFT", 1, -1)
	button.color:SetPoint("BOTTOMRIGHT", -1, 1)

	local hover = button:CreateTexture(nil, "HIGHLIGHT")
	hover:SetAllPoints(button.swatch)
	hover:SetColorTexture(unpack(Style.hover))

	function button:SetColor(r, g, b, a)
		self.r, self.g, self.b, self.a = r or 1, g or 1, b or 1, a or 1
		self.color:SetColorTexture(self.r, self.g, self.b, 1)
	end

	---the name isn't shown, the swatch sits next to the setting it colors
	function button:SetLabel(text)
		self.name = text
	end

	function button:SetDisabled(disabled)
		self:SetEnabled(not disabled)
		self.swatch:SetAlpha(disabled and 0.4 or 1)
	end

	button:SetScript("OnClick", function(self)
		--the picker keeps this callback, so it outlives the swatch being reused
		local pick, a = self.onChange, self.a
		openColorPicker(self.r, self.g, self.b, function(r, g, b)
			if self.onChange == pick then
				self:SetColor(r, g, b, a)
			end
			if pick then
				pick(r, g, b, a)
			end
		end)
	end)

	return button
end

---a row of text tabs, the selected one underlined
---@param onSelect fun(value: any)
function UI.Tabs(parent, onSelect)
	local tabs = CreateFrame("Frame", nil, parent)
	tabs:SetHeight(Style.rowHeight + 4)

	local line = tabs:CreateTexture(nil, "BORDER")
	line:SetColorTexture(unpack(Style.border))
	line:SetPoint("BOTTOMLEFT")
	line:SetPoint("BOTTOMRIGHT")
	line:SetHeight(1)

	--folder tabs: each a dark box, the open one in the window's color and open at the bottom,
	--so it joins the page under the line
	local pool = UI.Pool(function()
		local tab = CreateFrame("Button", nil, tabs)
		Style.Flat(tab, Style.strip)
		tab:SetHeight(Style.rowHeight + 4)
		tab.label = UI.Text(tab)
		tab.label:SetPoint("CENTER", 0, 1)
		tab.opening = tab:CreateTexture(nil, "OVERLAY")
		tab.opening:SetColorTexture(unpack(Style.window))
		tab.opening:SetPoint("BOTTOMLEFT", 1, 0)
		tab.opening:SetPoint("BOTTOMRIGHT", -1, 0)
		tab.opening:SetHeight(1)
		local hover = tab:CreateTexture(nil, "HIGHLIGHT")
		hover:SetAllPoints()
		hover:SetColorTexture(unpack(Style.hover))
		tab:SetScript("OnClick", function(self)
			if self.value ~= tabs.value then
				tabs:Select(self.value)
				onSelect(self.value)
			end
		end)
		return tab
	end)

	---@param list {value: any, text: string}[]
	function tabs:SetTabs(list, value)
		pool:ReleaseAll()
		local previous
		for _, item in ipairs(list) do
			local tab = pool:Acquire()
			tab.value = item.value
			tab.label:SetText(item.text)
			tab:SetWidth(tab.label:GetStringWidth() + 24)
			if previous then
				tab:SetPoint("LEFT", previous, "RIGHT", 2, 0)
			else
				tab:SetPoint("BOTTOMLEFT")
			end
			previous = tab
		end
		self:Select(value)
	end

	function tabs:Select(value)
		self.value = value
		for _, tab in ipairs(pool.used) do
			local isSelected = tab.value == value
			tab.neuronFlat.bg:SetColorTexture(unpack(isSelected and Style.window or Style.strip))
			tab.opening:SetShown(isSelected)
			tab.label:SetTextColor(unpack(isSelected and Style.accent or Style.dim))
		end
	end

	return tabs
end

---a vertical scroll area. put things in .child and give it their height with SetContentHeight
---a dark track with a gray thumb (.thumb), 8 wide
function UI.ScrollBar(parent)
	local bar = CreateFrame("Slider", nil, parent)
	Style.Flat(bar, Style.field)
	bar:SetWidth(8)
	bar:SetOrientation("VERTICAL")
	bar:EnableMouse(true)
	bar.thumb = bar:CreateTexture(nil, "OVERLAY")
	bar.thumb:SetColorTexture(unpack(Style.dim))
	bar.thumb:SetSize(6, 30)
	bar:SetThumbTexture(bar.thumb)
	return bar
end

---a square icon to click, the icon is .icon
function UI.IconButton(parent, size)
	local button = CreateFrame("Button", nil, parent)
	Style.Flat(button, Style.field)
	button:SetSize(size, size)

	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("TOPLEFT", 1, -1)
	button.icon:SetPoint("BOTTOMRIGHT", -1, 1)

	local hover = button:CreateTexture(nil, "HIGHLIGHT")
	hover:SetAllPoints()
	hover:SetColorTexture(unpack(Style.hover))
	return button
end

function UI.ScrollArea(parent)
	local scroll = CreateFrame("ScrollFrame", nil, parent)
	scroll.neuronScroll = true

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(1, 1)
	scroll:SetScrollChild(child)
	scroll.child = child

	local bar = UI.ScrollBar(scroll)
	local thumb = bar.thumb
	bar:SetPoint("TOPRIGHT")
	bar:SetPoint("BOTTOMRIGHT")
	bar:SetMinMaxValues(0, 0)
	bar:SetValue(0)
	bar:SetScript("OnValueChanged", function(_, value)
		scroll:SetVerticalScroll(value)
	end)

	local contentHeight = 0
	local function updateRange()
		local view = scroll:GetHeight()
		local range = math.max(0, contentHeight - view)
		bar:SetMinMaxValues(0, range)
		bar:SetShown(range > 0)
		if range > 0 then
			thumb:SetHeight(math.max(20, view * view / contentHeight))
		end
		if bar:GetValue() > range then
			bar:SetValue(range)
		end
	end

	---the width things in child should fill, the bar's room left out
	function scroll:GetContentWidth()
		return math.max(1, self:GetWidth() - 12)
	end

	function scroll:SetContentHeight(height)
		contentHeight = height
		child:SetHeight(math.max(1, height))
		self:UpdateScrollChildRect()
		updateRange()
	end

	function scroll:ScrollTo(offset)
		bar:SetValue(math.max(0, offset))
	end

	function scroll:Scroll(delta)
		bar:SetValue(bar:GetValue() - delta * 40)
	end

	scroll:SetScript("OnSizeChanged", function(self)
		child:SetWidth(self:GetContentWidth())
		updateRange()
		if self.OnResize then
			self:OnResize()
		end
	end)

	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", scroll.Scroll)

	return scroll
end

---gives a StaticPopupDialogs entry OnShow and OnHide that put the popup over kit windows while it is up
function UI.RaisePopup(dialog)
	dialog.OnShow = function(self)
		self:SetFrameStrata("FULLSCREEN_DIALOG")
	end
	dialog.OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end
	return dialog
end

---passes a mouse wheel turn to the nearest kit ScrollArea above frame
function UI.ForwardWheel(frame, delta)
	local parent = frame:GetParent()
	while parent do
		if parent.neuronScroll then
			parent:Scroll(delta)
			return
		end
		parent = parent:GetParent()
	end
end

local BOX_EDGE = {edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12}
--a tint over the border's light gray
local BOX_EDGE_COLOR = {0.7, 0.7, 0.7, 1}
local BOX_EDGE_SIZE = 3
local BOX_BG_INSET = 3

---a dark box in blizzard's tooltip border with a title strip (.strip, .title).
---.edge is how far in its contents start
function UI.Box(parent)
	local box = CreateFrame("Frame", nil, parent)
	Style.Flat(box, Style.box)

	local border = CreateFrame("Frame", nil, box, "BackdropTemplate")
	border:SetAllPoints()
	border:SetBackdrop(BOX_EDGE)
	border:SetBackdropBorderColor(unpack(BOX_EDGE_COLOR))
	Style.SetFlatShown(box, true, false)
	--inside the rounded corners
	local bg = box.neuronFlat.bg
	bg:ClearAllPoints()
	bg:SetPoint("TOPLEFT", BOX_BG_INSET, -BOX_BG_INSET)
	bg:SetPoint("BOTTOMRIGHT", -BOX_BG_INSET, BOX_BG_INSET)
	box.edge = BOX_EDGE_SIZE

	local edge = box.edge
	box.strip = CreateFrame("Frame", nil, box)
	box.strip:SetPoint("TOPLEFT", edge, -edge)
	box.strip:SetPoint("TOPRIGHT", -edge, -edge)
	box.strip:SetHeight(Style.stripHeight)
	local stripBg = box.strip:CreateTexture(nil, "BACKGROUND")
	stripBg:SetAllPoints()
	stripBg:SetColorTexture(unpack(Style.strip))
	local line = box.strip:CreateTexture(nil, "BORDER")
	line:SetColorTexture(unpack(Style.border))
	line:SetPoint("BOTTOMLEFT")
	line:SetPoint("BOTTOMRIGHT")
	line:SetHeight(1)

	box.title = UI.Text(box.strip, nil, Style.accent)
	box.title:SetPoint("LEFT", Style.padding, 0)
	box.title:SetPoint("RIGHT", -Style.padding, 0)
	box.title:SetJustifyH("CENTER")
	box.title:SetWordWrap(false)
	return box
end

---a movable, resizable window with a title bar and a status line.
---put things in .content. closes with escape, so it needs a global name
---@param name string
function UI.Window(name, title)
	local window = CreateFrame("Frame", name, UIParent)
	Style.Flat(window, Style.window)
	--over the button edit overlays (DIALOG), under menus (FULLSCREEN_DIALOG).
	--StaticPopups are DIALOG, so one shown from a window needs UI.RaisePopup
	window:SetFrameStrata("FULLSCREEN")
	window:SetToplevel(true)
	window:SetClampedToScreen(true)
	window:SetMovable(true)
	window:SetResizable(true)
	window:EnableMouse(true)
	window:SetPoint("CENTER")
	window:Hide()

	local titleBar = CreateFrame("Frame", nil, window)
	Style.Flat(titleBar, Style.panel)
	titleBar:SetPoint("TOPLEFT")
	titleBar:SetPoint("TOPRIGHT")
	titleBar:SetHeight(26)
	titleBar:EnableMouse(true)
	titleBar:RegisterForDrag("LeftButton")
	titleBar:SetScript("OnDragStart", function()
		window:StartMoving()
	end)
	titleBar:SetScript("OnDragStop", function()
		window:StopMovingOrSizing()
	end)

	local titleText = UI.Text(titleBar, nil, Style.accent)
	titleText:SetPoint("LEFT", Style.padding, 0)
	titleText:SetText(title)

	local close = UI.CloseButton(titleBar, function()
		window:Hide()
	end)
	close:SetPoint("RIGHT", -3, 0)

	local status = UI.Text(window, Style.font, Style.dim)
	status:SetPoint("BOTTOMLEFT", Style.padding, 6)
	status:SetPoint("BOTTOMRIGHT", -24, 6)
	status:SetWordWrap(false)

	local grip = CreateFrame("Button", nil, window)
	grip:SetSize(16, 16)
	grip:SetPoint("BOTTOMRIGHT", -2, 2)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetScript("OnMouseDown", function()
		window:StartSizing("BOTTOMRIGHT")
	end)
	grip:SetScript("OnMouseUp", function()
		window:StopMovingOrSizing()
	end)

	window.content = CreateFrame("Frame", nil, window)
	window.content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", Style.padding, -Style.padding)
	window.content:SetPoint("BOTTOMRIGHT", -Style.padding, 24)

	function window:SetStatus(text)
		status:SetText(text)
	end

	function window:SetMinSize(width, height)
		if self.SetResizeBounds then -- WoW 10.0
			self:SetResizeBounds(width, height)
		else
			self:SetMinResize(width, height)
		end
	end

	if not tContains(UISpecialFrames, name) then
		tinsert(UISpecialFrames, name)
	end

	return window
end
