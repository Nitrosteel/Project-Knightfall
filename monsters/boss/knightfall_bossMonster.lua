require "/scripts/util.lua"
require "/scripts/rect.lua"
require "/scripts/interp.lua"

function init()
  self.tookDamage = false
  self.dead = false

  if rangedAttack then
    rangedAttack.loadConfig()
  end

  self.idleTouchDamage = config.getParameter("idleTouchDamage")
  self.defaultDamageSources = {self.idleTouchDamage}
  self.damageSources = self.defaultDamageSources

  self.concurrentSkills = {}
  self.currentConcurrentSkills = {}

  --Movement
  self.spawnPosition = mcontroller.position()

  self.jumpTimer = 0
  self.isBlocked = false
  self.willFall = false

  self.queryTargetDistance = config.getParameter("queryTargetDistance", 30)
  self.trackTargetDistance = config.getParameter("trackTargetDistance")
  self.switchTargetDistance = config.getParameter("switchTargetDistance")
  self.keepTargetInSight = config.getParameter("keepTargetInSight", true)

  self.targets = {}

  --Non-combat states
  local states = stateMachine.scanScripts(config.getParameter("scripts"), "(%a+State)%.lua")
  self.state = stateMachine.create(states)

  self.state.leavingState = function(stateName)
    self.state.moveStateToEnd(stateName)
  end

  self.skillParameters = {}
  for _, skillName in pairs(config.getParameter("skills")) do
    self.skillParameters[skillName] = config.getParameter(skillName)
  end

  --Load phases
  self.phases = config.getParameter("phases")
  setPhaseStates(self.phases)

  for skillName, params in pairs(self.skillParameters) do
    if type(_ENV[skillName].onInit) == "function" then
      _ENV[skillName].onInit()
    end
  end

  monster.setUniqueId(config.getParameter("uniqueId"))

  monster.setDeathParticleBurst("deathPoof")

  monster.setDamageBar("None")

  self.musicEnabled = false
end

function update(dt)
  self.tookDamage = false
  monster.setDamageSources(self.damageSources)

  if not status.resourcePositive("health") then
    local inState = self.state.stateDesc()
    if inState ~= "dieState" and not self.state.pickState({ die = true }) then
      self.state.endState()
      self.dead = true
    end

    self.state.update(dt)

    setBattleMusicEnabled(false)
  else
    trackTargets(self.keepTargetInSight, self.queryTargetDistance, self.trackTargetDistance, self.switchTargetDistance)

    for skillName, params in pairs(self.skillParameters) do
      if type(_ENV[skillName].onUpdate) == "function" then
        _ENV[skillName].onUpdate(dt)
      end
    end

    if hasTarget() then
      script.setUpdateDelta(1)
      updatePhase(dt)

      for _, concurrentSkill in ipairs(self.currentConcurrentSkills) do
        local skillData = self.concurrentSkills[concurrentSkill]
        _ENV[concurrentSkill].update(dt, skillData)
      end

      monster.setDamageBar("Special")
      monster.setAggressive(true)
      setBattleMusicEnabled(true)
      monster.setDamageOnTouch(true)

      animator.setGlobalTag("phase", "phase"..currentPhase())
    else
      if self.hadTarget then
        --Lost target, reset boss
        if currentPhase() then
          self.phaseStates[currentPhase()].endState()
        end
        self.phase = nil
        self.lastPhase = nil
        setPhaseStates(self.phases)
        status.setResource("health", status.stat("maxHealth"))

        if bossReset then bossReset() end
        monster.setDamageBar("None")
        monster.setAggressive(false)
        monster.setDamageOnTouch(false)
      end

      script.setUpdateDelta(10)

      if not self.state.update(dt) then
        self.state.pickState()
      end

      setBattleMusicEnabled(false)
    end

    self.hadTarget = hasTarget()
  end
end

function setActiveSkillName(skillName)
  monster.setActiveSkillName(skillName)
  self.activeSkill = skillName
end

function isSkillInUse(skillList)
  for _, skill in ipairs(skillList or {}) do 
    if skill == self.activeSkill then
      return true
    end
  end
  return false
end

function fireProjectile(skillData, firePosition, aimVector)
  local params = sb.jsonMerge(skillData.projectileParameters, {})
  params.power = scalePower(params.power or 1)

  local projectileType = skillData.projectileType
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (skillData.projectileCount or 1) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end
    if params.speed then
      params.speed = util.randomInRange(params.speed)
    end

    projectileId = world.spawnProjectile(
        projectileType,
        firePosition or mcontroller.position(),
        entity.id(),
        aimVector or {0, 0},
        false,
        params
      )
  end
  return projectileId
end

function scalePower(power)
  return power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
end

function playSound(sound, loop)
  if animator.hasSound(sound) then
    animator.playSound(sound, loop)
  else
    sb.logError("%s sound does not exist!", sound)
  end
end

function updateDamageSources(damageSource, ignoreDefault)
  local damageSources = {}
  if not ignoreDefault then
    table.insert(damageSources, self.idleTouchDamage)
  end
  table.insert(damageSources, damageSource)
  self.damageSources = damageSources
end

function flipPoly(poly)
  local flippedPoly = {}
  for x, vec in ipairs(poly) do
    local newVec = vec
    newVec[1] = vec[1] * mcontroller.facingDirection()
    table.insert(flippedPoly, newVec)
  end
  return flippedPoly
end

function damage(args)
  self.tookDamage = true

  if args.sourceId and args.sourceId ~= 0 and not inTargets(args.sourceId) then
    table.insert(self.targets, args.sourceId)
  end
end

function shouldDie()
  return self.dead
end

function hasTarget()
  if self.targetId and self.targetId ~= 0 then
    return self.targetId
  end
  return false
end

function targetIsBehind()
  return (mcontroller.facingDirection() == 1 and mcontroller.position()[1] > self.targetPosition[1]) or (mcontroller.facingDirection() == -1 and mcontroller.position()[1] < self.targetPosition[1])
end

function trackTargets(keepInSight, queryRange, trackingRange)
  if keepInSight == nil then keepInSight = true end

  if #self.targets == 0 then
    local newTarget = util.closestValidTarget(queryRange)
    table.insert(self.targets, newTarget)
  end

  self.targets = util.filter(self.targets, function(targetId)
    if not world.entityExists(targetId) then return false end

    if keepInSight and not entity.entityInSight(targetId) then return false end

    if trackingRange and world.magnitude(mcontroller.position(), world.entityPosition(targetId)) > trackingRange then
      return false
    end

    return true
  end)

  --Set target to be top of the list
  self.targetId = self.targets[1]
  if self.targetId then
    self.targetPosition = world.entityPosition(self.targetId)
  end
end

function validTarget(targetId, keepInSight, trackingRange)
  local entityType = world.entityType(targetId)
  if entityType ~= "player" and entityType ~= "npc" then
    return false
  end

  if not world.entityExists(targetId) then return false end

  if keepInSight and not entity.entityInSight(targetId) then return false end

  if trackingRange then
    local distance = world.magnitude(mcontroller.position(), world.entityPosition(targetId))
    if distance > trackingRange then return false end
  end

  return true
end

function inTargets(entityId)
  for i,targetId in ipairs(self.targets) do
    if targetId == entityId then
      return i
    end
  end
  return false
end

--PHASES-----------------------------------------------------------------------

function currentPhase()
  return self.phase
end

function updatePhase(dt)
  if not self.phase then
    self.phase = 1
  end

  --Check if next phase is ready
  local nextPhase = self.phases[self.phase + 1]
  if nextPhase then
    if nextPhase.trigger and nextPhase.trigger == "healthPercentage" then
      if status.resourcePercentage("health") < nextPhase.healthPercentage then
        self.phase = self.phase + 1
      end
    end
  end

  if not self.lastPhase or self.lastPhase ~= self.phase then
    if self.lastPhase then
      self.phaseStates[self.lastPhase].endState()

      for _, concurrentSkill in ipairs(self.currentConcurrentSkills) do
        local skillData = self.concurrentSkills[concurrentSkill]
        _ENV[concurrentSkill].uninit(skillData)
      end
    end
    self.phaseStates[currentPhase()].pickState({enteringPhase = currentPhase()})
    self.currentConcurrentSkills = self.phases[self.phase].concurrentSkills
    for _, concurrentSkill in ipairs(self.currentConcurrentSkills) do
      local skillData = self.concurrentSkills[concurrentSkill]
      _ENV[concurrentSkill].enterSkill(skillData)
    end
  end
  if not self.phaseStates[currentPhase()].update(dt) then
    self.phaseStates[currentPhase()].pickState()
  end

  self.lastPhase = self.phase
end

function setPhaseStates(phases)
  self.phaseSkills = {}
  self.phaseStates = {}
  self.concurrentSkills = {}
  local filePath = config.getParameter("filePath")
  for i, phase in ipairs(phases) do
    self.phaseSkills[i] = {}
    for _,skillName in ipairs(phase.skills) do
      table.insert(self.phaseSkills[i], skillName)
    end
    if phase.enterPhase then
      table.insert(self.phaseSkills[i], 1, phase.enterPhase)
    end
    self.phaseStates[i] = stateMachine.create(self.phaseSkills[i])

    --Cycle through the skills
    self.phaseStates[i].leavingState = function(stateName)
      self.phaseStates[i].moveStateToEnd(stateName)
    end

    for i, concurrentSkill in ipairs(phase.concurrentSkills) do
      local skillData = _ENV[concurrentSkill].init()
      self.concurrentSkills[concurrentSkill] = skillData
    end
  end
end

--MOVEMENT---------------------------------------------------------------------

function boundingBox(force)
  if self.boundingBox and not force then return self.boundingBox end

  local collisionPoly = mcontroller.collisionPoly()
  local bounds = {0, 0, 0, 0}

  for _,point in pairs(collisionPoly) do
    if point[1] < bounds[1] then bounds[1] = point[1] end
    if point[2] < bounds[2] then bounds[2] = point[2] end
    if point[1] > bounds[3] then bounds[3] = point[1] end
    if point[2] > bounds[4] then bounds[4] = point[2] end
  end
  self.boundingBox = bounds

  return bounds
end

function checkWalls(direction)
  local bounds = mcontroller.boundBox()
  bounds[2] = bounds[2] + 1
  if direction > 0 then
    bounds[1] = bounds[3]
    bounds[3] = bounds[3] + 0.25
  else
    bounds[3] = bounds[1]
    bounds[1] = bounds[1] - 0.25
  end
  util.debugRect(rect.translate(bounds, mcontroller.position()), "yellow")
  return world.rectTileCollision(rect.translate(bounds, mcontroller.position()), {"Null", "Block", "Dynamic", "Slippery"})
end

function flyTo(position, speed)
  if speed then mcontroller.controlParameters({flySpeed = speed}) end
  local toPosition = vec2.norm(world.distance(position, mcontroller.position()))
  mcontroller.controlFly(toPosition)
end

--------------------------------------------------------------------------------
function move(delta, run, jumpThresholdX)
  checkTerrain(delta[1])

  mcontroller.controlMove(delta[1], run)

  if self.jumpTimer > 0 and not self.onGround then
    mcontroller.controlHoldJump()
  else
    if self.jumpTimer <= 0 then
      if jumpThresholdX == nil then jumpThresholdX = 4 end

      -- We either need to be blocked by something, the target is above us and
      -- we are about to fall, or the target is significantly high above us
      local doJump = false
      if isBlocked() then
        doJump = true
      elseif (delta[2] >= 0 and willFall() and math.abs(delta[1]) > 7) then
        doJump = true
      elseif (math.abs(delta[1]) < jumpThresholdX and delta[2] > config.getParameter("jumpTargetDistance")) then
        doJump = true
      end

      if doJump then
        self.jumpTimer = util.randomInRange(config.getParameter("jumpTime"))
        mcontroller.controlJump()
      end
    end
  end

  if delta[2] < 0 then
    mcontroller.controlDown()
  end
end

--------------------------------------------------------------------------------
--TODO: this could probably be further optimized by creating a list of discrete points and using sensors... project for another time
function checkTerrain(direction)
  --normalize to 1 or -1
  direction = direction > 0 and 1 or -1

  local reverse = false
  if direction ~= nil then
    reverse = direction ~= mcontroller.facingDirection()
  end

  local boundBox = mcontroller.boundBox()

  -- update self.isBlocked
  local blockLine, topLine
  if not reverse then
    blockLine = {monster.toAbsolutePosition({boundBox[3] + 0.25, boundBox[4]}), monster.toAbsolutePosition({boundBox[3] + 0.25, boundBox[2] - 1.0})}
  else
    blockLine = {monster.toAbsolutePosition({-boundBox[3] - 0.25, boundBox[4]}), monster.toAbsolutePosition({-boundBox[3] - 0.25, boundBox[2] - 1.0})}
  end

  local blockBlocks = world.collisionBlocksAlongLine(blockLine[1], blockLine[2])
  self.isBlocked = false
  if #blockBlocks > 0 then
    --check for basic blockage
    local topOffset = blockBlocks[1][2] - blockLine[2][2]
    if topOffset > 2.75 then
      self.isBlocked = true
    elseif topOffset > 0.25 then
      --also check for that stupid little hook ledge thing
      self.isBlocked = not world.pointTileCollision({blockBlocks[1][1] - direction, blockBlocks[1][2] - 1})

      if not self.isBlocked then
        --also check if blocks above prevent us from climbing
        topLine = {monster.toAbsolutePosition({boundBox[1], boundBox[4] + 0.5}), monster.toAbsolutePosition({boundBox[3], boundBox[4] + 0.5})}
        self.isBlocked = world.lineTileCollision(topLine[1], topLine[2])
      end
    end
  end

  -- update self.willFall
  local fallLine
  if reverse then
    fallLine = {monster.toAbsolutePosition({-0.5, boundBox[2] - 0.75}), monster.toAbsolutePosition({boundBox[3], boundBox[2] - 0.75})}
  else
    fallLine = {monster.toAbsolutePosition({0.5, boundBox[2] - 0.75}), monster.toAbsolutePosition({-boundBox[3], boundBox[2] - 0.75})}
  end
  self.willFall =
      world.lineTileCollision(fallLine[1], fallLine[2]) == false and
      world.lineTileCollision({fallLine[1][1], fallLine[1][2] - 1}, {fallLine[2][1], fallLine[2][2] - 1}) == false
end

--------------------------------------------------------------------------------
function isBlocked()
  return self.isBlocked
end

--------------------------------------------------------------------------------
function willFall()
  return self.willFall
end

function setBattleMusicEnabled(enabled)
  if self.musicEnabled ~= enabled then
    local musicStagehands = config.getParameter("musicStagehands", {})
    for _,stagehand in pairs(musicStagehands) do
      local entityId = world.loadUniqueEntity(stagehand)

      if entityId and world.entityExists(entityId) then
        world.callScriptedEntity(entityId, "setMusicEnabled", enabled)
        self.musicEnabled = enabled
      end
    end
  end
end
