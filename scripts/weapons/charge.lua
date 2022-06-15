require "/items/active/weapons/ranged/abilities/chargefire/chargefire.lua"

local oi = ChargeFire.init
function ChargeFire:init()
	oi(self)
	
	animator.setAnimationState("firing", "off")
	
	self.maxChargeTime = 0
	for _,c in ipairs(self.chargeLevels) do
		if c.time > self.maxChargeTime then
			self.maxChargeTime = c.time
		end
	end
end

function ChargeFire:charge()
	self.chargeTimer = 0
	
	if not self.shiftHeld then
		self.weapon:setStance(self.stances.charge)
		animator.setAnimationState("firing", "charge")
		
		while self.fireMode == (self.activatingFireMode or self.abilitySlot)
		and self.chargeTimer < self.maxChargeTime
		and not status.resourceLocked("energy") do
			self.chargeTimer = self.chargeTimer + self.dt
			coroutine.yield()
		end
	end
	
  self.chargeLevel = self:currentChargeLevel()
  local energyCost = (self.chargeLevel and self.chargeLevel.energyCost) or 0
	
  if self.chargeLevel
	and not world.lineTileCollision(mcontroller.position(), self:firePosition())
	and (energyCost == 0 or status.overConsumeResource("energy", energyCost)) then
    self:setState(self.fire)
  else
		animator.setAnimationState("firing", "off")
	end
end

function ChargeFire:fire()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, self.chargeLevel.muzzleFlashVariants or 3))
  animator.setAnimationState("firing", self.chargeLevel.fireAnimationState or "fire")
	animator.burstParticleEmitter(self.chargeLevel.particleEmitter or "muzzleFlash")
  animator.playSound(self.chargeLevel.fireSound or "fire")

  self:fireProjectile()

  self.weapon:setStance(self.stances.fire)
  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end

  self.cooldownTimer = self.chargeLevel.cooldown or 0

  self:setState(self.cooldown, self.cooldownTimer)
end

function ChargeFire:firePosition()
	local pos = self.weapon.muzzleOffset
	if self.chargeLevel and self.chargeLevel.projectileOffset then
		pos = vec2.add(pos, self.chargeLevel.projectileOffset)
	end
  return vec2.add(mcontroller.position(), activeItem.handPosition(pos))
end