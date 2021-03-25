require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

NebBeamFire = WeaponAbility:new()

function NebBeamFire:init()
  self.damageConfig.baseDamage = self.baseDps * self.fireTime

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.impactSoundTimer = 0
  self.impactDamageTimeout = self.impactDamageTimeout or 1.0
  self.impactDamageTimer = self.impactDamageTimeout
  
  self.weapon.onLeaveAbility = function()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("chains", {})
    animator.setParticleEmitterActive("beamCollision", false)
	animator.setParticleEmitterActive("muzzleFlash", false)
    animator.stopAllSounds("fireLoop")
    self.weapon:setStance(self.stances.idle)
  end
end

function NebBeamFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.impactSoundTimer = math.max(self.impactSoundTimer - self.dt, 0)
  self.impactDamageTimer = math.max(self.impactDamageTimer - self.dt, 0)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then

    self:setState(self.fire)
  end
end

function NebBeamFire:fire()
  self.weapon:setStance(self.stances.fire)

  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)
  
  animator.setParticleEmitterActive("muzzleFlash", true)
  
  local wasColliding = false
  while (self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt) and not world.lineTileCollision(mcontroller.position(), self:firePosition())) do
    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(self.inaccuracy or 0)), self.beamLength))
    local beamLength = self.beamLength
	local beamIsColliding = false

	--Do a line collision check on terrain
    local collidePoint = world.lineCollision(beamStart, beamEnd)
	if collidePoint then
	  beamIsColliding = true
	end
	
	--If the beam is colliding and not ending at max beam length
    if beamIsColliding == true then
      beamEnd = collidePoint

      beamLength = world.magnitude(beamStart, beamEnd)

      animator.setParticleEmitterActive("beamCollision", true)
      animator.resetTransformationGroup("beamEnd")
      animator.translateTransformationGroup("beamEnd", {beamLength, 0})

      if self.impactSoundTimer == 0 then
        animator.setSoundPosition("beamImpact", {beamLength, 0})
        animator.playSound("beamImpact")
        self.impactSoundTimer = self.fireTime
      end
	  
	  --Run through configured actions when the impact timer is ready
	  if self.impactDamageTimer == 0 then
	  
	  --If so configured, spawn a projectile at the impact position
		if self.spawnImpactProjectile then
		  world.spawnProjectile(
			self.impactProjectile,
			collidePoint,
			activeItem.ownerEntityId()
		  )
		end
		
		--Count down the impact timer again
		self.impactDamageTimer = self.impactDamageTimeout
	  end
    else
      animator.setParticleEmitterActive("beamCollision", false)
    end
	
	--Box collision type (uses beamWidth)
	if self.beamType == "box" then
	  local damagePoly = {
		vec2.add(self.weapon.muzzleOffset, {0, self.beamWidth/2}),
		vec2.add(self.weapon.muzzleOffset, {0, -self.beamWidth/2}),
		{self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2] - self.beamWidth/2},
		{self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2] + self.beamWidth/2}
	  }
	  self.weapon:setDamage(self.damageConfig, damagePoly, self.fireTime)
	
	--Taper collision type (uses beamWidth, tapers to a point)
	elseif self.beamType == "taper" then
	  local damagePoly = {
		vec2.add(self.weapon.muzzleOffset, {0, self.beamWidth/2}),
		vec2.add(self.weapon.muzzleOffset, {0, -self.beamWidth/2}),
		{self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]}
	  }
	  self.weapon:setDamage(self.damageConfig, damagePoly, self.fireTime)
	
	--Line collision type (default)
	elseif self.beamType == "line" or not self.beamType then
	  self.weapon:setDamage(self.damageConfig, {self.weapon.muzzleOffset, {self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]}}, self.fireTime)
	end
	
	--Draw the beam
    self:drawBeam(beamEnd, collidePoint)

    coroutine.yield()
  end
  
  self:reset()
  animator.playSound("fireEnd")

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function NebBeamFire:drawBeam(endPos, didCollide)
  local newChain = copy(self.chain)
  newChain.startOffset = vec2.add(self.weapon.muzzleOffset, self.chain.startOffset or 0)
  newChain.endPosition = endPos

  if didCollide then
    newChain.endSegmentImage = nil
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function NebBeamFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()
  
  util.wait(self.stances.cooldown.duration, function()

  end)
end

function NebBeamFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function NebBeamFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function NebBeamFire:uninit()
  self:reset()
end

function NebBeamFire:reset()
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("chains", {})
  animator.setParticleEmitterActive("beamCollision", false)
  animator.setParticleEmitterActive("beamParticles", false)
  animator.setParticleEmitterActive("muzzleFlash", false)
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
end
