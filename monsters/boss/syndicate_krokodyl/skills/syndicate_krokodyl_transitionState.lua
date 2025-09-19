syndicate_krokodyl_transitionState = {}

function syndicate_krokodyl_transitionState.enterWith(args)
  if not args or not args.enteringPhase then return nil end

  return {
    idleTimer = config.getParameter("syndicate_krokodyl_transitionState.idleTime", 2.5),
    timeForReinforcements = config.getParameter("syndicate_krokodyl_transitionState.timeForReinforcements", 0.5),
      
    projectileType = config.getParameter("syndicate_krokodyl_transitionState.projectileType"),
    projectileParameters = config.getParameter("syndicate_krokodyl_transitionState.projectileParameters"),

    enemyCount = config.getParameter("syndicate_krokodyl_transitionState.enemyCount"),
    
    npcSpecies = config.getParameter("syndicate_krokodyl_transitionState.npcSpecies"),
    npcTypes = config.getParameter("syndicate_krokodyl_transitionState.npcTypes"),
    monsterTypes = config.getParameter("syndicate_krokodyl_transitionState.monsterTypes"),
    
    testPoly = config.getParameter("syndicate_krokodyl_transitionState.testPoly"),
    
    spawnOnGround = config.getParameter("syndicate_krokodyl_transitionState.spawnOnGround"),
    spawnRange = config.getParameter("syndicate_krokodyl_transitionState.spawnRange"),
    spawnTolerance = config.getParameter("syndicate_krokodyl_transitionState.spawnTolerance"),
    
    spawnEffects = config.getParameter("syndicate_krokodyl_transitionState.spawnEffects"),
    validTypes = {}
  }
end

function syndicate_krokodyl_transitionState.enteringState(stateData)
  setActiveSkillName("syndicate_krokodyl_transitionState")
  status.addPersistentEffect("syndicate_krokodyl_transitionState", "maxprotection")

  self.bossSummons = self.bossSummons or {}

  playSound("phaseTransition")
  playSound("phaseTransitionLoop", -1)

  animator.burstParticleEmitter("phaseTransition")
  animator.setParticleEmitterActive("phaseTransitionLoop", true)

  fireProjectile(stateData, mcontroller.position(), {mcontroller.facingDirection(), 2})
  
  if stateData.monsterTypes and #stateData.monsterTypes > 0 then
    table.insert(stateData.validTypes, "monster")
  end
  if stateData.npcTypes and #stateData.npcTypes > 0 then
    table.insert(stateData.validTypes, "npc")
  end
end

function syndicate_krokodyl_transitionState.update(dt, stateData)
  stateData.idleTimer = stateData.idleTimer - dt

  if stateData.idleTimer <= 0 then
    return true
  end

  if stateData.timeForReinforcements then
    stateData.timeForReinforcements = stateData.timeForReinforcements - dt
    if stateData.timeForReinforcements <= 0 then
      stateData.timeForReinforcements = nil
      syndicate_krokodyl_transitionState.spawnEnemies(stateData)
    end
  else
    local newList = {}
    for i = 1, #(self.bossSummons or {}) do
      if world.entityExists(self.bossSummons[i]) then
        table.insert(newList, self.bossSummons[i])
      end
    end
    self.bossSummons = newList
    if #self.bossSummons == 0 then
      return true
    end
  end
end

function syndicate_krokodyl_transitionState.spawnEnemies(stateData)
  for i = 1, math.random(stateData.enemyCount[1], stateData.enemyCount[2]) do
    local xOffset = math.random() * stateData.spawnRange[1]
    xOffset = xOffset * util.randomChoice({-1, 1})
    local yOffset = math.random(0, stateData.spawnRange[2])
    local position = vec2.add(self.targetPosition, {xOffset, yOffset})

    local calcPos = {position, nil}
	  calcPos = world.lineTileCollisionPoint(self.targetPosition, position) or {position, 0}
  
    local correctedPositionAndNormal = {calcPos[1], nil}
    if stateData.spawnOnGround then
	    correctedPositionAndNormal = world.lineTileCollisionPoint(calcPos[1], vec2.add(calcPos[1], {0, -50})) or {calcPos[1], 0}
    end
  
    local resolvedPosition = world.resolvePolyCollision(stateData.testPoly, correctedPositionAndNormal[1], stateData.spawnTolerance)
  
    if resolvedPosition then
      local entityId = syndicate_krokodyl_transitionState.spawnEntity(stateData, util.randomChoice(stateData.validTypes), resolvedPosition)
      for _, effect in pairs(stateData.spawnEffects) do
        world.sendEntityMessage(entityId, "applyStatusEffect", effect)
      end
      table.insert(self.bossSummons, entityId)
    end
  end
end

function syndicate_krokodyl_transitionState.spawnEntity(stateData, type, pos)
  if type == "npc" then
    return world.spawnNpc(pos, util.randomChoice(stateData.npcSpecies), util.randomChoice(stateData.npcTypes), world.threatLevel())
  elseif type == "monster" then
	  return world.spawnMonster(util.randomChoice(stateData.monsterTypes), pos, {level = world.threatLevel(), aggressive = true})
  end
end


function syndicate_krokodyl_transitionState.leavingState(stateData)
  setActiveSkillName()
  status.clearPersistentEffects("syndicate_krokodyl_transitionState")

  animator.stopAllSounds("phaseTransitionLoop")
  animator.setParticleEmitterActive("phaseTransitionLoop", false)
end