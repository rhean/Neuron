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

---frames made on demand and hidden, not destroyed, when released.
---a frame's OnRelease, if it has one, runs when it is released
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
			if frame.OnRelease then
				frame:OnRelease()
			end
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
function UI.Button(parent, text, onClick)
	local button = CreateFrame("Button", nil, parent)
	Style.Flat(button, Style.panel)
	button:SetHeight(Style.rowHeight)

	local label = UI.Text(button)
	label:SetPoint("CENTER")
	button:SetFontString(label)
	button:SetDisabledFontObject(GameFontDisable)

	local hover = button:CreateTexture(nil, "HIGHLIGHT")
	hover:SetAllPoints()
	hover:SetColorTexture(unpack(Style.hover))

	button:SetScript("OnClick", onClick)

	---sets the text and widens the button to fit it
	function button:SetLabel(value)
		self:SetText(value)
		self:SetWidth(math.max(80, label:GetStringWidth() + 20))
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

local function focusBorder(box)
	box:HookScript("OnEditFocusGained", function(self)
		Style.SetBorder(self.neuronFlat and self or self:GetParent():GetParent(), Style.focus)
	end)
	box:HookScript("OnEditFocusLost", function(self)
		Style.SetBorder(self.neuronFlat and self or self:GetParent():GetParent(), Style.border)
	end)
end

---a single line. onChange only runs on typing, not on SetText
---@param onChange? fun(text: string)
function UI.EditBox(parent, onChange)
	local box = CreateFrame("EditBox", nil, parent)
	Style.Flat(box, Style.field)
	box:SetHeight(Style.rowHeight)
	box:SetAutoFocus(false)
	box:SetFontObject(Style.font)
	box:SetTextInsets(6, 6, 0, 0)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", box.ClearFocus)

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
	focusBorder(box)
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
	focusBorder(box)

	function frame:SetText(text)
		box:SetText(text)
		scroll:SetVerticalScroll(0)
	end

	function frame:GetText()
		return box:GetText()
	end

	return frame
end

---a button that opens a menu. build gets MenuUtil's root description
---@param build fun(root: table)
function UI.MenuButton(parent, text, build)
	local button = UI.Button(parent, text, function(self)
		MenuUtil.CreateContextMenu(self, function(_, root)
			build(root)
		end)
	end)

	local label = button:GetFontString()
	label:ClearAllPoints()
	label:SetPoint("LEFT", 8, 0)
	label:SetPoint("RIGHT", -22, 0)

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
	dropdown = UI.MenuButton(parent, "", function(root)
		for _, item in ipairs(dropdown.items) do
			root:CreateRadio(item.text, function()
				return item.value == dropdown.value
			end, function()
				dropdown:SetValue(item.value)
				onSelect(item.value)
			end)
		end
	end)
	dropdown.items = {}

	---@param items {value: any, text: string}[]
	function dropdown:SetItems(items)
		self.items = items
	end

	function dropdown:SetValue(value)
		self.value = value
		for _, item in ipairs(self.items) do
			if item.value == value then
				self:SetText(item.text)
			end
		end
	end

	return dropdown
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

	local pool = UI.Pool(function()
		local tab = CreateFrame("Button", nil, tabs)
		tab:SetHeight(Style.rowHeight + 4)
		tab.label = UI.Text(tab)
		tab.label:SetPoint("CENTER", 0, 1)
		tab.underline = tab:CreateTexture(nil, "ARTWORK")
		tab.underline:SetColorTexture(unpack(Style.accent))
		tab.underline:SetPoint("BOTTOMLEFT")
		tab.underline:SetPoint("BOTTOMRIGHT")
		tab.underline:SetHeight(2)
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
			tab.underline:SetShown(isSelected)
			tab.label:SetTextColor(unpack(isSelected and Style.text or Style.dim))
		end
	end

	return tabs
end

---a vertical scroll area. put things in .child and give it their height with SetContentHeight
function UI.ScrollArea(parent)
	local scroll = CreateFrame("ScrollFrame", nil, parent)
	scroll.neuronScroll = true

	local child = CreateFrame("Frame", nil, scroll)
	child:SetSize(1, 1)
	scroll:SetScrollChild(child)
	scroll.child = child

	local bar = CreateFrame("Slider", nil, scroll)
	bar:SetPoint("TOPRIGHT")
	bar:SetPoint("BOTTOMRIGHT")
	bar:SetWidth(6)
	bar:SetOrientation("VERTICAL")
	bar:SetMinMaxValues(0, 0)
	bar:SetValue(0)
	bar:EnableMouse(true)
	local thumb = bar:CreateTexture(nil, "OVERLAY")
	thumb:SetColorTexture(1, 1, 1, 0.25)
	thumb:SetSize(6, 30)
	bar:SetThumbTexture(thumb)
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
		return math.max(1, self:GetWidth() - 10)
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
