-- -------------------------------------------------------------------------- --
-- BattlegroundTargets (World of Warcraft 1.12.1 Enhanced)                    --
-- Engineered natively for ClassicAPI v1.13.4+, SuperWoW v2.2+, UnitXP SP3,   --
-- NamPower v4.6.3+, and DXVK high-refresh framerate pacing.                  --
-- -------------------------------------------------------------------------- --

-- Strict Engine Dependency Guard (Mandatory ClassicAPI v1.13.4+ & SuperWoW v2.2+)
if not (CLASSIC_API_VERSION and SUPERWOW_VERSION) then
	DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[Fatal Error]|r BattlegroundTargets requires ClassicAPI.dll (v1.13.4+) & SuperWoW (v2.2+)! Please ensure both DLLs are loaded.", 1, 0.2, 0.2)
	return
end

local MOD_VERSION = "3.1.0"
local MAX_ENEMIES = 40
local BRACKETS = { 10, 15, 40 }
local FONT = "Fonts\\FRIZQT__.TTF"
local BAR_TEXTURE = [[Interface\AddOns\BattlegroundTargets\Textures\barTexture.tga]]

BattlegroundTargets = CreateFrame("Frame", "BattlegroundTargets_CoreFrame", UIParent)
local BGT = BattlegroundTargets
BGT.Version = MOD_VERSION
BGT.currentSize = 10
BGT.isConfig = false

local playerName = UnitName("player")
local playerFaction = UnitFactionGroup("player") == "Horde" and 0 or 1
local enemyFaction = playerFaction == 0 and 1 or 0
local activeBG = false
local currentSize = 10

local CLASS_COLORS = RAID_CLASS_COLORS
local FALLBACK_COLOR = { r = 0.60, g = 0.60, b = 0.60 }
local CLASS_ORDER = {
	DRUID = 1,
	HUNTER = 2,
	MAGE = 3,
	PALADIN = 4,
	PRIEST = 5,
	ROGUE = 6,
	SHAMAN = 7,
	WARLOCK = 8,
	WARRIOR = 9,
}

-- Fixed-size roster storage (1..MAX_ENEMIES). Only 1..enemyCount is active.
local roster = {}
for i = 1, MAX_ENEMIES do
	roster[i] = { name = nil, classToken = nil, guid = nil }
end
local enemyCount = 0

-- Runtime lookup/telemetry caches
local nameToRow = {}
local nameToGUID = {}
local shortNameToFull = {}
local healthPct = {}
local deadState = {}

local wipe = table.wipe

local function StripRealm(name)
	local p = string.find(name, "-", 1, true)
	if p then
		return string.sub(name, 1, p - 1)
	end
	return name
end

local function GetClassColor(classToken)
	return CLASS_COLORS[classToken] or FALLBACK_COLOR
end

local function ClassThenNameSort(a, b)
	local oa = CLASS_ORDER[a.classToken] or 99
	local ob = CLASS_ORDER[b.classToken] or 99
	if oa ~= ob then
		return oa < ob
	end
	return a.name < b.name
end

local function NameSort(a, b)
	return a.name < b.name
end

-- Allocation-free insertion sort strictly over the active segment (1..enemyCount)
local function SortActiveRoster(comparator)
	for i = 2, enemyCount do
		local j = i
		while j > 1 and comparator(roster[j], roster[j - 1]) do
			roster[j], roster[j - 1] = roster[j - 1], roster[j]
			j = j - 1
		end
	end
end

function BGT:EnsureOptions()
	if type(BattlegroundTargets_Options) ~= "table" then
		BattlegroundTargets_Options = {}
	end

	local o = BattlegroundTargets_Options
	o.pos = o.pos or {}
	o.EnableBracket = o.EnableBracket or {}
	o.IndependentPositioning = o.IndependentPositioning or {}
	o.ButtonFontSize = o.ButtonFontSize or {}
	o.ButtonScale = o.ButtonScale or {}
	o.ButtonWidth = o.ButtonWidth or {}
	o.ButtonHeight = o.ButtonHeight or {}
	o.ButtonShowHealthBar = o.ButtonShowHealthBar or {}
	o.ButtonShowHealthText = o.ButtonShowHealthText or {}
	o.ButtonHideRealm = o.ButtonHideRealm or {}
	o.ButtonSortBy = o.ButtonSortBy or {}

	for _, size in ipairs(BRACKETS) do
		if o.EnableBracket[size] == nil then o.EnableBracket[size] = true end
		if o.IndependentPositioning[size] == nil then o.IndependentPositioning[size] = false end
		if o.ButtonFontSize[size] == nil then o.ButtonFontSize[size] = 10 end
		if o.ButtonScale[size] == nil then o.ButtonScale[size] = size == 10 and 1.10 or (size == 15 and 1.00 or 0.90) end
		if o.ButtonWidth[size] == nil then o.ButtonWidth[size] = 150 end
		if o.ButtonHeight[size] == nil then o.ButtonHeight[size] = size == 40 and 18 or 20 end
		if o.ButtonShowHealthBar[size] == nil then o.ButtonShowHealthBar[size] = true end
		if o.ButtonShowHealthText[size] == nil then o.ButtonShowHealthText[size] = true end
		if o.ButtonHideRealm[size] == nil then o.ButtonHideRealm[size] = false end
		if o.ButtonSortBy[size] == nil then o.ButtonSortBy[size] = 1 end
	end

	if o.MinimapButton == nil then o.MinimapButton = true end
	if o.UseFosterThemeWSG == nil then o.UseFosterThemeWSG = true end
end
BGT:EnsureOptions()

local function CreateLine(parent, layer)
	local t = parent:CreateTexture(nil, layer or "OVERLAY")
	t:SetTexture(1, 1, 1, 1)
	return t
end

local function SetBorderColor(btn, r, g, b, a)
	btn.BorderTop:SetTexture(r, g, b, a)
	btn.BorderBottom:SetTexture(r, g, b, a)
	btn.BorderLeft:SetTexture(r, g, b, a)
	btn.BorderRight:SetTexture(r, g, b, a)
end

local function UpdateRowSelectionVisual(btn)
	if not btn.targetName then return end

	local targetName = UnitExists("target") and UnitName("target") or nil
	local focusName = UnitExists("focus") and UnitName("focus") or nil

	if targetName == btn.targetName then
		SetBorderColor(btn, 1.0, 0.82, 0.20, 1.0)
		btn.Selection:Show()
	elseif focusName == btn.targetName then
		SetBorderColor(btn, 0.35, 0.75, 1.0, 1.0)
		btn.Selection:Show()
	else
		-- Reset border back to neutral dark to prevent sticky target borders
		SetBorderColor(btn, 0, 0, 0, 0.80)
		btn.Selection:Hide()
	end
end

local function UpdateAllSelectionVisuals()
	if not BGT.TargetButton then return end
	for i = 1, currentSize do
		local btn = BGT.TargetButton[i]
		if btn:IsShown() then
			UpdateRowSelectionVisual(btn)
		end
	end
end

function BGT:CreateFrames()
	if BGT.MainFrame then return end

	local main = CreateFrame("Frame", "BattlegroundTargets_MainFrame", UIParent)
	BGT.MainFrame = main
	main:SetWidth(150)
	main:SetHeight(20)
	main:SetMovable(true)
	main:SetClampedToScreen(true)
	main:EnableMouse(BGT.isConfig and true or false)
	main:Hide()

	main:SetScript("OnMouseDown", function()
		if BGT.isConfig then
			this:StartMoving()
		end
	end)
	main:SetScript("OnMouseUp", function()
		this:StopMovingOrSizing()
		BGT:Frame_SavePosition("BattlegroundTargets_MainFrame")
	end)

	main.MoveText = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	main.MoveText:SetPoint("CENTER", main, "CENTER", 0, 0)
	main.MoveText:SetText("click & move")
	main.MoveText:SetTextColor(0.8, 0.8, 0.8, 1)

	BGT.TargetButton = {}
	for i = 1, MAX_ENEMIES do
		local btn = CreateFrame("Button", "BattlegroundTargets_TargetButton" .. i, main)
		BGT.TargetButton[i] = btn
		btn.buttonNum = i
		btn:SetWidth(150)
		btn:SetHeight(20)
		btn:Hide()

		if i == 1 then
			btn:SetPoint("TOPLEFT", main, "BOTTOMLEFT", 0, 0)
		else
			btn:SetPoint("TOPLEFT", BGT.TargetButton[i - 1], "BOTTOMLEFT", 0, 0)
		end

		btn.Background = btn:CreateTexture(nil, "BACKGROUND")
		btn.Background:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
		btn.Background:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
		btn.Background:SetTexture(0, 0, 0, 0.58)

		btn.ClassBackground = btn:CreateTexture(nil, "BORDER")
		btn.ClassBackground:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
		btn.ClassBackground:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
		btn.ClassBackground:SetTexture(0, 0, 0, 1)

		btn.HealthBar = btn:CreateTexture(nil, "ARTWORK")
		btn.HealthBar:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
		btn.HealthBar:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 1, 1)
		btn.HealthBar:SetWidth(148)

		btn.Selection = btn:CreateTexture(nil, "ARTWORK")
		btn.Selection:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
		btn.Selection:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
		btn.Selection:SetTexture(1, 1, 1, 0.08)
		btn.Selection:Hide()

		btn.Name = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		btn.Name:SetPoint("LEFT", btn, "LEFT", 4, 0)
		btn.Name:SetJustifyH("LEFT")
		btn.Name:SetFont(FONT, 10, "")
		btn.Name:SetTextColor(1, 1, 1, 1)

		btn.HealthText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		btn.HealthText:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
		btn.HealthText:SetJustifyH("RIGHT")
		btn.HealthText:SetFont(FONT, 10, "OUTLINE")
		btn.HealthText:SetTextColor(1, 1, 1, 0.90)

		btn.Name:SetPoint("RIGHT", btn.HealthText, "LEFT", -4, 0)

		btn.BorderTop = CreateLine(btn, "OVERLAY")
		btn.BorderTop:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
		btn.BorderTop:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
		btn.BorderTop:SetHeight(1)

		btn.BorderBottom = CreateLine(btn, "OVERLAY")
		btn.BorderBottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
		btn.BorderBottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
		btn.BorderBottom:SetHeight(1)

		btn.BorderLeft = CreateLine(btn, "OVERLAY")
		btn.BorderLeft:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
		btn.BorderLeft:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
		btn.BorderLeft:SetWidth(1)

		btn.BorderRight = CreateLine(btn, "OVERLAY")
		btn.BorderRight:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
		btn.BorderRight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
		btn.BorderRight:SetWidth(1)

		SetBorderColor(btn, 0, 0, 0, 0.80)

		btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

		btn:SetScript("OnClick", function()
			local name = this.targetName
			if not name then return end

			local guid = this.targetGUID or nameToGUID[name]
			if arg1 == "LeftButton" then
				if guid then
					TargetUnit(guid)
				else
					TargetByName(name, true)
				end
			elseif arg1 == "RightButton" then
				local isCurrentTarget = UnitExists("target") and (UnitName("target") == name)
				if isCurrentTarget then
					FocusUnit("target")
				else
					local hadPriorTarget = UnitExists("target")
					if guid then
						TargetUnit(guid)
					else
						TargetByName(name, true)
					end
					if UnitExists("target") and UnitName("target") == name then
						FocusUnit("target")
					end
					if hadPriorTarget then
						TargetLastTarget()
					else
						ClearTarget()
					end
				end
			end
		end)
	end

	BGT:Frame_SetupPosition("BattlegroundTargets_MainFrame")
end

function BGT:Frame_SetupPosition(frameName)
	local frame = _G[frameName]
	if not frame then return end

	local o = BattlegroundTargets_Options
	local size = currentSize
	local keyPrefix = frameName
	if frameName == "BattlegroundTargets_MainFrame" and o.IndependentPositioning[size] then
		keyPrefix = frameName .. size
	end

	local x = o.pos[keyPrefix .. "_posX"]
	local y = o.pos[keyPrefix .. "_posY"]
	frame:ClearAllPoints()
	if x and y then
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	elseif frameName == "BattlegroundTargets_MainFrame" then
		frame:SetPoint("CENTER", UIParent, "CENTER", 300, 50)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	end
end

function BGT:Frame_SavePosition(frameName)
	local frame = _G[frameName]
	if not frame then return end

	local o = BattlegroundTargets_Options
	local keyPrefix = frameName
	if frameName == "BattlegroundTargets_MainFrame" and o.IndependentPositioning[currentSize] then
		keyPrefix = frameName .. currentSize
	end

	o.pos[keyPrefix .. "_posX"] = frame:GetLeft()
	o.pos[keyPrefix .. "_posY"] = frame:GetTop()
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", o.pos[keyPrefix .. "_posX"], o.pos[keyPrefix .. "_posY"])
end

function BGT:SetupButtonLayout(size)
	size = size or currentSize
	currentSize = size
	BGT.currentSize = size

	if not BGT.TargetButton then
		BGT:CreateFrames()
	end

	local o = BattlegroundTargets_Options
	local width = o.ButtonWidth[size]
	local height = o.ButtonHeight[size]
	local fontSize = o.ButtonFontSize[size]
	local scale = o.ButtonScale[size]
	local useTexture = size == 10 and o.UseFosterThemeWSG

	BGT.MainFrame:SetWidth(width)
	BGT.MainFrame:SetScale(scale)
	BGT.MainFrame:EnableMouse(BGT.isConfig and true or false)

	for i = 1, MAX_ENEMIES do
		local btn = BGT.TargetButton[i]
		btn:SetWidth(width)
		btn:SetHeight(height)
		btn.Name:SetFont(FONT, fontSize, "")
		btn.HealthText:SetFont(FONT, fontSize, "OUTLINE")
		if useTexture then
			btn.HealthBar:SetTexture(BAR_TEXTURE)
		else
			btn.HealthBar:SetTexture(1, 1, 1, 1)
		end
	end

	BGT:Frame_SetupPosition("BattlegroundTargets_MainFrame")
end

local function GetBracketSize(bgName)
	if not bgName then return currentSize end
	if string.find(bgName, "Warsong") or string.find(bgName, "Kriegshymnen") or string.find(bgName, "Goulet") then
		return 10
	elseif string.find(bgName, "Arathi") or string.find(bgName, "Eye") or string.find(bgName, "Auge") or string.find(bgName, "Oeil") then
		return 15
	elseif string.find(bgName, "Alterac") then
		return 40
	end
	return currentSize
end

local function DetectBattleground()
	local maxQueues = MAX_BATTLEFIELD_QUEUES or 3
	for i = 1, maxQueues do
		local status, mapName = GetBattlefieldStatus(i)
		if status == "active" then
			return true, mapName
		end
	end
	return false, nil
end

local function RenderHealthForRow(index, name)
	local btn = BGT.TargetButton[index]
	local o = BattlegroundTargets_Options
	local pct = healthPct[name] or 100
	local dead = deadState[name]
	local maxWidth = o.ButtonWidth[currentSize] - 2

	if o.ButtonShowHealthBar[currentSize] then
		btn.HealthBar:SetWidth(math.max(0.01, maxWidth * pct / 100))
		btn.HealthBar:Show()
	else
		btn.HealthBar:Hide()
	end

	if o.ButtonShowHealthText[currentSize] then
		btn.HealthText:SetText(dead and "|cffff4040DEAD|r" or (pct .. "%"))
		btn.HealthText:Show()
	else
		btn.HealthText:Hide()
	end

	btn:SetAlpha(dead and 0.55 or 1.0)
end

local function RenderRoster()
	local o = BattlegroundTargets_Options
	if not o.EnableBracket[currentSize] and not BGT.isConfig then
		BGT.MainFrame:Hide()
		return
	end

	wipe(nameToRow)
	wipe(shortNameToFull)

	local displayCount = math.min(enemyCount, currentSize)
	for i = 1, displayCount do
		local fullName = roster[i].name
		local shortName = StripRealm(fullName)
		if shortNameToFull[shortName] == nil then
			shortNameToFull[shortName] = fullName
		elseif shortNameToFull[shortName] ~= fullName then
			shortNameToFull[shortName] = false
		end
	end

	for i = 1, currentSize do
		local btn = BGT.TargetButton[i]
		if i <= displayCount then
			local data = roster[i]
			local color = GetClassColor(data.classToken)
			local name = data.name

			btn.targetName = name
			btn.targetGUID = nameToGUID[name]
			btn.classToken = data.classToken
			nameToRow[name] = i

			btn.ClassBackground:SetTexture(color.r * 0.30, color.g * 0.30, color.b * 0.30, 1)
			btn.HealthBar:SetVertexColor(color.r, color.g, color.b, 1)

			btn.Name:SetText(o.ButtonHideRealm[currentSize] and StripRealm(name) or name)
			RenderHealthForRow(i, name)
			UpdateRowSelectionVisual(btn)
			btn:Show()
		else
			btn.targetName = nil
			btn.targetGUID = nil
			btn:Hide()
		end
	end

	BGT.MainFrame:Show()
	BGT.MainFrame:EnableMouse(BGT.isConfig and true or false)
	BGT.MainFrame.MoveText:SetShown(BGT.isConfig and true or false)
end
BGT.RenderRoster = RenderRoster

function BGT:BattlefieldScoreUpdate()
	if BGT.isConfig then return end

	local inBG, bgName = DetectBattleground()
	if not inBG then
		activeBG = false
		BGT.MainFrame:Hide()
		return
	end
	activeBG = true

	local size = GetBracketSize(bgName)
	if size ~= currentSize then
		BGT:SetupButtonLayout(size)
	end

	local numScores = GetNumBattlefieldScores()
	for i = 1, numScores do
		local name, _, _, _, _, faction = GetBattlefieldScore(i)
		if name == playerName then
			enemyFaction = faction == 0 and 1 or 0
			break
		end
	end

	enemyCount = 0
	for i = 1, numScores do
		local name, _, _, _, _, faction, _, _, _, classToken = GetBattlefieldScore(i)
		if name and name ~= playerName and faction == enemyFaction and enemyCount < MAX_ENEMIES then
			enemyCount = enemyCount + 1
			local e = roster[enemyCount]
			e.name = name
			e.classToken = classToken or "WARRIOR"
			e.guid = nameToGUID[name]
		end
	end

	for i = enemyCount + 1, MAX_ENEMIES do
		local e = roster[i]
		e.name = nil
		e.classToken = nil
		e.guid = nil
	end

	if BattlegroundTargets_Options.ButtonSortBy[currentSize] == 2 then
		SortActiveRoster(NameSort)
	else
		SortActiveRoster(ClassThenNameSort)
	end

	RenderRoster()
end

local function ObserveUnit(unit)
	if not unit or not UnitExists(unit) then return end
	local observedName = UnitName(unit)
	if not observedName then return end
	local name = nameToRow[observedName] and observedName or shortNameToFull[StripRealm(observedName)]
	if not name then return end

	local guid = UnitGUID(unit)
	if guid then
		nameToGUID[name] = guid
		local row = nameToRow[name]
		if row then
			BGT.TargetButton[row].targetGUID = guid
		end
	end

	local row = nameToRow[name]
	if not row then return end

	local hp, hpMax
	if UnitXP then
		local ok1, cur = pcall(UnitXP, "health", unit)
		local ok2, maxh = pcall(UnitXP, "maxhealth", unit)
		if ok1 and ok2 and cur and maxh and maxh > 0 then
			hp, hpMax = cur, maxh
		end
	end
	if not hp then
		hp = UnitHealth(unit)
		hpMax = UnitHealthMax(unit)
	end

	local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit) or (UnitIsDead(unit) or UnitIsGhost(unit))
	local pct = 100
	if hpMax and hpMax > 0 then
		pct = math.floor((hp / hpMax) * 100 + 0.5)
	end
	if dead or (hp and hp <= 0) then pct = 0 end

	if healthPct[name] == pct and deadState[name] == dead then return end
	healthPct[name] = pct
	deadState[name] = dead
	RenderHealthForRow(row, name)
end

function BGT:EnableConfigMode(size)
	BGT.isConfig = true
	currentSize = size or currentSize
	BGT.currentSize = currentSize
	BGT:CreateFrames()
	BGT:SetupButtonLayout(currentSize)

	enemyCount = currentSize
	local classes = { "WARRIOR", "PRIEST", "MAGE", "DRUID", "HUNTER", "ROGUE", "SHAMAN", "PALADIN", "WARLOCK" }
	for i = 1, currentSize do
		local e = roster[i]
		e.name = "Target" .. i .. "-Realm"
		e.classToken = classes[((i - 1) % table.getn(classes)) + 1]
		e.guid = nil
		healthPct[e.name] = 100 - ((i * 7) % 85)
		deadState[e.name] = false
	end
	RenderRoster()
end

function BGT:DisableConfigMode()
	BGT.isConfig = false
	if activeBG then
		BGT:BattlefieldScoreUpdate()
	else
		BGT.MainFrame:Hide()
	end
end

function BGT:CopySettings(sourceSize, destinationSize)
	local o = BattlegroundTargets_Options
	o.ButtonFontSize[destinationSize] = o.ButtonFontSize[sourceSize]
	o.ButtonScale[destinationSize] = o.ButtonScale[sourceSize]
	o.ButtonWidth[destinationSize] = o.ButtonWidth[sourceSize]
	o.ButtonHeight[destinationSize] = o.ButtonHeight[sourceSize]
	o.ButtonShowHealthBar[destinationSize] = o.ButtonShowHealthBar[sourceSize]
	o.ButtonShowHealthText[destinationSize] = o.ButtonShowHealthText[sourceSize]
	o.ButtonHideRealm[destinationSize] = o.ButtonHideRealm[sourceSize]
	o.ButtonSortBy[destinationSize] = o.ButtonSortBy[sourceSize]
	o.IndependentPositioning[destinationSize] = o.IndependentPositioning[sourceSize]
end

function BGT:ToggleOptions()
	if not BattlegroundTargets_OptionsFrame and BGT.CreateOptionsFrame then
		BGT:CreateOptionsFrame()
	end
	if BattlegroundTargets_OptionsFrame then
		BattlegroundTargets_OptionsFrame:SetShown(not BattlegroundTargets_OptionsFrame:IsShown())
	end
end

BGT:RegisterEvent("PLAYER_LOGIN")
BGT:RegisterEvent("PLAYER_ENTERING_WORLD")
BGT:RegisterEvent("ZONE_CHANGED_NEW_AREA")
BGT:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
BGT:RegisterEvent("UNIT_HEALTH")
BGT:RegisterEvent("UNIT_HEALTH_FREQUENT")
BGT:RegisterEvent("UNIT_TARGET")
BGT:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
BGT:RegisterEvent("PLAYER_TARGET_CHANGED")
BGT:RegisterEvent("PLAYER_FOCUS_CHANGED")
BGT:RegisterEvent("NAME_PLATE_UNIT_ADDED")
BGT:RegisterEvent("UNIT_NAME_UPDATE")

BGT:SetScript("OnEvent", function()
	if event == "PLAYER_LOGIN" then
		BGT:EnsureOptions()
		BGT:CreateFrames()
		BGT:SetupButtonLayout(currentSize)
		if BGT.CreateMinimapButton then BGT:CreateMinimapButton() end

	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
		RequestBattlefieldScoreData()
		BGT:BattlefieldScoreUpdate()

	elseif event == "UPDATE_BATTLEFIELD_SCORE" then
		BGT:BattlefieldScoreUpdate()

	elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
		ObserveUnit(arg1)

	elseif event == "UNIT_TARGET" then
		if arg1 then ObserveUnit(arg1 .. "target") end

	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		ObserveUnit("mouseover")

	elseif event == "PLAYER_TARGET_CHANGED" then
		ObserveUnit("target")
		UpdateAllSelectionVisuals()

	elseif event == "PLAYER_FOCUS_CHANGED" then
		ObserveUnit("focus")
		UpdateAllSelectionVisuals()

	elseif event == "NAME_PLATE_UNIT_ADDED" or event == "UNIT_NAME_UPDATE" then
		ObserveUnit(arg1)
	end
end)

SLASH_BATTLEGROUNDTARGETS1 = "/bgt"
SLASH_BATTLEGROUNDTARGETS2 = "/battlegroundtargets"
SlashCmdList["BATTLEGROUNDTARGETS"] = function(msg)
	local cmd = string.lower(msg or "")
	if cmd == "test" then
		if BGT.isConfig then BGT:DisableConfigMode() else BGT:EnableConfigMode(10) end
	elseif cmd == "reset" then
		BattlegroundTargets_Options.pos = {}
		BGT:Frame_SetupPosition("BattlegroundTargets_MainFrame")
		if BattlegroundTargets_OptionsFrame then
			BGT:Frame_SetupPosition("BattlegroundTargets_OptionsFrame")
		end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[BattlegroundTargets]|r Frame positions reset.", 1, 1, 1)
	else
		BGT:ToggleOptions()
	end
end
