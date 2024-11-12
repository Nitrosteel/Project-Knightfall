--[[--
	MADE WITH HELP FROM SILVER SOKOLOVA.

	I REPEAT.

	MADE WITH HELP FROM SILVER SOKOLOVA.

	U W U ~ SILVER SOKOLOVA.
--]]--

local ini = init or function() end
function init()
	ini()

	if string.find(npc.npcType() , "knightfall") then
		status.addPersistentEffects("knightfall_crew_statlist", config.getParameter("kf-persistentStatusEffects", {}))
	end
end