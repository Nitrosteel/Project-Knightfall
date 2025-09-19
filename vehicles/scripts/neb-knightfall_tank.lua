require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init(dt)
  self.levelApproachFactor = config.getParameter("levelApproachFactor")
  self.angleApproachFactor = config.getParameter("angleApproachFactor")
  self.maxGroundSearchDistance = config.getParameter("maxGroundSearchDistance")
  self.maxAngle = config.getParameter("maxAngle") * math.pi / 180
  self.backSpringPositions = config.getParameter("backSpringPositions")
  self.frontSpringPositions = config.getParameter("frontSpringPositions")
  
  --STATS
  self.materialKind = config.getParameter("materialKind", {})
  self.stats = config.getParameter("stats", {})
  self.weaponry = config.getParameter("weaponry", {})
  
  --Assume maxhealth
  if not (storage.health) then
    local startHealthFactor = config.getParameter("startHealthFactor")

    if (startHealthFactor == nil) then
       storage.health = self.stats.health
    else
       storage.health = math.min(startHealthFactor * self.stats.health, self.stats.health)
    end
    --animator.setAnimationState("movement", "warpInPart1")
  end
  
  self.currentFrame = 1
  self.trackFrames = config.getParameter("trackFrames", 4)
  self.trackFrameCycle = config.getParameter("trackFrameCycle", 4)
  animator.setGlobalTag("trackFrame", self.currentFrame)
  
  self.moveSpeed = config.getParameter("moveSpeed")
  self.groundForce = config.getParameter("groundForce")
  self.jumpSpeed = config.getParameter("jumpSpeed")
  
  self.movementSettings = config.getParameter("movementSettings")
  self.occupiedMovementSettings = config.getParameter("occupiedMovementSettings")

  self.aimDirection = 1
  self.angle = 0
  self.fireInterval = config.getParameter("fireInterval")

  self.driving = false
  self.lastDriver = nil
end

function update(dt)
  self.currentFrame = math.abs(((self.currentFrame + (mcontroller.xVelocity() * dt / self.trackFrameCycle)) % self.trackFrames) * ((mcontroller.xVelocity() > 0) and 1 or -1))
  animator.setGlobalTag("trackFrame", math.floor(self.currentFrame) + 1)

  --If at world limit terminate vehicle
  if mcontroller.atWorldLimit() then
    vehicle.destroy()
    sb.logInfo("%s, vehicle at world limit!", config.getParameter("name", "Unknown Tank"))
	return
  end
  
  --If health is zero, fucking die
  if storage.health <= 0 then
    animator.burstParticleEmitter("damageShards")
    animator.playSound("explode")
    vehicle.destroy()
  end
  
  local driver = vehicle.entityLoungingIn("drivingSeat")
  if driver then
    updateMovement()
	
    if self.lastDriver == nil then
      animator.playSound("engineStart")
      animator.playSound("engineLoop", -1)
    end

    vehicle.setDamageTeam(world.entityDamageTeam(driver))
    mcontroller.applyParameters(self.occupiedMovementSettings)
    vehicle.setInteractive(false)
  else
    animator.stopAllSounds("engineLoop")
    vehicle.setDamageTeam({type = "passive"})
    mcontroller.applyParameters(self.movementSettings)
    vehicle.setInteractive(true)
  end
  self.lastDriver = driver
  
  updateWeapons()
end

function updateMovement()
  local frontSpringDistance = minimumSpringDistance(self.frontSpringPositions)
  local backSpringDistance = minimumSpringDistance(self.backSpringPositions)
  if frontSpringDistance == self.maxGroundSearchDistance and backSpringDistance == self.maxGroundSearchDistance then
    self.angle = self.angle - self.angle * self.angleApproachFactor
  else
    self.angle = self.angle + math.atan((backSpringDistance - frontSpringDistance) * self.levelApproachFactor)
    self.angle = math.min(math.max(self.angle, -self.maxAngle), self.maxAngle)
  end
	
  local moveDir = 0
  if vehicle.controlHeld("drivingSeat", "right") then
    moveDir = moveDir + 1
  end
  if vehicle.controlHeld("drivingSeat", "left") then
    moveDir = moveDir - 1
  end

  self.aimDirection = (world.distance(vehicle.aimPosition("drivingSeat"), mcontroller.position())[1]) > 0 and 1 or (world.distance(vehicle.aimPosition("drivingSeat"), mcontroller.position())[1]) < 0 and -1 or 0
  local flipped = self.aimDirection < 0
  animator.setFlipped(flipped)
  if mcontroller.onGround() then
    if math.abs(moveDir) > 0 then
      animator.setAnimationState("body", "movement")
    else
      animator.setAnimationState("body", "idle")
    end
  end
  local xVel = vec2.rotate({moveDir * self.moveSpeed, 0}, self.angle)[1] -----------------------------------------------ADJSUT SO YOU CAN CLIMB
  mcontroller.approachXVelocity(xVel, self.groundForce)

  local driving = moveDir ~= 0
  if driving and not self.driving then
    animator.playSound("engineDrive", -1)
  elseif not driving then
    animator.stopAllSounds("engineDrive", 0.5)
  end
  self.driving = driving

  mcontroller.setRotation(self.angle)
  animator.resetTransformationGroup("rotation")
  animator.rotateTransformationGroup("rotation", flipped and -self.angle or self.angle)
end

function minimumSpringDistance(points)
  local min = nil
  for _, point in ipairs(points) do
    point = vec2.rotate(point, self.angle)
    point = vec2.add(point, mcontroller.position())
    local d = distanceToGround(point)
    if min == nil or d < min then
      min = d
    end
  end
  return min
end

function distanceToGround(point)
  local endPoint = vec2.add(point, {0, -self.maxGroundSearchDistance})

  world.debugLine(point, endPoint, {255, 255, 0, 255})
  local intPoint = world.lineCollision(point, endPoint)

  if intPoint then
    world.debugPoint(intPoint, {255, 255, 0, 255})
    return point[2] - intPoint[2]
  else
    return self.maxGroundSearchDistance
  end
end

function updateWeapons()
  for seat, arsenal in pairs(self.weaponry) do
    local aim = vehicle.aimPosition(seat)
    self[seat.."Entity"] = vehicle.entityLoungingIn(seat)
    for arsenalTrigger, subArsenal in pairs(arsenal) do
      for gunName, gun in pairs(subArsenal) do
        gun.fireTimer = math.max(0, (gun.fireTimer or gun.fireTime) - script.updateDt())
        
        local aimSource = vec2.add(mcontroller.position(), animator.partPoint(gun.animationPart or gunName, "rotationCenter"))
        local mouseDir = vec2.norm(world.distance(aim, aimSource))
      
        local aimAngle = math.atan(mouseDir[2], math.abs(mouseDir[1])) + (self.aimDirection < 0 and self.angle or -self.angle)
        if gun.aimAngleMinMax then
          gun.aimAngle = util.clamp(aimAngle, math.rad(gun.aimAngleMinMax[1]), math.rad(gun.aimAngleMinMax[2]))
        end
        
        local rotCenter = animator.partPoint(gun.animationPart or gunName, "rotationCenter")
        rotCenter[1] = rotCenter[1] * self.aimDirection
        animator.resetTransformationGroup(gun.transGroup or gunName)
        animator.rotateTransformationGroup(gun.transGroup or gunName, gun.aimAngle, rotCenter)
      end
      
      local triggers = nebSplitString(arsenalTrigger, ":")
      local triggersHeld = true
      for _, trigger in ipairs(triggers) do
        if not vehicle.controlHeld(seat, trigger) then
          triggersHeld = false
        end
      end
      if triggersHeld then
        for gunName, gun in pairs(subArsenal) do
          fireSubarsenal(seat, subArsenal, gunName, gun)
        end
      end
    end
  end
end

--Separate the string into chunks based on where separator or ? is
function nebSplitString(string, separator)
  local separator, fields = separator or "?", {}
  local pattern = string.format("([^%s]+)", separator)
  string:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function fireSubarsenal(seat, subarsenal, gunName, gun)
  if gun.fireTimer == 0 then
    local gunTip = vec2.add(mcontroller.position(), animator.partPoint(gun.animationPart or gunName, "fireOffset"))
   
    fireProjectile(gun.projectileType, gun.projectileParams, gun.inaccuracy, gunTip, gun.projectileCount, util.wrapAngle(gun.aimAngle - (self.aimDirection < 0 and self.angle or -self.angle)))
   
    gun.fireTimer = gun.fireTime
	
    for _, sound in ipairs(gun.playSounds or {}) do
      animator.playSound(sound)
    end
    for animation, state in pairs(gun.setAnimationStates or {}) do
      animator.setAnimationState(animation, type(state) == "table" and state[1] or state,type(state) == "table" and state[2] or false)
    end
  end
end

function fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount, aimAngle)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end
  
    projectileId = world.spawnProjectile(
        projectileType,
        firePosition,
        entity.id(),
        aimVector(inaccuracy or self.inaccuracy or 0, aimAngle),
        false,
        params
      )
  end
  return projectileId
end

function aimVector(inaccuracy, aimAngle)
  local aimVector = vec2.rotate({1, 0}, aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end

--Determine damage taken, resistances and other functions
function applyDamage(damageRequest)
  --Determine how much damage was taken
  local damage = 0
  if damageRequest.damageType == "Damage" then
    damage = damage + root.evalFunction2("protection", damageRequest.damage, self.stats.protection)
  elseif damageRequest.damageType == "IgnoresDef" then
    damage = damage + damageRequest.damage
  else
    return {}
  end
  
  local elementalStat = root.elementalResistance(damageRequest.damageSourceKind)
  local resistance = self.stats.elementalResistances and self.stats.elementalResistances[elementalStat] or 0.0
  damage = damage - (resistance * damage)

  local knockbackFactor = (1 - (self.stats.grit or 0.0))

  local knockbackMomentum = vec2.mul(damageRequest.knockbackMomentum, knockbackFactor)
  local knockback = vec2.mag(knockbackMomentum)
  if knockback > self.stats.knockbackThreshold or 1.0 then
    local dir = knockbackMomentum[1] > 0 and 1 or -1
    mcontroller.addMomentum({dir * knockback / 1.41, knockback / 1.41})
  end

  local healthLost = math.min(damage, storage.health)
  storage.health = storage.health - healthLost

  --Return the modified damage request
  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = storage.health <= 0 and "Kill" or "Hit",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = self.materialKind,
    killed = storage.health <= 0
  }}
end