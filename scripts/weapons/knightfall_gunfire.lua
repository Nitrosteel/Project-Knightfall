-- Original script by Nebulox.
-- Modified by Nitrosteel, using ChatGPT and Claude Sonnet 4.6.
--
-- Features:
--   * Pitch Variance
--   * Dynamic Inaccuracy
--   * Integrated Interval Projectiles
--
-- Last edited on 04/28/2026

require "/scripts/util.lua"
require "/scripts/interp.lua"

KFGunFire = WeaponAbility:new()

function KFGunFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.dynamicInaccuracyEnabled = self.enableDynamicInaccuracy or false
  self.baseInaccuracy = self.inaccuracy or 0
  self.finalInaccuracy = self.finalInaccuracy or self.inaccuracy
  self.inaccuracyRampTime = self.inaccuracyRampTime or 0
  self.inaccuracyResetTime = self.inaccuracyResetTime or 0
  self.inaccuracyGracePeriod = self.inaccuracyGracePeriod or 0

  self.dynamicInaccuracyActive =
    self.dynamicInaccuracyEnabled
    and self.finalInaccuracy
    and self.inaccuracyRampTime
    and self.inaccuracyResetTime

  self.currentInaccuracy = self.baseInaccuracy
  self.inaccuracyProgress = 0
  self.timeSinceLastFire = math.huge
  self.firedThisUpdate = false

  if self.altProjectile then
    self.altProjectile._shots = 0
  end

  if self.abilitySlot == "alt" then
    local altConfig = config.getParameter("altAbility")
    if altConfig and altConfig.projectileParameters then
      self.projectileParameters = altConfig.projectileParameters
    elseif altConfig and not altConfig.projectileParameters then
      self.projectileParameters = {}
    end
  end

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function KFGunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  self.firedThisUpdate = false

  self:updateDynamicInaccuracy(dt)

  if animator.animationState("firing") ~= "fire" then
    animator.setLightActive("muzzleFlash", false)
  end

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy")
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then

    if self.fireType == "auto" and status.overConsumeResource("energy", self:energyPerShot()) then
      self:setState(self.auto)
    elseif self.fireType == "burst" then
      self:setState(self.burst)
    end
  end
end

function KFGunFire:updateDynamicInaccuracy(dt)
  if not self.dynamicInaccuracyActive then return end

  if not self.firedThisUpdate then
    self.timeSinceLastFire = self.timeSinceLastFire + dt
  end

  if self.timeSinceLastFire > self.inaccuracyGracePeriod then
    if self.inaccuracyResetTime > 0 then
      self.inaccuracyProgress = math.max(0, self.inaccuracyProgress - dt / self.inaccuracyResetTime)
    else
      self.inaccuracyProgress = 0
    end
  end

  self.currentInaccuracy = interp.linear(
    self.inaccuracyProgress,
    self.baseInaccuracy,
    self.finalInaccuracy
  )
end

function KFGunFire:applyInaccuracyRamp(dt)
  if not self.dynamicInaccuracyActive then return end

  self.firedThisUpdate = true
  self.timeSinceLastFire = 0

  if self.inaccuracyRampTime > 0 then
    self.inaccuracyProgress = math.min(1, self.inaccuracyProgress + dt / self.inaccuracyRampTime)
  else
    self.inaccuracyProgress = 1
  end
end

function KFGunFire:shoot()
  if not self.altProjectile then
    self:fireProjectile()
    self:muzzleFlash()
    return nil
  end

  local alt = self.altProjectile
  alt._shots = (alt._shots + 1) % alt.interval

  if alt._shots == 0 then
    if alt.fireBoth then self:fireProjectile() end
    self:fireProjectile(alt.projectileType, alt.projectileParameters, alt.inaccuracy, nil, alt.projectileCount)
    self:muzzleFlash(alt.animation)
    return alt
  else
    self:fireProjectile()
    self:muzzleFlash()
    return nil
  end
end

function KFGunFire:auto()
  self:applyInaccuracyRamp(self.fireTime)

  local alt = self:shoot()

  local fireStance = (alt and alt.fireStance) or self.stances.fire
  self.weapon:setStance(fireStance)
  if fireStance.duration then
    util.wait(fireStance.duration)
  end

  self.cooldownTimer = (alt and alt.fireTime) or self.fireTime
  self:setState(function() self:cooldown((alt and alt.cooldownStance) or nil) end)
end

function KFGunFire:burst()
  local altShot
  local stance = self.stances.fire
  self.weapon:setStance(stance)

  local shots = self.burstCount
  while shots > 0 and status.overConsumeResource("energy", self:energyPerShot()) do
    self:applyInaccuracyRamp(self.burstTime)

    local alt = self:shoot()
    if alt then
      altShot = alt
      stance = alt.fireStance or stance
    end

    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, stance.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, stance.armRotation))

    util.wait(self.burstTime)
  end

  local t = (altShot and altShot.fireTime) or self.fireTime
  self.cooldownTimer = (t - self.burstTime) * self.burstCount
  self:setState(function() self:cooldown(altShot and altShot.cooldownStance or nil) end)
end

function KFGunFire:cooldown(stance)
  local cooldownStance = stance or self.stances.cooldown
  self.weapon:setStance(cooldownStance)
  self.weapon:updateAim()

  local progress = 0
  util.wait(cooldownStance.duration, function()
    local from = cooldownStance.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {
      interp.linear(progress, from[1], to[1]),
      interp.linear(progress, from[2], to[2])
    }

    self.weapon.relativeWeaponRotation = util.toRadians(
      interp.linear(progress, cooldownStance.weaponRotation, self.stances.idle.weaponRotation)
    )
    self.weapon.relativeArmRotation = util.toRadians(
      interp.linear(progress, cooldownStance.armRotation, self.stances.idle.armRotation)
    )

    progress = math.min(1.0, progress + (self.dt / cooldownStance.duration))
  end)
end

function KFGunFire:muzzleFlash(anim)
  if not anim then
    local pitchVariance = (1 + (self.pitchVariance or 0.15)) - (math.random() * ((self.pitchVariance or 0.15) * 2))
    animator.setSoundPitch("fire", pitchVariance)
    animator.playSound("fire")

    animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
    animator.setAnimationState("firing", "fire")

    animator.burstParticleEmitter("muzzleFlash")
    animator.setLightActive("muzzleFlash", true)
  else
    animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
    animator.setLightActive("muzzleFlash", true)
    animator.burstParticleEmitter(anim.burstParticle or "muzzleFlash")
    animator.playSound(anim.sound or "fire")

    if not anim.states then
      animator.setAnimationState("firing", "fire")
    else
      for k, v in pairs(anim.states) do
        animator.setAnimationState(k, v)
      end
    end
  end

  if self.fireAnimationStates then
    for k, v in pairs(self.fireAnimationStates) do
      animator.setAnimationState(k, v)
    end
  end
end

function KFGunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()

  local usedInaccuracy = inaccuracy or self.inaccuracy
  if self.dynamicInaccuracyActive then
    usedInaccuracy = self.currentInaccuracy
  end

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
      self:aimVector(usedInaccuracy),
      false,
      params
    )
  end
  return projectileId
end

function KFGunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function KFGunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function KFGunFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function KFGunFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime))
    * (self.baseDamageMultiplier or 1.0)
    * config.getParameter("damageLevelMultiplier")
    / self.projectileCount
end

function KFGunFire:uninit()
end