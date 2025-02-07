--[[--
	MADE WITH HELP FROM SILVER SOKOLOVA.

	I REPEAT.

	MADE WITH HELP FROM SILVER SOKOLOVA.

	U W U ~ SILVER SOKOLOVA.
--]]--

local originalUpdate = update or function(...) end
function update(...)
	
	if not knightfallActivatePersistentEffects then
		local npcType = config.getParameter("kf-npcType")
		local statusEffects = config.getParameter("kf-persistentStatusEffects", {})
		local statList = config.getParameter("kf-statList", "knightfall_carrier_statlist")

		if npcType and string.find(npc.npcType() , npcType) then
			status.addPersistentEffects(statList, statusEffects)
		end
		
		knightfallActivatePersistentEffects = true
	end
	
	originalUpdate(...)
end