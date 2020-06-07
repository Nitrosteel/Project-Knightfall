require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

WaveStrike = WeaponAbility:new()

function WaveStrike:init()
  self.cooldownTimer = self.cooldownTime
end

function WaveStrike:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.weapon.currentAbility == nil
     and self.fireMode == "alt"
     and self.cooldownTimer == 0
     and not status.statPositive("activeMovementAbilities")
     and status.overConsumeResource("energy", self.energyUsage) then

    self:setState(self.windup)
  end
end

function WaveStrike:windup()
  self.weapon:setStance(self.stances.windup)

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  animator.playSound("waveCharge")

  util.wait(self.stances.windup.duration, function(dt)
    mcontroller.controlModifiers({jumpingSuppressed = true})
  end)

  self:setState(self.dash)
end

function WaveStrike:dash()
  self.weapon:setStance(self.stances.dash)

  animator.playSound("waveDash")
  animator.burstParticleEmitter("dashBurst")

  local wasInvulnerable = status.stat("invulnerable") > 0
  status.addEphemeralEffect("invulnerable", self.dashTime)

  util.wait(self.dashTime, function(dt)
    mcontroller.setXVelocity(self.weapon.aimDirection * self.dashSpeed)
    mcontroller.controlMove(self.weapon.aimDirection)
    local damageArea = partDamageArea("blade")
    self.weapon:setDamage(self.damageConfig, damageArea)
  end)
  
  mcontroller.setXVelocity(self.weapon.aimDirection * self.dashSpeed / 8)
  
  local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
  local params = {
    powerMultiplier = activeItem.ownerPowerMultiplier(),
    power = self.baseDamage * config.getParameter("damageLevelMultiplier"),
	speed = 200
  }
  
  animator.playSound("waveStrike")
  
  self.weapon:setStance(self.stances.slash)
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {mcontroller.facingDirection(), 0}, false, params)
  util.wait(self.stances.slash.duration)
 
  self.cooldownTimer = self.cooldownTime
end

function WaveStrike:uninit()
  status.clearPersistentEffects("weaponMovementAbility")

  --[[if self.weapon.currentState == self.slash then
    mcontroller.setXVelocity(mcontroller.setXVelocity(self.weapon.aimDirection * self.dashSpeed / 8))
  end]]--
end
