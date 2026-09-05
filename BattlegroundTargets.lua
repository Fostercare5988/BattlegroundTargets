-- -------------------------------------------------------------------------- --
-- BattlegroundTargets (World of Warcraft 1.12.1 Enhanced)                    --
-- Engineered natively for ClassicAPI v1.13.4+, SuperWoW v2.2+, UnitXP SP3,   --
-- NamPower v4.6.3+, and DXVK high-refresh framerate pacing.                  --
-- -------------------------------------------------------------------------- --

-- Strict Engine Dependency Guard (Mandatory ClassicAPI v1.13.4+ & SuperWoW v2.2+)
local MIN_CLASSIC_API = 11304

if not (CLASSIC_API_VERSION and SUPERWOW_VERSION) or 
   (type(CLASSIC_API_VERSION) == "number" and CLASSIC_API_VERSION < MIN_CLASSIC_API) then
	DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[Fatal Error]|r BattlegroundTargets requires ClassicAPI (v1.13.4+) & SuperWoW (v2.2+)! Please ensure both DLLs are loaded.", 1, 0.2, 0.2)
	return
end

local MOD_VERSION = "3.3.0"
local MAX_ENEMIES = 40
local BRACKETS = { 10, 15, 40 }
local FONT = "Fonts\\FRIZQT__.TTF"
local BAR_TEXTURE = [[Interface\AddOns\BattlegroundTargets\Textures\barTexture.tga]]
local PROWL_TEXTURE = [[Interface\AddOns\BattlegroundTargets\Textures\prowl.tga]]

BattlegroundTargets = CreateFrame("Frame", "BattlegroundTargets_CoreFrame", UIParent)
local BGT = BattlegroundTargets
BGT.Version = MOD_VERSION
BGT.currentSize = 10
BGT.isConfig = false

local playerName = UnitName("player")
local playerFaction = UnitFactionGroup("player") == "Horde" and 0 or 1
local enemyFaction = playerFaction == 0 and 1 or 0
local activeBG = false
BGT.activeBG = false
local currentSize = 10

local CLASS_COLORS = {
	HUNTER  = { r = 0.67, g = 0.83, b = 0.45 },
	WARLOCK = { r = 0.58, g = 0.51, b = 0.79 },
	PRIEST  = { r = 1.00, g = 1.00, b = 1.00 },
	PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
	MAGE    = { r = 0.41, g = 0.80, b = 0.94 },
	ROGUE   = { r = 1.00, g = 0.96, b = 0.41 },
	DRUID   = { r = 1.00, g = 0.49, b = 0.04 },
	SHAMAN  = { r = 0.00, g = 0.44, b = 0.87 },
	WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
}
if RAID_CLASS_COLORS then
	for k, v in pairs(RAID_CLASS_COLORS) do
		if k ~= "SHAMAN" and not CLASS_COLORS[k] then
			CLASS_COLORS[k] = v
		end
	end
end

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

local function ResolveClassToken(rawClass)
	if not rawClass or type(rawClass) ~= "string" then return "WARRIOR" end
	local upper = string.upper(rawClass)
	return (CLASS_COLORS[upper] and upper) or "WARRIOR"
end

local function GetClassColor(classToken)
	return CLASS_COLORS[classToken] or FALLBACK_COLOR
end
BGT.ResolveClassToken = ResolveClassToken
BGT.GetClassColor = GetClassColor

-- Fixed-size roster storage (1..MAX_ENEMIES). Only 1..enemyCount is active.
local roster = {}
for i = 1, MAX_ENEMIES do
	roster[i] = { name = nil, classToken = nil, guid = nil }
end
local enemyCount = 0

-- Runtime lookup/telemetry caches
local nameToRow = {}
local nameToGUID = {}
local guidToName = {}
local shortNameToFull = {}
local healthPct = {}
local deadState = {}
local stealthedState = {}

local wipe = table.wipe

local STEALTH_SPELLS = {
	-- Rogue Stealth
	[1784] = { name = "Stealth", texture = "Interface\\Icons\\Ability_Stealth", duration = 0 },
	[1785] = { name = "Stealth", texture = "Interface\\Icons\\Ability_Stealth", duration = 0 },
	[1786] = { name = "Stealth", texture = "Interface\\Icons\\Ability_Stealth", duration = 0 },
	[1787] = { name = "Stealth", texture = "Interface\\Icons\\Ability_Stealth", duration = 0 },
	-- Rogue Vanish
	[1856] = { name = "Vanish",  texture = "Interface\\Icons\\Ability_Stealth",  duration = 0 },
	[1857] = { name = "Vanish",  texture = "Interface\\Icons\\Ability_Stealth",  duration = 0 },
	-- Druid Prowl
	[5215] = { name = "Prowl",   texture = PROWL_TEXTURE, duration = 0 },
	[6783] = { name = "Prowl",   texture = PROWL_TEXTURE, duration = 0 },
	[9913] = { name = "Prowl",   texture = PROWL_TEXTURE, duration = 0 },
	-- Night Elf Shadowmeld
	[20580] = { name = "Shadowmeld", texture = "Interface\\Icons\\Ability_Racial_ShadowMeld", duration = 0 },
	-- Invisibility Potions
	[3680]  = { name = "Lesser Invisibility", texture = "Interface\\Icons\\Spell_Nature_Invisibilty", duration = 15 },
	[11464] = { name = "Invisibility",        texture = "Interface\\Icons\\Spell_Nature_Invisibilty", duration = 18 },
	-- Gnomish Cloaking Device
	[8342]  = { name = "Cloaking",            texture = "Interface\\Icons\\INV_Misc_EngGizmos_04",   duration = 60 },
	-- Deepwood Pipe (Smoke Cloud)
	[23133] = { name = "Smoke Cloud",         texture = "Interface\\Icons\\Ability_Stealth", duration = 30 },
	[23134] = { name = "Smoke Cloud",         texture = "Interface\\Icons\\Ability_Stealth", duration = 30 },
	-- Mage Invisibility (custom/Vanilla+)
	[66]    = { name = "Invisibility",        texture = "Interface\\Icons\\Spell_Nature_Invisibilty", duration = 20 },
	[32612] = { name = "Invisibility",        texture = "Interface\\Icons\\Spell_Nature_Invisibilty", duration = 20 },
}

local STEALTH_NAMES = {
	["Stealth"]             = { name = "Stealth",             texture = "Interface\\Icons\\Ability_Stealth", duration = 0 },
	["Prowl"]               = { name = "Prowl",               texture = PROWL_TEXTURE, duration = 0 },
	["Vanish"]              = { name = "Vanish",              texture = "Interface\\Icons\\Ability_Stealth", duration = 0 },
	["Shadowmeld"]          = { name = "Shadowmeld",          texture = "Interface\\Icons\\Ability_Racial_ShadowMeld", duration = 0 },
	["Invisibility"]        = { name = "Invisibility",        texture = "Interface\\Icons\\Spell_Nature_Invisibilty", duration = 18 },
	["Lesser Invisibility"] = { name = "Lesser Invisibility", texture = "Interface\\Icons\\Spell_Nature_Invisibilty", duration = 15 },
	["Cloaking"]            = { name = "Cloaking",            texture = "Interface\\Icons\\INV_Misc_EngGizmos_04", duration = 60 },
	["Smoke Cloud"]         = { name = "Smoke Cloud",         texture = "Interface\\Icons\\Ability_Stealth", duration = 30 },
}

local STEALTH_TEXTURE_LOOKUP = {
	["Interface\\Icons\\Ability_Stealth"]            = "Stealth",
	[PROWL_TEXTURE]                                  = "Prowl",
	["Interface\\Icons\\Ability_Druid_SupriseAttack"] = "Prowl",
	["Interface\\Icons\\Ability_Druid_CatForm"]      = "Prowl",
	["Interface\\Icons\\Ability_Ambush"]             = "Prowl",
	["Interface\\Icons\\Ability_Hunter_Pet_Cat"]     = "Prowl",
	["Interface\\Icons\\Ability_Vanish"]             = "Vanish",
	["Interface\\Icons\\Ability_Racial_ShadowMeld"]  = "Shadowmeld",
	["Interface\\Icons\\Spell_Nature_Invisibilty"]    = "Invisibility",
	["Interface\\Icons\\INV_Misc_EngGizmos_04"]      = "Cloaking",
}

local function CheckIsStealthSpell(spellId)
	if not spellId then return false end
	local s = STEALTH_SPELLS[spellId]
	local spellTex = s and s.texture
	local spellName = s and s.name
	local spellDur = s and s.duration or 0

	if SpellInfo then
		local name = SpellInfo(spellId)
		if name and name ~= "" then
			spellName = spellName or name
		end
	end

	if s or (spellName and STEALTH_NAMES[spellName]) then
		local def = spellName and STEALTH_NAMES[spellName]
		local finalName = spellName or (def and def.name) or "Stealth"
		local finalTex = (def and def.texture) or spellTex or "Interface\\Icons\\Ability_Stealth"
		local finalDur = spellDur or (def and def.duration) or 0
		return true, finalName, finalTex, finalDur
	end

	return false
end

local function CheckIsStealthName(spellName)
	if not spellName then return false end
	local data = STEALTH_NAMES[spellName]
	if data then
		return true, data.name, data.texture, data.duration
	end
	return false
end
BGT.CheckIsStealthSpell = CheckIsStealthSpell
BGT.CheckIsStealthName = CheckIsStealthName

local function StripRealm(name)
	if not name then return "" end
	local p = string.find(name, "-", 1, true)
	if p then
		return string.sub(name, 1, p - 1)
	end
	return name
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

-- Roster delta-detection buffers (fixed 1..MAX_ENEMIES, zero GC allocation)
local prevEnemyCount = -1
local prevSortBy = -1
local prevEnemyNames = {}
local prevEnemyClasses = {}
for i = 1, MAX_ENEMIES do
	prevEnemyNames[i] = ""
	prevEnemyClasses[i] = ""
end

local function HasRosterChanged()
	local sortBy = (BattlegroundTargets_Options and BattlegroundTargets_Options.ButtonSortBy and BattlegroundTargets_Options.ButtonSortBy[currentSize]) or 1
	if sortBy ~= prevSortBy then return true end
	if enemyCount ~= prevEnemyCount then return true end
	for i = 1, enemyCount do
		if roster[i].name ~= prevEnemyNames[i] or roster[i].classToken ~= prevEnemyClasses[i] then
			return true
		end
	end
	return false
end

local function SaveRosterSnapshot()
	prevSortBy = (BattlegroundTargets_Options and BattlegroundTargets_Options.ButtonSortBy and BattlegroundTargets_Options.ButtonSortBy[currentSize]) or 1
	prevEnemyCount = enemyCount
	for i = 1, enemyCount do
		prevEnemyNames[i] = roster[i].name or ""
		prevEnemyClasses[i] = roster[i].classToken or ""
	end
	for i = enemyCount + 1, MAX_ENEMIES do
		prevEnemyNames[i] = ""
		prevEnemyClasses[i] = ""
	end
end

function BGT:InvalidateRosterCache()
	prevEnemyCount = -1
	prevSortBy = -1
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
	o.ShowStealthIcon = o.ShowStealthIcon or {}
	o.DimStealthed = o.DimStealthed or {}
	o.ShowStealthText = o.ShowStealthText or {}

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
		if o.ShowStealthIcon[size] == nil then o.ShowStealthIcon[size] = true end
		if o.DimStealthed[size] == nil then o.DimStealthed[size] = false end
		if o.ShowStealthText[size] == nil then o.ShowStealthText[size] = true end
	end

	-- One-time migration for users updating to the improved stealth visibility defaults
	if not o.StealthDefaultsV2 then
		o.StealthDefaultsV2 = true
		for _, size in ipairs(BRACKETS) do
			o.ShowStealthIcon[size] = true
			o.DimStealthed[size] = false
			o.ShowStealthText[size] = true
		end
	end

	if o.MinimapButton == nil then o.MinimapButton = true end

	o.Spy = o.Spy or {}
	if o.Spy.Enabled == nil then o.Spy.Enabled = true end
	if o.Spy.SoundAlert == nil then o.Spy.SoundAlert = true end
	if o.Spy.StealthAlert == nil then o.Spy.StealthAlert = true end
	if o.Spy.AutoHide == nil then o.Spy.AutoHide = true end
	if o.Spy.Timeout == nil then o.Spy.Timeout = 30 end
	if o.Spy.MaxRows == nil then o.Spy.MaxRows = 5 end
	if o.Spy.Scale == nil then o.Spy.Scale = 1.0 end
end
BGT:EnsureOptions()

local function UpdateRowStealthVisual(index, name)
	if not BGT.TargetButton then return end
	local btn = BGT.TargetButton[index]
	if not btn or not name then return end
	local o = BattlegroundTargets_Options
	local size = currentSize
	local stealth = stealthedState[name]
	local dead = deadState[name]
	local height = o.ButtonHeight[size] or 20

	if stealth and not dead and (o.ShowStealthIcon[size] ~= false) then
		local sName = stealth.spellName or "Stealth"
		local tex = stealth.texture
		if sName == "Prowl" or string.find(tex or "", "prowl") or string.find(tex or "", "SupriseAttack") or string.find(tex or "", "Pet_Cat") or string.find(tex or "", "Ambush") or string.find(tex or "", "CatForm") then
			tex = PROWL_TEXTURE
		elseif sName == "Vanish" or sName == "Stealth" or string.find(tex or "", "Vanish") or string.find(tex or "", "Stealth") then
			tex = "Interface\\Icons\\Ability_Stealth"
		elseif not tex or tex == "" then
			tex = "Interface\\Icons\\Ability_Stealth"
		end
		btn.StealthIcon:SetTexture(tex)
		btn.StealthIcon:SetVertexColor(1, 1, 1, 1)
		btn.StealthIcon:Show()
		btn.StealthIconBg:Show()
		btn.Name:SetPoint("LEFT", btn, "LEFT", height + 1, 0)
	else
		btn.StealthIcon:Hide()
		btn.StealthIconBg:Hide()
		btn.Name:SetPoint("LEFT", btn, "LEFT", 4, 0)
	end

	if dead then
		btn:SetAlpha(0.55)
	elseif stealth and o.DimStealthed[size] then
		btn:SetAlpha(0.75)
	else
		btn:SetAlpha(1.0)
	end

	if stealth and not dead and (o.ShowStealthText[size] ~= false) then
		local sName = stealth.spellName or "Stealth"
		local tag = (sName == "Prowl" and "|cffb0b0ffPROWL|r")
			or (sName == "Vanish" and "|cffb0b0ffVANISH|r")
			or (sName == "Shadowmeld" and "|cff9090ffMELD|r")
			or (sName == "Cloaking" and "|cff00ffffCLOAK|r")
			or (string.find(sName, "Invis") and "|cff00ffffINVIS|r")
			or "|cff9090ffSTEALTH|r"
		btn.HealthText:SetText(tag)
		btn.HealthText:Show()
	else
		local pct = healthPct[name] or 100
		if o.ButtonShowHealthText[size] then
			btn.HealthText:SetText(dead and "|cffff4040DEAD|r" or (pct .. "%"))
			btn.HealthText:Show()
		else
			btn.HealthText:Hide()
		end
	end
end

local function SetUnitStealth(name, isStealthed, spellName, texture, duration)
	if not name then return end
	if isStealthed then
		local entry = stealthedState[name]
		if not entry then
			entry = {}
			stealthedState[name] = entry
		end
		entry.isStealthed = true
		entry.spellName = spellName or "Stealth"
		entry.texture = texture or "Interface\\Icons\\Ability_Stealth"
		entry.expireTime = (duration and duration > 0) and (GetTime() + duration) or nil

		if duration and duration > 0 and C_Timer and C_Timer.After then
			C_Timer.After(duration + 0.5, function()
				local cur = stealthedState[name]
				if cur and cur.expireTime and GetTime() >= cur.expireTime then
					SetUnitStealth(name, false)
				end
			end)
		end
	else
		if stealthedState[name] then
			stealthedState[name] = nil
		end
	end

	local row = nameToRow[name]
	if row then
		UpdateRowStealthVisual(row, name)
	end
end

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
	for i = 1, MAX_ENEMIES do
		local btn = BGT.TargetButton[i]
		if btn and btn:IsShown() then
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

		btn.StealthIconBg = btn:CreateTexture(nil, "ARTWORK")
		btn.StealthIconBg:SetPoint("LEFT", btn, "LEFT", 1, 0)
		btn.StealthIconBg:SetTexture(0, 0, 0, 1)
		btn.StealthIconBg:Hide()

		btn.StealthIcon = btn:CreateTexture(nil, "OVERLAY")
		btn.StealthIcon:SetPoint("LEFT", btn, "LEFT", 2, 0)
		btn.StealthIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		btn.StealthIcon:Hide()

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
	elseif frameName == "BattlegroundTargets_SpyFrame" then
		frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -200)
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

	BGT.MainFrame:SetWidth(width)
	BGT.MainFrame:SetScale(scale)
	BGT.MainFrame:EnableMouse(BGT.isConfig and true or false)

	for i = 1, MAX_ENEMIES do
		local btn = BGT.TargetButton[i]
		btn:SetWidth(width)
		btn:SetHeight(height)
		btn.Name:SetFont(FONT, fontSize, "")
		btn.HealthText:SetFont(FONT, fontSize, "OUTLINE")
		if btn.StealthIconBg then
			btn.StealthIconBg:SetWidth(height - 2)
			btn.StealthIconBg:SetHeight(height - 2)
		end
		if btn.StealthIcon then
			btn.StealthIcon:SetWidth(height - 4)
			btn.StealthIcon:SetHeight(height - 4)
		end
		btn.HealthBar:SetTexture(BAR_TEXTURE)
	end

	BGT:Frame_SetupPosition("BattlegroundTargets_MainFrame")
end

local function GetBracketSize(bgName)
	if not bgName then return currentSize end
	if string.find(bgName, "Warsong") then
		return 10
	elseif string.find(bgName, "Arathi") or string.find(bgName, "Eye") then
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

	if dead and stealthedState[name] then
		stealthedState[name] = nil
	end

	UpdateRowStealthVisual(index, name)
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

	for i = 1, MAX_ENEMIES do
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
			if btn.StealthIcon then btn.StealthIcon:Hide() end
			if btn.StealthIconBg then btn.StealthIconBg:Hide() end
			btn:Hide()
		end
	end

	BGT.MainFrame:Show()
	BGT.MainFrame:EnableMouse(BGT.isConfig and true or false)
	BGT.MainFrame.MoveText:SetShown(BGT.isConfig and true or false)
end
BGT.RenderRoster = RenderRoster

function BGT:BattlefieldScoreUpdate(force)
	if BGT.isConfig then return end

	local inBG, bgName = DetectBattleground()
	if not inBG then
		activeBG = false
		BGT.activeBG = false
		if BGT.Spy and BGT.Spy.OnBattlegroundChanged then
			BGT.Spy:OnBattlegroundChanged(false)
		end
		prevEnemyCount = -1
		wipe(stealthedState)
		wipe(guidToName)
		BGT.MainFrame:Hide()
		return
	end
	activeBG = true
	BGT.activeBG = true
	if BGT.Spy and BGT.Spy.OnBattlegroundChanged then
		BGT.Spy:OnBattlegroundChanged(true)
	end

	local size = GetBracketSize(bgName)
	if size ~= currentSize then
		prevEnemyCount = -1
		BGT:SetupButtonLayout(size)
	end

	local numScores = GetNumBattlefieldScores()
	for i = 1, numScores do
		local name, _, _, _, _, faction = GetBattlefieldScore(i)
		if name and StripRealm(name) == playerName then
			enemyFaction = faction == 0 and 1 or 0
			break
		end
	end

	enemyCount = 0
	for i = 1, numScores do
		local name, _, _, _, _, faction, _, _, class, classToken = GetBattlefieldScore(i)
		if name and StripRealm(name) ~= playerName and faction == enemyFaction and enemyCount < MAX_ENEMIES then
			enemyCount = enemyCount + 1
			local e = roster[enemyCount]
			e.name = name
			local rawClass = (type(classToken) == "string" and classToken) or (type(class) == "string" and class)
			e.classToken = ResolveClassToken(rawClass)
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

	if not force and not HasRosterChanged() then return end
	SaveRosterSnapshot()

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
		guidToName[guid] = name
		local row = nameToRow[name]
		if row then
			BGT.TargetButton[row].targetGUID = guid
		end
	end

	local row = nameToRow[name]
	if not row then return end

	local _, unitClassToken = UnitClass(unit)
	if unitClassToken then
		local btn = BGT.TargetButton[row]
		if btn and btn.classToken ~= unitClassToken then
			btn.classToken = unitClassToken
			if roster[row] then roster[row].classToken = unitClassToken end
			local color = GetClassColor(unitClassToken)
			btn.ClassBackground:SetTexture(color.r * 0.30, color.g * 0.30, color.b * 0.30, 1)
			btn.HealthBar:SetVertexColor(color.r, color.g, color.b, 1)
		end
	end

	-- Check Stealth/Invisibility Auras on observed unit
	local foundStealth = nil
	if C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot then
		local slots = C_UnitAuras.GetAuraSlots(unit, "HELPFUL")
		if slots then
			for s = 1, #slots do
				local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[s])
				if aura then
					if aura.name and STEALTH_NAMES[aura.name] then
						foundStealth = STEALTH_NAMES[aura.name]
						break
					elseif aura.icon and STEALTH_TEXTURE_LOOKUP[aura.icon] then
						local sName = STEALTH_TEXTURE_LOOKUP[aura.icon]
						foundStealth = STEALTH_NAMES[sName]
						break
					end
				end
			end
		end
	else
		for i = 1, 32 do
			local tex, _, auraId = UnitBuff(unit, i)
			if not tex then break end
			if auraId and STEALTH_SPELLS[auraId] then
				foundStealth = STEALTH_SPELLS[auraId]
				break
			elseif tex and STEALTH_TEXTURE_LOOKUP[tex] then
				local sName = STEALTH_TEXTURE_LOOKUP[tex]
				foundStealth = STEALTH_NAMES[sName]
				break
			end
		end
	end

	if foundStealth then
		SetUnitStealth(name, true, foundStealth.name, foundStealth.texture, foundStealth.duration)
	elseif stealthedState[name] then
		SetUnitStealth(name, false)
	end

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
	prevEnemyCount = -1
	currentSize = size or currentSize
	BGT.currentSize = currentSize
	BGT:CreateFrames()
	BGT:SetupButtonLayout(currentSize)

	enemyCount = currentSize
	local classes = { "WARRIOR", "PRIEST", "MAGE", "DRUID", "HUNTER", "ROGUE", "SHAMAN", "PALADIN", "WARLOCK" }
	for i = 1, currentSize do
		local e = roster[i]
		e.name = "Target" .. i .. "-Realm"
		e.classToken = classes[((i - 1) % #classes) + 1]
		e.guid = nil
		healthPct[e.name] = 100 - ((i * 7) % 85)
		deadState[e.name] = false
		if e.classToken == "ROGUE" then
			if i % 2 == 1 then
				stealthedState[e.name] = { isStealthed = true, spellName = "Stealth", texture = "Interface\\Icons\\Ability_Stealth" }
			else
				stealthedState[e.name] = { isStealthed = true, spellName = "Vanish", texture = "Interface\\Icons\\Ability_Stealth" }
			end
		elseif e.classToken == "DRUID" and (i % 2 == 0) then
			stealthedState[e.name] = { isStealthed = true, spellName = "Prowl", texture = PROWL_TEXTURE }
		elseif i == 3 then
			stealthedState[e.name] = { isStealthed = true, spellName = "Invisibility", texture = "Interface\\Icons\\Spell_Nature_Invisibilty" }
		else
			stealthedState[e.name] = nil
		end
	end
	for i = currentSize + 1, MAX_ENEMIES do
		local e = roster[i]
		e.name = nil
		e.classToken = nil
		e.guid = nil
	end
	RenderRoster()
end

function BGT:DisableConfigMode()
	BGT.isConfig = false
	prevEnemyCount = -1
	wipe(stealthedState)
	for i = 1, MAX_ENEMIES do
		local btn = BGT.TargetButton[i]
		if btn then
			btn.targetName = nil
			btn.targetGUID = nil
			if btn.StealthIcon then btn.StealthIcon:Hide() end
			if btn.StealthIconBg then btn.StealthIconBg:Hide() end
			btn:Hide()
		end
	end
	if activeBG then
		BGT:BattlefieldScoreUpdate(true)
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
	o.ShowStealthIcon[destinationSize] = o.ShowStealthIcon[sourceSize]
	o.DimStealthed[destinationSize] = o.DimStealthed[sourceSize]
	o.ShowStealthText[destinationSize] = o.ShowStealthText[sourceSize]
	o.IndependentPositioning[destinationSize] = o.IndependentPositioning[sourceSize]
end

function BGT:ToggleOptions()
	if not BattlegroundTargets_OptionsFrame and BGT.CreateOptionsFrame then
		BGT:CreateOptionsFrame()
	end
	if BattlegroundTargets_OptionsFrame then
		if BattlegroundTargets_OptionsFrame:IsShown() then
			BattlegroundTargets_OptionsFrame:Hide()
		else
			BattlegroundTargets_OptionsFrame:Show()
		end
	end
end

BGT:RegisterEvent("PLAYER_LOGIN")
BGT:RegisterEvent("PLAYER_ENTERING_WORLD")
BGT:RegisterEvent("ZONE_CHANGED_NEW_AREA")
BGT:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
BGT:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
BGT:RegisterEvent("UNIT_HEALTH")
BGT:RegisterEvent("UNIT_HEALTH_FREQUENT")
BGT:RegisterEvent("UNIT_TARGET")
BGT:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
BGT:RegisterEvent("PLAYER_TARGET_CHANGED")
BGT:RegisterEvent("PLAYER_FOCUS_CHANGED")
BGT:RegisterEvent("NAME_PLATE_UNIT_ADDED")
BGT:RegisterEvent("UNIT_NAME_UPDATE")
BGT:RegisterEvent("UNIT_CASTEVENT")
BGT:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
BGT:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
BGT:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
BGT:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
BGT:RegisterEvent("CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS")

BGT:SetScript("OnEvent", function()
	if event == "PLAYER_LOGIN" then
		BGT:EnsureOptions()
		BGT:CreateFrames()
		BGT:SetupButtonLayout(currentSize)
		if BGT.CreateMinimapButton then BGT:CreateMinimapButton() end

	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" or event == "UPDATE_BATTLEFIELD_STATUS" then
		prevEnemyCount = -1
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

	elseif event == "UNIT_CASTEVENT" then
		local casterGUID = arg1
		local eventType = arg3
		local spellId = arg4
		if not casterGUID then return end

		local rawName = UnitName(casterGUID) or guidToName[casterGUID]
		if not rawName then return end
		local name = nameToRow[rawName] and rawName or shortNameToFull[StripRealm(rawName)]
		if not name then return end

		guidToName[casterGUID] = name
		nameToGUID[name] = casterGUID
		local row = nameToRow[name]
		if row and BGT.TargetButton[row] then
			BGT.TargetButton[row].targetGUID = casterGUID
		end

		if eventType == "CAST" then
			local isStealth, sName, sTex, sDur = CheckIsStealthSpell(spellId)
			if isStealth then
				SetUnitStealth(name, true, sName, sTex, sDur)
			elseif stealthedState[name] then
				SetUnitStealth(name, false)
			end
		elseif eventType == "START" or eventType == "CHANNEL" or eventType == "MAINHAND" or eventType == "OFFHAND" then
			if stealthedState[name] then
				SetUnitStealth(name, false)
			end
		end

	elseif event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS" then
		if arg1 then
			local _, _, enemyName, buffName = string.find(arg1, "^(.-) gains (.-)%.$")
			if enemyName and buffName and CheckIsStealthName(buffName) then
				local name = nameToRow[enemyName] and enemyName or shortNameToFull[enemyName]
				if name then
					local data = STEALTH_NAMES[buffName]
					SetUnitStealth(name, true, data.name, data.texture, data.duration)
				end
			end
		end

	elseif event == "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF" then
		if arg1 then
			local _, _, enemyName, spellName = string.find(arg1, "^(.-) casts (.-)%.$")
			if not enemyName then
				_, _, enemyName, spellName = string.find(arg1, "^(.-) performs (.-)%.$")
			end
			if enemyName and spellName and CheckIsStealthName(spellName) then
				local name = nameToRow[enemyName] and enemyName or shortNameToFull[enemyName]
				if name then
					local data = STEALTH_NAMES[spellName]
					SetUnitStealth(name, true, data.name, data.texture, data.duration)
				end
			end
		end

	elseif event == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then
		if arg1 then
			local _, _, buffName, enemyName = string.find(arg1, "^(.-) fades from (.-)%.$")
			if buffName and enemyName and CheckIsStealthName(buffName) then
				local name = nameToRow[enemyName] and enemyName or shortNameToFull[enemyName]
				if name and stealthedState[name] then
					SetUnitStealth(name, false)
				end
			end
		end

	elseif event == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE" then
		if arg1 then
			local _, _, enemyName = string.find(arg1, "^(.-)'s ")
			if enemyName then
				local name = nameToRow[enemyName] and enemyName or shortNameToFull[enemyName]
				if name and stealthedState[name] then
					SetUnitStealth(name, false)
				end
			end
		end

	elseif event == "CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS" then
		if arg1 then
			local _, _, enemyName = string.find(arg1, "^(.-) hits ")
			if not enemyName then _, _, enemyName = string.find(arg1, "^(.-) crits ") end
			if not enemyName then _, _, enemyName = string.find(arg1, "^(.-) misses ") end
			if not enemyName then _, _, enemyName = string.find(arg1, "^(.-) attacks%.") end
			if enemyName then
				local name = nameToRow[enemyName] and enemyName or shortNameToFull[enemyName]
				if name and stealthedState[name] then
					SetUnitStealth(name, false)
				end
			end
		end
	end
end)

-- -------------------------------------------------------------------------- --
-- Periodic Scoreboard Poller (Hardware C_Timer.NewTicker, 3.0s cadence)      --
-- Strictly gated by activeBG; zero allocations, zero DOM redraws on delta 0. --
-- -------------------------------------------------------------------------- --
local function AutoScoreboardTicker()
	if activeBG and not BGT.isConfig then
		RequestBattlefieldScoreData()
	end
end

if C_Timer and C_Timer.NewTicker then
	C_Timer.NewTicker(3.0, AutoScoreboardTicker)
end

SLASH_BATTLEGROUNDTARGETS1 = "/bgt"
SLASH_BATTLEGROUNDTARGETS2 = "/battlegroundtargets"
SlashCmdList["BATTLEGROUNDTARGETS"] = function(msg)
	local cmd = string.lower(msg or "")
	if cmd == "test" then
		if BGT.isConfig then BGT:DisableConfigMode() else BGT:EnableConfigMode(10) end
	elseif cmd == "spy" then
		if BGT.Spy and BGT.Spy.ToggleTestMode then
			BGT.Spy:ToggleTestMode()
		end
	elseif cmd == "reset" then
		BattlegroundTargets_Options.pos = {}
		BGT:Frame_SetupPosition("BattlegroundTargets_MainFrame")
		if BGT.Spy and BGT.Spy.ApplyPosition then
			BGT.Spy:ApplyPosition()
		end
		if BattlegroundTargets_OptionsFrame then
			BGT:Frame_SetupPosition("BattlegroundTargets_OptionsFrame")
		end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[BattlegroundTargets]|r Frame positions reset.", 1, 1, 1)
	else
		BGT:ToggleOptions()
	end
end
