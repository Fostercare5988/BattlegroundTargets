-- Strict Engine Dependency Guard (Mandatory ClassicAPI v1.13.3+ & SuperWoW v2.2+)
if not (CLASSIC_API_VERSION and SUPERWOW_VERSION) then
	DEFAULT_CHAT_FRAME:AddMessage("|cffff2020[Fatal Error]|r BattlegroundTargets requires ClassicAPI.dll (v1.13.3+) & SuperWoW (v2.2+)! Please ensure both DLLs are loaded.", 1, 0.2, 0.2)
	return
end

-- -------------------------------------------------------------------------- --
-- BattlegroundTargets by kunda, modernized by Fostercare5988                 --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- BattlegroundTargets is a 'Enemy Unit Frame' for battlegrounds.             --
-- BattlegroundTargets is not a 'real' (Enemy) Unit Frame.                    --
-- BattlegroundTargets simply generates buttons with target macros.           --
--                                                                            --
-- Features:                                                                  --
-- # Shows all battleground enemies with role, class and name.                --
--   - Left-click : set target                                                --
--   - Right-click: set focus                                                 --
-- # Independent settings for '10 vs 10', '15 vs 15' and '40 vs 40'.          --
-- # Target                                                                   --
-- # Main Assist Target                                                       --
-- # Focus                                                                    --
-- # Enemy Flag Carrier                                                       --
-- # Target Count                                                             --
-- # Health                                                                   --
-- # Range Check                                                              --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- These events are always registered:                                        --
-- - PLAYER_REGEN_DISABLED                                                    --
-- - PLAYER_REGEN_ENABLED                                                     --
-- - ZONE_CHANGED_NEW_AREA (to determine if current zone is a battleground)   --
-- - PLAYER_LEVEL_UP (only registered if player level < level cap)            --
--                                                                            --
-- In Battleground:                                                           --
-- # If enabled: ------------------------------------------------------------ --
--   - UPDATE_BATTLEFIELD_SCORE                                               --
--   - PLAYER_DEAD                                                            --
--   - PLAYER_UNGHOST                                                         --
--   - PLAYER_ALIVE                                                           --
--                                                                            --
-- # Range Check: --------------------------------------- VERY HIGH CPU USAGE --
--   - Events:                                                                --
--        1) Combat Log: --- COMBAT_LOG_EVENT_UNFILTERED                      --
--        2) Class: -------- PLAYER_TARGET_CHANGED                            --
--                         - UNIT_HEALTH_FREQUENT                             --
--                         - UPDATE_MOUSEOVER_UNIT                            --
--                         - UNIT_TARGET                                      --
--      3/4) Mix: ---------- COMBAT_LOG_EVENT_UNFILTERED                      --
--                         - PLAYER_TARGET_CHANGED                            --
--                         - UNIT_HEALTH_FREQUENT                             --
--                         - UPDATE_MOUSEOVER_UNIT                            --
--                         - UNIT_TARGET                                      --
--   - The data to determine the distance to an enemy is not always available.--
--     This is restricted by the WoW API.                                     --
--   - This feature is a compromise between CPU usage (FPS), lag/network      --
--     bandwidth (no SendAdd0nMessage), fast and easy visual recognition and  --
--     suitable data.                                                         --
--                                                                            --
-- # Health: ------------------------------------------------- HIGH CPU USAGE --
--   - Events:             - UNIT_TARGET                                      --
--                         - UNIT_HEALTH_FREQUENT                             --
--                         - UPDATE_MOUSEOVER_UNIT                            --
--   - The health from an enemy is not always available.                      --
--     This is restricted by the WoW API.                                     --
--   - A raidmember/raidpet MUST target(focus/mouseover) an enemy OR          --
--     you/yourpet MUST target/focus/mouseover an enemy to get the health.    --
--                                                                            --
-- # Target Count: ------------------------------------ HIGH MEDIUM CPU USAGE --
--   - Event:              - UNIT_TARGET                                      --
--                                                                            --
-- # Main Assist Target: ------------------------------- LOW MEDIUM CPU USAGE --
--   - Events:             - RAID_ROSTER_UPDATE                               --
--                         - UNIT_TARGET                                      --
--                                                                            --
-- # Leader: ------------------------------------------- LOW MEDIUM CPU USAGE --
--   - Event:              - UNIT_TARGET                                      --
--                                                                            --
-- # Level: (only if player level < level cap) ---------------- LOW CPU USAGE --
--   - Event:              - UNIT_TARGET                                      --
--                                                                            --
-- # Target: -------------------------------------------------- LOW CPU USAGE --
--   - Event:              - PLAYER_TARGET_CHANGED                            --
--                                                                            --
-- # Focus: --------------------------------------------------- LOW CPU USAGE --
--   - Event:              - PLAYER_FOCUS_CHANGED                             --
--                                                                            --
-- # Enemy Flag Carrier: --------------------------------- VERY LOW CPU USAGE --
--   - Events:             - CHAT_MSG_BG_SYSTEM_HORDE                         --
--                         - CHAT_MSG_BG_SYSTEM_ALLIANCE                      --
--   Flag detection in case of disconnect, UI reload or mid-battle-joins:     --
--   (temporarily registered until each enemy is scanned)                     --
--                         - UNIT_TARGET                                      --
--                         - UPDATE_MOUSEOVER_UNIT                            --
--                         - PLAYER_TARGET_CHANGED                            --
--                                                                            --
-- # No SendAdd0nMessage(): ------------------------------------------------- --
--   This AddOn does not use/need SendAdd0nMessage(). SendAdd0nMessage()      --
--   increases the available data by transmitting information to other        --
--   players. This has certain pros and cons. I may include (opt-in) such     --
--   functionality in some future release. maybe. dontknow.                   --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- slash commands: /bgt - /bgtargets - /battlegroundtargets                   --
-- slash commands for HD (Heals Detection and Cross Faction mod):             --
--      /bgt hdlog    -- Announces of any detection in the chat frame.        --
--      /bgt hdreport -- Shows all current info at that time about detects.   --
--                                                                            --
--      /bgt hdlogAlways                                                      --
--                      To enable permanent healer detection mode while       --
--                      you are in BG. After that, you don't need to enter    --
--                      /bgt hdlog every time                                 --
--                                                                            --
--      /bgt dbStoragePeriod <number>                                         --
--                      "GET or SET (if the <number> exists)                  --
--                      retention period of the data in months, after which   --
--                      the obsolete data about healer will be deleted."      --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- Thanks to all who helped with the localization.                            --
--                                                                            --
-- Special thanks to Roma.                                                    --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- UPD. Cross-faction (CF) and Heals Detection (HD) support provided          --
-- by Nobraix (aka Splight-Fun) from forum.wowcircle.net                      --
--                                                                            --
-- Special thanks to Jud from forum.wowcircle.net                             -- 
-- for his supports, feedback and quality testing.                            --
--                                                                            --
-- -------------------------------------------------------------------------- --
--                                                                            --
-- Minor adjustments for Warmane's Mercenary Mode.           	              --
-- Integrated combatlog-based Healer Detection from BattleGroundHealers.      --
-- Added Netherstorm Flag carrier tracking                                    --
-- by Khal (https://github.com/KhalGH)                                        --
--                                                                            --
-- -------------------------------------------------------------------------- --

-- ---------------------------------------------------------------------------------------------------------------------
BattlegroundTargets_Options   = {};
BattlegroundTargets_Character = {};
BattlegroundTargets_HealersDB = {};

local BattlegroundTargets = CreateFrame("Frame");
local MOD_VERSION = "1.14.2-Vanilla";

local L   = BattlegroundTargets_Localization;
local BGN = BattlegroundTargets_BGNames;
local FLG = BattlegroundTargets_Flag;
local RNA = BattlegroundTargets_RaceNames;
local DBUtils = BattlegroundTargets_DBUtils;

local GVAR     = {};
local TEMPLATE = {};
local OPT      = {};

local AddonIcon = "Interface\\AddOns\\BattlegroundTargets\\Textures\\BattlegroundTargets-texture-button";

local _G = _G;
local GetTime = _G.GetTime;
local InCombatLockdown = _G.InCombatLockdown;
local IsInInstance = _G.IsInInstance;
local IsRatedBattleground = _G.IsRatedBattleground;

local GetBattlefieldArenaFaction = _G.GetBattlefieldArenaFaction;
local GetRealZoneText            = _G.GetRealZoneText;
local GetMaxBattlefieldID        = _G.GetMaxBattlefieldID;
local GetBattlefieldStatus       = _G.GetBattlefieldStatus;
local GetNumBattlefieldScores    = _G.GetNumBattlefieldScores;
local GetBattlefieldScore        = _G.GetBattlefieldScore;
local SetBattlefieldScoreFaction = _G.SetBattlefieldScoreFaction;
local UnitName                   = _G.UnitName;
local UnitClass         		 = _G.UnitClass;
local UnitLevel                  = _G.UnitLevel;
local UnitHealthMax              = _G.UnitHealthMax;
local UnitHealth                 = _G.UnitHealth;
local UnitIsPartyLeader          = _G.UnitIsPartyLeader;
local UnitIsEnemy                = _G.UnitIsEnemy;
local UnitBuff                   = _G.UnitBuff;
local UnitDebuff                 = _G.UnitDebuff;
local GetSpellInfo               = _G.GetSpellInfo;
local IsSpellInRange             = _G.IsSpellInRange;
local CheckInteractDistance      = _G.CheckInteractDistance;
local GetNumRaidMembers          = _G.GetNumRaidMembers;
local GetRaidRosterInfo          = _G.GetRaidRosterInfo;
local math_min                   = _G.math.min;
local math_max                   = _G.math.max;
local math_floor                 = _G.math.floor;
local math_random                = _G.math.random;
local string_find                = _G.string.find;
local string_match               = _G.string.match;
local string_format              = _G.string.format;
local table_sort                 = _G.table.sort;
local table_wipe                 = _G.table.wipe;
local pairs                      = _G.pairs;
local tonumber                   = _G.tonumber;
local next 						 = _G.next;
local GetPlayerMapPosition		 = _G.GetPlayerMapPosition;

local inWorld;
local inBattleground;
local inCombat;
local reCheckBG;
local reCheckScore;
local reSizeCheck = 0;
local reSetLayout;
local isConfig;
local testDataLoaded;
local isTarget = 0;
local hasFlag;
local isDeadUpdateStop;
local isLeader;
local isHealer; 
local isAssistName;
local isAssistUnitId;
local rangeSpellName, rangeMin, rangeMax;
local isFlagBG = 0;
local flagCHK;
local flagflag;

-- THROTTLE (reduce CPU usage) -----------------------------------------------------------------------------------------
local scoreUpdateThrottle = GetTime();       -- scoreupdate: B.attlefieldScoreUpdate()
local scoreUpdateFrequency = 1;              -- scoreupdate: 0-20 updates = 1 second | 21+ updates = 5 seconds
local scoreUpdateCount = 0;              	 -- scoreupdate: (reason: later score updates are less relevant and 5 seconds is still very high)
local range_SPELL_Frequency = 0.2;       	 -- rangecheck: [class-spell]: the 0.2 second freq is per enemy (variable: ENEMY_Name2Range[enemyname]) 
local range_CL_Throttle = 0;         		 -- rangecheck: [combatlog] C.ombatLogRangeCheck()
local range_CL_Frequency = 3;         		 -- rangecheck: [combatlog] 50/50 or 66/33 or 75/25 (%Yes/%No) => 64/36 = 36% combatlog messages filtered (36% vs overhead: two variables, one addition, one number comparison and if filtered one math_random)
local range_CL_DisplayThrottle = GetTime();  -- rangecheck: [combatlog] display update
local range_CL_DisplayFrequency = 0.33;      -- rangecheck: [combatlog] display update
local leaderThrottle = 0;                    -- leader: C.heckUnitTarget()
local leaderFrequency = 5;                   -- leader: if isLeader is true then pause 5 times(events) until next check (reason: leader does not change often in a bg, irrelevant info anyway)
-- FORCE UPDATE (precise results) --------------------------------------------------------------------------------------
local assistForceUpdate = GetTime();         -- assist: C.heckUnitTarget()
local assistFrequency = 0.5;               	 -- assist: immediate assist target check (reason: target loss and I don't know why... -> brute force)
local targetCountForceUpdate = GetTime();    -- targetcount: C.heckUnitTarget()
local targetCountFrequency = 30;          	 -- targetcount: a complete raid/raidtarget check every 30 seconds (reason: target loss and I don't know why... -> brute force)
-- WARNING -------------------------------------------------------------------------------------------------------------
local latestScoreUpdate = GetTime();         -- scoreupdate: B.attlefieldScoreUpdate()
local latestScoreWarning = 60;               -- scoreupdate: inCombat-warning icon if latest score update is >= 60 seconds
-- MISC ----------------------------------------------------------------------------------------------------------------
local range_DisappearTime = 8;               -- rangecheck: display update - clears range display if an enemy was not seen for 8 seconds

local playerLevel = UnitLevel("player");
local isLowLevel;
local maxLevel = 60;

local playerName = UnitName("player");
local playerClass, playerClassEN = UnitClass("player");
local targetName, targetRealm;
local focusName, focusRealm;
local assistTargetName, assistTargetRealm;

local playerFactionDEF   = 0;  -- player faction (DEFAULT)
local oppositeFactionDEF = 0;  -- opposite faction (DEFAULT)
local playerFactionBG    = 0;  -- player faction (in battleground)
local oppositeFactionBG  = 0;  -- opposite faction (in battleground)
local oppositeFactionREAL;     -- real opposite faction 	
local factionIsValid = false;  -- cross-server faction validate flag

local ENEMY_Data           = {};  -- numerical | all data
local ENEMY_Names          = {};  -- key/value | key = enemyName, value = count
local ENEMY_Names4Flag     = {};  -- key/value | key = enemyName without realm, value = button number
local ENEMY_Name2Button    = {};  -- key/value | key = enemyName, value = button number
local ENEMY_Name2Percent   = {};  -- key/value | key = enemyName, value = health in percent
local ENEMY_Name2Range     = {};  -- key/value | key = enemyName, value = time of last contact
local ENEMY_Name2Level     = {};  -- key/value | key = enemyName, value = level
local ENEMY_FirstFlagCheck = {};  -- key/value | key = enemyName, value = 1
local FRIEND_Names         = {};  -- key/value | key = friendName, value = 1
local TARGET_Names         = {};  -- key/value | key = friendName, value = enemyName
local SPELL_Range          = {};  -- key/value | key = spellID, value = maxRange
local ENEMY_Healers        = {};  -- Hash table. key/value | key = Enemy name, value = table where with options: status, classToken, reason (which spell has been detected)
local UITitle = "BattlegroundTarget |cff33ff99(JimsProxy 1.14.2)|r"

local testSize     = 10;
local testIcon1    = 2;
local testIcon2    = 5;
local testIcon3    = 3;
local testIcon4    = 4;
local testHealth   = {};
local testRange    = {};
local testLeader   = 4;
local testHealers  = {};

local healthBarWidth = 0.01;

local sizeOffset    = 5;
local sizeBarHeight = 14;

local fontPath = _G["GameFontNormal"]:GetFont();

local currentSize = 10;
local bgSize = {
	["Alterac Valley"] = 40,
	["Warsong Gulch"] = 10,
	["Arathi Basin"] = 15,
};

local bgSizeINT = {
	[1] = 10,
	[2] = 15,
	[3] = 40
};

------------------------------------------------------------
-- Spec-specific buffs (Vanilla 1.12.1)
-----------------------------------------------------------
local HEALER_SpellBase = {
	["Healers"] = {
		"PALADIN",
		"SHAMAN",
		"PRIEST",
		"DRUID"
	},
	["HealerBuffs"] = { 
		-- PRIEST
		20711, -- Spirit of Redemption
		14752, 14818, 14819, 27841, 25312, -- Divine Spirit
		10060, -- Power Infusion
		
		-- SHAMAN
		16188, -- Nature's Swiftness
		
		-- DRUID
		17116, -- Nature's Swiftness
		18562, -- Swiftmend
		29166, -- Innervate

		-- PALADIN
		20216, -- Divine Favor
		19977, 19978, 19979, 25890, -- Blessing of Light
		20473 -- Holy Shock
	},
	["aoeHealerBuffs"] = {
		-- Priest
		10060, -- Power Infusion

		-- RESTORATION SHAMAN
		5675, 10495, 10496, 10497, -- Mana Spring Totem
		5394, 6375, 6377, 10462, 10463 -- Healing Stream Totem
	},
	["DamageBuffs"] = {
		-- SHADOW PRIEST --
    	 15473 -- Shadowform 
		,15286 -- Vampiric Embrace

		-- RETRIBUTION PALADIN -- 
		,20375 -- Seal of Command
		,20050, 20052, 20053 -- Vengeance
		
		-- ELEMENTAL SHAMAN --
		,16166 -- Elemental Mastery
		
		-- BALANCE DRUID
		,24858 -- Moonkin Form
	},
	["aoeDamageBuffs"] = {
		-- Add any vanilla aoe damage buffs here if needed
	},
};

local icoMinimapFactionBG;
local battleFieldIconTextures = {
	[0] = "Interface\\BattlefieldFrame\\Battleground-Horde",		
	[1] = "Interface\\BattlefieldFrame\\Battleground-Alliance",
}
local battleFieldRoleIcons = {
	[0] = "Interface\\AddOns\\BattlegroundTargets\\Textures\\UnknownRoleIco",
	[1] = "Interface\\AddOns\\BattlegroundTargets\\Textures\\DamageDealerIco",
	[2] = "Interface\\AddOns\\BattlegroundTargets\\Textures\\HealDealerIco",
}
local roleLayoutPos = {
	[1] = L["Show roles on the right"],
	[2] = L["Show roles on the left"],
	[3] = L["Don't show roles"],
}; 

local hdlog = BattlegroundTargets_Options  and  BattlegroundTargets_Options.hdlog or false;
local flagBG = {
	["Warsong Gulch"] = 1,
};

local flagIDs = {
	[23333] = 1, -- Warsong Flag
	[23335] = 1, -- Silverwing Flag
};

local sortBy = {
	[1] = CLASS.."* / "..NAME,
	[2] = NAME,  
	[3] = CLASS.."* / "..NAME.." [healers first]", 
};

local locale = GetLocale();
local sortDetail = {
	[1] = "*"..CLASS.." ("..locale..")",
	[2] = "*"..CLASS.." (english)",
	[3] = "*"..CLASS.." (Blizzard)"
};

local classcolors = {};
for class, color in pairs(RAID_CLASS_COLORS) do
	classcolors[class] = { r = color.r, g = color.g, b = color.b }
end

local classes = {
	DRUID       = { 0.7578125, 0.9765625, 0.015625, 0.234375 },
	HUNTER      = { 0.01953125, 0.23828125, 0.265625, 0.484375 },
	MAGE        = { 0.265625, 0.484375, 0.015625, 0.234375 },
	PALADIN     = { 0.01953125, 0.23828125, 0.515625, 0.734375 },
	PRIEST      = { 0.51171875, 0.73046875, 0.265625, 0.484375 },
	ROGUE       = { 0.51171875, 0.73046875, 0.015625, 0.234375 },
	SHAMAN      = { 0.265625, 0.484375, 0.265625, 0.484375 },
	WARLOCK     = { 0.7578125, 0.9765625, 0.265625, 0.484375 },
	WARRIOR     = { 0.01953125, 0.23828125, 0.015625, 0.234375 },
	ZZZFAILURE  = { 0, 0, 0, 0 }
};

local class_LocaSort = {};
FillLocalizedClassList(class_LocaSort, false);

local class_BlizzSort = {};
for i = 1, #CLASS_SORT_ORDER do
	class_BlizzSort[ CLASS_SORT_ORDER[i] ] = i;
end

local class_IntegerSort = {
	[1]  = { cid = "DRUID", 	  blizz = class_BlizzSort.DRUID       or 7,  eng = "Druid", 	   loc = class_LocaSort.DRUID or "Druid" },
	[2]  = { cid = "HUNTER", 	  blizz = class_BlizzSort.HUNTER 	  or 10, eng = "Hunter", 	   loc = class_LocaSort.HUNTER or "Hunter" },
	[3]  = { cid = "MAGE",        blizz = class_BlizzSort.MAGE 		  or 9,  eng = "Mage", 		   loc = class_LocaSort.MAGE or "Mage"},
	[4]  = { cid = "PALADIN",     blizz = class_BlizzSort.PALADIN 	  or 3,  eng = "Paladin", 	   loc = class_LocaSort.PALADIN or "Paladin" },
	[5]  = { cid = "PRIEST",      blizz = class_BlizzSort.PRIEST 	  or 5,  eng = "Priest",       loc = class_LocaSort.PRIEST or "Priest" },
	[6]  = { cid = "ROGUE",       blizz = class_BlizzSort.ROGUE 	  or 8,  eng = "Rogue",  	   loc = class_LocaSort.ROGUE or "Rogue" },
	[7]  = { cid = "SHAMAN",      blizz = class_BlizzSort.SHAMAN 	  or 6,  eng = "Shaman", 	   loc = class_LocaSort.SHAMAN or "Shaman" },
	[8]  = { cid = "WARLOCK",     blizz = class_BlizzSort.WARLOCK 	  or 9,  eng = "Warlock",      loc = class_LocaSort.WARLOCK or "Warlock" },
	[9]  = { cid = "WARRIOR",     blizz = class_BlizzSort.WARRIOR 	  or 1,  eng = "Warrior",      loc = class_LocaSort.WARRIOR or "Warrior" }
};

local ranges = {
	DRUID       = 5176,
	HUNTER      = 75,
	MAGE        = 133,
	PALADIN     = 635, -- Holy Light
	PRIEST      = 589,
	ROGUE       = 6770,
	SHAMAN      = 403,
	WARLOCK     = 686,
	WARRIOR     = 100
};

local rangeTypeName = {
	[1] = "1) CombatLog |cffffff79(0-73)|r",
	[2] = "2) ...",
	[3] = "3) ...",
	[4] = "4) ..."
};

local rangeDisplay = {
	[1]  = "STD 100",
	[2]  = "STD 100 mono",
	[3]  = "STD 50",
	[4]  = "STD 50 mono",
	[5]  = "STD 25",
	[6]  = "STD 25 mono",
	[7]  = "STD 10",
	[8]  = "STD 10 mono",
	[9]  = "X 100 mono",
	[10] = "X 50",
	[11] = "X 50 mono",
	[12] = "X 25",
	[13] = "X 25 mono",
	[14] = "X 10",
	[15] = "X 10 mono"
};

local function rt(H, E, M, P) return E, P, E, M, H, P, H, M; end

local Textures = {
	BattlegroundTargetsIcons = { path = "Interface\\AddOns\\BattlegroundTargets\\Textures\\BattlegroundTargets-texture-icons.tga" },
	SliderKnob = { coords = { 19/64, 30/64,  1/64, 18/64 } },
	SliderBG = {
		coordsL = { 19/64, 24/64, 27/64, 33/64 },
		coordsM = { 25/64, 26/64, 27/64, 33/64 },
		coordsR = { 26/64, 31/64, 27/64, 33/64 },
		coordsLdis = { 19/64, 24/64, 19/64, 25/64 },
		coordsMdis = { 25/64, 26/64, 19/64, 25/64 },
		coordsRdis = { 26/64, 31/64, 19/64, 25/64 }
	},
	Expand   = { coords = { 1/64, 18/64,  1/64, 18/64 } },
	Collapse = { coords = { rt( 1/64, 18/64,  1/64, 18/64) } },
	Close    = { coords = { 1/64,  18/64, 19/64, 36/64 } },
	Healer   = { coords = { 33/64, 47/64, 17/64, 31/64} },
	l40_18   = { coords = { 36/64, 41/64, 37/64, 51/64 },  width =  5*2, height = 14*2 },
	l40_24   = { coords = { 27/64, 36/64, 37/64, 47/64 },  width =  9*2, height = 10*2 },
	l40_42   = { coords = { 14/64, 27/64, 37/64, 44/64 },  width = 13*2, height =  7*2 },
	l40_81   = { coords = { 0/64,  14/64, 37/64, 42/64 },   width = 14*2, height =  5*2 },
	UpdateWarning = {coords = { 0/64, 35/64, 47/64, 63/64 }, width = 35/1.5, height = 16/1.5 }
};

local raidUnitID = {};
for i = 1, 40 do
	raidUnitID["raid"..i]    = 1;
	raidUnitID["raidpet"..i] = 1;
end

local playerUnitID = {};
playerUnitID["target"]    = 1;
playerUnitID["pettarget"] = 1;
playerUnitID["focus"]     = 1;
playerUnitID["mouseover"] = 1;

local startMapCoordsA = {
	["Alterac Valley"]       = { 417, 424, -56,  -26  },
	["Arathi Basin"]         = { 230, 258, -105, -78  },
	["Isle of Conquest"]      = { 300, 419, -429, -385 },
	["Eye of the Storm"]    = { 360, 375, -144, -125 },
	["Warsong Gulch"]        = { 370, 402, -85,  -64  },
}

local function Print(...)
	print("|cffffff7fBattlegroundTargets:|r", ...);
end

local function HDLog(...)
	if hdlog or BattlegroundTargets_Options.hdlog then Print(...) end
end

local function contains(table, element)
	for _, value in pairs(table) do
		if (value == element) then return true end
	end
	return false
end

function GetRealCoords(rawX, rawY)
	local realX, realY = 0, 0;
	realX = rawX * 783; -- X -17
	realY = -rawY * 522; -- Y -78
	return realX, realY;
end

local function inRange(val, min, max)
    if not min or not max then return nil end;
    if min <= val and val <= max then return true;
    else return false end;
end

local function isStartPosition(rx, ry, mapName)
    local cords = startMapCoordsA[mapName];
    local tx, ty;
    for i=1, #cords, 2 do
        if i == 1 then tx = inRange(rx, cords[i], cords[i+1]);
		else ty = inRange(ry, cords[i], cords[i+1]); end
    end
    if tx and ty then return true end
end

local function ClassHexColor(class)
	local hex;
	if(classcolors[class]) then
		hex = string_format("%.2x%.2x%.2x", classcolors[class].r*255, classcolors[class].g*255, classcolors[class].b*255);
	end
	return hex or "cccccc";
end

local function NOOP() end

-- Export internal namespaces and tables to BattlegroundTargets for BattlegroundTargetsOpt.lua
BattlegroundTargets.GVAR = GVAR
BattlegroundTargets.TEMPLATE = TEMPLATE
BattlegroundTargets.OPT = OPT
BattlegroundTargets.Textures = Textures
BattlegroundTargets.classes = classes
BattlegroundTargets.classcolors = classcolors
BattlegroundTargets.class_IntegerSort = class_IntegerSort
BattlegroundTargets.battleFieldRoleIcons = battleFieldRoleIcons
BattlegroundTargets.roleLayoutPos = roleLayoutPos
BattlegroundTargets.bgSize = bgSize
BattlegroundTargets.bgSizeINT = bgSizeINT
BattlegroundTargets.startMapCoordsA = startMapCoordsA
BattlegroundTargets.Print = Print
BattlegroundTargets.HDLog = HDLog
BattlegroundTargets.contains = contains
BattlegroundTargets.inRange = inRange
BattlegroundTargets.ClassHexColor = ClassHexColor
BattlegroundTargets.Desaturation = Desaturation
BattlegroundTargets.NOOP = NOOP
BattlegroundTargets.GetRealCoords = GetRealCoords
BattlegroundTargets.isStartPosition = isStartPosition

function BattlegroundTargets:CreateFrames()
	GVAR.MainFrame = CreateFrame("Frame", "BattlegroundTargets_MainFrame", UIParent);
	TEMPLATE.BorderTRBL(GVAR.MainFrame);
	GVAR.MainFrame:EnableMouse(true);
	GVAR.MainFrame:SetMovable(true);
	GVAR.MainFrame:SetResizable(true);
	GVAR.MainFrame:SetToplevel(true);
	GVAR.MainFrame:SetClampedToScreen(true);
	GVAR.MainFrame:SetWidth(150);
	GVAR.MainFrame:SetHeight(20);
	GVAR.MainFrame:SetScript("OnShow", function() BattlegroundTargets:MainFrameShow(); end);
	GVAR.MainFrame:SetScript("OnEnter", function() GVAR.MainFrame.Movetext:SetTextColor(1, 1, 1, 1); end);
	GVAR.MainFrame:SetScript("OnLeave", function() GVAR.MainFrame.Movetext:SetTextColor(0.3, 0.3, 0.3, 1) end);
	GVAR.MainFrame:SetScript("OnMouseDown", function()
		if(inCombat or InCombatLockdown()) then return; end
		
		GVAR.MainFrame:StartMoving();
	end)
	GVAR.MainFrame:SetScript("OnMouseUp", function()
		if(inCombat or InCombatLockdown()) then return; end
		
		GVAR.MainFrame:StopMovingOrSizing();
		BattlegroundTargets:Frame_SavePosition("BattlegroundTargets_MainFrame");
	end)
	
	GVAR.MainFrame:Hide();
	
	GVAR.MainFrame.Movetext = GVAR.MainFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall");
	GVAR.MainFrame.Movetext:SetWidth(150);
	GVAR.MainFrame.Movetext:SetHeight(20);
	GVAR.MainFrame.Movetext:SetPoint("CENTER", 0, 0);
	GVAR.MainFrame.Movetext:SetJustifyH("CENTER");
	GVAR.MainFrame.Movetext:SetText(L["click & move"]);
	GVAR.MainFrame.Movetext:SetTextColor(0.3, 0.3, 0.3, 1);
	
	local function OnEnter(self)
		self.HighlightT:SetTexture(1, 1, 0.49, 1);
		self.HighlightR:SetTexture(1, 1, 0.49, 1);
		self.HighlightB:SetTexture(1, 1, 0.49, 1);
		self.HighlightL:SetTexture(1, 1, 0.49, 1);
	end
	
	local function OnLeave(self)
		if(isTarget == self.buttonNum) then
			self.HighlightT:SetTexture(0.5, 0.5, 0.5, 1);
			self.HighlightR:SetTexture(0.5, 0.5, 0.5, 1);
			self.HighlightB:SetTexture(0.5, 0.5, 0.5, 1);
			self.HighlightL:SetTexture(0.5, 0.5, 0.5, 1);
		else
			self.HighlightT:SetTexture(0, 0, 0, 1);
			self.HighlightR:SetTexture(0, 0, 0, 1);
			self.HighlightB:SetTexture(0, 0, 0, 1);
			self.HighlightL:SetTexture(0, 0, 0, 1);
		end
	end
	
	local buttonWidth = 150;
	local buttonHeight = 20;
	
	GVAR.TargetButton = {};
	
	for i = 1, 40 do
		GVAR.TargetButton[i] = CreateFrame("Button", nil, UIParent);

		local GVAR_TargetButton = GVAR.TargetButton[i];

		GVAR_TargetButton:SetWidth(buttonWidth);
		GVAR_TargetButton:SetHeight(buttonHeight);
		
		if(i == 1) then
			GVAR_TargetButton:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, 0);
		else
			GVAR_TargetButton:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
		end
		
		GVAR_TargetButton:Hide();
		
		GVAR_TargetButton.colR = 0;
		GVAR_TargetButton.colG = 0;
		GVAR_TargetButton.colB = 0;
		GVAR_TargetButton.colR5 = 0;
		GVAR_TargetButton.colG5 = 0;
		GVAR_TargetButton.colB5 = 0;
		
		GVAR_TargetButton.HighlightT = GVAR_TargetButton:CreateTexture(nil, "BACKGROUND");
		GVAR_TargetButton.HighlightT:SetWidth(buttonWidth);
		GVAR_TargetButton.HighlightT:SetHeight(1);
		GVAR_TargetButton.HighlightT:SetPoint("TOP", 0, 0);
		GVAR_TargetButton.HighlightT:SetTexture(0, 0, 0, 1);
		GVAR_TargetButton.HighlightR = GVAR_TargetButton:CreateTexture(nil, "BACKGROUND");
		GVAR_TargetButton.HighlightR:SetWidth(1);
		GVAR_TargetButton.HighlightR:SetHeight(buttonHeight);
		GVAR_TargetButton.HighlightR:SetPoint("RIGHT", 0, 0);
		GVAR_TargetButton.HighlightR:SetTexture(0, 0, 0, 1);
		GVAR_TargetButton.HighlightB = GVAR_TargetButton:CreateTexture(nil, "BACKGROUND");
		GVAR_TargetButton.HighlightB:SetWidth(buttonWidth);
		GVAR_TargetButton.HighlightB:SetHeight(1);
		GVAR_TargetButton.HighlightB:SetPoint("BOTTOM", 0, 0);
		GVAR_TargetButton.HighlightB:SetTexture(0, 0, 0, 1);
		GVAR_TargetButton.HighlightL = GVAR_TargetButton:CreateTexture(nil, "BACKGROUND");
		GVAR_TargetButton.HighlightL:SetWidth(1);
		GVAR_TargetButton.HighlightL:SetHeight(buttonHeight);
		GVAR_TargetButton.HighlightL:SetPoint("LEFT", 0, 0);
		GVAR_TargetButton.HighlightL:SetTexture(0, 0, 0, 1);
		
		GVAR_TargetButton.Background = GVAR_TargetButton:CreateTexture(nil, "BACKGROUND");
		GVAR_TargetButton.Background:SetWidth(buttonWidth - 2);
		GVAR_TargetButton.Background:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.Background:SetPoint("TOPLEFT", 1, -1);
		GVAR_TargetButton.Background:SetTexture(0, 0, 0, 0.25);
		
		GVAR_TargetButton.RangeTexture = GVAR_TargetButton:CreateTexture(nil, "BORDER");
		GVAR_TargetButton.RangeTexture:SetWidth((buttonHeight - 2) / 2);
		GVAR_TargetButton.RangeTexture:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.RangeTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", 1, 0);
		GVAR_TargetButton.RangeTexture:SetTexture(0, 0, 0, 0);
		
		GVAR_TargetButton.ClassTexture = GVAR_TargetButton:CreateTexture(nil, "BORDER");
		GVAR_TargetButton.ClassTexture:SetWidth(buttonHeight - 2);
		GVAR_TargetButton.ClassTexture:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.ClassTexture:SetPoint("LEFT", GVAR_TargetButton.RangeTexture, "RIGHT", 0, 0);
		GVAR_TargetButton.ClassTexture:SetTexture("Interface\\WorldStateFrame\\Icons-Classes");
        GVAR_TargetButton.ClassTexture:SetTexCoord(0, 0, 0, 0);
		
		GVAR_TargetButton.LeaderTexture = GVAR_TargetButton:CreateTexture(nil, "ARTWORK");
		GVAR_TargetButton.LeaderTexture:SetWidth((buttonHeight - 2) / 1.5);
		GVAR_TargetButton.LeaderTexture:SetHeight((buttonHeight - 2) / 1.5);
		GVAR_TargetButton.LeaderTexture:SetPoint("RIGHT", GVAR_TargetButton, "LEFT", 0, 0);
		GVAR_TargetButton.LeaderTexture:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon");
		GVAR_TargetButton.LeaderTexture:SetAlpha(0);
		
		GVAR_TargetButton.ClassColorBackground = GVAR_TargetButton:CreateTexture(nil, "BORDER")
		GVAR_TargetButton.ClassColorBackground:SetWidth((buttonWidth - 2) - (buttonHeight - 2) - (buttonHeight - 2));
		GVAR_TargetButton.ClassColorBackground:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton.ClassTexture, "RIGHT", 0, 0);
		GVAR_TargetButton.ClassColorBackground:SetTexture(0, 0, 0, 0);
		
		GVAR_TargetButton.HealthBar = GVAR_TargetButton:CreateTexture(nil, "ARTWORK");
		GVAR_TargetButton.HealthBar:SetWidth((buttonWidth - 2) - (buttonHeight - 2) - (buttonHeight - 2));
		GVAR_TargetButton.HealthBar:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.HealthBar:SetPoint("LEFT", GVAR_TargetButton.ClassColorBackground, "LEFT", 0, 0);
		GVAR_TargetButton.HealthBar:SetTexture(0, 0, 0, 0);
		
		GVAR_TargetButton.HealthTextButton = CreateFrame("Button", nil, GVAR_TargetButton);
		GVAR_TargetButton.HealthTextButton:EnableMouse(false);
		GVAR_TargetButton.HealthText = GVAR_TargetButton.HealthTextButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		GVAR_TargetButton.HealthText:SetWidth((buttonWidth - 2) - (buttonHeight - 2) - (buttonHeight - 2) - 2);
		GVAR_TargetButton.HealthText:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.HealthText:SetPoint("RIGHT", GVAR_TargetButton.ClassColorBackground, "RIGHT", 0, 0);
		GVAR_TargetButton.HealthText:SetJustifyH("RIGHT");
		
		GVAR_TargetButton.Name = GVAR_TargetButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		GVAR_TargetButton.Name:SetWidth((buttonWidth - 2) - (buttonHeight - 2) - (buttonHeight - 2) - 2)
		GVAR_TargetButton.Name:SetHeight(buttonHeight - 2)
		GVAR_TargetButton.Name:SetPoint("LEFT", GVAR_TargetButton.ClassColorBackground, "LEFT", 2, 0);
		GVAR_TargetButton.Name:SetJustifyH("LEFT");
		
		GVAR_TargetButton.TargetCountBackground = GVAR_TargetButton:CreateTexture(nil, "ARTWORK");
		GVAR_TargetButton.TargetCountBackground:SetWidth(20);
		GVAR_TargetButton.TargetCountBackground:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.TargetCountBackground:SetPoint("RIGHT", GVAR_TargetButton, "RIGHT", -1, 0);
		GVAR_TargetButton.TargetCountBackground:SetTexture(0, 0, 0, 1);
		GVAR_TargetButton.TargetCountBackground:SetAlpha(1);
		
		GVAR_TargetButton.TargetCount = GVAR_TargetButton:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		GVAR_TargetButton.TargetCount:SetWidth(20);
		GVAR_TargetButton.TargetCount:SetHeight(buttonHeight - 4);
		GVAR_TargetButton.TargetCount:SetPoint("CENTER", GVAR_TargetButton.TargetCountBackground, "CENTER", 0, 0);
		GVAR_TargetButton.TargetCount:SetJustifyH("CENTER");
		
		GVAR_TargetButton.TargetTextureButton = CreateFrame("Button", nil, GVAR_TargetButton);
		GVAR_TargetButton.TargetTextureButton:EnableMouse(false);
		GVAR_TargetButton.TargetTexture = GVAR_TargetButton.TargetTextureButton:CreateTexture(nil, "OVERLAY");
		GVAR_TargetButton.TargetTexture:SetWidth(buttonHeight - 2);
		GVAR_TargetButton.TargetTexture:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.TargetTexture:SetPoint("LEFT", GVAR_TargetButton, "RIGHT", 0, 0);
		GVAR_TargetButton.TargetTexture:SetTexture(AddonIcon);
		GVAR_TargetButton.TargetTexture:SetAlpha(0);

		GVAR_TargetButton.HealersTexture = GVAR_TargetButton:CreateTexture(nil, "BORDER");
		GVAR_TargetButton.HealersTexture:SetWidth(buttonHeight - 2);
		GVAR_TargetButton.HealersTexture:SetHeight(buttonHeight - 2);
		if OPT.ButtonRoleLayoutPos[currentSize] == 2 then -- LEFT
			GVAR_TargetButton.HealersTexture:SetPoint("LEFT", GVAR_TargetButton.RangeTexture, "RIGHT", buttonHeight, 0);
		end
		GVAR_TargetButton.HealersTexture:SetTexture(battleFieldRoleIcons[1]);
		GVAR_TargetButton.HealersTexture:SetAlpha(0);

		
		GVAR_TargetButton.FocusTextureButton = CreateFrame("Button", nil, GVAR_TargetButton);
		GVAR_TargetButton.FocusTextureButton:EnableMouse(false);
		GVAR_TargetButton.FocusTexture = GVAR_TargetButton.FocusTextureButton:CreateTexture(nil, "OVERLAY");
		GVAR_TargetButton.FocusTexture:SetWidth(buttonHeight - 2);
		GVAR_TargetButton.FocusTexture:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.FocusTexture:SetPoint("LEFT", GVAR_TargetButton, "RIGHT", 0, 0);
		GVAR_TargetButton.FocusTexture:SetTexture("Interface\\AddOns\\BattlegroundTargets\\Textures\\Focus");
		GVAR_TargetButton.FocusTexture:SetAlpha(0);
		
		GVAR_TargetButton.FlagTextureButton = CreateFrame("Button", nil, GVAR_TargetButton);
		GVAR_TargetButton.FlagTextureButton:EnableMouse(false);
		GVAR_TargetButton.FlagTexture = GVAR_TargetButton.FlagTextureButton:CreateTexture(nil, "OVERLAY");
		GVAR_TargetButton.FlagTexture:SetWidth(buttonHeight - 2);
		GVAR_TargetButton.FlagTexture:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.FlagTexture:SetPoint("LEFT", GVAR_TargetButton, "RIGHT", 0, 0);
		GVAR_TargetButton.FlagTexture:SetTexCoord(0.15625001, 0.84374999, 0.15625001, 0.84374999);
		
		if playerFactionDEF == 0 then GVAR_TargetButton.FlagTexture:SetTexture("Interface\\WorldStateFrame\\HordeFlag");
		else GVAR_TargetButton.FlagTexture:SetTexture("Interface\\WorldStateFrame\\AllianceFlag"); end
		
		GVAR_TargetButton.FlagTexture:SetAlpha(0);
		
		GVAR_TargetButton.AssistTextureButton = CreateFrame("Button", nil, GVAR_TargetButton);
		GVAR_TargetButton.AssistTextureButton:EnableMouse(false);
		GVAR_TargetButton.AssistTexture = GVAR_TargetButton.AssistTextureButton:CreateTexture(nil, "OVERLAY");
		GVAR_TargetButton.AssistTexture:SetWidth(buttonHeight - 2);
		GVAR_TargetButton.AssistTexture:SetHeight(buttonHeight - 2);
		GVAR_TargetButton.AssistTexture:SetPoint("LEFT", GVAR_TargetButton, "RIGHT", 0, 0);
		GVAR_TargetButton.AssistTexture:SetTexCoord(0.07812501, 0.92187499, 0.07812501, 0.92187499);
		GVAR_TargetButton.AssistTexture:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot");
		GVAR_TargetButton.AssistTexture:SetAlpha(0);
		
		GVAR_TargetButton:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		if GVAR_TargetButton.SetAttribute then
			GVAR_TargetButton:SetAttribute("type1", "macro");
			GVAR_TargetButton:SetAttribute("type2", "macro");
			GVAR_TargetButton:SetAttribute("macrotext1", "");
			GVAR_TargetButton:SetAttribute("macrotext2", "");
		end
		GVAR_TargetButton:SetScript("OnClick", function()
			local name = this.targetName
			if not name or name == "" then return end
			if arg1 == "LeftButton" then
				TargetByName(name, true)
			elseif arg1 == "RightButton" then
				TargetByName(name, true)
				if FocusUnit then
					FocusUnit("target")
				end
				TargetLastTarget()
			end
		end)
		GVAR_TargetButton:SetScript("OnEnter", OnEnter);
		GVAR_TargetButton:SetScript("OnLeave", OnLeave);
	end

	GVAR.ScoreUpdateTexture = GVAR.TargetButton[1]:CreateTexture(nil, "OVERLAY");
	GVAR.ScoreUpdateTexture:SetWidth(Textures.UpdateWarning.width);
	GVAR.ScoreUpdateTexture:SetHeight(Textures.UpdateWarning.height);
	GVAR.ScoreUpdateTexture:SetPoint("BOTTOMLEFT", GVAR.TargetButton[1], "TOPLEFT", 1, 1);
	GVAR.ScoreUpdateTexture:SetTexture(Textures.BattlegroundTargetsIcons.path);
	GVAR.ScoreUpdateTexture:SetTexCoord(unpack(Textures.UpdateWarning.coords));
	
	GVAR.WorldStateScoreWarning = CreateFrame("Frame", nil, WorldStateScoreFrame);
	TEMPLATE.BorderTRBL(GVAR.WorldStateScoreWarning);
	GVAR.WorldStateScoreWarning:SetToplevel(true);
	GVAR.WorldStateScoreWarning:SetHeight(30);
	GVAR.WorldStateScoreWarning:SetPoint("BOTTOM", WorldStateScoreFrame, "TOP", 0, 10);
	GVAR.WorldStateScoreWarning:Hide();
	
	GVAR.WorldStateScoreWarning.Texture = GVAR.WorldStateScoreWarning:CreateTexture(nil, "ARTWORK");
	GVAR.WorldStateScoreWarning.Texture:SetWidth(20);
	GVAR.WorldStateScoreWarning.Texture:SetHeight(17.419);
	GVAR.WorldStateScoreWarning.Texture:SetPoint("LEFT", GVAR.WorldStateScoreWarning, "LEFT", 5, 0);
	GVAR.WorldStateScoreWarning.Texture:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew");
	GVAR.WorldStateScoreWarning.Texture:SetTexCoord(1/64, 63/64, 1/64, 55/64);
	
	GVAR.WorldStateScoreWarning.Text = GVAR.WorldStateScoreWarning:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	GVAR.WorldStateScoreWarning.Text:SetHeight(30);
	GVAR.WorldStateScoreWarning.Text:SetPoint("LEFT", GVAR.WorldStateScoreWarning.Texture, "RIGHT", 5, 0);
	GVAR.WorldStateScoreWarning.Text:SetJustifyH("CENTER");
	GVAR.WorldStateScoreWarning.Text:SetFont(fontPath, 10);
	GVAR.WorldStateScoreWarning.Text:SetText(L["BattlegroundTargets does not update if this Tab is opened."]);
	
	GVAR.WorldStateScoreWarning.Close = CreateFrame("Button", nil, GVAR.WorldStateScoreWarning);
	TEMPLATE.IconButton(GVAR.WorldStateScoreWarning.Close, 1);
	GVAR.WorldStateScoreWarning.Close:SetWidth(20);
	GVAR.WorldStateScoreWarning.Close:SetHeight(20);
	GVAR.WorldStateScoreWarning.Close:SetPoint("TOPRIGHT", GVAR.WorldStateScoreWarning, "TOPRIGHT", 0, 0);
	GVAR.WorldStateScoreWarning.Close:SetScript("OnClick", function() GVAR.WorldStateScoreWarning:Hide(); end);

	local width = GVAR.WorldStateScoreWarning.Text:GetStringWidth() + 20;
	GVAR.WorldStateScoreWarning.Text:SetWidth(width);
	GVAR.WorldStateScoreWarning:SetWidth(30 + width + 30);
end


function BattlegroundTargets:SetupLayout()
	if(inCombat or InCombatLockdown()) then
		reCheckBG = true;
		reSetLayout = true;
		
		return;
	end
	
	local LayoutTH = BattlegroundTargets_Options.LayoutTH[currentSize];
	local LayoutSpace = BattlegroundTargets_Options.LayoutSpace[currentSize];
	
	if(currentSize == 10) then
		for i = 1, currentSize do
			if(LayoutTH == 81) then
				if(i == 6) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[1], "TOPRIGHT", LayoutSpace, 0);
				elseif(i > 1) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
				end
			elseif(LayoutTH == 18) then
				if(i > 1) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
				end
			end
		end
	elseif(currentSize == 15) then
		for i = 1, currentSize do
			if(LayoutTH == 81) then
				if(i == 6) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[1], "TOPRIGHT", LayoutSpace, 0);
				elseif(i == 11) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[6], "TOPRIGHT", LayoutSpace, 0);
				elseif(i > 1) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
				end
			elseif(LayoutTH == 18) then
				if(i > 1) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
				end
			end
		end
	elseif(currentSize == 40) then
		for i = 1, currentSize do
			if(LayoutTH == 81) then
				if (i == 6) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[1], "TOPRIGHT", LayoutSpace, 0);
				elseif (i == 11) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[6], "TOPRIGHT", LayoutSpace, 0);
				elseif (i == 16) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[11], "TOPRIGHT", LayoutSpace, 0);
				elseif (i == 21) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[16], "TOPRIGHT", LayoutSpace, 0);
				elseif (i == 26) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[21], "TOPRIGHT", LayoutSpace, 0);
				elseif (i == 31) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[26], "TOPRIGHT", LayoutSpace, 0);
				elseif (i == 36) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[31], "TOPRIGHT", LayoutSpace, 0);
				elseif (i > 1) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
				end
			elseif(LayoutTH == 42) then
				if (i == 11) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[1], "TOPRIGHT", LayoutSpace, 0);
				elseif(i == 21) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[11], "TOPRIGHT", LayoutSpace, 0);
				elseif(i == 31) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[21], "TOPRIGHT", LayoutSpace, 0);
				elseif(i > 1) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
				end
			elseif(LayoutTH == 24) then
				if(i == 21) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[1], "TOPRIGHT", LayoutSpace, 0);
				elseif(i > 1) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
				end
			elseif(LayoutTH == 18) then
				if(i > 1) then
					GVAR.TargetButton[i]:SetPoint("TOPLEFT", GVAR.TargetButton[(i-1)], "BOTTOMLEFT", 0, 0);
				end
			end
		end
	end
end

function BattlegroundTargets:SetupButtonLayout()
	if(inCombat or InCombatLockdown()) then
		reCheckBG = true;
		reSetLayout = true;
		
		return;
	end
	BattlegroundTargets:SetupLayout()
	
	local ButtonScale           = OPT.ButtonScale[currentSize];
	local ButtonWidth           = OPT.ButtonWidth[currentSize];
	local ButtonHeight          = OPT.ButtonHeight[currentSize];
	local ButtonFontSize        = OPT.ButtonFontSize[currentSize];
	local ButtonClassIcon       = OPT.ButtonClassIcon[currentSize];
	local ButtonRoleLayoutPos   = OPT.ButtonRoleLayoutPos[currentSize];
	local ButtonShowTargetCount = OPT.ButtonShowTargetCount[currentSize];
	local ButtonShowTarget      = OPT.ButtonShowTarget[currentSize];
	local ButtonTargetScale     = OPT.ButtonTargetScale[currentSize];
	local ButtonTargetPosition  = OPT.ButtonTargetPosition[currentSize];
	local ButtonShowFocus       = OPT.ButtonShowFocus[currentSize];
	local ButtonFocusScale      = OPT.ButtonFocusScale[currentSize];
	local ButtonFocusPosition   = OPT.ButtonFocusPosition[currentSize];
	local ButtonShowFlag        = OPT.ButtonShowFlag[currentSize];
	local ButtonFlagScale       = OPT.ButtonFlagScale[currentSize];
	local ButtonFlagPosition    = OPT.ButtonFlagPosition[currentSize];
	local ButtonShowAssist      = OPT.ButtonShowAssist[currentSize];
	local ButtonAssistScale     = OPT.ButtonAssistScale[currentSize];
	local ButtonAssistPosition  = OPT.ButtonAssistPosition[currentSize];
	local ButtonRangeCheck      = OPT.ButtonRangeCheck[currentSize];
	local ButtonRangeDisplay    = OPT.ButtonRangeDisplay[currentSize];
	local ButtonShowHealer      = OPT.ButtonShowHealer[currentSize];

	local LayoutTH    = BattlegroundTargets_Options.LayoutTH[currentSize];
	local LayoutSpace = BattlegroundTargets_Options.LayoutSpace[currentSize];

	local TargetIcon = BattlegroundTargets_Options.TargetIcon;

	local ButtonWidth_2  = ButtonWidth - 2;
	local ButtonHeight_2 = ButtonHeight - 2;

	local backfallFontSize = ButtonFontSize;
	if(ButtonHeight < ButtonFontSize) then
		backfallFontSize = ButtonHeight;
	end
	
	local withIconWidth;
	
	local iconNum = 0; 
	if ButtonClassIcon and ButtonShowHealer then iconNum = 2;
	elseif ButtonShowHealer or ButtonClassIcon then iconNum = 1 end
	
	if(ButtonRangeCheck and ButtonRangeDisplay < 9) then
		withIconWidth = (ButtonWidth - ( (ButtonHeight_2 * iconNum) + (ButtonHeight_2 / 2) ) ) - 2;
	else
		withIconWidth = (ButtonWidth - (ButtonHeight_2 * iconNum)) - 2;
	end

	for i = 1, currentSize do
		local GVAR_TargetButton = GVAR.TargetButton[i];
		
		local lvl = GVAR_TargetButton:GetFrameLevel();
		GVAR_TargetButton.HealthTextButton:SetFrameLevel(lvl + 2);
		GVAR_TargetButton.TargetTextureButton:SetFrameLevel(lvl + 3);
		GVAR_TargetButton.AssistTextureButton:SetFrameLevel(lvl + 4);
		GVAR_TargetButton.FocusTextureButton:SetFrameLevel(lvl + 5);
		GVAR_TargetButton.FlagTextureButton:SetFrameLevel(lvl + 6);
		
		GVAR_TargetButton:SetScale(ButtonScale);
		
		GVAR_TargetButton:SetWidth(ButtonWidth);
		GVAR_TargetButton:SetHeight(ButtonHeight);
		GVAR_TargetButton.HighlightT:SetWidth(ButtonWidth);
		GVAR_TargetButton.HighlightR:SetHeight(ButtonHeight);
		GVAR_TargetButton.HighlightB:SetWidth(ButtonWidth);
		GVAR_TargetButton.HighlightL:SetHeight(ButtonHeight);
		GVAR_TargetButton.Background:SetWidth(ButtonWidth_2);
		GVAR_TargetButton.Background:SetHeight(ButtonHeight_2);
		
		if(ButtonRangeCheck and ButtonRangeDisplay < 9) then
			GVAR_TargetButton.RangeTexture:Show();
			GVAR_TargetButton.RangeTexture:SetWidth(ButtonHeight_2/2);
			GVAR_TargetButton.RangeTexture:SetHeight(ButtonHeight_2);
		else
			GVAR_TargetButton.RangeTexture:Hide();
		end
		
		GVAR_TargetButton.ClassTexture:SetWidth(ButtonHeight_2);
		GVAR_TargetButton.ClassTexture:SetHeight(ButtonHeight_2);

		GVAR_TargetButton.LeaderTexture:SetWidth(ButtonHeight_2 / 1.5);
		GVAR_TargetButton.LeaderTexture:SetHeight(ButtonHeight_2 / 1.5);
		GVAR_TargetButton.LeaderTexture:ClearAllPoints()
		GVAR_TargetButton.LeaderTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", -(ButtonHeight_2 / 1.5) / 2, 0)

		GVAR_TargetButton.ClassColorBackground:SetHeight(ButtonHeight_2);
		GVAR_TargetButton.HealthBar:SetHeight(ButtonHeight_2);

		GVAR_TargetButton.HealersTexture:ClearAllPoints();

		if OPT.ButtonRoleLayoutPos[currentSize] == 2 then
			
			GVAR_TargetButton.HealersTexture:SetWidth(ButtonHeight_2);
			GVAR_TargetButton.HealersTexture:SetHeight(ButtonHeight_2);

			if(ButtonShowHealer) then
				if(ButtonRangeCheck and ButtonRangeDisplay < 9) then
					GVAR_TargetButton.HealersTexture:SetPoint("LEFT", GVAR_TargetButton.RangeTexture, "RIGHT", 0, 0);
				else
					GVAR_TargetButton.HealersTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", 1, 0);
				end
				
				GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton.HealersTexture, "RIGHT", 0, 0);
			end
	
			if(ButtonClassIcon) then
				GVAR_TargetButton.ClassTexture:Show();
	
				if ButtonShowHealer then
					GVAR_TargetButton.ClassTexture:SetPoint("LEFT", GVAR_TargetButton.HealersTexture, "RIGHT", 0, 0);
					GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton.ClassTexture, "RIGHT", 0, 0);
				else
					if(ButtonRangeCheck and ButtonRangeDisplay < 9) then
						GVAR_TargetButton.ClassTexture:SetPoint("LEFT", GVAR_TargetButton.RangeTexture, "RIGHT", 0, 0);
					else
						GVAR_TargetButton.ClassTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", 1, 0);
					end
	
					GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton.ClassTexture, "RIGHT", 0, 0);
				end
			
			else
				GVAR_TargetButton.ClassTexture:Hide();
			end
	
			if not ButtonShowHealer and not ButtonClassIcon then
				if(ButtonRangeCheck and ButtonRangeDisplay < 9) then
					GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton.RangeTexture, "RIGHT", 0, 0);
				else
					GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton, "LEFT", 1, 0);
				end
			end

		elseif OPT.ButtonRoleLayoutPos[currentSize] == 1 or OPT.ButtonRoleLayoutPos[currentSize] == 3 then

			if(ButtonClassIcon) then
				GVAR_TargetButton.ClassTexture:Show();

				if(ButtonRangeCheck and ButtonRangeDisplay < 9) then
					GVAR_TargetButton.ClassTexture:SetPoint("LEFT", GVAR_TargetButton.RangeTexture, "RIGHT", 0, 0);
				else
					GVAR_TargetButton.ClassTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", 1, 0);
				end
				
				GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton.ClassTexture, "RIGHT", 0, 0);
			else
				GVAR_TargetButton.ClassTexture:Hide();
				
				if(ButtonRangeCheck and ButtonRangeDisplay < 9) then
					GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton.RangeTexture, "RIGHT", 0, 0);
				else
					GVAR_TargetButton.ClassColorBackground:SetPoint("LEFT", GVAR_TargetButton, "LEFT", 1, 0);
				end
			end
		
		end
		
		GVAR_TargetButton.Name:SetFont(fontPath, ButtonFontSize, "");
		GVAR_TargetButton.Name:SetShadowOffset(0, 0);
		GVAR_TargetButton.Name:SetShadowColor(0, 0, 0, 0);
		GVAR_TargetButton.Name:SetTextColor(0, 0, 0, 1);
		GVAR_TargetButton.Name:SetHeight(backfallFontSize);
		
		GVAR_TargetButton.HealthText:SetFont(fontPath, ButtonFontSize, "OUTLINE");
		GVAR_TargetButton.HealthText:SetShadowOffset(0, 0);
		GVAR_TargetButton.HealthText:SetShadowColor(0, 0, 0, 0);
		GVAR_TargetButton.HealthText:SetTextColor(1, 1, 1, 1);
		GVAR_TargetButton.HealthText:SetHeight(backfallFontSize);
		GVAR_TargetButton.HealthText:SetAlpha(0.6);

		if(ButtonShowTargetCount) then
			healthBarWidth = withIconWidth - 20;
			
			GVAR_TargetButton.ClassColorBackground:SetWidth(withIconWidth - 20);
			GVAR_TargetButton.HealthBar:SetWidth(withIconWidth - 20);

			if OPT.ButtonRoleLayoutPos[currentSize] == 1 then
				GVAR_TargetButton.HealersTexture:SetPoint("RIGHT", GVAR_TargetButton.TargetCountBackground, -OPT.ButtonHeight[currentSize], 0);
			end

			GVAR_TargetButton.Name:SetPoint("LEFT", GVAR_TargetButton.ClassColorBackground, "LEFT", 2, 0);
			GVAR_TargetButton.Name:SetWidth(withIconWidth - 20 - 2);
			GVAR_TargetButton.TargetCountBackground:SetHeight(ButtonHeight_2);
			GVAR_TargetButton.TargetCountBackground:Show();
			GVAR_TargetButton.TargetCount:SetFont(fontPath, ButtonFontSize, "");
			GVAR_TargetButton.TargetCount:SetShadowOffset(0, 0);
			GVAR_TargetButton.TargetCount:SetShadowColor(0, 0, 0, 0);
			GVAR_TargetButton.TargetCount:SetHeight(backfallFontSize);
			GVAR_TargetButton.TargetCount:SetTextColor(1, 1, 1, 1);
			GVAR_TargetButton.TargetCount:SetText("");
			GVAR_TargetButton.TargetCount:Show();

			
		else
			healthBarWidth = withIconWidth;
			
			GVAR_TargetButton.ClassColorBackground:SetWidth(withIconWidth);
			GVAR_TargetButton.HealthBar:SetWidth(withIconWidth);

			if OPT.ButtonRoleLayoutPos[currentSize] == 1 then
				GVAR_TargetButton.HealersTexture:SetPoint("RIGHT", GVAR_TargetButton.TargetCountBackground, 2, 0);
			end
			GVAR_TargetButton.Name:SetPoint("LEFT", GVAR_TargetButton.ClassColorBackground, "LEFT", 2, 0);
			GVAR_TargetButton.Name:SetWidth(withIconWidth - 2);
			
			GVAR_TargetButton.TargetCountBackground:Hide();
			GVAR_TargetButton.TargetCount:Hide();
		end

		if(ButtonShowTarget) then
			if(TargetIcon == "default") then
				GVAR_TargetButton.TargetTexture:SetTexture("Interface\\AddOns\\BattlegroundTargets\\Textures\\Target");
			else
				GVAR_TargetButton.TargetTexture:SetTexture(AddonIcon);
			end
			
			local quad = ButtonHeight_2 * ButtonTargetScale;
			local leftPos = -quad;
			
			GVAR_TargetButton.TargetTexture:SetWidth(quad);
			GVAR_TargetButton.TargetTexture:SetHeight(quad);
			
			if(ButtonTargetPosition >= 100) then
				leftPos = ButtonWidth;
			elseif(ButtonTargetPosition > 0) then
				leftPos = ((quad + ButtonWidth) * (ButtonTargetPosition / 100) ) - quad;
			end
			
			GVAR_TargetButton.TargetTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", leftPos, 0);
			GVAR_TargetButton.TargetTexture:Show();
		else
			GVAR_TargetButton.TargetTexture:Hide();
		end

		if(ButtonShowFocus) then
			local quad = ButtonHeight_2 * ButtonFocusScale;
			local leftPos = -quad;
			
			GVAR_TargetButton.FocusTexture:SetWidth(quad);
			GVAR_TargetButton.FocusTexture:SetHeight(quad);
			
			if(ButtonFocusPosition >= 100) then
				leftPos = ButtonWidth;
			elseif(ButtonFocusPosition > 0) then
				leftPos = ( (quad + ButtonWidth) * (ButtonFocusPosition/100) ) - quad;
			end
			
			GVAR_TargetButton.FocusTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", leftPos, 0);
			GVAR_TargetButton.FocusTexture:Show();
		else
			GVAR_TargetButton.FocusTexture:Hide();
		end
		
		if(ButtonShowFlag) then
			local quad = ButtonHeight_2 * ButtonFlagScale;
			local leftPos = -quad;
			
			GVAR_TargetButton.FlagTexture:SetWidth(quad);
			GVAR_TargetButton.FlagTexture:SetHeight(quad);
			
			if(ButtonFlagPosition >= 100) then
				leftPos = ButtonWidth
			elseif(ButtonFlagPosition > 0) then
				leftPos = ((quad + ButtonWidth) * (ButtonFlagPosition / 100)) - quad;
			end
			
			GVAR_TargetButton.FlagTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", leftPos, 0);
			GVAR_TargetButton.FlagTexture:Show();
		else
			GVAR_TargetButton.FlagTexture:Hide();
		end
		
		if(ButtonShowAssist) then
			local quad = ButtonHeight_2 * ButtonAssistScale;
			local leftPos = -quad;
			
			GVAR_TargetButton.AssistTexture:SetWidth(quad);
			GVAR_TargetButton.AssistTexture:SetHeight(quad);
			
			if(ButtonAssistPosition >= 100) then
				leftPos = ButtonWidth;
			elseif(ButtonAssistPosition > 0) then
				leftPos = ( (quad + ButtonWidth) * (ButtonAssistPosition/100) ) - quad;
			end
			
			GVAR_TargetButton.AssistTexture:SetPoint("LEFT", GVAR_TargetButton, "LEFT", leftPos, 0);
			GVAR_TargetButton.AssistTexture:Show();
		else
			GVAR_TargetButton.AssistTexture:Hide();
		end
	end
	
	reSetLayout = false;
end

function BattlegroundTargets:MainDataUpdate()
	local ButtonSortBy = OPT.ButtonSortBy[currentSize];
	local ButtonSortDetail = OPT.ButtonSortDetail[currentSize];
	
	if ButtonSortBy == 1 then
		if ButtonSortDetail == 3 then
			table_sort(ENEMY_Data, sortfunc13); -- Class/Name | 13
		elseif ButtonSortDetail == 1 then
			table_sort(ENEMY_Data, sortfunc11); -- Class/Name | 11
		else
			table_sort(ENEMY_Data, sortfunc12); -- Class/Name | 12
		end
	elseif ButtonSortBy == 2 then
		table_sort(ENEMY_Data, sortfunc2); -- Name | 2

	elseif ButtonSortBy == 3 then -- Heals First + Class/Name
		table_sort(ENEMY_Data, sortfunc33); -- Heals First + Class/Name | 33
	end
	
	local ButtonClassIcon       = OPT.ButtonClassIcon[currentSize];
	local ButtonRoleLayoutPos   = OPT.ButtonRoleLayoutPos[currentSize];
	local ButtonShowLeader      = OPT.ButtonShowLeader[currentSize];
	local ButtonShowHealer      = OPT.ButtonShowHealer[currentSize]; 
	local ButtonHideRealm       = OPT.ButtonHideRealm[currentSize];
	local ButtonShowTargetCount = OPT.ButtonShowTargetCount[currentSize];
	local ButtonShowHealthBar   = OPT.ButtonShowHealthBar[currentSize];
	local ButtonShowHealthText  = OPT.ButtonShowHealthText[currentSize];
	local ButtonShowTarget      = OPT.ButtonShowTarget[currentSize];
	local ButtonShowFocus       = OPT.ButtonShowFocus[currentSize];
	local ButtonShowFlag        = OPT.ButtonShowFlag[currentSize];
	local ButtonShowAssist      = OPT.ButtonShowAssist[currentSize];
	local ButtonRangeCheck      = OPT.ButtonRangeCheck[currentSize];
	
	table_wipe(ENEMY_Name2Button);
	table_wipe(ENEMY_Names4Flag);

	for i = 1, currentSize do
		if ENEMY_Data[i] then
			local GVAR_TargetButton = GVAR.TargetButton[i];
			
			local qname       = ENEMY_Data[i].name
			local qclassToken = ENEMY_Data[i].classToken
			ENEMY_Name2Button[qname] = i;
			GVAR_TargetButton.buttonNum = i;
			
			local colR = classcolors[qclassToken].r;
			local colG = classcolors[qclassToken].g;
			local colB = classcolors[qclassToken].b;
			
			GVAR_TargetButton.colR = colR;
			GVAR_TargetButton.colG = colG;
			GVAR_TargetButton.colB = colB;
			GVAR_TargetButton.colR5 = colR*0.5;
			GVAR_TargetButton.colG5 = colG*0.5;
			GVAR_TargetButton.colB5 = colB*0.5;
			GVAR_TargetButton.ClassColorBackground:SetTexture(GVAR_TargetButton.colR5, GVAR_TargetButton.colG5, GVAR_TargetButton.colB5, 1);
			GVAR_TargetButton.HealthBar:SetTexture(colR, colG, colB, 1);
			
			local onlyname = qname;
			if(ButtonShowFlag or ButtonHideRealm) then
				if(string_find(qname, "-", 1, true)) then
					onlyname = string_match(qname, "(.-)%-(.*)$");
				end
				
				ENEMY_Names4Flag[onlyname] = i;
			end

			if(ButtonHideRealm) then
				if(isLowLevel) then
					GVAR_TargetButton.name4button = onlyname;
				end
				
				if(isLowLevel and ENEMY_Name2Level[qname]) then
					GVAR_TargetButton.Name:SetText(ENEMY_Name2Level[qname].." "..onlyname);
				else
					GVAR_TargetButton.Name:SetText(onlyname);
				end
			else
				if(isLowLevel) then
					GVAR_TargetButton.name4button = qname;
				end
				
				if(isLowLevel and ENEMY_Name2Level[qname]) then
					GVAR_TargetButton.Name:SetText(ENEMY_Name2Level[qname].." "..qname);
				else
					GVAR_TargetButton.Name:SetText(qname);
				end
			end
			
			GVAR_TargetButton.targetName = qname;
			if(GVAR_TargetButton.SetAttribute and (not inCombat or not InCombatLockdown())) then
				GVAR_TargetButton:SetAttribute("macrotext1", "/targetexact "..qname);
				GVAR_TargetButton:SetAttribute("macrotext2", "/targetexact "..qname.."\n/focus\n/targetlasttarget");
			end
			
			if(ButtonRangeCheck) then
				GVAR_TargetButton.RangeTexture:SetTexture(colR, colG, colB, 1);
			end
			
			if(ButtonClassIcon) then
				GVAR_TargetButton.ClassTexture:SetTexCoord(classes[qclassToken][1], classes[qclassToken][2], classes[qclassToken][3], classes[qclassToken][4]);
			end
			
			local nameE = ENEMY_Names[qname];
			local percentE = ENEMY_Name2Percent[qname];
			
			if(ButtonShowTargetCount) then
				if(nameE) then
					GVAR_TargetButton.TargetCount:SetText(nameE);
				else
					GVAR_TargetButton.TargetCount:SetText("0");
				end
			end

			if(ButtonShowHealthBar or ButtonShowHealthText) then
				if(nameE and percentE) then
					if(ButtonShowHealthBar) then
						local width = healthBarWidth * (percentE / 100);
						
						width = math_max(0.01, width);
						width = math_min(healthBarWidth, width);
						GVAR_TargetButton.HealthBar:SetWidth(width);
					end
					
					if(ButtonShowHealthText) then
						GVAR_TargetButton.HealthText:SetText(percentE);
					end
				end
			end
			
			if(ButtonShowTarget and targetName) then
				if(qname == targetName) then
					GVAR_TargetButton.HighlightT:SetTexture(0.5, 0.5, 0.5, 1);
					GVAR_TargetButton.HighlightR:SetTexture(0.5, 0.5, 0.5, 1);
					GVAR_TargetButton.HighlightB:SetTexture(0.5, 0.5, 0.5, 1);
					GVAR_TargetButton.HighlightL:SetTexture(0.5, 0.5, 0.5, 1);
					GVAR_TargetButton.TargetTexture:SetAlpha(1);
				else
					GVAR_TargetButton.HighlightT:SetTexture(0, 0, 0, 1);
					GVAR_TargetButton.HighlightR:SetTexture(0, 0, 0, 1);
					GVAR_TargetButton.HighlightB:SetTexture(0, 0, 0, 1);
					GVAR_TargetButton.HighlightL:SetTexture(0, 0, 0, 1);
					GVAR_TargetButton.TargetTexture:SetAlpha(0);
				end
			end
			
			if(ButtonShowFocus and focusName) then
				if(qname == focusName) then
					GVAR_TargetButton.FocusTexture:SetAlpha(1);
				else
					GVAR_TargetButton.FocusTexture:SetAlpha(0);
				end
			end
			
			if(ButtonShowFlag and hasFlag) then
				if(qname == hasFlag) then
					GVAR_TargetButton.FlagTexture:SetAlpha(1);
				else
					GVAR_TargetButton.FlagTexture:SetAlpha(0);
				end
			end
			
			if(ButtonShowAssist and assistTargetName) then
				if(qname == assistTargetName) then
					GVAR_TargetButton.AssistTexture:SetAlpha(1);
				else
					GVAR_TargetButton.AssistTexture:SetAlpha(0);
				end
			end

			if(ButtonShowLeader and isLeader) then
				if(qname == isLeader) then
					GVAR_TargetButton.LeaderTexture:SetAlpha(0.75);
				else
					GVAR_TargetButton.LeaderTexture:SetAlpha(0);
				end
			end

			if(ButtonShowHealer) then
			
				BattlegroundTargets:initHealersTable(qname, qclassToken);

				local healerStatus = BattlegroundTargets:GetHealerStatus(qname, qclassToken);
				
				if not healerStatus then healerStatus = 0;
				elseif healerStatus == 3 then healerStatus = 2 end;
				GVAR_TargetButton.HealersTexture:SetTexture(battleFieldRoleIcons[healerStatus]);

			end
		else
			local GVAR_TargetButton = GVAR.TargetButton[i];
			
			BattlegroundTargets:ClearConfigButtonValues(GVAR_TargetButton);
			
			GVAR_TargetButton.targetName = nil;
			if(GVAR_TargetButton.SetAttribute and (not inCombat or not InCombatLockdown())) then
				GVAR_TargetButton:SetAttribute("macrotext1", "");
				GVAR_TargetButton:SetAttribute("macrotext2", "");
			end
		end
	end
	
	if(isConfig) then
		if(isLowLevel) then
			for i = 1, currentSize do
				local GVAR_TargetButton = GVAR.TargetButton[i];
				
				GVAR_TargetButton.Name:SetText(playerLevel.." "..GVAR_TargetButton.name4button);
			end
		end
		
		return;
	end
	
	if(ButtonRangeCheck) then
		local curTime = GetTime();
		
		if(range_CL_DisplayThrottle + range_CL_DisplayFrequency > curTime) then return; end
		
		range_CL_DisplayThrottle = curTime;
		BattlegroundTargets:UpdateRange(curTime);
	end
end

function BattlegroundTargets:NameFactionToNumber(faction)
	if (faction == "Horde") then return 0;
	elseif (faction == "Alliance") then return 1 end;
end

--[[ function BattlegroundTargets:ParseFactionFromMSG(msg)
	local str, faction = msg, nil;
	if str:find("Орды!")    or str:find("Horde!")    then faction = 0 end
	if str:find("Альянса!") or str:find("Alliance!") then faction = 1 end
	if faction then 
		BattlegroundTargets_Character.TempFaction = faction;
		BattlegroundTargets:ValidateFactionBG(nil, faction, true)
	end
end ]]

function BattlegroundTargets:ValidateFactionBG(faction)
	BattlegroundTargets:CheckNativeFaction();
	if (faction == oppositeFactionBG) then 
		if (faction == 0) then
			oppositeFactionBG  = 1;
			playerFactionBG    = 0
		else
			oppositeFactionBG  = 0;
			playerFactionBG    = 1;
		end
	end

	BattlegroundTargets_Character.TempFaction = faction;
	
	icoMinimapFactionBG = battleFieldIconTextures[playerFactionBG];
	MiniMapBattlefieldIcon:SetTexture(icoMinimapFactionBG)
	MiniMapBattlefieldFrame:SetNormalTexture(icoMinimapFactionBG)
	--BattlegroundTargets:UnregisterEvent("CHAT_MSG_RAID_BOSS_EMOTE");

	factionIsValid = true;
end

function BattlegroundTargets:initHealersTable(name, class)
	if(isConfig) then return; end
	if not ENEMY_Healers[name] and contains(HEALER_SpellBase["Healers"], class) then
		ENEMY_Healers[name]          = {};
		ENEMY_Healers[name].status   = 0;
		ENEMY_Healers[name].class    = class;
		ENEMY_Healers[name].reason   = "UNKNOWN";
		ENEMY_Healers[name].tries    = 0; 
		ENEMY_Healers[name].DBstatus = 0; 
	end
end 

function BattlegroundTargets:CheckEnemyHealer(name, class, enemyID)
	if(isConfig) then return; end
	if (name and contains(HEALER_SpellBase["Healers"], class)) then 
		BattlegroundTargets:initHealersTable(name, class);
		local status = ENEMY_Healers[name].status;
		local reason;
		if status == 0 or status == 3 then
			status, reason = BattlegroundTargets:GetHealerStatusByBuff(enemyID, name, class);
			ENEMY_Healers[name].status = status;
			ENEMY_Healers[name].reason = reason;
			ENEMY_Healers[name].tries  = ENEMY_Healers[name].tries + 1;
		end	
		return status;
	end
	return nil;
end

local coloredLOG = {
	log    = "|cffffff7f[TARGET_SCAN_LOG]|r",
	reason = "|cfff4db49Reason:|r",
	name   = "|cfff4db49Name:|r",
	target = "|cfff4db49Target:|r",
	source = "|cfff4db49Source:|r",
	tries  = "|cfff4db49Tries:|r",
	dd     = "|cffff0000DD|r",
	heal   = "|cff55c912HEALER|r"
}

local function coloredClass(class)
	return "|cff"..ClassHexColor(class)..class.."|r";
end

function BattlegroundTargets:GetHealerStatusByBuff(enemyID, name, class)
	local i = 1;
	local unitStatus = 0;
	local buffOwnerID, spellID;
	local reason;
	if class == "PALADIN" or class == "DRUID" then
		local maxpower = UnitPowerMax(enemyID, 0); -- Check Mana.
		if maxpower and maxpower ~= 0 then
			local tpl; 
			local status;
			if class == "PALADIN" then
				status = tonumber(maxpower) > 16000 and 2 or 1;
				tpl = status == 1 and coloredLOG.dd or coloredLOG.heal;
			else -- druid
				status = tonumber(maxpower) < 12000 and 1 or 0;
				tpl = status == 1 and coloredLOG.dd
			end
			if status > 0 then
				HDLog(coloredLOG.log.." "..coloredClass(class).." "..tpl.." detected. "..coloredLOG.reason.." max-mana is "..maxpower, coloredLOG.name, name, coloredLOG.target, enemyID, coloredLOG.tries, ENEMY_Healers[name].tries+1,"\n\n")
				reason = "Max mana: "..maxpower;
				return status, reason;
			end
		else 
			return 0; 
		end
	end
	local buff = UnitBuff(enemyID, i);
	while buff do
		local _, _, _, _, _, _, buffOwnerID, _, _, spellID = UnitBuff(enemyID, i);
		for _,val in ipairs(HEALER_SpellBase["HealerBuffs"]) do
			if (spellID == val or GetSpellInfo(val) == buff) then
				local owner = buffOwnerID or "-";
				HDLog(coloredLOG.log.." "..coloredClass(class).." "..coloredLOG.heal.." detected. "..coloredLOG.reason.." "..buff,val.." "..coloredLOG.name, name, coloredLOG.target, enemyID,"|cfff4db49OWNER:|r "..owner, coloredLOG.tries, ENEMY_Healers[name].tries+1,"\n\n")
				return 2, "buff: "..buff.." spellID: "..val;
			end
		end
		for _, val in ipairs(HEALER_SpellBase["DamageBuffs"]) do
			if (spellID == val or GetSpellInfo(val) == buff) then
				local owner = buffOwnerID or "-";
				HDLog(coloredLOG.log.." "..coloredClass(class).." "..coloredLOG.dd.." detected. "..coloredLOG.reason.." "..buff,val.." "..coloredLOG.name, name, coloredLOG.target, enemyID,"|cfff4db49OWNER:|r "..owner, coloredLOG.tries, ENEMY_Healers[name].tries+1,"\n\n")
				return 1, "buff: "..buff.." spellID: "..val;
			end
		end
		i = i + 1;
		buff = UnitBuff(enemyID, i);
	end;
	return unitStatus; 
end

function BattlegroundTargets:GetHealerStatus(name, class) 
	if(isConfig) then return; end
	local status = nil;
	local isHealerClass = contains(HEALER_SpellBase["Healers"], class);
	local DBisEnable = BattlegroundTargets_Options.DB and BattlegroundTargets_Options.DB.outOfDateRange and BattlegroundTargets_Options.DB.outOfDateRange > 0;
	if name then
		if isHealerClass and 
		ENEMY_Healers[name].status == 0 and ENEMY_Healers[name].DBstatus == 0 then 
			local sUnit = {}
			local isExists = false;
			sUnit.name  = name;
			sUnit.class = class;
			if DBisEnable then isExists = BattlegroundTargets_DBUtils:checkHealerDB(BattlegroundTargets_HealersDB, sUnit) end
			if isExists then
				ENEMY_Healers[name].status 	 = 3;
				ENEMY_Healers[name].reason 	 = "Received from the database";
				ENEMY_Healers[name].tries  	 = ENEMY_Healers[name].tries + 1;
				ENEMY_Healers[name].class  	 = class;
				ENEMY_Healers[name].DBstatus = 1;
				HDLog("[DB]: "..coloredClass(class), coloredLOG.heal, name.." was found in DB!")
			else 
				ENEMY_Healers[name].DBstatus = -1;
			end
		elseif not isHealerClass then
			status = 1;
		end
	end
	local rStatus = ENEMY_Healers[name]  and  ENEMY_Healers[name].status  or  status;
	return rStatus;
end

function BattlegroundTargets:DetectHealerByAOEBuffs(...)
	if isConfig or not inBattleground then return; end
	if OPT.ButtonShowHealer[currentSize] then
		local trackingEvents = {"SPELL_AURA_APPLIED", "SPELL_AURA_REMOVED", "SPELL_AURA_REFRESH"}
		local _,event,_,ownerName,_,_,targetName,_,spellID,spellName,_,spellType = ...;
		if contains(trackingEvents, event) then
			if ENEMY_Healers[ownerName] and (ENEMY_Healers[ownerName].status == 0 or ENEMY_Healers[ownerName].status == 3) then
				local successDetect;
				if contains(HEALER_SpellBase["aoeHealerBuffs"], spellID) or 
				   contains(HEALER_SpellBase["HealerBuffs"], spellID) then
						ENEMY_Healers[ownerName].status = 2;
						successDetect = true;
				elseif 
					contains(HEALER_SpellBase["aoeDamageBuffs"], spellID) or 
				    contains(HEALER_SpellBase["DamageBuffs"], spellID) then
						ENEMY_Healers[ownerName].status = 1;
						successDetect = true;
				end
				if successDetect then
					local tpl = ENEMY_Healers[ownerName].status == 1  and  coloredLOG.dd  or  coloredLOG.heal;
					ENEMY_Healers[ownerName].reason = spellType..": "..spellName.." spellID: "..spellID;
					ENEMY_Healers[ownerName].tries  = ENEMY_Healers[ownerName].tries  + 1;
					HDLog("[COMBAT_LOG] "..coloredClass(ENEMY_Healers[ownerName].class).." "..tpl.." detected. "..coloredLOG.reason.." "..spellName,spellID.." "..coloredLOG.name, ownerName, coloredLOG.tries, ENEMY_Healers[ownerName].tries,"\n\n")
				end
			end
		end 
	end
end

--------- Integrates CombatLog-based detection from BattleGroundHealers, by Khal ---------
function BattlegroundTargets:DetectHealerByBGH(name, class)
	if isConfig or not inBattleground then return end
	if not name or not class then return end
	BattlegroundTargets:initHealersTable(name, class)
	if ENEMY_Healers[name] and (ENEMY_Healers[name].status == 0 or ENEMY_Healers[name].status == 3) then
		ENEMY_Healers[name].status = 2
		ENEMY_Healers[name].reason = "BGH callback"
		ENEMY_Healers[name].tries  = ENEMY_Healers[name].tries + 1
		HDLog("[BGH] "..coloredClass(class).." "..coloredLOG.heal.." detected. "..coloredLOG.name, name, coloredLOG.reason, ENEMY_Healers[name].reason, coloredLOG.tries, ENEMY_Healers[name].tries, "\n\n")
	end
end

local function RegisterBGH_Notifier()
	if not BGH_Notifier then return end
	Print("BGH loaded, detection method added.")
	BGH_Notifier.OnHealerDetected = function(name, class)
		BattlegroundTargets:DetectHealerByBGH(name, class)
	end
end
-------------------------------------------------------------------------------------------

function BattlegroundTargets:HDreport()
	local next = next;
	if next(ENEMY_Healers) then
		Print("\nHEALER DETECTION. REPORT:")
		local report   = {};
		report.healers = {};
		report.dd      = {};
		report.unk     = {};
		local report_title_HEALERS = "\n==================\n|cff55c912HEALERS|r DETECTED: \n";
		local report_title_DD      = "\n==================\n|cffff0000DD|r DETECTED: \n";
		local report_title_UNKNOWN = "\n==================\n|cff969696UNKNOWN|r ROLE: \n";
		for name, data in pairs(ENEMY_Healers) do
			if (type(data) == "table") then
				local str = "" 
				str  = str.."   NAME: "..name.."\n"
				str  = str.."      CLASS: "..coloredClass(data.class).."\n"
				str  = str.."      REASON: "..(data.reason or "... no data ...").."\n"
				str  = str.."      Total attempts to detect: "..data.tries.."\n"
				if data.status >= 2 then report.healers[name] = str;	
				elseif data.status == 1 then report.dd[name]  = str;
				elseif data.status == 0 then
					str = str.."      status: "..data.status.."\n";
					report.unk[name] = str;
				end
			end
		end
		for role, tbl in pairs(report) do
			if role == "healers"  and   next(report.healers)  then print(report_title_HEALERS);
			elseif role == "dd"   and   next(report.dd)       then print(report_title_DD);
			elseif role == "unk"  and   next(report.unk)      then print(report_title_UNKNOWN); end;
			for _, str in pairs(tbl) do print(str) end
		end
	end
end
----------------------------------------------------------

function BattlegroundTargets:BattlefieldScoreUpdate()
	local curTime = GetTime();
	local diff = curTime - latestScoreUpdate;
	if(diff < 1) then return end
	local queueStatus, queueMapName, bgName;

	for i=1, MAX_BATTLEFIELD_QUEUES do
		queueStatus, queueMapName = GetBattlefieldStatus(i);
		if(queueStatus == "active") then
			bgName = BGN[queueMapName];
			break;
		end
	end

	--------- Adjustment for Warmane's Mercenary Mode, by Khal ---------
	if not factionIsValid then
		for i = 1, GetNumBattlefieldScores() do
			local iName, _, _, _, _, iFaction = GetBattlefieldScore(i);
			if playerName == iName then
				faction = iFaction;
				break
			end
		end
		if faction then
			BattlegroundTargets:ValidateFactionBG(faction)
			if bgName then
				if faction == 0 then
					Print(bgName, "- |cffcc1a1aHorde|r ")
				elseif faction == 1 then
					Print(bgName, "- |cff3060ffAlliance|r ")
				end
			end
		end
	end

	if not factionIsValid then return end
	---------------------------------------------------------------------

	if(inCombat or InCombatLockdown()) then
		if(curTime - latestScoreWarning) then
			GVAR.ScoreUpdateTexture:Show();
		else
			GVAR.ScoreUpdateTexture:Hide();
		end
		
		reCheckScore = true;
		return;
	end

	local wssf = WorldStateScoreFrame;
	if(wssf and wssf:IsShown() and wssf.selectedTab and wssf.selectedTab > 1) then return; end

	scoreUpdateCount = scoreUpdateCount + 1;
	if(scoreUpdateCount > 20) then
		scoreUpdateFrequency = 5;
	end
	reCheckScore = nil;
	latestScoreUpdate = curTime;
	GVAR.ScoreUpdateTexture:Hide();

	table_wipe(ENEMY_Data);
	table_wipe(FRIEND_Names);

	local x = 1;
	for index = 1, GetNumBattlefieldScores() do
		local name, _, _, _, _, iFaction, _, _, _, classToken = GetBattlefieldScore(index);
		
		if (name and name ~= playerName) then
			
			if (iFaction == oppositeFactionBG) then
				
				if (oppositeFactionREAL == nil and race) then
					local n = RNA[race];
					
					if (n == 0) then
						oppositeFactionREAL = n;
					elseif (n == 1) then
						oppositeFactionREAL = n;
					end
				end
				
				local class = "ZZZFAILURE";
				if (classToken) then
					class = classToken;
				end
				
				ENEMY_Data[x] = {};
				ENEMY_Data[x].name = name;
				ENEMY_Data[x].classToken = class;
				
				x = x + 1;

				if(not ENEMY_Names[name]) then
					ENEMY_Names[name] = 0;
				end
			else
				FRIEND_Names[name] = 1;
				
				local class = "ZZZFAILURE";
				if(classToken) then
					class = classToken;
				end
			end
		end
	end
	
	if(ENEMY_Data[1]) then
		BattlegroundTargets:MainDataUpdate();
		
		if(not flagflag and isFlagBG > 0) then
			if(OPT.ButtonShowFlag[currentSize]) then
				BattlegroundTargets:CheckFlagCarrierSTART();
			end
		end
	end
	
	if(reSizeCheck >= 10) then return; end
	
	if(bgName) then
		BattlegroundTargets:BattlefieldCheck();
	else
		local zone = GetRealZoneText();
		
		if BGN[zone] then
			BattlegroundTargets:BattlefieldCheck();
		else
			reSizeCheck = reSizeCheck + 1;
		end
	end
end

function BattlegroundTargets:CheckFlagCarrierCHECK(unit, targetName)
	if(not ENEMY_FirstFlagCheck[targetName]) then return; end
	for i = 1, 40 do
		local spellID = select(10, UnitBuff(unit, i));
		if(not spellID) then break; end
		if(flagIDs[spellID]) then
			hasFlag = targetName;
			for j = 1, currentSize do
				local GVAR_TargetButton = GVAR.TargetButton[j];
				
				GVAR_TargetButton.FlagTexture:SetAlpha(0);
			end
			local button = ENEMY_Name2Button[targetName];
			if(button) then
				local GVAR_TargetButton = GVAR.TargetButton[button];
				if(GVAR_TargetButton) then
					GVAR_TargetButton.FlagTexture:SetAlpha(1);
				end
			end
			BattlegroundTargets:CheckFlagCarrierEND();
			return;
		end
	end
	ENEMY_FirstFlagCheck[targetName] = nil;
	local x = 0;
	for k in pairs(ENEMY_FirstFlagCheck) do
		x = x + 1;
	end
	if(x == 0) then
		BattlegroundTargets:CheckFlagCarrierEND();
	end
end

function BattlegroundTargets:CheckFlagCarrierSTART()
	flagCHK = true;
	flagflag = true;
	table_wipe(ENEMY_FirstFlagCheck);
	for i = 1, #ENEMY_Data do
		ENEMY_FirstFlagCheck[ENEMY_Data[i].name] = 1;
	end
	for num = 1, GetNumRaidMembers() do
		local unitID = "raid"..num;
		for i = 1, 40 do
			local spellID = select(10, UnitBuff(unitID, i));
			if not spellID then break end
			if flagIDs[spellID] then return end
		end
	end
	BattlegroundTargets:RegisterEvent("UNIT_TARGET");
	BattlegroundTargets:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
	BattlegroundTargets:RegisterEvent("PLAYER_TARGET_CHANGED");
end

function BattlegroundTargets:CheckFlagCarrierEND() -- FLAGSPY
	flagCHK = nil;
	flagflag = true;
	wipe(ENEMY_FirstFlagCheck);
	if not OPT.ButtonShowHealthBar[currentSize] and
	   not OPT.ButtonShowHealthText[currentSize] and
	   not OPT.ButtonShowTargetCount[currentSize] and
	   not OPT.ButtonShowAssist[currentSize] and
	   not OPT.ButtonShowLeader[currentSize] and
	   not OPT.ButtonShowHealer[currentSize] and
	   (not OPT.ButtonRangeCheck[currentSize] or OPT.ButtonTypeRangeCheck[currentSize] < 2) and
	   not isLowLevel -- LVLCHK
	then
		BattlegroundTargets:UnregisterEvent("UNIT_TARGET")
	end
	if not OPT.ButtonShowHealthBar[currentSize] and
	   not OPT.ButtonShowHealthText[currentSize] and
	   (not OPT.ButtonRangeCheck[currentSize] or OPT.ButtonTypeRangeCheck[currentSize] < 2)
	then
		BattlegroundTargets:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
	end
	if not OPT.ButtonShowTarget[currentSize] and
	   (not OPT.ButtonRangeCheck[currentSize] or OPT.ButtonTypeRangeCheck[currentSize] < 2) and 
	   not OPT.ButtonShowHealer[currentSize]
	then
		BattlegroundTargets:UnregisterEvent("PLAYER_TARGET_CHANGED")
	end
end

function BattlegroundTargets:BattlefieldCheck()
	if(not inWorld) then return; end
	local _, instanceType = IsInInstance();
	if instanceType == "pvp" then
		BattlegroundTargets:IsBattleground();
	else
		BattlegroundTargets:IsNotBattleground();
	end
end

function BattlegroundTargets:IsBattleground()
	inBattleground = true;
	isFlagBG = 0;
	if hdlog and not BattlegroundTargets_Options.hdlog then
		HDLog(L["Logging of healers detection is enabled.\nType |cff55c912/bgt hdlog|r again to disable."]);
	elseif not hdlog and BattlegroundTargets_Options.hdlog then
		HDLog(L["Permanent logging of healers detection is enabled. Type |cff55c912/bgt hdlogAlways|r again to disable."]);
	end

	local queueStatus, queueMapName, bgName;
	for i = 1, MAX_BATTLEFIELD_QUEUES do
		queueStatus, queueMapName = GetBattlefieldStatus(i);
		if(queueStatus == "active") then
			bgName = BGN[queueMapName]
			break;
		end
	end

	if not BattlegroundTargets_Character.TempFaction then
		local faction
		if bgName and bgName ~= "Strand of the Ancients" then 
			local rawx, rawy = GetPlayerMapPosition("player");
			if rawx and rawy then
				local rx, ry = GetRealCoords(rawx, rawy)
				if isStartPosition(rx, ry, bgName) then 	
					faction = 1
				else 
					faction = 0
				end
			end
		else -- Adjustment for Warmane's Mercenary Mode, by Khal
			BattlegroundTargets:BattlefieldScoreRequest()
			for i = 1, GetNumBattlefieldScores() do
				local iName, _, _, _, _, iFaction = GetBattlefieldScore(i);
				if playerName == iName then
					faction = iFaction;
					break;
				end
			end		
		end
		if faction then
			BattlegroundTargets:ValidateFactionBG(faction)
			if bgName then
				if faction == 0 then
					Print(bgName, "- |cffcc1a1aHorde|r ")
				elseif faction == 1 then
					Print(bgName, "- |cff3060ffAlliance|r ")
				end
			end
		end
	else
		BattlegroundTargets:ValidateFactionBG(BattlegroundTargets_Character.TempFaction);
	end
	--------------------------------

	if bgName then
		currentSize = bgSize[ bgName ];
		reSizeCheck = 10;
		local flagBGnum = flagBG[ bgName ];
		if(flagBGnum) then
			isFlagBG = flagBGnum;
		end
	else
		local zone = GetRealZoneText();
		if(BGN[zone]) then
			currentSize = bgSize[ BGN[zone] ];
			reSizeCheck = 10;
			local flagBGnum = flagBG[ BGN[zone] ];
			if(flagBGnum) then
				isFlagBG = flagBGnum;
			end
		else
			if(reSizeCheck >= 10) then
				Print("ERROR", "unknown battleground name", locale, queueMapName, zone);
			end
			currentSize = 10;
			reSizeCheck = reSizeCheck + 1;
		end
	end
	
	if(playerLevel >= maxLevel) then
		isLowLevel = nil;
	else
		isLowLevel = true;
	end
	
	if(inCombat or InCombatLockdown()) then
		reCheckBG = true;
	else
		reCheckBG = false;
		if(BattlegroundTargets_Options.EnableBracket[currentSize]) then
			GVAR.MainFrame:Show();
			GVAR.MainFrame:EnableMouse(false);
			GVAR.MainFrame:SetHeight(0.001);
			GVAR.MainFrame.Movetext:Hide();
			GVAR.TargetButton[1]:SetPoint("TOPLEFT", GVAR.MainFrame, "BOTTOMLEFT", 0, -(20 / OPT.ButtonScale[currentSize]));
			GVAR.ScoreUpdateTexture:Hide();
			for i = 1, 40 do
				local GVAR_TargetButton = GVAR.TargetButton[i]
				if(i < currentSize + 1) then
					BattlegroundTargets:ClearConfigButtonValues(GVAR_TargetButton, 1);
					GVAR_TargetButton:Show();
				else
					GVAR_TargetButton:Hide();
				end
			end
			BattlegroundTargets:SetupButtonLayout();
			if(OPT.ButtonShowFlag[currentSize]) then
				if bgName == "Warsong Gulch" then
					local flagIcon;
					if(playerFactionBG == 0) then
						flagIcon = "Interface\\WorldStateFrame\\HordeFlag";
					else
						flagIcon = "Interface\\WorldStateFrame\\AllianceFlag";
					end
					for i = 1, currentSize do
						GVAR.TargetButton[i].FlagTexture:SetTexture(flagIcon);
					end
				elseif bgName == "Eye of the Storm" then
					local flagIcon;
					if(playerFactionBG == 0) then
						flagIcon = "Interface\\WorldStateFrame\\AllianceFlag";
					else
						flagIcon = "Interface\\WorldStateFrame\\HordeFlag";
					end
					for i = 1, currentSize do
						GVAR.TargetButton[i].FlagTexture:SetTexture(flagIcon);
					end					
				end
			end
		else
			GVAR.MainFrame:Hide();
			for i = 1, 40 do
				GVAR.TargetButton[i]:Hide();
			end
		end
	end
	
	BattlegroundTargets:UnregisterEvent("PLAYER_DEAD");
	BattlegroundTargets:UnregisterEvent("PLAYER_UNGHOST");
	BattlegroundTargets:UnregisterEvent("PLAYER_ALIVE");
	BattlegroundTargets:UnregisterEvent("UNIT_HEALTH_FREQUENT");
	BattlegroundTargets:UnregisterEvent("UPDATE_MOUSEOVER_UNIT");
	BattlegroundTargets:UnregisterEvent("UNIT_TARGET");
	BattlegroundTargets:UnregisterEvent("PLAYER_TARGET_CHANGED");
	BattlegroundTargets:UnregisterEvent("PLAYER_FOCUS_CHANGED");
	BattlegroundTargets:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE");
	BattlegroundTargets:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE");
	BattlegroundTargets:UnregisterEvent("RAID_ROSTER_UPDATE");
	BattlegroundTargets:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	BattlegroundTargets:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE");
	
	if(BattlegroundTargets_Options.EnableBracket[currentSize]) then
		BattlegroundTargets:RegisterEvent("PLAYER_DEAD");
		BattlegroundTargets:RegisterEvent("PLAYER_UNGHOST");
		BattlegroundTargets:RegisterEvent("PLAYER_ALIVE");
		
		if(isLowLevel) then
			BattlegroundTargets:RegisterEvent("UNIT_TARGET");
		end
		
		if(OPT.ButtonShowHealthBar[currentSize] or OPT.ButtonShowHealthText[currentSize]) then
			BattlegroundTargets:RegisterEvent("UNIT_TARGET");
			BattlegroundTargets:RegisterEvent("UNIT_HEALTH_FREQUENT");
			BattlegroundTargets:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
		end
		
		if(OPT.ButtonShowTargetCount[currentSize]) then
			BattlegroundTargets:RegisterEvent("UNIT_TARGET");
		end
		
		if(OPT.ButtonShowTarget[currentSize]) then
			BattlegroundTargets:RegisterEvent("PLAYER_TARGET_CHANGED");
		end

		if(OPT.ButtonShowFocus[currentSize]) then
			BattlegroundTargets:RegisterEvent("PLAYER_FOCUS_CHANGED");
		end

		if(OPT.ButtonShowFlag[currentSize]) then
			if(currentSize == 10 or currentSize == 15) then
				BattlegroundTargets:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE");
				BattlegroundTargets:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE");
			end
		end
		
		if(OPT.ButtonShowAssist[currentSize]) then
			BattlegroundTargets:RegisterEvent("RAID_ROSTER_UPDATE");
			BattlegroundTargets:RegisterEvent("UNIT_TARGET");
		end
		
		if OPT.ButtonShowLeader[currentSize] then
			BattlegroundTargets:RegisterEvent("UNIT_TARGET")
		end
		
		if OPT.ButtonShowHealer[currentSize] then
			BattlegroundTargets:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			BattlegroundTargets:RegisterEvent("RAID_ROSTER_UPDATE");
			BattlegroundTargets:RegisterEvent("UNIT_TARGET");
			BattlegroundTargets:RegisterEvent("PLAYER_TARGET_CHANGED");
		end

		rangeSpellName = nil;
		rangeMin = nil;
		rangeMax = nil;
		
		if(OPT.ButtonRangeCheck[currentSize]) then
			if(OPT.ButtonTypeRangeCheck[currentSize] == 1) then
				BattlegroundTargets:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			elseif(OPT.ButtonTypeRangeCheck[currentSize] >= 2) then
				if(ranges[playerClassEN]) then
					if(IsSpellKnown(ranges[playerClassEN])) then
						rangeSpellName, _, _, _, _, _, _, rangeMin, rangeMax = GetSpellInfo(ranges[playerClassEN]);
						if(not rangeSpellName) then
							Print("ERROR", "unknown spell (rangecheck)", locale, playerClassEN, "id:", ranges[playerClassEN]);
						elseif (not rangeMin or not rangeMax) or (rangeMin <= 0 and rangeMax <= 0) then
							Print("ERROR", "spell min/max fail (rangecheck)", locale, rangeSpellName, rangeMin, rangeMax);
						else
							BattlegroundTargets:RegisterEvent("UNIT_HEALTH_FREQUENT");
							BattlegroundTargets:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
							BattlegroundTargets:RegisterEvent("PLAYER_TARGET_CHANGED");
							BattlegroundTargets:RegisterEvent("UNIT_TARGET");
							
							if(OPT.ButtonTypeRangeCheck[currentSize] >= 3) then
								BattlegroundTargets:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
							end
						end
					elseif playerClassEN == "PALADIN" and playerLevel < 14 then
						Print("WARNING", playerClassEN, "Required level for class-spell based rangecheck is 14.");
					elseif playerClassEN == "ROGUE" and playerLevel < 12 then
						Print("WARNING", playerClassEN, "Required level for class-spell based rangecheck is 12.");
					else
						Print("ERROR", "unknown spell (rangecheck)", locale, playerClassEN, "id:", ranges[playerClassEN]);
					end
				else
					Print("ERROR", "unknown class (rangecheck)", locale, playerClassEN);
				end
			end
		end
		
		BattlegroundTargets:RegisterEvent("UPDATE_BATTLEFIELD_SCORE");
		BattlegroundTargets:BattlefieldScoreRequest();
		
		local frequency = 1;   --   0-20 updates = 1 second
		local elapsed 	= 0 ;  --   21-60 updates = 2 seconds
		local count 	= 0;   --   61+   updates = 5 seconds
		
		GVAR.MainFrame:SetScript("OnUpdate", function(self, elap)
			elapsed = elapsed + elap;
			if(elapsed < frequency) then return; end
			
			elapsed = 0;
			if(count > 60) then
				frequency = 5;
			elseif(count > 20) then
				frequency = 2;
				count = count + 1;
			else
				count = count + 1;
			end
			
			BattlegroundTargets:BattlefieldScoreRequest();
		end);
	end
end

function BattlegroundTargets:IsNotBattleground()
	if not (inBattleground or reCheckBG or BattlegroundTargets_Character.TempFaction) then return end
	inBattleground      = false;
	reSizeCheck         = 0;
	oppositeFactionREAL = nil;
	isFlagBG            = 0;
	flagCHK             = nil;
	flagflag            = nil;
	scoreUpdateCount    = 0;
	isLeader            = nil;
	isHealer            = nil;
	hasFlag             = nil;
	reCheckBG           = nil;
	reCheckScore        = nil;
	factionIsValid      = false;
	icoMinimapFactionBG = nil;
	BattlegroundTargets_Character.TempFaction = nil;
	local factionID = BattlegroundTargets:NameFactionToNumber(BattlegroundTargets_Character.NativeFaction);
	MiniMapBattlefieldIcon:SetTexture(battleFieldIconTextures[factionID])
	MiniMapBattlefieldFrame:SetNormalTexture(battleFieldIconTextures[factionID])
	if OPT.ButtonShowHealer[10] or OPT.ButtonShowHealer[15] or OPT.ButtonShowHealer[40] then
		if hdlog or BattlegroundTargets_Options.hdlog then BattlegroundTargets:HDreport() end;
		local DBisEnable = BattlegroundTargets_Options.DB and BattlegroundTargets_Options.DB.outOfDateRange and BattlegroundTargets_Options.DB.outOfDateRange > 0;
		if DBisEnable and next(ENEMY_Healers) then
			for name, data in pairs(ENEMY_Healers) do
				if (type(data) == "table") then
					if ENEMY_Healers[name].DBstatus <= 0 and ENEMY_Healers[name].status == 2 then 
						local unit = {};
						unit.name  = name;
						unit.class = data.class;
						DBUtils:insertNewUnit(BattlegroundTargets_HealersDB, unit)
					end

				end
			end
		end
	end

	BattlegroundTargets:CheckPlayerLevel();
	
	BattlegroundTargets:UnregisterEvent("PLAYER_DEAD");
	BattlegroundTargets:UnregisterEvent("PLAYER_UNGHOST");
	BattlegroundTargets:UnregisterEvent("PLAYER_ALIVE");
	BattlegroundTargets:UnregisterEvent("UNIT_HEALTH_FREQUENT");
	BattlegroundTargets:UnregisterEvent("UPDATE_MOUSEOVER_UNIT");
	BattlegroundTargets:UnregisterEvent("UNIT_TARGET");
	BattlegroundTargets:UnregisterEvent("PLAYER_TARGET_CHANGED");
	BattlegroundTargets:UnregisterEvent("PLAYER_FOCUS_CHANGED");
	BattlegroundTargets:UnregisterEvent("CHAT_MSG_BG_SYSTEM_HORDE");
	BattlegroundTargets:UnregisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE");
	BattlegroundTargets:UnregisterEvent("RAID_ROSTER_UPDATE");
	BattlegroundTargets:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	BattlegroundTargets:UnregisterEvent("UPDATE_BATTLEFIELD_SCORE");
	
	if(not isConfig) then
		table_wipe(ENEMY_Data);
	end
	
	table_wipe(ENEMY_Names);
	table_wipe(ENEMY_Names4Flag);
	table_wipe(ENEMY_Name2Button);
	table_wipe(ENEMY_Name2Percent);
	table_wipe(ENEMY_Name2Range);
	table_wipe(ENEMY_Name2Level);
	table_wipe(TARGET_Names);
	table_wipe(ENEMY_Healers);
	
	GVAR.MainFrame:SetScript("OnUpdate", nil);
	
	if(inCombat or InCombatLockdown()) then
		reCheckBG = true;
	else
		reCheckBG = false;
		GVAR.MainFrame:Hide();
		local flagIcon = "Interface\\WorldStateFrame\\AllianceFlag";
		if(playerFactionDEF == 0) then
			flagIcon = "Interface\\WorldStateFrame\\HordeFlag";
		end
		for i = 1, 40 do
			local GVAR_TargetButton = GVAR.TargetButton[i];
			GVAR_TargetButton.FlagTexture:SetTexture(flagIcon);
			GVAR_TargetButton:Hide();
		end
	end
end

function BattlegroundTargets:CheckPlayerTarget()
	if(isConfig) then return; end
	targetName, targetRealm = UnitName("target");
	if targetRealm and targetRealm ~= "" then
		targetName = targetName.."-"..targetRealm;
	end
	for i = 1, currentSize do
		local GVAR_TargetButton = GVAR.TargetButton[i];
		GVAR_TargetButton.TargetTexture:SetAlpha(0);
		GVAR_TargetButton.HighlightT:SetTexture(0, 0, 0, 1);
		GVAR_TargetButton.HighlightR:SetTexture(0, 0, 0, 1);
		GVAR_TargetButton.HighlightB:SetTexture(0, 0, 0, 1);
		GVAR_TargetButton.HighlightL:SetTexture(0, 0, 0, 1);
	end
	isTarget = 0;
	if(not targetName) then return; end
	local targetButton = ENEMY_Name2Button[targetName];
	if(not targetButton) then return; end
	local GVAR_TargetButton = GVAR.TargetButton[targetButton];
	if(not GVAR_TargetButton) then return; end
	if OPT.ButtonShowTarget[currentSize] then
		GVAR_TargetButton.TargetTexture:SetAlpha(1);
		GVAR_TargetButton.HighlightT:SetTexture(0.5, 0.5, 0.5, 1);
		GVAR_TargetButton.HighlightR:SetTexture(0.5, 0.5, 0.5, 1);
		GVAR_TargetButton.HighlightB:SetTexture(0.5, 0.5, 0.5, 1);
		GVAR_TargetButton.HighlightL:SetTexture(0.5, 0.5, 0.5, 1);
		isTarget = targetButton;
	end
	if(isDeadUpdateStop) then return; end
	BattlegroundTargets:CheckUnitTarget("player", targetName);
end

function BattlegroundTargets:CheckAssist()
	if(isConfig) then return; end
	isAssistUnitId = nil;
	isAssistName = nil;
	for i = 1, GetNumRaidMembers() do
		local name, _, _, _, _, _, _, _, _, role = GetRaidRosterInfo(i);
		if(name and role and role == "MAINASSIST") then
			isAssistName = name;
			isAssistUnitId = "raid"..i.."target";
			
			break;
		end
	end
	for i = 1, currentSize do
		GVAR.TargetButton[i].AssistTexture:SetAlpha(0);
	end
	if(not isAssistName) then return; end
	assistTargetName, assistTargetRealm = UnitName(isAssistUnitId);
	if(assistTargetRealm and assistTargetRealm ~= "") then
		assistTargetName = assistTargetName.."-"..assistTargetRealm;
	end
	if(not assistTargetName) then return; end
	local assistButton = ENEMY_Name2Button[assistTargetName];
	if(not assistButton) then return; end
	if(not GVAR.TargetButton[assistButton]) then return; end
	if(OPT.ButtonShowAssist[currentSize]) then
		GVAR.TargetButton[assistButton].AssistTexture:SetAlpha(1);
	end
end

function BattlegroundTargets:CheckPlayerFocus()
	if(isConfig) then return; end
	focusName, focusRealm = UnitName("focus");
	if(focusRealm and focusRealm ~= "") then
		focusName = focusName.."-"..focusRealm;
	end
	for i = 1, currentSize do
		GVAR.TargetButton[i].FocusTexture:SetAlpha(0);
	end
	if(not focusName) then return; end
	local focusButton = ENEMY_Name2Button[focusName];
	if(not focusButton) then return; end
	local GVAR_TargetButton = GVAR.TargetButton[focusButton];
	if(not GVAR_TargetButton) then return; end
	if(OPT.ButtonShowFocus[currentSize]) then
		GVAR_TargetButton.FocusTexture:SetAlpha(1);
	end
	if(rangeSpellName and OPT.ButtonTypeRangeCheck[currentSize] >= 2) then
		local curTime = GetTime();
		local Name2Range = ENEMY_Name2Range[focusName];
		if(Name2Range) then
			if(Name2Range + range_SPELL_Frequency > curTime) then return; end
		end
		local healerState = OPT.ButtonShowHealer[currentSize] and true;
		if(IsSpellInRange(rangeSpellName, "focus") == 1) then
			ENEMY_Name2Range[focusName] = curTime;
			Range_Display(true, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], healerState);
		else
			ENEMY_Name2Range[focusName] = nil;
			Range_Display(false, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], healerState);
		end
	end
end

function BattlegroundTargets:CheckUnitTarget(unitID, unitName)
	if(isConfig) then return; end

	local friendName, friendRealm, enemyID, enemyName, enemyRealm;
	if(not unitName) then
		enemyID = unitID.."target";
		
		friendName, friendRealm = UnitName(unitID);
		if(friendRealm and friendRealm ~= "") then
			friendName = friendName.."-"..friendRealm
		end
		
		enemyName, enemyRealm = UnitName(enemyID);
		if(enemyRealm and enemyRealm ~= "") then
			enemyName = enemyName.."-"..enemyRealm;
		end
	else
		enemyID    = "target";
		friendName = playerName;
		enemyName  = unitName;
	end
	
	local curTime = GetTime();
	
	if(flagCHK and isFlagBG > 0) then
		if(OPT.ButtonShowFlag[currentSize]) then
			BattlegroundTargets:CheckFlagCarrierCHECK(enemyID, enemyName);
		end
	end
	
	if(OPT.ButtonShowTargetCount[currentSize]) then
		if(curTime > targetCountForceUpdate + targetCountFrequency) then
			targetCountForceUpdate = curTime;
			table_wipe(TARGET_Names);
			
			for num = 1, GetNumRaidMembers() do
				local uID = "raid"..num;
				
				local fName, fRealm = UnitName(uID);
				if(fName) then
					if(fRealm and fRealm ~= "") then
						fName = fName.."-"..fRealm;
					end
					
					local eName, eRealm = UnitName(uID.."target");
					if(eName) then
						if(eRealm and eRealm ~= "") then
							eName = eName.."-"..eRealm;
						end
						
						if(ENEMY_Names[eName]) then
							TARGET_Names[fName] = eName;
						end
					end
				end
			end
		else
			if(friendName) then
				if(ENEMY_Names[enemyName]) then
					TARGET_Names[friendName] = enemyName;
				else
					TARGET_Names[friendName] = nil;
				end
			end
		end
		
		for eName in pairs(ENEMY_Names) do
			ENEMY_Names[eName] = 0;
		end
		
		for _, eName in pairs(TARGET_Names) do
			if(ENEMY_Names[eName]) then
				ENEMY_Names[eName] = ENEMY_Names[eName] + 1;
			end
		end
		
		for i = 1, currentSize do
			if(ENEMY_Data[i]) then
				local count = ENEMY_Names[ ENEMY_Data[i].name ];
				if count then
					GVAR.TargetButton[i].TargetCount:SetText(count);
				end
			else
				GVAR.TargetButton[i].TargetCount:SetText("");
			end
		end
	end
	
	if(not ENEMY_Names[enemyName]) then return; end

	local GVAR_TargetButton;
	if(enemyName) then
		local enemyButton = ENEMY_Name2Button[enemyName];
		if(enemyButton) then
			GVAR_TargetButton = GVAR.TargetButton[enemyButton];
		end
	end
	
	if(OPT.ButtonShowHealthBar[currentSize] or OPT.ButtonShowHealthText[currentSize]) then
		if(enemyID and enemyName) then
			BattlegroundTargets:CheckUnitHealth(enemyID, enemyName, 1);
		end
	end
	
	if(isAssistName and OPT.ButtonShowAssist[currentSize]) then
		if(curTime > assistForceUpdate + assistFrequency) then
			assistForceUpdate = curTime;
			
			assistTargetName, assistTargetRealm = UnitName(isAssistUnitId);
			if(assistTargetRealm and assistTargetRealm ~= "") then
				assistTargetName = assistTargetName.."-"..assistTargetRealm;
			end
			
			for i = 1, currentSize do
				GVAR.TargetButton[i].AssistTexture:SetAlpha(0);
			end
			
			if(assistTargetName) then
				local assistButton = ENEMY_Name2Button[assistTargetName];
				if(assistButton) then
					local button = GVAR.TargetButton[assistButton];
					if(button) then
						button.AssistTexture:SetAlpha(1);
					end
				end
			end
		elseif(friendName and isAssistName == friendName) then
			for i = 1, currentSize do
				GVAR.TargetButton[i].AssistTexture:SetAlpha(0);
			end
			
			if(GVAR_TargetButton) then
				assistTargetName = enemyName;
				GVAR_TargetButton.AssistTexture:SetAlpha(1);
			end
		end
	end
	
	if(OPT.ButtonShowLeader[currentSize]) then
		if(GVAR_TargetButton) then
			if(isLeader) then
				leaderThrottle = leaderThrottle + 1;
				
				if(leaderThrottle > leaderFrequency) then
					leaderThrottle = 0
					
					if(UnitIsPartyLeader(enemyID)) then
						isLeader = enemyName;
						
						for i = 1, currentSize do
							GVAR.TargetButton[i].LeaderTexture:SetAlpha(0);
						end
						GVAR_TargetButton.LeaderTexture:SetAlpha(0.75);
					else
						GVAR_TargetButton.LeaderTexture:SetAlpha(0);
					end
				end
			else
				if(UnitIsPartyLeader(enemyID)) then
					isLeader = enemyName;
					
					for i = 1, currentSize do
						GVAR.TargetButton[i].LeaderTexture:SetAlpha(0);
					end
					
					GVAR_TargetButton.LeaderTexture:SetAlpha(0.75);
				else
					GVAR_TargetButton.LeaderTexture:SetAlpha(0);
				end
			end
		end
	end

	if (OPT.ButtonShowHealer[currentSize]) then
		if(enemyID and enemyName) then
			local _, uClass = UnitClass(enemyID);
			BattlegroundTargets:CheckEnemyHealer(enemyName, uClass, enemyID);
		end
	end
	
	if(isLowLevel) then
		local level = UnitLevel(enemyID) or 0;
		
		if level > 0 then
			ENEMY_Name2Level[enemyName] = level;
			
			if GVAR_TargetButton then
				GVAR_TargetButton.Name:SetText(level.." "..GVAR_TargetButton.name4button);
			end
		end
	end
	
	if(rangeSpellName and OPT.ButtonTypeRangeCheck[currentSize] >= 2) then
		if(GVAR_TargetButton) then
			local Name2Range = ENEMY_Name2Range[enemyName];
			
			if(Name2Range) then
				if(Name2Range + range_SPELL_Frequency > curTime) then return; end
			end
			
			if(IsSpellInRange(rangeSpellName, enemyID) == 1) then
				ENEMY_Name2Range[enemyName] = curTime;
				Range_Display(true, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize]);
			else
				ENEMY_Name2Range[enemyName] = nil;
				Range_Display(false, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize]);
			end
		end
	end
end

function BattlegroundTargets:CheckUnitHealth(unitID, unitName, healthonly)
	if(isConfig) then return; end

	local targetID, targetName, targetRealm;
	if(not unitName) then
		if(raidUnitID[unitID]) then
			targetID = unitID.."target";
		elseif(playerUnitID[unitID]) then
			targetID = unitID;
		else
			return;
		end
		
		targetName, targetRealm = UnitName(targetID);
		if(targetRealm and targetRealm ~= "") then
			targetName = targetName.."-"..targetRealm;
		end
	else
		targetID = unitID;
		targetName = unitName;
	end
	
	if(not targetName) then return; end
	
	local targetButton = ENEMY_Name2Button[targetName];
	if(not targetButton) then return; end
	
	local GVAR_TargetButton = GVAR.TargetButton[targetButton];
	if(not GVAR_TargetButton) then return; end
	
	local ButtonShowHealthBar  = OPT.ButtonShowHealthBar[currentSize];
	local ButtonShowHealthText = OPT.ButtonShowHealthText[currentSize];
	
	if(ButtonShowHealthBar or ButtonShowHealthText) then
		local maxHealth = UnitHealthMax(targetID);
		
		if(maxHealth) then
			local health = UnitHealth(targetID);
			
			if(health) then
				local width = 0.01;
				local percent = 0;
				
				if(maxHealth > 0 and health > 0) then
					local hvalue = maxHealth / health;
					width = healthBarWidth / hvalue;
					width = math_max(0.01, width);
					width = math_min(healthBarWidth, width);
					percent = math_floor( (100/hvalue) + 0.5 );
					percent = math_max(0, percent);
					percent = math_min(100, percent);
				end
				
				ENEMY_Name2Percent[targetName] = percent;
				
				if(ButtonShowHealthBar) then
					GVAR_TargetButton.HealthBar:SetWidth(width);
				end
				
				if(ButtonShowHealthText) then
					GVAR_TargetButton.HealthText:SetText(percent);
				end
			end
		end
	end
	
	if(healthonly) then return; end
	
	if(flagCHK and isFlagBG > 0) then
		if(OPT.ButtonShowFlag[currentSize]) then
			BattlegroundTargets:CheckFlagCarrierCHECK(targetID, targetName);
		end
	end
	
	if(rangeSpellName and OPT.ButtonTypeRangeCheck[currentSize] >= 2) then
		local curTime = GetTime();
		local Name2Range = ENEMY_Name2Range[targetName];
		
		if(Name2Range) then
			if(Name2Range + range_SPELL_Frequency > curTime) then return; end
		end
		
		if(IsSpellInRange(rangeSpellName, targetID) == 1) then
			ENEMY_Name2Range[targetName] = curTime;
			Range_Display(true, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize]);
		else
			ENEMY_Name2Range[targetName] = nil;
			Range_Display(false, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize]);
		end
	end
end

function BattlegroundTargets:FlagCheck(message, messageFaction)
	if messageFaction == playerFactionBG then
		if string_match(message, FLG["WSG_TP_MATCH_CAPTURED"]) or message == FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] or message == FLG["EOTS_STRING_CAPTURED_BY_HORDE"] then
			for i = 1, currentSize do GVAR.TargetButton[i].FlagTexture:SetAlpha(0) end
			hasFlag = nil
			if flagCHK then BattlegroundTargets:CheckFlagCarrierEND() end
		elseif string_match(message, FLG["WSG_TP_MATCH_DROPPED"]) then
			for i = 1, currentSize do GVAR.TargetButton[i].FlagTexture:SetAlpha(0) end
			hasFlag = nil
		end
	else
		local efc = string_match(message, FLG["WSG_TP_REGEX_PICKED1"]) or string_match(message, FLG["WSG_TP_REGEX_PICKED2"]) or string_match(message, FLG["EOTS_REGEX_PICKED"])
		if efc then
			for i = 1, currentSize do GVAR.TargetButton[i].FlagTexture:SetAlpha(0) end
			if flagCHK then BattlegroundTargets:CheckFlagCarrierEND() end
			for name, button in pairs(ENEMY_Names4Flag) do
				if name == efc then
					local GVAR_TargetButton = GVAR.TargetButton[button];
					if GVAR_TargetButton then
						GVAR_TargetButton.FlagTexture:SetAlpha(1)
						for fullname, fullnameButton in pairs(ENEMY_Name2Button) do
							if button == fullnameButton then
								hasFlag = fullname
								return
							end
						end
					end
					return
				end
			end
		elseif string_match(message, FLG["WSG_TP_MATCH_CAPTURED"]) or message == FLG["EOTS_STRING_CAPTURED_BY_ALLIANCE"] or message == FLG["EOTS_STRING_CAPTURED_BY_HORDE"] then
			for i = 1, currentSize do GVAR.TargetButton[i].FlagTexture:SetAlpha(0) end
			hasFlag = nil
			if flagCHK then BattlegroundTargets:CheckFlagCarrierEND() end
		elseif string_match(message, FLG["EOTS_STRING_DROPPED"]) then
			for i = 1, currentSize do GVAR.TargetButton[i].FlagTexture:SetAlpha(0) end
			hasFlag = nil		
		end
	end
end

local function CombatLogRangeCheck(sourceName, destName, spellID)
	if not SPELL_Range[spellID] then
		local name, _, _, _, _, _, _, _, maxRange = GetSpellInfo(spellID) -- local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellID)
		if not maxRange then return end
		SPELL_Range[spellID] = maxRange
	end

	if OPT.ButtonTypeRangeCheck[currentSize] == 4 then
		
		if SPELL_Range[spellID] > rangeMax then return end
		if SPELL_Range[spellID] < rangeMin then return end

		-- enemy attack player
		if ENEMY_Names[sourceName] then
			if destName == playerName then

				if ENEMY_Name2Percent[sourceName] == 0 then
					ENEMY_Name2Range[sourceName] = nil
					local sourceButton = ENEMY_Name2Button[sourceName]
					if sourceButton then
						local GVAR_TargetButton = GVAR.TargetButton[sourceButton]
						if GVAR_TargetButton then
							Range_Display(false, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize])
						end
					end
					return
				end

				local curTime = GetTime()
				ENEMY_Name2Range[sourceName] = curTime
				local sourceButton = ENEMY_Name2Button[sourceName]
				if sourceButton then
					local GVAR_TargetButton = GVAR.TargetButton[sourceButton]
					if GVAR_TargetButton then
						Range_Display(true, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize])
					end
				end
				if range_CL_DisplayThrottle + range_CL_DisplayFrequency > curTime then return end
				range_CL_DisplayThrottle = curTime
				BattlegroundTargets:UpdateRange(curTime)
			end
		end

	elseif OPT.ButtonTypeRangeCheck[currentSize] == 3 then

		if SPELL_Range[spellID] > 45 then return end

		-- enemy attack player
		if ENEMY_Names[sourceName] then
			if destName == playerName then

				if ENEMY_Name2Percent[sourceName] == 0 then
					ENEMY_Name2Range[sourceName] = nil
					local sourceButton = ENEMY_Name2Button[sourceName]
					if sourceButton then
						local GVAR_TargetButton = GVAR.TargetButton[sourceButton]
						if GVAR_TargetButton then
							Range_Display(false, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize])
						end
					end
					return
				end

				local curTime = GetTime()
				ENEMY_Name2Range[sourceName] = curTime
				local sourceButton = ENEMY_Name2Button[sourceName]
				if sourceButton then
					local GVAR_TargetButton = GVAR.TargetButton[sourceButton]
					if GVAR_TargetButton then
						Range_Display(true, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize])
					end
				end
				if range_CL_DisplayThrottle + range_CL_DisplayFrequency > curTime then return end
				range_CL_DisplayThrottle = curTime
				BattlegroundTargets:UpdateRange(curTime)
			end
		end

	else--if OPT.ButtonTypeRangeCheck[currentSize] == 1 then
		if SPELL_Range[spellID] > 45 then return end

		-- enemy attack friend
		if ENEMY_Names[sourceName] then
			
			if destName == playerName then
				ENEMY_Name2Range[sourceName] = GetTime()
				local sourceButton = ENEMY_Name2Button[sourceName]
				if sourceButton then
					local GVAR_TargetButton = GVAR.TargetButton[sourceButton]
					if GVAR_TargetButton then
						Range_Display(true, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize])
					end
				end
			elseif FRIEND_Names[destName] then
				local curTime = GetTime()
				if CheckInteractDistance(destName, 1) then -- 1:Inspect=28
					ENEMY_Name2Range[sourceName] = curTime
				end
				if range_CL_DisplayThrottle + range_CL_DisplayFrequency > curTime then return end
				range_CL_DisplayThrottle = curTime
				BattlegroundTargets:UpdateRange(curTime)
			end
		-- friend attack enemy
		elseif ENEMY_Names[destName] then
			if sourceName == playerName then
				ENEMY_Name2Range[destName] = GetTime()
				local destButton = ENEMY_Name2Button[destName]
				if destButton then
					local GVAR_TargetButton = GVAR.TargetButton[destButton]
					if GVAR_TargetButton then
						Range_Display(true, GVAR_TargetButton, OPT.ButtonRangeDisplay[currentSize], OPT.ButtonShowHealer[currentSize])
					end
				end
			elseif FRIEND_Names[sourceName] then
				local curTime = GetTime()
				if CheckInteractDistance(sourceName, 1) then -- 1:Inspect=28
					ENEMY_Name2Range[destName] = curTime
				end
				if range_CL_DisplayThrottle + range_CL_DisplayFrequency > curTime then return end
				range_CL_DisplayThrottle = curTime
				BattlegroundTargets:UpdateRange(curTime)
			end
		end

	end

end

function BattlegroundTargets:UpdateRange(curTime)
	if(isDeadUpdateStop) then
		BattlegroundTargets:ClearRangeData();
		return;
	end
	local healerState = OPT.ButtonShowHealer[currentSize] and true;
	local ButtonRangeDisplay = OPT.ButtonRangeDisplay[currentSize];
	for i = 1, currentSize do
		Range_Display(false, GVAR.TargetButton[i], ButtonRangeDisplay, healerState);
	end
	for name, timeStamp in pairs(ENEMY_Name2Range) do
		local button = ENEMY_Name2Button[name]
		if not button then
			ENEMY_Name2Range[name] = nil
		elseif ENEMY_Name2Percent[name] == 0 then
			ENEMY_Name2Range[name] = nil
		elseif timeStamp + range_DisappearTime < curTime then
			ENEMY_Name2Range[name] = nil
		else
			local GVAR_TargetButton = GVAR.TargetButton[button]
			if GVAR_TargetButton then
				Range_Display(true, GVAR_TargetButton, ButtonRangeDisplay, healerState)
			end
		end
	end
end

function BattlegroundTargets:ClearRangeData()
	if(OPT.ButtonRangeCheck[currentSize]) then
		table_wipe(ENEMY_Name2Range);
		local ButtonRangeDisplay = OPT.ButtonRangeDisplay[currentSize];
		for i = 1, currentSize do
			Range_Display(false, GVAR.TargetButton[i], ButtonRangeDisplay, OPT.ButtonShowHealer[currentSize]);
		end
	end
end

function BattlegroundTargets:CheckPlayerLevel()
	if(playerLevel == maxLevel) then
		isLowLevel = nil;
		BattlegroundTargets:UnregisterEvent("PLAYER_LEVEL_UP");
	elseif(playerLevel < maxLevel) then
		isLowLevel = true;
		BattlegroundTargets:RegisterEvent("PLAYER_LEVEL_UP");
	else
		isLowLevel = nil;
		BattlegroundTargets:UnregisterEvent("PLAYER_LEVEL_UP");
	end
end

function BattlegroundTargets:CheckNativeFaction()
	if(BattlegroundTargets_Character.NativeFaction == "Horde") then
		playerFactionDEF = 0;
		oppositeFactionDEF = 1;
	else
		playerFactionDEF = 1;
		oppositeFactionDEF = 0;
	end
	playerFactionBG   = playerFactionDEF;
	oppositeFactionBG = oppositeFactionDEF;
end

function BattlegroundTargets:CheckIfPlayerIsGhost()
	if(not inBattleground) then return end
	if UnitIsGhost("player") then
		isDeadUpdateStop = true	
		BattlegroundTargets:ClearRangeData()
	else
		isDeadUpdateStop = false
	end
end

function BattlegroundTargets:BattlefieldScoreRequest()
	local wssf = WorldStateScoreFrame
	if wssf and wssf:IsShown() then
		return
	end
	SetBattlefieldScoreFaction()
	RequestBattlefieldScoreData()
end

local function OnEvent(a1, a2, a3, a4, a5, a6, a7, a8, a9)
	local self, event
	if type(a1) == "table" and type(a2) == "string" then
		self = a1
		event = a2
	else
		self = this or BattlegroundTargets
		event = a1 or _G.event
	end
	local ev_arg1 = _G.arg1 or (self == a1 and a3 or a2)

	if event == "PLAYER_REGEN_DISABLED" then
		inCombat = true
		if isConfig then
			if not inWorld then return end
			BattlegroundTargets:DisableInsecureConfigWidges()
		end

	elseif event == "PLAYER_REGEN_ENABLED" then
		inCombat = false
		if reCheckScore or reCheckBG then
			if not inWorld then return end
			BattlegroundTargets:BattlefieldScoreRequest()
		end
		if reSetLayout then
			if not inWorld then return; end
			BattlegroundTargets:SetupButtonLayout()
		end
		if isConfig then
			if not inWorld then return end
			BattlegroundTargets:EnableInsecureConfigWidges()
			if BattlegroundTargets_Options.EnableBracket[currentSize] then
				BattlegroundTargets:EnableConfigMode()
			else
				BattlegroundTargets:DisableConfigMode()
			end
		end

	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if isConfig or isDeadUpdateStop then return end
		--local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool = ...	
		local _, _, _, sourceName, _, _, destName, _, spellID = ...
		if not sourceName or not destName or not spellID then return end
		BattlegroundTargets:DetectHealerByAOEBuffs(...)
		if not OPT.ButtonRangeCheck[currentSize] then return end
		if sourceName == destName then return end
		range_CL_Throttle = range_CL_Throttle + 1
		if range_CL_Throttle > range_CL_Frequency then
			range_CL_Throttle = 0
			range_CL_Frequency = math_random(1,3)
			return
		end
		CombatLogRangeCheck(sourceName, destName, spellID)

	elseif event == "UNIT_HEALTH_FREQUENT" then
		if isDeadUpdateStop then return end
		local arg1 = ev_arg1
		BattlegroundTargets:CheckUnitHealth(arg1)

	elseif event == "UNIT_TARGET" then
		if isDeadUpdateStop then return end
		local arg1 = ev_arg1
		if not raidUnitID[arg1] then return end
		BattlegroundTargets:CheckUnitTarget(arg1)

	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		if isDeadUpdateStop then return end
		BattlegroundTargets:CheckUnitHealth("mouseover")

	elseif event == "PLAYER_TARGET_CHANGED" then
		BattlegroundTargets:CheckPlayerTarget()

	elseif event == "PLAYER_FOCUS_CHANGED" then
		BattlegroundTargets:CheckPlayerFocus()

	elseif event == "UPDATE_BATTLEFIELD_SCORE" then
		if isConfig then return end
		BattlegroundTargets:BattlefieldScoreUpdate()

	elseif event == "RAID_ROSTER_UPDATE" then
		if OPT.ButtonShowAssist[currentSize] then
			BattlegroundTargets:CheckAssist()
		end

	elseif event == "CHAT_MSG_BG_SYSTEM_HORDE" then
		local arg1 = ev_arg1
		BattlegroundTargets:FlagCheck(arg1, 0)

	elseif event == "CHAT_MSG_BG_SYSTEM_ALLIANCE" then
		local arg1 = ev_arg1
		BattlegroundTargets:FlagCheck(arg1, 1)

	--[[ elseif event == "CHAT_MSG_RAID_BOSS_EMOTE" then
		local arg1 = ...
		if arg1 then
			BattlegroundTargets:ParseFactionFromMSG(arg1)
		end ]]	

	elseif event == "PLAYER_DEAD" then
		if not inBattleground then return end
		isDeadUpdateStop = false

	elseif event == "PLAYER_UNGHOST" then
		if not inBattleground then return end
		isDeadUpdateStop = false

	elseif event == "PLAYER_ALIVE" then
		BattlegroundTargets:CheckIfPlayerIsGhost()

	elseif event == "ZONE_CHANGED_NEW_AREA" then
		if not inWorld then return end
		if isConfig then return end
		BattlegroundTargets:BattlefieldCheck()

	elseif event == "PLAYER_LEVEL_UP" then
		local arg1 = ev_arg1
		if arg1 then
			playerLevel = arg1
			BattlegroundTargets:CheckPlayerLevel()
		end

	elseif event == "PLAYER_LOGIN" then
		BattlegroundTargets:CheckNativeFaction()
		BattlegroundTargets:InitOptions()
		BattlegroundTargets:CreateInterfaceOptions()
		BattlegroundTargets:LDBcheck()
		BattlegroundTargets:CreateFrames()
		BattlegroundTargets:CreateOptionsFrame()
		RegisterBGH_Notifier() -- by Khal
		if IsShowHealers then
			if BattlegroundTargets_Options.hdlog then
				Print(L["Permanent logging of healers detection is enabled. Type |cff55c912/bgt hdlogAlways|r again to disable."])
			end
			if BattlegroundTargets_Options.DB and BattlegroundTargets_Options.DB.outOfDateRange and BattlegroundTargets_Options.DB.outOfDateRange > 0 then
				DBUtils:CheckHealersDataBase(BattlegroundTargets_HealersDB)
			end
		end
		hooksecurefunc("PanelTemplates_SetTab", function(frame)
			if frame and frame == WorldStateScoreFrame then
				BattlegroundTargets:ScoreWarningCheck()
			end
		end)
		table.insert(UISpecialFrames, "BattlegroundTargets_OptionsFrame")
		BattlegroundTargets:UnregisterEvent("PLAYER_LOGIN")

	elseif event == "PLAYER_ENTERING_WORLD" then 
		inWorld = true
		BattlegroundTargets:CheckPlayerLevel()
		BattlegroundTargets:BattlefieldCheck()
		BattlegroundTargets:CheckIfPlayerIsGhost()
		BattlegroundTargets:CreateMinimapButton()
		if not BattlegroundTargets_Options.FirstRun then
			BattlegroundTargets:Frame_Toggle(GVAR.OptionsFrame)
			BattlegroundTargets_Options.FirstRun = true
		end
		BattlegroundTargets:UnregisterEvent("PLAYER_ENTERING_WORLD");
	end
end

BattlegroundTargets:RegisterEvent("PLAYER_REGEN_DISABLED")
BattlegroundTargets:RegisterEvent("PLAYER_REGEN_ENABLED")
BattlegroundTargets:RegisterEvent("ZONE_CHANGED_NEW_AREA")
BattlegroundTargets:RegisterEvent("PLAYER_LOGIN")
BattlegroundTargets:RegisterEvent("PLAYER_ENTERING_WORLD")
--BattlegroundTargets:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
BattlegroundTargets:SetScript("OnEvent", OnEvent)
