require "/scripts/util.lua"
require "/scripts/interp.lua"

--Basically gunfire and zenshot merged together, modified and polished.
--Supports auto, burst fire, inaccuracy. Allows to fire in a high-arc trajectory,
--similar to zenshot bow ability. -Jetfire

--ToDo - charged fire mode.

PlungingFire = WeaponAbility:new()

function PlungingFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.projectileParameters = self.projectileParameters or {}

  local projectileConfig = root.projectileConfig(self.projectileType)
  self.projectileParameters.speed = self.projectileParameters.speed or projectileConfig.speed

  self.projectileGravityMultiplier = root.projectileGravityMultiplier(self.projectileType)

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function PlungingFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    if self.aimType == "normal" then
      self:setState(self.aim)
    elseif self.aimType == "charged" then
      self:setState(self.aimCharge)
    end
  end
end

function PlungingFire:aim()
  self.weapon:setStance(self.stances.aim)

  --Here might be a sound or/and animation
  animator.playSound("aim")

  util.wait(self.stances.aim.duration, function()
    if self.walkWhileFiring then mcontroller.controlModifiers({runningSuppressed = true}) end

    local aimVec = self:aimVector()
    aimVec[1] = aimVec[1] * self.weapon.aimDirection
    self.weapon.aimAngle = (4 * self.weapon.aimAngle + vec2.angle(aimVec)) / 5

    coroutine.yield()
  end)

  if self.fireType == "auto" then
    self:setState(self.auto)
  elseif self.fireType == "burst" then
    self:setState(self.burst)
  end
end

function PlungingFire:aimCharge()
  self.weapon:setStance(self.stances.aim)
  local chargeTime = 0

  --Here might be a sound or/and animation
  animator.playSound("aim")

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    if self.walkWhileFiring then mcontroller.controlModifiers({runningSuppressed = true}) end
    chargeTime = chargeTime + self.dt

    self.projectileParameters.speed = interp.linear(math.min(chargeTime,self.stances.aim.duration)/self.stances.aim.duration, self.minSpeed, self.maxSpeed)

    local aimVec = self:aimVector()
    aimVec[1] = aimVec[1] * self.weapon.aimDirection
    self.weapon.aimAngle = (4 * self.weapon.aimAngle + vec2.angle(aimVec)) / 5

    coroutine.yield()
  end

  if self.fireType == "auto" then
    self:setState(self.auto)
  elseif self.fireType == "burst" then
    self:setState(self.burst)
  end
end

function PlungingFire:auto()
  self.weapon:setStance(self.stances.fire)

  while self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", self:energyPerShot()) and not world.lineTileCollision(mcontroller.position(), self:firePosition()) do

    local aimVec = self:aimVector()
    aimVec[1] = aimVec[1] * self.weapon.aimDirection
    self.weapon.aimAngle = vec2.angle(aimVec)
    self:fireProjectile()
    self:muzzleFlash()

    if self.stances.fire.duration then
      util.wait(self.stances.fire.duration)
    end

  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function PlungingFire:burst()
  self.weapon:setStance(self.stances.fire)

    local shots = self.burstCount
    while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) and not world.lineTileCollision(mcontroller.position(), self:firePosition()) do
      local aimVec = self:aimVector()
      aimVec[1] = aimVec[1] * self.weapon.aimDirection
      self.weapon.aimAngle = vec2.angle(aimVec)

      self:fireProjectile()
      self:muzzleFlash()
      shots = shots - 1

      self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
      self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))

      util.wait(self.burstTime)
    end

  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function PlungingFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
end

function PlungingFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", self.fireAnimationState or "fire")
  animator.burstParticleEmitter(self.particleEmitter or "muzzleFlash")
  animator.playSound(self.fireSound or "fire")

  animator.setLightActive("muzzleFlash", true)

  if self.fireAnimationStates then
    for k,v in pairs(self.fireAnimationStates) do
      animator.setAnimationState(k, v)
    end
  end
end

function PlungingFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = self.projectileParameters.speed

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
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        vec2.rotate(self:aimVector(), sb.nrand(inaccuracy or self.inaccuracy, 0)),
        false,
        params
      )
  end
  return projectileId
end

function PlungingFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function PlungingFire:aimVector()
  local targetOffset = world.distance(activeItem.ownerAimPosition(), self:firePosition())
  return util.aimVector(targetOffset, self.projectileParameters.speed, self.projectileGravityMultiplier, true)
end

function PlungingFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function PlungingFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function PlungingFire:uninit()
end
