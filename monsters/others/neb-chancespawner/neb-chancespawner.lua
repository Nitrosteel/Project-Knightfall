function init()
  local spawnConfig = config.getParameter("neb-toSpawn")
  for _, data in ipairs(spawnConfig) do
    if math.random() <= data.weight then
      if data.monsterType then
        world.spawnMonster(data.monsterType[math.random(#data.monsterType)], entity.position(),
          {
            aggressive = config.getParameter("aggressive", true),
            damageTeam = entity.damageTeam().team,
            level = monster.level() or world.threatLevel() or 1
          }
        )
      elseif data.npcType and data.npcSpecies then
        world.spawnNpc(entity.position(), data.npcSpecies[math.random(#data.npcSpecies)], data.npcType[math.random(#data.npcType)], monster.level() or world.threatLevel() or 1, nil,
          {
            aggressive = config.getParameter("aggressive", true),
            damageTeam = entity.damageTeam().team
          }
        )
      else
        sb.logWarn("nebnitro-changespawner.lua - No entity spawn identified!")
      end
    end
  end
end