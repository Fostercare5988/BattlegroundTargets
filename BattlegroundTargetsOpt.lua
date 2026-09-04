-- -------------------------------------------------------------------------- --
-- BattlegroundTargets Options GUI (Rule H7 Modular Architecture)             --
-- -------------------------------------------------------------------------- --

local BGT = BattlegroundTargets

local selectedTab = 10
local activeTabButton = nil

-- UI Helper Templates
local function CreateCheckButton(name, parent, text, onClick)
	local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
	cb:SetWidth(20)
	cb:SetHeight(20)
	local label = _G[name .. "Text"] or cb:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	label:SetPoint("LEFT", cb, "RIGHT", 4, 1)
	label:SetText(text)
	cb.Label = label
	cb:SetScript("OnClick", onClick)
	return cb
end

local function CreateSlider(name, parent, text, minVal, maxVal, step, isPercent, onValChanged)
	local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	s:SetWidth(150)
	s:SetHeight(16)
	s:SetMinMaxValues(minVal, maxVal)
	s:SetValueStep(step)
	_G[name .. "Low"]:SetText(tostring(minVal))
	_G[name .. "High"]:SetText(tostring(maxVal))
	_G[name .. "Text"]:SetText(text)
	s.ValueText = s:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	s.ValueText:SetPoint("LEFT", s, "RIGHT", 10, 0)
	s:SetScript("OnValueChanged", function()
		local val = math.floor(this:GetValue())
		s.ValueText:SetText(isPercent and (val .. "%") or tostring(val))
		onValChanged(val)
	end)
	return s
end

-- -------------------------------------------------------------------------- --
-- Options Frame Assembly                                                     --
-- -------------------------------------------------------------------------- --
function BGT:CreateOptionsFrame()
	if BattlegroundTargets_OptionsFrame then return end

	local f = CreateFrame("Frame", "BattlegroundTargets_OptionsFrame", UIParent)
	f:Hide()
	f:SetWidth(330)
	f:SetHeight(330)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetBackdrop({
		bgFile = "Interface\DialogFrame\UI-DialogBox-Background",
		edgeFile = "Interface\DialogFrame\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})

	tinsert(UISpecialFrames, "BattlegroundTargets_OptionsFrame")

	f:SetScript("OnMouseDown", function() f:StartMoving() end)
	f:SetScript("OnMouseUp", function()
		f:StopMovingOrSizing()
		BGT:Frame_SavePosition("BattlegroundTargets_OptionsFrame")
	end)

	-- Title Bar
	local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOP", 0, -14)
	title:SetText("BattlegroundTargets")

	-- Close Button (X)
	local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
	closeBtn:SetScript("OnClick", function() f:Hide() end)

	-- Bottom Close Configuration Button
	local bottomClose = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	bottomClose:SetWidth(160)
	bottomClose:SetHeight(24)
	bottomClose:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
	bottomClose:SetText("Close Configuration")
	bottomClose:SetScript("OnClick", function()
		f:Hide()
	end)

	-- ---------------------------------------------------------------------- --
	-- Tab Buttons (10 vs 10, 15 vs 15, 40 vs 40, General)                   --
	-- ---------------------------------------------------------------------- --
	local tabs = {}
	local tabConfigs = {
		{ id = 10, name = "10 vs 10" },
		{ id = 15, name = "15 vs 15" },
		{ id = 40, name = "40 vs 40" },
		{ id = 0,  name = "General" },
	}

	local function SelectTab(tabId)
		selectedTab = tabId
		for _, tab in ipairs(tabs) do
			if tab.tabId == tabId then
				tab:SetBackdropColor(0.8, 0.2, 0.2, 1)
			else
				tab:SetBackdropColor(0.2, 0.2, 0.2, 1)
			end
		end

		if tabId == 0 then
			f.BracketPanel:Hide()
			f.GeneralPanel:Show()
			local opt = BattlegroundTargets_Options
			if f.GeneralPanel.Minimap then
				f.GeneralPanel.Minimap:SetChecked(opt.MinimapButton and true or false)
			end
			if f.GeneralPanel.UseFosterWSG then
				f.GeneralPanel.UseFosterWSG:SetChecked(opt.UseFosterThemeWSG and true or false)
			end
		else
			f.GeneralPanel:Hide()
			f.BracketPanel:Show()
			BGT:UpdateOptionsWidgets(tabId)
			BGT:EnableConfigMode(tabId)
		end
	end

	for i, cfg in ipairs(tabConfigs) do
		local tab = CreateFrame("Button", nil, f)
		tab.tabId = cfg.id
		tab:SetWidth(66)
		tab:SetHeight(22)
		tab:SetPoint("TOPLEFT", f, "TOPLEFT", 14 + (i - 1) * 72, -38)
		tab:SetBackdrop({
			bgFile = "Interface\Tooltips\UI-Tooltip-Background",
			edgeFile = "Interface\Tooltips\UI-Tooltip-Border",
			tile = true, tileSize = 8, edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 }
		})
		tab:SetBackdropColor(0.2, 0.2, 0.2, 1)
		tab.Text = tab:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		tab.Text:SetPoint("CENTER", 0, 0)
		tab.Text:SetText(cfg.name)
		tab:SetScript("OnClick", function()
			SelectTab(this.tabId)
		end)
		tabs[i] = tab
	end

	-- ---------------------------------------------------------------------- --
	-- Bracket Panel Widgets                                                  --
	-- ---------------------------------------------------------------------- --
	local bp = CreateFrame("Frame", nil, f)
	f.BracketPanel = bp
	bp:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -65)
	bp:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 45)

	-- Checkbuttons
	bp.EnableBracket = CreateCheckButton("BGTOpt_EnableBracket", bp, "Enable", function()
		local opt = BattlegroundTargets_Options
		opt.EnableBracket[selectedTab] = this:GetChecked() and true or false
		BGT:SetupButtonLayout(selectedTab)
		if BGT.isConfig and BGT.RenderRoster then BGT:RenderRoster() end
	end)
	bp.EnableBracket:SetPoint("TOPLEFT", bp, "TOPLEFT", 12, -4)

	bp.IndependentPos = CreateCheckButton("BGTOpt_IndependentPos", bp, "Independent Positioning", function()
		local opt = BattlegroundTargets_Options
		opt.IndependentPositioning[selectedTab] = this:GetChecked() and true or false
		BGT:Frame_SetupPosition("BattlegroundTargets_MainFrame")
	end)
	bp.IndependentPos:SetPoint("LEFT", bp.EnableBracket.Label, "RIGHT", 24, 0)

	bp.HideRealm = CreateCheckButton("BGTOpt_HideRealm", bp, "Hide Realm", function()
		local opt = BattlegroundTargets_Options
		opt.ButtonHideRealm[selectedTab] = this:GetChecked() and true or false
		if BGT.isConfig and BGT.RenderRoster then BGT:RenderRoster() end
	end)
	bp.HideRealm:SetPoint("TOPLEFT", bp.EnableBracket, "BOTTOMLEFT", 0, -6)

	bp.ShowHealthBar = CreateCheckButton("BGTOpt_ShowHealthBar", bp, "Show Health Bar", function()
		local opt = BattlegroundTargets_Options
		opt.ButtonShowHealthBar[selectedTab] = this:GetChecked() and true or false
		if BGT.isConfig and BGT.RenderRoster then BGT:RenderRoster() end
	end)
	bp.ShowHealthBar:SetPoint("TOPLEFT", bp.HideRealm, "BOTTOMLEFT", 0, -6)

	bp.ShowHealthText = CreateCheckButton("BGTOpt_ShowHealthText", bp, "Show Percent", function()
		local opt = BattlegroundTargets_Options
		opt.ButtonShowHealthText[selectedTab] = this:GetChecked() and true or false
		if BGT.isConfig and BGT.RenderRoster then BGT:RenderRoster() end
	end)
	bp.ShowHealthText:SetPoint("LEFT", bp.ShowHealthBar.Label, "RIGHT", 24, 0)

	-- Sliders
	bp.FontSize = CreateSlider("BGTOpt_FontSize", bp, "Text Size", 6, 20, 1, false, function(val)
		BattlegroundTargets_Options.ButtonFontSize[selectedTab] = val
		BGT:SetupButtonLayout(selectedTab)
		if BGT.isConfig and BGT.RenderRoster then BGT:RenderRoster() end
	end)
	bp.FontSize:SetPoint("TOPLEFT", bp.ShowHealthBar, "BOTTOMLEFT", 4, -18)

	bp.Scale = CreateSlider("BGTOpt_Scale", bp, "Scale", 50, 200, 5, true, function(val)
		BattlegroundTargets_Options.ButtonScale[selectedTab] = val / 100
		BGT:SetupButtonLayout(selectedTab)
	end)
	bp.Scale:SetPoint("TOPLEFT", bp.FontSize, "BOTTOMLEFT", 0, -18)

	bp.Width = CreateSlider("BGTOpt_Width", bp, "Width", 60, 300, 5, false, function(val)
		BattlegroundTargets_Options.ButtonWidth[selectedTab] = val
		BGT:SetupButtonLayout(selectedTab)
		if BGT.isConfig and BGT.RenderRoster then BGT:RenderRoster() end
	end)
	bp.Width:SetPoint("TOPLEFT", bp.Scale, "BOTTOMLEFT", 0, -18)

	bp.Height = CreateSlider("BGTOpt_Height", bp, "Height", 10, 40, 1, false, function(val)
		BattlegroundTargets_Options.ButtonHeight[selectedTab] = val
		BGT:SetupButtonLayout(selectedTab)
		if BGT.isConfig and BGT.RenderRoster then BGT:RenderRoster() end
	end)
	bp.Height:SetPoint("TOPLEFT", bp.Width, "BOTTOMLEFT", 0, -18)

	-- ---------------------------------------------------------------------- --
	-- General Panel Widgets                                                  --
	-- ---------------------------------------------------------------------- --
	local gp = CreateFrame("Frame", nil, f)
	f.GeneralPanel = gp
	gp:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -65)
	gp:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 45)
	gp:Hide()

	gp.Minimap = CreateCheckButton("BGTOpt_Minimap", gp, "Show Minimap-Button", function()
		BattlegroundTargets_Options.MinimapButton = this:GetChecked() and true or false
		if BattlegroundTargets_MinimapButton then
			if BattlegroundTargets_Options.MinimapButton then
				BattlegroundTargets_MinimapButton:Show()
			else
				BattlegroundTargets_MinimapButton:Hide()
			end
		end
	end)
	gp.Minimap:SetPoint("TOPLEFT", gp, "TOPLEFT", 12, -12)

	gp.UseFosterWSG = CreateCheckButton("BGTOpt_UseFosterWSG", gp, "Use FosterFrames Theme in WSG", function()
		BattlegroundTargets_Options.UseFosterThemeWSG = this:GetChecked() and true or false
		BGT:SetupButtonLayout(10)
		if BGT.isConfig and BGT.RenderRoster then BGT:RenderRoster() end
	end)
	gp.UseFosterWSG:SetPoint("TOPLEFT", gp.Minimap, "BOTTOMLEFT", 0, -12)

	-- Hook OnShow & OnHide
	f:SetScript("OnShow", function()
		BGT:Frame_SetupPosition("BattlegroundTargets_OptionsFrame")
		SelectTab(selectedTab)
	end)
	f:SetScript("OnHide", function()
		BGT:DisableConfigMode()
	end)
end

function BGT:UpdateOptionsWidgets(sz)
	local bp = BattlegroundTargets_OptionsFrame and BattlegroundTargets_OptionsFrame.BracketPanel
	if not bp then return end
	local opt = BattlegroundTargets_Options

	bp.EnableBracket:SetChecked(opt.EnableBracket[sz])
	bp.IndependentPos:SetChecked(opt.IndependentPositioning[sz])
	bp.HideRealm:SetChecked(opt.ButtonHideRealm[sz])
	bp.ShowHealthBar:SetChecked(opt.ButtonShowHealthBar[sz])
	bp.ShowHealthText:SetChecked(opt.ButtonShowHealthText[sz])

	bp.FontSize:SetValue(opt.ButtonFontSize[sz] or 10)
	bp.FontSize.ValueText:SetText(tostring(opt.ButtonFontSize[sz] or 10))

	local scalePct = math.floor((opt.ButtonScale[sz] or 1.0) * 100)
	bp.Scale:SetValue(scalePct)
	bp.Scale.ValueText:SetText(scalePct .. "%")

	bp.Width:SetValue(opt.ButtonWidth[sz] or 150)
	bp.Width.ValueText:SetText(tostring(opt.ButtonWidth[sz] or 150))

	bp.Height:SetValue(opt.ButtonHeight[sz] or 20)
	bp.Height.ValueText:SetText(tostring(opt.ButtonHeight[sz] or 20))
end

-- -------------------------------------------------------------------------- --
-- Minimap Button Creation                                                    --
-- -------------------------------------------------------------------------- --
function BGT:CreateMinimapButton()
	if BattlegroundTargets_MinimapButton then return end

	local btn = CreateFrame("Button", "BattlegroundTargets_MinimapButton", Minimap)
	btn:SetWidth(32)
	btn:SetHeight(32)
	btn:SetFrameStrata("MEDIUM")
	btn:SetToplevel(true)
	btn:EnableMouse(true)
	btn:SetMovable(true)

	local icon = btn:CreateTexture(nil, "BACKGROUND")
	icon:SetWidth(20)
	icon:SetHeight(20)
	icon:SetPoint("CENTER", 0, 0)
	icon:SetTexture("Interface\\Icons\\Spell_Holy_PrayerOfHealing02")

	local border = btn:CreateTexture(nil, "OVERLAY")
	border:SetWidth(54)
	border:SetHeight(54)
	border:SetPoint("TOPLEFT", 0, 0)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local function UpdatePos()
		local angle = BattlegroundTargets_Options.MinimapButtonPos or 45
		local rad = math.rad(angle)
		local x = 80 * math.cos(rad)
		local y = 80 * math.sin(rad)
		btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
	end

	btn:RegisterForDrag("LeftButton")
	btn:SetScript("OnDragStart", function()
		this:SetScript("OnUpdate", function()
			local cx, cy = GetCursorPosition()
			local mx, my = Minimap:GetCenter()
			local scale = Minimap:GetEffectiveScale()
			cx = cx / scale
			cy = cy / scale
			local angle = math.deg(math.atan2(cy - my, cx - mx))
			BattlegroundTargets_Options.MinimapButtonPos = angle
			UpdatePos()
		end)
	end)
	btn:SetScript("OnDragStop", function()
		this:SetScript("OnUpdate", nil)
	end)

	btn:SetScript("OnClick", function()
		BGT:ToggleOptions()
	end)

	btn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
		GameTooltip:SetText("BattlegroundTargets")
		GameTooltip:AddLine("Click to open configuration.", 1, 1, 1)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	UpdatePos()
	if not BattlegroundTargets_Options.MinimapButton then
		btn:Hide()
	end
end
