require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

ChargedTravelingSlash = WeaponAbility:new()

function ChargedTravelingSlash:init()
  self.chargeTime = self.chargeTime or 2

  self.cooldownTimer = self.cooldownTime
end

function ChargedTravelingSlash:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil and self.fireMode == "alt" and self.cooldownTimer == 0 and not status.resourceLocked("energy") then
    self:setState(self.windup)
  end
end

function ChargedTravelingSlash:windup()
  self.weapon:setStance(self.stances.windup)
  
  animator.playSound("charge")

  local chargeTimer = 0.1
  local full
  while self.fireMode == "alt" and not full do
    if not status.overConsumeResource("energy", self.energyUsage / 2 * self.dt) then break end
    chargeTimer = math.min(self.chargeTime, chargeTimer + self.dt)

	coroutine.yield()

	if chargeTimer >= self.chargeTime then 
	  full = true
	end
  end

  self.weapon:setStance(self.stances.full)
  self.weapon:updateAim()

  animator.stopAllSounds("charge")
  animator.playSound("charged")

  animator.resetTransformationGroup("rotatedSwoosh")
  animator.rotateTransformationGroup("rotatedSwoosh", 0)

  while full and self.fireMode == "alt" do
    coroutine.yield()
  end

  self.chargeTimer = chargeTimer
  self:setState(self.fire)
end

function ChargedTravelingSlash:fire()
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  local position = vec2.add(mcontroller.position(), {self.projectileOffset[1] * mcontroller.facingDirection(), self.projectileOffset[2]})
  local params = {
    powerMultiplier = activeItem.ownerPowerMultiplier(),
    power = self.baseDamage * config.getParameter("damageLevelMultiplier") * self.chargeTimer,
	speed = 200 + self.chargeTimer * 25
  }

  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)
  animator.playSound("travelslash")
  animator.setGlobalTag("bladeDirectives", "")
  animator.rotateTransformationGroup("rotatedSwoosh", self.stances.fire.swooshRotation or 0)

  util.wait(self.stances.fire.duration)
  
  self:setState(self.wait)
end

function ChargedTravelingSlash:wait()
  self.weapon:setStance(self.stances.wait)

  animator.resetTransformationGroup("rotatedSwoosh")
  animator.rotateTransformationGroup("rotatedSwoosh", 0)

  util.wait(self.stances.wait.duration)

  self:setState(self.comboSpin)
end

function ChargedTravelingSlash:comboSpin()
  self.weapon:setStance(self.stances.comboSpin)
  self.weapon:updateAim()

  animator.playSound("comboSpin")
  
  local progress = 0
  util.wait(self.stances.comboSpin.duration, function()

	self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.comboSpin.weaponRotation, self.stances.comboSpin.endWeaponRotation))
	self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.comboSpin.armRotation, self.stances.comboSpin.endArmRotation))

	progress = math.min(1.0, progress + (self.dt / self.stances.comboSpin.duration))
  end)
  
  self.cooldownTimer = self.cooldownTime
end

function ChargedTravelingSlash:aimVector()
  if not self.aimable then return {mcontroller.facingDirection(), 0} end

  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle)
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function ChargedTravelingSlash:uninit()
end