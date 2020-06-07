require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

PlasmaCannon = WeaponAbility:new()

function PlasmaCannon:init()
  self.cooldownTimer = self.cooldownTime
end

function PlasmaCannon:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and self.cooldownTimer == 0 and status.overConsumeResource("energy", self.energyUsage) then
    self:setState(self.windup)
  end
end

function PlasmaCannon:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  util.wait(self.stances.windup.duration)

  self:setState(self.fire)
end

function PlasmaCannon:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  local position = vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("blade", "projectileSource")))
  local params = {
    powerMultiplier = activeItem.ownerPowerMultiplier(),
    power = self:damageAmount()
  }
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {mcontroller.facingDirection() * math.cos(self.weapon.aimAngle), math.sin(self.weapon.aimAngle)}, false, params)

  animator.playSound(self:slashSound())

  util.wait(self.stances.fire.duration)
  self.cooldownTimer = self.cooldownTime
end

function PlasmaCannon:slashSound()
  return self.weapon.elementalType.."PlasmaCannon"
end

function PlasmaCannon:aimVector()
  return {mcontroller.facingDirection(), 0}
end

function PlasmaCannon:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier")
end

function PlasmaCannon:uninit()
end