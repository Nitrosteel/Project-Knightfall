--[[--
	MADE WITH HELP FROM SILVER SOKOLOVA.

	I REPEAT.

	MADE WITH HELP FROM SILVER SOKOLOVA.

	U W U ~ SILVER SOKOLOVA.
--]]--

local ini = init or function() end
function init()
	ini()
	
	local npcType = config.getParameter("kf-npcType")
	local statusEffects = config.getParameter("kf-persistentStatusEffects", {})
	local statList = config.getParameter("kf-statList", "knightfall_carrier_statlist")

	if npcType and string.find(npc.npcType() , npcType) then
		status.addPersistentEffects(statList, statusEffects)
	end
end