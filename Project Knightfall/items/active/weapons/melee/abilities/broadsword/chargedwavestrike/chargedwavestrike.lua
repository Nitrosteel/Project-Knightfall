require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

ChargedWaveStrike = WeaponAbility:new()

function ChargedWaveStrike:init()
  self.cooldownTimer = self.cooldownTime
end

function ChargedWaveStrike:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil 
	and self.fireMode == "alt" 
	and self.cooldownTimer == 0 
	and not status.resourceLocked("energy") 
	and not status.statPositive("activeMovementAbilities")
	and status.overConsumeResource("energy", self.energyUsage) then
		self:setState(self.windup)
  end
end

function ChargedWaveStrike:windup()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()
  
  status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  
  animator.playSound("Charge")
  
  local chargeTimer = 0.1
  local full
  
  while self.fireMode == "alt" and not full do
    if not status.overConsumeResource("energy", self.energyUsage / 2 * self.dt) then 
		break 
	end
	
    chargeTimer = math.min(2, chargeTimer + self.dt)
	animator.setGlobalTag("bladeDirectives", "flipx?border=2;4d7ec6"..self:num2hex(math.floor(chargeTimer * 127.5))..";00000000")
	coroutine.yield()
	
	if chargeTimer >= 2 then 
	  full = true
	end
  end
  
  self.weapon:setStance(self.stances.full)
  self.weapon:updateAim()
  
  animator.stopAllSounds("Charge")
  animator.playSound("waveCharged")
  
  while full and self.fireMode == "alt" do
    coroutine.yield()
  end
  
  util.wait(self.stances.windup.duration, function(dt)
    mcontroller.controlModifiers({jumpingSuppressed = true})
  end)
  
  self.chargeTimer = chargeTimer
  self:setState(self.dash)
end

function ChargedWaveStrike:dash()
  self.weapon:setStance(self.stances.dash)
  self.weapon:updateAim()
  
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
    power = self:damageAmount(),
	speed = 200 + self.chargeTimer * 25
  }
  
  animator.playSound("waveStrike")
  
  self.weapon:setStance(self.stances.slash)
  world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), self:aimVector(), false, params)
  animator.playSound(self:slashSound())
  
  local timer = self.chargeTimer / 2
  while timer > 0.1 do
    timer = math.max(0.1, timer - self.dt)
	animator.setGlobalTag("bladeDirectives", "flipx?border=2;4d7ec6"..self:num2hex(math.floor(timer * 255))..";00000000")
	coroutine.yield()
  end
  
  animator.setGlobalTag("bladeDirectives", "")
  
  self.cooldownTimer = self.cooldownTime
end

function ChargedWaveStrike:slashSound()
  return "TravelSlash"
end

function ChargedWaveStrike:num2hex(num)
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

function ChargedWaveStrike:aimVector()
  return {mcontroller.facingDirection(), 0}
end

function ChargedWaveStrike:damageAmount()
  return self.baseDamage * config.getParameter("damageLevelMultiplier") * self.chargeTimer
end

function ChargedWaveStrike:uninit()
	status.clearPersistentEffects("weaponMovementAbility")
end
