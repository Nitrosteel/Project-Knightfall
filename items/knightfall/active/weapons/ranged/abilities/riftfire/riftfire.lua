require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
RiftFire = WeaponAbility:new()

function RiftFire:init()
  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function RiftFire:update(dt, fireMode, shiftHeld)
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

function RiftFire:charge()
  animator.setLightActive("muzzleFlash", true)
  self.weapon:setStance(self.stances.charge)
  self.weapon:updateAim()
  animator.playSound("charge")
  animator.setAnimationState("firing", "ch0")

  local chargeTimer = self.stances.charge.duration
  while chargeTimer > 0 and self.fireMode == (self.activatingFireMode or self.abilitySlot) do
    chargeTimer = chargeTimer - self.dt

    mcontroller.controlModifiers({runningSuppressed=true})

    coroutine.yield()
  end

  

  if chargeTimer <= 0 then
    self:setState(self.charged)

--    animator.playSound(self.elementalType.."discharge")
  end
	util.wait(0.784 + chargeTimer, function() end)
	self:setState(self.cooldown)
end

function RiftFire:charged()
  self.weapon:setStance(self.stances.charged)
  animator.setParticleEmitterActive("charged", true)
  animator.setParticleEmitterActive("chargedback", true)
  animator.playSound("ready")
  animator.playSound("charged",-1)
  animator.playSound("zonepower",-1)

--  animator.playSound(self.elementalType.."fullcharge")

--  animator.setParticleEmitterActive(self.elementalType .. "charge", true)

  local targetValid
  while self.fireMode == (self.activatingFireMode or self.abilitySlot) do 
    mcontroller.controlModifiers({runningSuppressed=true})
    coroutine.yield()
    animator.setAnimationState("firing", "loop")
  end
  if not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
  animator.setAnimationState("firing", "fire")
  self:setState(self.fire)
else
	animator.setAnimationState("firing", "stop")
	util.wait(0.784, function() end)
	self:setState(self.cooldown)
  end
end

--  function RiftFire:charge()
--  self.weapon:setStance(self.stances.charge)
--  self.weapon:updateAim()
--  animator.playSound("charge")
--  animator.setAnimationState("firing", "ch0")
--
--  util.wait(self.stances.charge.duration, function()
--  end)
--  self:setState(self.fire)
--end

function RiftFire:fire()
  status.overConsumeResource("energy", self:energyPerShot())
  self.weapon:setStance(self.stances.fire)
  animator.setParticleEmitterActive("charged", false)
  animator.setParticleEmitterActive("chargedback", false)
  self:fireProjectile()
  self:muzzleFlash()

  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)

end


function RiftFire:cooldown()
  animator.stopAllSounds("charged")
  animator.stopAllSounds("zonepower")
  animator.playSound("stop")
  self.weapon:setStance(self.stances.cooldown)
  animator.setParticleEmitterActive("cooldown", true)
  self.weapon:updateAim()

  util.wait(self.stances.cooldown.duration, function()
  end)
  animator.setParticleEmitterActive("cooldown", false)
end

function RiftFire:muzzleFlash()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", "fire")
  animator.burstParticleEmitter("muzzleFlash")
  animator.burstParticleEmitter("backexhaust")
  animator.playSound("fire")

end

function RiftFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
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

function RiftFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function RiftFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function RiftFire:energyPerShot()
  return self.energyUsage * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function RiftFire:damagePerShot()
  return (self.baseDamage or (self.baseDps * self.fireTime)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
end

function RiftFire:uninit()
  animator.setParticleEmitterActive("charged", false)
  animator.setParticleEmitterActive("chargedback", false)
  animator.setParticleEmitterActive("cooldown", false)
  animator.stopAllSounds("charged")
  animator.stopAllSounds("zonepower")
  if animator.animationState("firing") == "loop" then
    animator.setAnimationState("firing","stop")
  end
end
