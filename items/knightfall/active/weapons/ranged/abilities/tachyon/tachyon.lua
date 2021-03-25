require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
TachyonFire = WeaponAbility:new()

function TachyonFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function TachyonFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if animator.animationState("firing") == "off" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and animator.animationState("firing") == "off"
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    self:setState(self.charge)
    
  end
end

function TachyonFire:charge()
  animator.setLightActive("muzzleFlash", true)
  self.weapon:setStance(self.stances.charge)
  self.weapon:updateAim()
  animator.playSound("charge")
  animator.setAnimationState("firing", "ch")

  local chargeTimer = self.stances.charge.duration
  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) and not world.lineTileCollision(mcontroller.position(), self:firePosition()) do
    chargeTimer = chargeTimer - self.dt
    coroutine.yield()
    if chargeTimer <= 0 then
      self:setState(self.fire)
    end
  end
--    animator.playSound(self.elementalType.."discharge")
end

--  function TachyonFire:charge()
--  self.weapon:setStance(self.stances.charge)
--  self.weapon:updateAim()
--  animator.playSound("charge")
--  animator.setAnimationState("firing", "ch0")
--
--  util.wait(self.stances.charge.duration, function()
--  end)
--  self:setState(self.fire)
--end

function TachyonFire:fire()
  status.overConsumeResource("energy", self:energyPerShot())
  self.weapon:setStance(self.stances.fire)
--  animator.setParticleEmitterActive("charged", false)
--  animator.setParticleEmitterActive("chargedback", false)
  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)

end

function TachyonFire:cooldown()
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

function TachyonFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
--  animator.burstParticleEmitter("backexhaust")
  animator.playSound("fire")

end

function TachyonFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
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

function TachyonFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function TachyonFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function TachyonFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function TachyonFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function TachyonFire:uninit()
--  animator.setParticleEmitterActive("charged", false)
--  animator.setParticleEmitterActive("chargedback", false)
--  animator.setParticleEmitterActive("cooldown", false)
--  animator.stopAllSounds("charged")
--  animator.stopAllSounds("zonepower")
  if animator.animationState("firing") == "loop" then
    animator.setAnimationState("firing","stop")
  end
end
