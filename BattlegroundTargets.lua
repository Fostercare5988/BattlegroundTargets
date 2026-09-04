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

local addonName = "BattlegroundTargets"
local MOD_VERSION = "3.0.0"

BattlegroundTargets = CreateFrame("Frame", "BattlegroundTargets_CoreFrame", UIParent)
local BGT = BattlegroundTargets
BGT.Version = MOD_VERSION

local L   = BattlegroundTargets_Localization or {}
local BGN = BattlegroundTargets_BGNames or {}
local RNA = BattlegroundTargets_RaceNames or {}

local playerName = UnitName("player")
local _, playerClassEN = UnitClass("player")
local playerFactionGroup = UnitFactionGroup("player")
local playerFactionDEF = (playerFactionGroup == "Horde") and 0 or 1
local oppositeFactionDEF = (playerFactionDEF == 0) and 1 or 0
local playerFactionBG = playerFactionDEF
local oppositeFactionBG = oppositeFactionDEF
local factionIsValid = false

local fontPath = "Fonts\\FRIZQT__.TTF"
local ffBorderTexture = [[Interface\AddOns\BattlegroundTargets\Textures\border.tga]]
local ffBarTexture    = [[Interface\AddOns\BattlegroundTargets\Textures\barTexture.tga]]

local CLASS_COLORS = RAID_CLASS_COLORS or {
	["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 },
	["MAGE"]    = { r = 0.41, g = 0.80, b = 0.94 },
	["ROGUE"]   = { r = 1.00, g = 0.96, b = 0.41 },
	["DRUID"]   = { r = 1.00, g = 0.49, b = 0.04 },
	["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45 },
	["SHAMAN"]  = { r = 0.00, g = 0.44, b = 0.87 },
	["PRIEST"]  = { r = 1.00, g = 1.00, b = 1.00 },
	["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
	["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
}

local CLASS_ORDER = {
	["DRUID"]   = 1,
	["HUNTER"]  = 2,
	["MAGE"]    = 3,
	["PALADIN"] = 4,
	["PRIEST"]  = 5,
	["ROGUE"]   = 6,
	["SHAMAN"]  = 7,
	["WARLOCK"] = 8,
	["WARRIOR"] = 9,
}

-- Pre-allocated data buffers (Rule D1: Zero Combat Heap Allocations)
local ENEMY_Data = {}
for i = 1, 40 do
	ENEMY_Data[i] = { name = "", classToken = "", scoreIndex = 0 }
end
local ENEMY_Count = 0
local ENEMY_NameToIndex = {}
local ENEMY_NameToPercent = {}
local ENEMY_NameToDead = {}

local currentSize = 10
BGT.currentSize = currentSize
BGT.isConfig = false
local inCombat = false
local latestScoreUpdate = 0
local scoreRequestThrottle = 0
local activeBG = false

-- -------------------------------------------------------------------------- --
-- FosterFrames WSG Visual Theme Helpers (CreateBorder)                       --
-- -------------------------------------------------------------------------- --
local ffDefaultTcut = 1 / 4.2
local function ffGetTextCoords(tcutsize)
	local sides = {
		[1] = { 0, tcutsize, tcutsize, 1 - tcutsize },
		[2] = { 1 - tcutsize, 1, tcutsize, 1 - tcutsize },
		[3] = { tcutsize, 1 - tcutsize, 0, tcutsize },
		[4] = { tcutsize, 1 - tcutsize, 1 - tcutsize, 1 },
	}
	local corners = {
		[1] = { { 0, tcutsize, 0, tcutsize }, 'TOPLEFT' },
		[2] = { { 1 - tcutsize, 1, 0, tcutsize }, 'TOPRIGHT' },
		[3] = { { 0, tcutsize, 1 - tcutsize, 1 }, 'BOTTOMLEFT' },
		[4] = { { 1 - tcutsize, 1, 1 - tcutsize, 1 }, 'BOTTOMRIGHT' },
	}
	return corners, sides
end

local function CreateBorder(name, parent, size, tcut)
	if not parent then return nil end
	local parentFrame = parent
	if not parent.GetFrameLevel and parent.GetParent then
		parentFrame = parent:GetParent()
	end
	if not parentFrame or not parentFrame.CreateTexture then return nil end

	local this = CreateFrame("Frame", name, parentFrame)
	this:ClearAllPoints()
	this:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	this:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	local level = (parentFrame.GetFrameLevel and parentFrame:GetFrameLevel() or 1) + 1
	this:SetFrameLevel(level)

	local tcutsize = tcut or ffDefaultTcut
	local corners, sides = ffGetTextCoords(tcutsize)

	this.c = {}
	for i = 1, 4 do
		this.c[i] = this:CreateTexture(nil, "OVERLAY")
		this.c[i]:SetHeight(size)
		this.c[i]:SetWidth(size)
		this.c[i]:SetTexture(ffBorderTexture)
		this.c[i]:SetTexCoord(corners[i][1][1], corners[i][1][2], corners[i][1][3], corners[i][1][4])
		local xo = (i == 1 or i == 3) and -1/8 or 1/8
		local yo = (i == 1 or i == 2) and 1/8 or -1/8
		this.c[i]:SetPoint(corners[i][2], this, xo * size, yo * size)
	end

	this.s = {}
	for i = 1, 4 do
		this.s[i] = this:CreateTexture(nil, "OVERLAY")
		this.s[i]:SetTexture(ffBorderTexture)
		this.s[i]:SetTexCoord(sides[i][1], sides[i][2], sides[i][3], sides[i][4])
	end

	this.s[1]:SetPoint("TOPLEFT", this.c[1], "BOTTOMLEFT")
	this.s[1]:SetPoint("BOTTOMRIGHT", this.c[3], "TOPRIGHT")
	this.s[2]:SetPoint("TOPLEFT", this.c[2], "BOTTOMLEFT")
	this.s[2]:SetPoint("BOTTOMRIGHT", this.c[4], "TOPRIGHT")
	this.s[3]:SetPoint("TOPLEFT", this.c[1], "TOPRIGHT")
	this.s[3]:SetPoint("BOTTOMRIGHT", this.c[2], "BOTTOMLEFT")
	this.s[4]:SetPoint("TOPLEFT", this.c[3], "TOPRIGHT")
	this.s[4]:SetPoint("BOTTOMRIGHT", this.c[4], "BOTTOMLEFT")

	return this
end

-- -------------------------------------------------------------------------- --
-- Options Initialization & Migration                                         --
-- -------------------------------------------------------------------------- --
function BGT:EnsureGlobalTables()
	if type(BattlegroundTargets_Options) ~= "table" then
		BattlegroundTargets_Options = {}
	end
	if type(BattlegroundTargets_Character) ~= "table" then
		BattlegroundTargets_Character = {}
	end

	local opt = BattlegroundTargets_Options
	if not opt.pos then opt.pos = {} end
	if not opt.EnableBracket then opt.EnableBracket = { [10] = true, [15] = true, [40] = true } end
	if not opt.IndependentPositioning then opt.IndependentPositioning = { [10] = false, [15] = false, [40] = false } end
	if not opt.ButtonFontSize then opt.ButtonFontSize = { [10] = 10, [15] = 10, [40] = 10 } end
	if not opt.ButtonScale then opt.ButtonScale = { [10] = 1.1, [15] = 1.0, [40] = 0.9 } end
	if not opt.ButtonWidth then opt.ButtonWidth = { [10] = 150, [15] = 150, [40] = 150 } end
	if not opt.ButtonHeight then opt.ButtonHeight = { [10] = 20, [15] = 20, [40] = 18 } end
	if not opt.ButtonShowHealthBar then opt.ButtonShowHealthBar = { [10] = true, [15] = true, [40] = true } end
	if not opt.ButtonShowHealthText then opt.ButtonShowHealthText = { [10] = true, [15] = true, [40] = true } end
	if not opt.ButtonHideRealm then opt.ButtonHideRealm = { [10] = false, [15] = false, [40] = false } end
	if not opt.ButtonSortBy then opt.ButtonSortBy = { [10] = 1, [15] = 1, [40] = 1 } end
	if opt.MinimapButton == nil then opt.MinimapButton = true end
	if opt.UseFosterThemeWSG == nil then opt.UseFosterThemeWSG = true end

	if not BattlegroundTargets_Character.NativeFaction then
		BattlegroundTargets_Character.NativeFaction = playerFactionGroup or "Horde"
	end
end
BGT:EnsureGlobalTables()

-- -------------------------------------------------------------------------- --
-- Frame Creation: Main Drag Handle & 40 Enemy Buttons                        --
-- -------------------------------------------------------------------------- --
function BGT:CreateFrames()
	if BGT.MainFrame then return end

	-- Main Container / Move Handle
	local mainFrame = CreateFrame("Frame", "BattlegroundTargets_MainFrame", UIParent)
	BGT.MainFrame = mainFrame
	mainFrame:SetWidth(150)
	mainFrame:SetHeight(20)
	mainFrame:SetMovable(true)
	mainFrame:SetResizable(true)
	mainFrame:SetClampedToScreen(true)
	mainFrame:EnableMouse(true)
	mainFrame:Hide()

	mainFrame:SetScript("OnMouseDown", function()
		mainFrame:StartMoving()
	end)
	mainFrame:SetScript("OnMouseUp", function()
		mainFrame:StopMovingOrSizing()
		BGT:Frame_SavePosition("BattlegroundTargets_MainFrame")
	end)

	mainFrame.MoveText = mainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	mainFrame.MoveText:SetPoint("CENTER", 0, 0)
	mainFrame.MoveText:SetText(L["click & move"] or "click & move")
	mainFrame.MoveText:SetTextColor(0.8, 0.8, 0.8, 1)

	-- 40 Target Buttons
	BGT.TargetButton = {}
	for i = 1, 40 do
		local btn = CreateFrame("Button", "BattlegroundTargets_TargetButton" .. i, UIParent)
		BGT.TargetButton[i] = btn
		btn.buttonNum = i
		btn:SetWidth(150)
		btn:SetHeight(20)
		btn:Hide()

		if i == 1 then
			btn:SetPoint("TOPLEFT", mainFrame, "BOTTOMLEFT", 0, 0)
		else
			btn:SetPoint("TOPLEFT", BGT.TargetButton[i - 1], "BOTTOMLEFT", 0, 0)
		end

		-- Background (dark translucent backplate)
		btn.Background = btn:CreateTexture(nil, "BACKGROUND")
		btn.Background:SetPoint("TOPLEFT", 1, -1)
		btn.Background:SetWidth(148)
		btn.Background:SetHeight(18)
		btn.Background:SetTexture(0, 0, 0, 0.45)

		-- Class Color Darker Background (tinted backing)
		btn.ClassColorBackground = btn:CreateTexture(nil, "BORDER")
		btn.ClassColorBackground:SetPoint("LEFT", btn, "LEFT", 1, 0)
		btn.ClassColorBackground:SetWidth(148)
		btn.ClassColorBackground:SetHeight(18)
		btn.ClassColorBackground:SetTexture(0, 0, 0, 0)

		-- Health Bar (bright class colored foreground bar)
		btn.HealthBar = btn:CreateTexture(nil, "ARTWORK")
		btn.HealthBar:SetPoint("LEFT", btn.ClassColorBackground, "LEFT", 0, 0)
		btn.HealthBar:SetWidth(148)
		btn.HealthBar:SetHeight(18)
		btn.HealthBar:SetTexture(0, 0, 0, 0)

		-- Health Text (Right-aligned FontString) - Rule C8: mouse passthrough
		btn.HealthText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		btn.HealthText:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
		btn.HealthText:SetJustifyH("RIGHT")
		btn.HealthText:SetFont(fontPath, 10, "OUTLINE")
		btn.HealthText:SetTextColor(1, 1, 1, 0.8)

		-- Player Name (Left-aligned FontString) - Rule C8: mouse passthrough
		btn.Name = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		btn.Name:SetPoint("LEFT", btn.ClassColorBackground, "LEFT", 4, 0)
		btn.Name:SetPoint("RIGHT", btn.HealthText, "LEFT", -4, 0)
		btn.Name:SetJustifyH("LEFT")
		btn.Name:SetFont(fontPath, 10, "")
		btn.Name:SetTextColor(1, 1, 1, 1)

		-- Highlight Borders (1px border lines)
		btn.HighlightT = btn:CreateTexture(nil, "HIGHLIGHT")
		btn.HighlightT:SetPoint("TOP", 0, 0)
		btn.HighlightT:SetHeight(1)
		btn.HighlightT:SetWidth(150)
		btn.HighlightT:SetTexture(1, 1, 0.5, 0.8)

		btn.HighlightB = btn:CreateTexture(nil, "HIGHLIGHT")
		btn.HighlightB:SetPoint("BOTTOM", 0, 0)
		btn.HighlightB:SetHeight(1)
		btn.HighlightB:SetWidth(150)
		btn.HighlightB:SetTexture(1, 1, 0.5, 0.8)

		btn.HighlightL = btn:CreateTexture(nil, "HIGHLIGHT")
		btn.HighlightL:SetPoint("LEFT", 0, 0)
		btn.HighlightL:SetWidth(1)
		btn.HighlightL:SetHeight(20)
		btn.HighlightL:SetTexture(1, 1, 0.5, 0.8)

		btn.HighlightR = btn:CreateTexture(nil, "HIGHLIGHT")
		btn.HighlightR:SetPoint("RIGHT", 0, 0)
		btn.HighlightR:SetWidth(1)
		btn.HighlightR:SetHeight(20)
		btn.HighlightR:SetTexture(1, 1, 0.5, 0.8)

		-- FosterFrames WSG Visual Theme Elements
		btn.ffBorder = CreateBorder(nil, btn, 10, 1 / 5)
		if btn.ffBorder then btn.ffBorder:Hide() end

		-- Rule C5: Explicit Right-Click Registration
		btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

		-- Instant Exact-Name Targeting via SuperWoW (works in/out of combat)
		btn:SetScript("OnClick", function()
			local targetName = this.targetName
			if not targetName or targetName == "" then return end
			if arg1 == "LeftButton" then
				TargetByName(targetName, true)
			elseif arg1 == "RightButton" then
				TargetByName(targetName, true)
				if FocusUnit then
					FocusUnit("target")
				end
				TargetLastTarget()
			end
		end)
	end

	BGT:Frame_SetupPosition("BattlegroundTargets_MainFrame")
end

-- -------------------------------------------------------------------------- --
-- Position Persistence & Setup                                               --
-- -------------------------------------------------------------------------- --
function BGT:Frame_SetupPosition(frameName)
	local f = _G[frameName]
	if not f then return end
	local opt = BattlegroundTargets_Options
	local sz = currentSize or 10

	if frameName == "BattlegroundTargets_MainFrame" then
		if opt.IndependentPositioning[sz] and opt.pos[frameName .. sz .. "_posX"] then
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", opt.pos[frameName .. sz .. "_posX"], opt.pos[frameName .. sz .. "_posY"])
		elseif opt.pos[frameName .. "_posX"] then
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", opt.pos[frameName .. "_posX"], opt.pos[frameName .. "_posY"])
		else
			f:ClearAllPoints()
			f:SetPoint("CENTER", UIParent, "CENTER", 300, 50)
		end
	elseif frameName == "BattlegroundTargets_OptionsFrame" then
		if opt.pos[frameName .. "_posX"] then
			f:ClearAllPoints()
			f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", opt.pos[frameName .. "_posX"], opt.pos[frameName .. "_posY"])
		else
			f:ClearAllPoints()
			f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
		end
	end
end

function BGT:Frame_SavePosition(frameName)
	local f = _G[frameName]
	if not f then return end
	local opt = BattlegroundTargets_Options
	local sz = currentSize or 10
	local keyX, keyY

	if frameName == "BattlegroundTargets_MainFrame" and opt.IndependentPositioning[sz] then
		keyX = frameName .. sz .. "_posX"
		keyY = frameName .. sz .. "_posY"
	else
		keyX = frameName .. "_posX"
		keyY = frameName .. "_posY"
	end

	opt.pos[keyX] = f:GetLeft()
	opt.pos[keyY] = f:GetTop()
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", opt.pos[keyX], opt.pos[keyY])
end

-- -------------------------------------------------------------------------- --
-- Layout Application for Current Bracket (10, 15, or 40)                     --
-- -------------------------------------------------------------------------- --
function BGT:SetupButtonLayout(bracketSize)
	local sz = bracketSize or currentSize or 10
	currentSize = sz
	BGT.currentSize = sz

	if not BGT.TargetButton then
		BGT:CreateFrames()
	end

	local opt = BattlegroundTargets_Options
	local btnWidth  = opt.ButtonWidth[sz] or 150
	local btnHeight = opt.ButtonHeight[sz] or 20
	local btnScale  = opt.ButtonScale[sz] or 1.0
	local fontSize  = opt.ButtonFontSize[sz] or 10
	local isWSG     = (sz == 10)
	local useFoster = isWSG and (opt.UseFosterThemeWSG ~= false)

	BGT.MainFrame:SetWidth(btnWidth)
	BGT.MainFrame:SetScale(btnScale)

	local btnWidth_2  = btnWidth - 2
	local btnHeight_2 = btnHeight - 2

	for i = 1, 40 do
		local btn = BGT.TargetButton[i]
		btn:SetScale(btnScale)
		btn:SetWidth(btnWidth)
		btn:SetHeight(btnHeight)

		btn.Background:SetWidth(btnWidth_2)
		btn.Background:SetHeight(btnHeight_2)
		btn.ClassColorBackground:SetWidth(btnWidth_2)
		btn.ClassColorBackground:SetHeight(btnHeight_2)
		btn.HealthBar:SetHeight(btnHeight_2)

		btn.HighlightT:SetWidth(btnWidth)
		btn.HighlightB:SetWidth(btnWidth)
		btn.HighlightL:SetHeight(btnHeight)
		btn.HighlightR:SetHeight(btnHeight)

		btn.Name:SetFont(fontPath, fontSize, "")
		btn.HealthText:SetFont(fontPath, fontSize, "OUTLINE")

		if useFoster then
			if btn.ffBorder then btn.ffBorder:Show() end
			btn.HealthBar:SetTexture(ffBarTexture)
			btn.Background:SetTexture(0, 0, 0, 0.65)
		else
			if btn.ffBorder then btn.ffBorder:Hide() end
			btn.Background:SetTexture(0, 0, 0, 0.45)
		end
	end

	BGT:Frame_SetupPosition("BattlegroundTargets_MainFrame")
end

-- -------------------------------------------------------------------------- --
-- Enemy Roster Processing (UPDATE_BATTLEFIELD_SCORE)                         --
-- -------------------------------------------------------------------------- --
local function ClassThenNameSort(a, b)
	if not a or not b then return false end
	local orderA = CLASS_ORDER[a.classToken] or 99
	local orderB = CLASS_ORDER[b.classToken] or 99
	if orderA ~= orderB then
		return orderA < orderB
	end
	return (a.name or "") < (b.name or "")
end

local function NameOnlySort(a, b)
	if not a or not b then return false end
	return (a.name or "") < (b.name or "")
end

function BGT:BattlefieldScoreUpdate()
	local now = GetTime()
	if (now - latestScoreUpdate) < 1.0 then return end
	latestScoreUpdate = now

	-- Detect active battleground
	local inBG = false
	local bgName = nil
	for i = 1, MAX_BATTLEFIELD_QUEUES do
		local status, mapName = GetBattlefieldStatus(i)
		if status == "active" then
			inBG = true
			bgName = BGN[mapName] or mapName
			break
		end
	end

	if not inBG and not BGT.isConfig then
		BGT.MainFrame:Hide()
		for i = 1, 40 do
			BGT.TargetButton[i]:Hide()
		end
		activeBG = false
		return
	end
	activeBG = true

	-- Determine bracket size from BG name
	local sz = 10
	if bgName == "Warsong Gulch" then
		sz = 10
	elseif bgName == "Arathi Basin" or bgName == "Eye of the Storm" then
		sz = 15
	elseif bgName == "Alterac Valley" then
		sz = 40
	else
		sz = currentSize or 10
	end

	if sz ~= currentSize then
		currentSize = sz
		BGT.currentSize = sz
		BGT:SetupButtonLayout(sz)
	end

	-- Check player faction from scoreboard (Mercenary mode support)
	local numScores = GetNumBattlefieldScores()
	for i = 1, numScores do
		local name, _, _, _, _, faction = GetBattlefieldScore(i)
		if name == playerName then
			playerFactionBG = faction
			oppositeFactionBG = (faction == 0) and 1 or 0
			factionIsValid = true
			break
		end
	end

	-- Extract enemy roster
	table.wipe(ENEMY_NameToIndex)
	ENEMY_Count = 0

	for i = 1, numScores do
		local name, _, _, _, _, faction, _, _, _, classToken = GetBattlefieldScore(i)
		if name and name ~= playerName and faction == oppositeFactionBG then
			ENEMY_Count = ENEMY_Count + 1
			if ENEMY_Count <= 40 then
				local entry = ENEMY_Data[ENEMY_Count]
				entry.name = name
				entry.classToken = classToken or "WARRIOR"
				entry.scoreIndex = i
			end
		end
	end

	-- Cap to currentSize
	local displayCount = math.min(ENEMY_Count, currentSize)

	-- Sort
	local sortMode = BattlegroundTargets_Options.ButtonSortBy[currentSize] or 1
	if sortMode == 2 then
		table.sort(ENEMY_Data, NameOnlySort)
	else
		table.sort(ENEMY_Data, ClassThenNameSort)
	end

	-- Render buttons
	local opt = BattlegroundTargets_Options
	local hideRealm = opt.ButtonHideRealm[currentSize]
	local showHealthBar = opt.ButtonShowHealthBar[currentSize]
	local showHealthText = opt.ButtonShowHealthText[currentSize]
	local maxBarWidth = (opt.ButtonWidth[currentSize] or 150) - 2

	for i = 1, currentSize do
		local btn = BGT.TargetButton[i]
		if i <= displayCount then
			local data = ENEMY_Data[i]
			local eName = data.name
			local cToken = data.classToken
			btn.targetName = eName
			btn.classToken = cToken
			ENEMY_NameToIndex[eName] = i

			-- Class Colors
			local col = CLASS_COLORS[cToken] or { r = 0.6, g = 0.6, b = 0.6 }
			local colR, colG, colB = col.r, col.g, col.b
			btn.ClassColorBackground:SetTexture(colR * 0.35, colG * 0.35, colB * 0.35, 1)
			if not (currentSize == 10 and opt.UseFosterThemeWSG) then
				btn.HealthBar:SetTexture(colR, colG, colB, 1)
			else
				btn.HealthBar:SetVertexColor(colR, colG, colB, 1)
			end

			-- Display Name (strip realm if hideRealm)
			local displayName = eName
			if hideRealm then
				local dashIdx = string.find(eName, "-", 1, true)
				if dashIdx then
					displayName = string.sub(eName, 1, dashIdx - 1)
				end
			end
			btn.Name:SetText(displayName)

			-- Health Telemetry
			local pct = ENEMY_NameToPercent[eName] or 100
			local isDead = ENEMY_NameToDead[eName]

			if showHealthBar then
				local barWidth = math.max(0.01, math.min(maxBarWidth, maxBarWidth * (pct / 100)))
				btn.HealthBar:SetWidth(barWidth)
				btn.HealthBar:Show()
			else
				btn.HealthBar:Hide()
			end

			if showHealthText then
				if isDead or pct <= 0 then
					btn.HealthText:SetText("|cffff2020DEAD|r")
					btn:SetAlpha(0.6)
				else
					btn.HealthText:SetText(pct .. "%")
					btn:SetAlpha(1.0)
				end
				btn.HealthText:Show()
			else
				btn.HealthText:Hide()
				btn:SetAlpha(isDead and 0.6 or 1.0)
			end

			btn:Show()
		else
			btn.targetName = nil
			btn:Hide()
		end
	end

	-- Show MainFrame if enabled
	if opt.EnableBracket[currentSize] and not BGT.isConfig then
		BGT.MainFrame:Show()
		BGT.MainFrame.MoveText:Hide()
	end
end

-- -------------------------------------------------------------------------- --
-- Real-Time Health Telemetry Mapper                                          --
-- -------------------------------------------------------------------------- --
function BGT:UpdateUnitHealth(unit)
	if not unit or not UnitExists(unit) then return end
	local name = UnitName(unit)
	if not name then return end

	local idx = ENEMY_NameToIndex[name]
	if not idx then return end

	local btn = BGT.TargetButton[idx]
	if not btn or not btn:IsShown() then return end

	-- Query Health
	local curHp = UnitHealth(unit)
	local maxHp = UnitHealthMax(unit)
	local isDead = UnitIsDead(unit) or UnitIsGhost(unit) or (curHp <= 0)

	local pct = 100
	if maxHp and maxHp > 0 then
		pct = math.floor((curHp / maxHp) * 100)
	end
	if isDead then pct = 0 end

	ENEMY_NameToPercent[name] = pct
	ENEMY_NameToDead[name] = isDead

	local opt = BattlegroundTargets_Options
	local showHealthBar = opt.ButtonShowHealthBar[currentSize]
	local showHealthText = opt.ButtonShowHealthText[currentSize]
	local maxBarWidth = (opt.ButtonWidth[currentSize] or 150) - 2

	if showHealthBar then
		local barWidth = math.max(0.01, math.min(maxBarWidth, maxBarWidth * (pct / 100)))
		btn.HealthBar:SetWidth(barWidth)
	end

	if showHealthText then
		if isDead then
			btn.HealthText:SetText("|cffff2020DEAD|r")
			btn:SetAlpha(0.6)
		else
			btn.HealthText:SetText(pct .. "%")
			btn:SetAlpha(1.0)
		end
	else
		btn:SetAlpha(isDead and 0.6 or 1.0)
	end
end

-- -------------------------------------------------------------------------- --
-- Test / Config Mode Preview                                                 --
-- -------------------------------------------------------------------------- --
local DUMMY_CLASSES = { "WARRIOR", "PRIEST", "MAGE", "DRUID", "HUNTER", "ROGUE", "SHAMAN", "PALADIN", "WARLOCK", "WARRIOR" }

function BGT:EnableConfigMode(bracketSize)
	BGT.isConfig = true
	local sz = bracketSize or currentSize or 10
	currentSize = sz
	BGT.currentSize = sz

	BGT:CreateFrames()
	BGT:SetupButtonLayout(sz)
	BGT.MainFrame:Show()
	BGT.MainFrame.MoveText:Show()

	local opt = BattlegroundTargets_Options
	local hideRealm = opt.ButtonHideRealm[sz]
	local showHealthBar = opt.ButtonShowHealthBar[sz]
	local showHealthText = opt.ButtonShowHealthText[sz]
	local maxBarWidth = (opt.ButtonWidth[sz] or 150) - 2

	for i = 1, 40 do
		local btn = BGT.TargetButton[i]
		if i <= sz then
			local cIndex = ((i - 1) % #DUMMY_CLASSES) + 1
			local cToken = DUMMY_CLASSES[cIndex]
			local dummyName = "Target" .. string.char(64 + i) .. "-Realm" .. (((i - 1) % 4) + 1)
			btn.targetName = dummyName
			btn.classToken = cToken

			local col = CLASS_COLORS[cToken] or { r = 0.6, g = 0.6, b = 0.6 }
			local colR, colG, colB = col.r, col.g, col.b
			btn.ClassColorBackground:SetTexture(colR * 0.35, colG * 0.35, colB * 0.35, 1)
			if not (sz == 10 and opt.UseFosterThemeWSG) then
				btn.HealthBar:SetTexture(colR, colG, colB, 1)
			else
				btn.HealthBar:SetVertexColor(colR, colG, colB, 1)
			end

			local displayName = dummyName
			if hideRealm then
				local dashIdx = string.find(dummyName, "-", 1, true)
				if dashIdx then
					displayName = string.sub(dummyName, 1, dashIdx - 1)
				end
			end
			btn.Name:SetText(displayName)

			local testPct = 100 - ((i * 7) % 85)
			if showHealthBar then
				local barWidth = math.max(0.01, math.min(maxBarWidth, maxBarWidth * (testPct / 100)))
				btn.HealthBar:SetWidth(barWidth)
				btn.HealthBar:Show()
			else
				btn.HealthBar:Hide()
			end

			if showHealthText then
				btn.HealthText:SetText(testPct .. "%")
				btn.HealthText:Show()
			else
				btn.HealthText:Hide()
			end

			btn:SetAlpha(1.0)
			btn:Show()
		else
			btn.targetName = nil
			btn:Hide()
		end
	end
end

function BGT:DisableConfigMode()
	BGT.isConfig = false
	BGT.MainFrame.MoveText:Hide()
	if activeBG then
		BGT:BattlefieldScoreUpdate()
	else
		BGT.MainFrame:Hide()
		for i = 1, 40 do
			BGT.TargetButton[i]:Hide()
		end
	end
end

function BGT:CopySettings(sourceSize, destinationSize)
	local opt = BattlegroundTargets_Options
	opt.ButtonFontSize[destinationSize]       = opt.ButtonFontSize[sourceSize]
	opt.ButtonScale[destinationSize]          = opt.ButtonScale[sourceSize]
	opt.ButtonWidth[destinationSize]          = opt.ButtonWidth[sourceSize]
	opt.ButtonHeight[destinationSize]         = opt.ButtonHeight[sourceSize]
	opt.ButtonShowHealthBar[destinationSize]  = opt.ButtonShowHealthBar[sourceSize]
	opt.ButtonShowHealthText[destinationSize] = opt.ButtonShowHealthText[sourceSize]
	opt.ButtonHideRealm[destinationSize]      = opt.ButtonHideRealm[sourceSize]
	opt.ButtonSortBy[destinationSize]         = opt.ButtonSortBy[sourceSize]
	opt.IndependentPositioning[destinationSize] = opt.IndependentPositioning[sourceSize]

	BGT:SetupButtonLayout(destinationSize)
end

function BGT:ToggleOptions()
	if not BattlegroundTargets_OptionsFrame then
		if BGT.CreateOptionsFrame then
			BGT:CreateOptionsFrame()
		end
	end
	if BattlegroundTargets_OptionsFrame then
		if BattlegroundTargets_OptionsFrame:IsShown() then
			BattlegroundTargets_OptionsFrame:Hide()
		else
			BattlegroundTargets_OptionsFrame:Show()
		end
	end
end

-- -------------------------------------------------------------------------- --
-- Event Registration & Dispatching                                           --
-- -------------------------------------------------------------------------- --
BGT:RegisterEvent("PLAYER_LOGIN")
BGT:RegisterEvent("PLAYER_ENTERING_WORLD")
BGT:RegisterEvent("ZONE_CHANGED_NEW_AREA")
BGT:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
BGT:RegisterEvent("PLAYER_REGEN_DISABLED")
BGT:RegisterEvent("PLAYER_REGEN_ENABLED")
BGT:RegisterEvent("UNIT_HEALTH")
BGT:RegisterEvent("UNIT_HEALTH_FREQUENT")
BGT:RegisterEvent("UNIT_TARGET")
BGT:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
BGT:RegisterEvent("PLAYER_TARGET_CHANGED")

BGT:SetScript("OnEvent", function()
	if event == "PLAYER_LOGIN" then
		BGT:EnsureGlobalTables()
		BGT:CreateFrames()
		if BGT.CreateMinimapButton then
			BGT:CreateMinimapButton()
		end

	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
		BGT:EnsureGlobalTables()
		RequestBattlefieldScoreData()
		BGT:BattlefieldScoreUpdate()

	elseif event == "UPDATE_BATTLEFIELD_SCORE" then
		BGT:BattlefieldScoreUpdate()

	elseif event == "PLAYER_REGEN_DISABLED" then
		inCombat = true

	elseif event == "PLAYER_REGEN_ENABLED" then
		inCombat = false

	elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
		BGT:UpdateUnitHealth(arg1)

	elseif event == "UNIT_TARGET" then
		if arg1 then
			BGT:UpdateUnitHealth(arg1 .. "target")
		end

	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		BGT:UpdateUnitHealth("mouseover")

	elseif event == "PLAYER_TARGET_CHANGED" then
		BGT:UpdateUnitHealth("target")
	end
end)

-- -------------------------------------------------------------------------- --
-- Slash Command Handlers                                                     --
-- -------------------------------------------------------------------------- --
SLASH_BATTLEGROUNDTARGETS1 = "/bgt"
SLASH_BATTLEGROUNDTARGETS2 = "/battlegroundtargets"
SlashCmdList["BATTLEGROUNDTARGETS"] = function(msg)
	local cmd = string.lower(msg or "")
	if cmd == "test" then
		if BGT.isConfig then
			BGT:DisableConfigMode()
		else
			BGT:EnableConfigMode(10)
		end
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
