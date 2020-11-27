require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
DoubleBarrelFire = WeaponAbility:new()

function DoubleBarrelFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function DoubleBarrelFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.fire)
    end
  end
end

function DoubleBarrelFire:fire()
  self.weapon:setStance(self.stances.fire)
  self:fireProjectile(self.projectileType, {}, self.inaccuarcy, self:firePosition(), self.projectileCount, self:damagePerShot()*2)
  animator.playSound("fire")

  self.weapon.weaponOffset = self.stances.fire.weaponOffset

  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    self:fireProjectile(self.projectileType2, {}, self.inaccuarcy, self:firePosition2(), self.projectileCount)
    self:muzzleFlash()
    animator.playSound("fire2")
    shots = shots - 1
    
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {util.interpolateSigmoid(1 - shots / self.burstCount, from[1], to[1]), util.interpolateSigmoid(1 - shots / self.burstCount, from[2], to[2])}
    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))
    
    util.wait(self.burstTime)
  end
  
  self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
end

function DoubleBarrelFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()


  util.wait(self.stances.cooldown.duration, function()
    -- local from = self.stances.cooldown.weaponOffset or {0,0}
    -- local to = self.stances.idle.weaponOffset or {0,0}
    -- self.weapon.weaponOffset = {util.interpolateSigmoid(progress, from[1], to[1]), util.interpolateSigmoid(progress, from[2], to[2])}

    -- self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    -- self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    -- progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
end

function DoubleBarrelFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")

  animator.setLightActive("muzzleFlash", true)
end

function DoubleBarrelFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount, damagePerShot)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = damagePerShot or self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
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
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  return projectileId
end

function DoubleBarrelFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function DoubleBarrelFire:firePosition2()
  return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.add(self.weapon.muzzleOffset,{-0.125,-0.3125})))
end

function DoubleBarrelFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function DoubleBarrelFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function DoubleBarrelFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function DoubleBarrelFire:uninit()
end
