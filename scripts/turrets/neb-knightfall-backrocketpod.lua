require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"

function init()
  --Initial checks
  self.crouchOnly = config.getParameter("crouchOnly", false)
  self.crouchCorrected = false
  self.active = true
  self.canFire = false
  self.firing = false
  animator.resetTransformationGroup("turret")
  
  --Loading stats from config file into self
  self.burstTime = config.getParameter("burstTime", 0)
  self.burstCount = config.getParameter("burstCount", 1)
  self.fireTime = config.getParameter("fireTime", 5)
  self.baseDps = config.getParameter("baseDps", 10)
  self.inaccuracy = config.getParameter("inaccuracy", 0.05)
  self.projectileType = config.getParameter("projectileType", "stardardbullet")
  self.projectileCount = config.getParameter("projectileCount", 1)
  self.projectileParameters = config.getParameter("projectileParameters", {})
  self.muzzleOffset = config.getParameter("muzzleOffset", {0, 6})
  self.searchRadius = config.getParameter("searchRadius", 20)
  
  --Setting stats
  self.cooldownTimer = self.fireTime
  self.shots = 0
  self.burstTimer = self.burstTime
end

function update(dt)
  --Reset group so rotation and movement doesnt stack
  animator.resetTransformationGroup("turret")
  --Crouch Correction
  if mcontroller.crouching() and not self.crouchCorrected then
	self.muzzleOffset = vec2.add(self.muzzleOffset, {0, -1})
	self.crouchCorrected = true
  elseif not mcontroller.crouching() and self.crouchCorrected then
	self.muzzleOffset = vec2.add(self.muzzleOffset, {0, 1})
	self.crouchCorrected = false
  end
  --Flip offset correction
  self.usedMuzzleOffset = {((self.muzzleOffset[1]) * mcontroller.facingDirection()),self.muzzleOffset[2]}
  
  --Flip sprite when play flips
  if mcontroller.facingDirection() < 0 then animator.setGlobalTag("facingDirection", "flipx") else animator.setGlobalTag("facingDirection", "") end
  animator.translateTransformationGroup("turret", self.usedMuzzleOffset)
  
  --Code for crouch only mechanics
  if not mcontroller.crouching() and self.crouchOnly then
    self.active = false
    animator.setAnimationState("turretHead", "hidden")
  elseif mcontroller.crouching() and self.crouchOnly and not self.active then
    self.active = true
    animator.setAnimationState("turretHead", "active")
  end
  
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  
  if self.firing then
    if self.active then
      if self.shots > 0 and (self.currentTarget and world.entityExists(self.currentTarget) or false) then
	    self.burstTimer = math.max(0, self.burstTimer - dt)
		if self.burstTimer <= 0 then
		  fireAnimation()
          fireProjectile()
	      self.shots = self.shots - 1
		  self.burstTimer = self.burstTime
	    end
	  else
	    self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
        self.firing = false
	  end
	end
  end
  
  self.currentTarget = findTarget() 
  if self.cooldownTimer == 0 
	and not self.firing then
	
	self.shots = self.burstCount
    if self.currentTarget
	  and self.active
	  and self.canFire
      and not world.lineTileCollision(mcontroller.position(), firePosition()) then
	
      self.firing = true
	end
  end  
  if (self.currentTarget and world.entityExists(self.currentTarget) or false) then
    self.targetAngle = vec2.angle(world.distance(world.entityPosition(self.currentTarget), vec2.add(mcontroller.position(), self.usedMuzzleOffset)))
	if (mcontroller.facingDirection() < 0 and self.targetAngle >= (math.pi/2) and self.targetAngle < (math.pi*1.5))
	  or (mcontroller.facingDirection() > 0 and (self.targetAngle >= (math.pi*1.5) or self.targetAngle < (math.pi/2))) then

	  if (mcontroller.facingDirection() < 0 and (self.targetAngle <= (-math.pi/2) or self.targetAngle >= (math.pi/2))) then
	    animator.setGlobalTag("facingDirection", "flipy")
	  end
      animator.rotateTransformationGroup("turret", vec2.angle(world.distance(world.entityPosition(self.currentTarget), vec2.add(mcontroller.position(), self.usedMuzzleOffset))), self.usedMuzzleOffset)
      self.canFire = true
    else
      self.canFire = false
    end
  
    world.debugLine(firePosition(), vec2.add(firePosition(), vec2.mul(vec2.norm(aimVector()), 3)), "green")
    world.debugText("Target is at this angle: " .. vec2.angle(world.distance(world.entityPosition(self.currentTarget), vec2.add(mcontroller.position(), self.usedMuzzleOffset))), vec2.add(mcontroller.position(), {0,3}), "red")
  else
    animator.rotateTransformationGroup("turret", 0, self.usedMuzzleOffset)
  end
  
  --Debug stuffs
  debugQuery()
  world.debugText("Cooldown ready in " .. self.cooldownTimer, mcontroller.position(), "red")
  world.debugText("Active: " .. sb.printJson(self.active), vec2.add(mcontroller.position(), {0,1}), "red")
  world.debugText("Target: " .. (self.currentTarget and world.entityTypeName(self.currentTarget) or "currently unknown, searching..."), vec2.add(mcontroller.position(), {0,2}), "red")
  world.debugText("Shots remaining: " .. self.shots, vec2.add(mcontroller.position(), {0,4}), "red")
  world.debugPoint(firePosition(), "red")
end

function fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = damagePerShot()
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
      vec2.add(mcontroller.position(), self.usedMuzzleOffset) or firePosition(),
      entity.id(),
      aimVector(inaccuracy or self.inaccuracy),
      false,
      params
    )
  end
  return projectileId
end

function debugQuery()
  world.debugPoly({
    vec2.add(firePosition(), {0,-self.searchRadius}),
    vec2.add(firePosition(), {self.searchRadius,0}),
    vec2.add(firePosition(), {0,self.searchRadius}),
    vec2.add(firePosition(), {-self.searchRadius,0})
  }, {255,0,0})
end

function firePosition()
  return vec2.add(mcontroller.position(), self.usedMuzzleOffset)
end

function aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, vec2.angle(vec2.sub(world.entityPosition(self.currentTarget), vec2.add(mcontroller.position(), self.usedMuzzleOffset))) + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * util.toDirection(self.currentTarget)
  return aimVector
end

function fireAnimation()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.setAnimationState("turretHead", "fired")
  animator.burstParticleEmitter("muzzleFlash")
  animator.playSound("fire")

  animator.setLightActive("muzzleFlash", true)
end

function damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) / self.projectileCount
end

function findTarget()
  local nearEntities = world.entityQuery(firePosition(), self.searchRadius, {
    includedTypes = {"npc", "monster", "player"},
    order = "nearest"
  })
  nearEntities = util.filter(nearEntities, function(entityId)
    if world.lineTileCollision(firePosition(), world.entityPosition(entityId)) then
      return false
    end
    -- sb.logInfo("%s",world.entityTypeName(entityId))
    if not world.entityCanDamage(entity.id(), entityId) then
      return false
    end

    if (world.entityDamageTeam(entityId).type == "passive") and (world.entityTypeName(entityId) ~= "punchy") then
      return false
    end

    return true
  end)
  local targetId = nearEntities[1]
  if targetId then return targetId else return nil end
end

function uninit()
end

function onExpire()
end