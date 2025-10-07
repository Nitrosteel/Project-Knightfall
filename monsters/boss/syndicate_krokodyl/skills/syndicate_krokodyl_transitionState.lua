syndicate_krokodyl_transitionState = {}

function syndicate_krokodyl_transitionState.enterWith(args)
  if not args or not args.enteringPhase then return nil end

  return {
    phase = 1,
    explosionTimer = config.getParameter("syndicate_krokodyl_transitionState.explosionDuration", 2.5),
    flareDelay = config.getParameter("syndicate_krokodyl_transitionState.flareDelay", 1.0),
    reinforcementDelay = config.getParameter("syndicate_krokodyl_transitionState.reinforcementDelay", 1.0),
    recoveryTimer = config.getParameter("syndicate_krokodyl_transitionState.recoveryTime", 10.0),

    projectileType = config.getParameter("syndicate_krokodyl_transitionState.projectileType"),
    projectileParameters = config.getParameter("syndicate_krokodyl_transitionState.projectileParameters"),
    explosionProjectile = config.getParameter("syndicate_krokodyl_transitionState.explosionProjectile", "mechexplosion"),

    enemyCount = config.getParameter("syndicate_krokodyl_transitionState.enemyCount"),
    npcSpecies = config.getParameter("syndicate_krokodyl_transitionState.npcSpecies"),
    npcTypes = config.getParameter("syndicate_krokodyl_transitionState.npcTypes"),
    monsterTypes = config.getParameter("syndicate_krokodyl_transitionState.monsterTypes"),

	testPoly = config.getParameter("syndicate_krokodyl_transitionState.testPoly"),
	
    spawnOnGround = config.getParameter("syndicate_krokodyl_transitionState.spawnOnGround"),
    spawnRange = config.getParameter("syndicate_krokodyl_transitionState.spawnRange"),
    spawnTolerance = config.getParameter("syndicate_krokodyl_transitionState.spawnTolerance"),
    spawnEffects = config.getParameter("syndicate_krokodyl_transitionState.spawnEffects"),

    validTypes = {},
    bossSummons = {},
  }
end

function syndicate_krokodyl_transitionState.enteringState(stateData)
  setActiveSkillName("syndicate_krokodyl_transitionState")
  status.addPersistentEffect("syndicate_krokodyl_transitionState", "maxprotection")

  playSound("phaseTransition")
  animator.setParticleEmitterActive("phaseTransitionLoop", false)

  if stateData.monsterTypes and #stateData.monsterTypes > 0 then
    table.insert(stateData.validTypes, "monster")
  end
  if stateData.npcTypes and #stateData.npcTypes > 0 then
    table.insert(stateData.validTypes, "npc")
  end
end

function syndicate_krokodyl_transitionState.update(dt, stateData)
  if stateData.phase == 1 then
    stateData.explosionTimer = stateData.explosionTimer - dt

    if math.random() < 0.2 then
      local offset = {math.random(-16, 16), math.random(-5, 2)}
	  animator.burstParticleEmitter("phaseTransition")
      world.spawnProjectile(stateData.explosionProjectile, vec2.add(mcontroller.position(), offset), entity.id(), {0, 0}, false)
    end

    if stateData.explosionTimer <= 0 then
      stateData.phase = 2
	  playSound("phaseTransitionLoop", -1)
      animator.setParticleEmitterActive("phaseTransitionLoop", true)
      stateData.flareTimer = stateData.flareDelay
    end
    return false
  end

  if stateData.phase == 2 then
    if stateData.flareTimer then
      stateData.flareTimer = stateData.flareTimer - dt
      if stateData.flareTimer <= 0 then
	    playSound("phaseTransitionFlare")
        fireProjectile(stateData, mcontroller.position(), {0, 1})
        stateData.flareTimer = nil
        stateData.reinforcementTimer = stateData.reinforcementDelay
      end
      return false
    end

    if stateData.reinforcementTimer then
      stateData.reinforcementTimer = stateData.reinforcementTimer - dt
      if stateData.reinforcementTimer <= 0 then
        syndicate_krokodyl_transitionState.spawnEnemies(stateData)
        stateData.reinforcementTimer = nil
      end
      return false
    end

    stateData.recoveryTimer = stateData.recoveryTimer - dt

    local aliveList = {}
    for _, id in ipairs(stateData.bossSummons or {}) do
      if world.entityExists(id) then table.insert(aliveList, id) end
    end
    stateData.bossSummons = aliveList

    if stateData.recoveryTimer <= 0 or #stateData.bossSummons == 0 then
      return true
    end
  end

  return false
end

function syndicate_krokodyl_transitionState.spawnEnemies(stateData)
  for i = 1, math.random(stateData.enemyCount[1], stateData.enemyCount[2]) do
    local xOffset = math.random() * stateData.spawnRange[1] * util.randomChoice({-1, 1})
    local yOffset = math.random(0, stateData.spawnRange[2])
    local position = vec2.add(self.targetPosition, {xOffset, yOffset})

    local calcPos = world.lineTileCollisionPoint(self.targetPosition, position) or {position, 0}
    local correctedPositionAndNormal = calcPos

    if stateData.spawnOnGround then
      correctedPositionAndNormal = world.lineTileCollisionPoint(calcPos[1], vec2.add(calcPos[1], {0, -50})) or {calcPos[1], 0}
    end

    local resolvedPosition = world.resolvePolyCollision(stateData.testPoly, correctedPositionAndNormal[1], stateData.spawnTolerance)
    if resolvedPosition then
      local entityId = syndicate_krokodyl_transitionState.spawnEntity(stateData, util.randomChoice(stateData.validTypes), resolvedPosition)
      for _, effect in pairs(stateData.spawnEffects) do
        world.sendEntityMessage(entityId, "applyStatusEffect", effect)
      end
      table.insert(stateData.bossSummons, entityId)
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