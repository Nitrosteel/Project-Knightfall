require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

Strikethrough = WeaponAbility:new()

function Strikethrough:init()
  self.cooldownTimer = self.cooldownTime
end

function Strikethrough:update(dt, fireMode, shiftHeld)
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

function Strikethrough:windup()
  self.weapon:setStance(self.stances.windup)

  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})

  animator.playSound("stCharge")

  util.wait(self.stances.windup.duration, function(dt)
    mcontroller.controlModifiers({jumpingSuppressed = true})
  end)

  self:setState(self.dash)
end

function Strikethrough:dash()
  self.weapon:setStance(self.stances.dash)

  animator.playSound("stDash")
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
  self.cooldownTimer = self.cooldownTime
end

function Strikethrough:uninit()
  status.clearPersistentEffects("weaponMovementAbility")

  if self.weapon.currentState == self.dash then
    mcontroller.setXVelocity(self.weapon.aimDirection * self.dashSpeed / 8)
  end
end
