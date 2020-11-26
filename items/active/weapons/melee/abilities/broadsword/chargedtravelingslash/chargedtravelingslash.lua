require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

ChargedTravelingSlash = WeaponAbility:new()

function ChargedTravelingSlash:init()
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
  self.weapon:updateAim()
  
  animator.playSound(self.weapon.elementalType.."Charge")
  local chargeTimer = 0.1
  local full
  while self.fireMode == "alt" and not full do
    if not status.overConsumeResource("energy", self.energyUsage / 2 * self.dt) then break end
    chargeTimer = math.min(2, chargeTimer + self.dt)
	animator.setGlobalTag("bladeDirectives", "border=2;4d7ec6"..self:num2hex(math.floor(chargeTimer * 127.5))..";00000000")
	coroutine.yield()
	if chargeTimer >= 2 then 
	  full = true
	end
  end
  self.weapon:setStance(self.stances.full)
  self.weapon:updateAim()
  animator.stopAllSounds(self.weapon.elementalType.."Charge")
  animator.playSound(self.weapon.elementalType.."Charged")
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
    power = self:damageAmount(),
	speed = 200 + self.chargeTimer * 25
  }
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)
  animator.playSound(self:slashSound())
  
  local timer = self.chargeTimer / 2
  while timer > 0.1 do
    timer = math.max(0.1, timer - self.dt)
	animator.setGlobalTag("bladeDirectives", "border=2;4d7ec6"..self:num2hex(math.floor(timer * 255))..";00000000")
	coroutine.yield()
  end
  
  animator.setGlobalTag("bladeDirectives", "")
  
  self.cooldownTimer = self.cooldownTime
end

function ChargedTravelingSlash:slashSound()
  return self.weapon.elementalType.."TravelSlash"
end

function ChargedTravelingSlash:num2hex(num)
    local hexstr = '0123456789abcdef'
    local s = ''
    while num > 0 do
      local mod = math.fmod(num, 16)
      s = string.sub(hexstr, mod+1, mod+1) .. s
      num = math.floor(num / 16)
    end
    if s == '' then s = '0' end
    return s
end

function ChargedTravelingSlash:aimVector()
  if not self.aimable then return {mcontroller.facingDirection(), 0} end

  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle)
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function ChargedTravelingSlash:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier") * self.chargeTimer
end

function ChargedTravelingSlash:uninit()
end
