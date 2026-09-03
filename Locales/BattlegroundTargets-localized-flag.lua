BattlegroundTargets_Flag = {};

function BattlegroundTargets_Flag:CreateLocaleTable(t)
	for k,v in pairs(t) do
		self[k] = (v == true and k) or v;
	end
end

BattlegroundTargets_Flag:CreateLocaleTable({
	-- # Warsong Gulch:
	["WSG_TP_REGEX_PICKED1"] = "was picked up by (.+)!",
	["WSG_TP_REGEX_PICKED2"] = "was picked up by (.+)!",
	["WSG_TP_MATCH_DROPPED"] = "was dropped",
	["WSG_TP_MATCH_CAPTURED"] = "captured the",
});
