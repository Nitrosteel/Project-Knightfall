
--[[-- TODO AAAA --]]--

function init()
  script.setUpdateDelta(0)
  status.setStatusProperty("kf.isEphemeral", true)

  self.isMonster = entity.entityType() == "monster"

  local inEffect = self.isMonster and config.getParameter("monsterInEffect", "") or config.getParameter("npcInEffect")
  if inEffect and inEffect ~= "" then status.addEphemeralEffect(inEffect) end
end

function uninit()
  local outEffect = self.isMonster and config.getParameter("monsterOutEffect", "") or config.getParameter("npcOutEffect")
  if outEffect and outEffect ~= "" then status.addEphemeralEffect(outEffect) end

  if self.isMonster then
    -- remove monster drops and death sound
    world.sendEntityMessage(entity.id(), "despawn")
  end
  status.setResource("health",0)
end
