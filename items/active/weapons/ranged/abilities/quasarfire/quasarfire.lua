require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

--Vanilla beamfire script, which was edited by Nebulox into neb_beamfire, which was edited by Jetfire with the help of Lyr to make Quasar work :D
--Currently implemented: warmup-loop-cooldown cycle, ability to mine blocks, animated beam (Lyr's anibeam script).

--ToDo: beam impact mechanic, impact projectile sprite, sounds.

Quasarfire = WeaponAbility:new()

--Initiate weapon
function Quasarfire:init()
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
    animator.stopAllSounds("fireLoop")
    animator.stopAllSounds("fireLoop1")
    self.weapon:setStance(self.stances.idle)
  end
end

--Charging state
function Quasarfire:warmup()
  self.weapon:setStance(self.stances.warmup)
  self.weapon:updateAim()
  animator.playSound("charge")
  animator.setAnimationState("firing", "ch0")
  util.wait(self.stances.warmup.duration, function()
  end)
  self:setState(self.fire)
end

--Update and check if player uses Quasar.
function Quasarfire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
  self.impactSoundTimer = math.max(self.impactSoundTimer - self.dt, 0)
  self.impactDamageTimer = math.max(self.impactDamageTimer - self.dt, 0)

  if self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and not self.weapon.currentAbility
    and animator.animationState("firing") == "off"
    and not world.lineTileCollision(mcontroller.position(), self:firePosition())
    and self.cooldownTimer == 0
    and not status.resourceLocked("energy") then
    
    self:setState(self.warmup)
  end
end
--Firing the beam
function Quasarfire:fire()
  self.weapon:setStance(self.stances.fire)

  animator.playSound("fireStart")
  animator.setAnimationState("firing", "fire")
  animator.playSound("fireLoop", -1)
  animator.playSound("fireLoop1", -1)
  
  
  local wasColliding = false
  while (self.fireMode == (self.activatingFireMode or self.abilitySlot) and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt) and not world.lineTileCollision(mcontroller.position(), self:firePosition())) do
    local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(0)), self.beamLength))
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

      --Mine blocks at impact position
      world.damageTileArea(beamEnd, 3, "foreground", mcontroller.position(), "blockish", 0.8)
      
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
  self:setState(self.cooldown)
  self:reset()
  animator.playSound("fireEnd")
  self.cooldownTimer = self.fireTime
  
end

function Quasarfire:drawBeam(endPos, didCollide)
  local newChain = copy(self.chain)
  newChain.startOffset = vec2.add(self.weapon.muzzleOffset, self.chain.startOffset or 0)
  newChain.endPosition = endPos

  if not didCollide then
    newChain.endSegmentImage = nil
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end
--Cooldown state
function Quasarfire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()

  animator.setAnimationState("firing", "st0")
  util.wait(self.stances.cooldown.duration, function()


  end)
end
--Position from which the beam starts.
function Quasarfire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end
--Aim vector of the beam
function Quasarfire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end
--Kicks in when you select another slot/throw weapon away/remove it from hotbar
function Quasarfire:uninit()
  self:reset()
  animator.setAnimationState("firing", "off")
end

function Quasarfire:reset()
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("chains", {})
  animator.setParticleEmitterActive("beamCollision", false)
  animator.setParticleEmitterActive("beamParticles", false)
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
  animator.stopAllSounds("fireLoop1")
  animator.stopAllSounds("charge")
end
