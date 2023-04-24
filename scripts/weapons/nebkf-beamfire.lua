require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/util.lua"

NebKFBeamFire = WeaponAbility:new()

function NebKFBeamFire:init()

  self.weapon:setStance(self.stances.idle)

  self.cooldownTimer = self.fireTime
  self.impactSoundTimer = 0
  self.impactDamageTimeout = self.impactDamageTimeout or 1.0
  self.impactDamageTimer = self.impactDamageTimeout
  self.timeSpentFiring = 0
  
  self.chainAnimationTimer = 0
  
  --Optional animation set-up
  self.active = false
  if self.activeAnimation then
	animator.setAnimationState("body", "idle")
  end
  
  self:calculateDamage()
  
  self.weapon.onLeaveAbility = function()
    self.weapon:setDamage()
    activeItem.setScriptedAnimationParameter("chains", {})
    animator.setParticleEmitterActive("beamCollision", false)
	animator.setParticleEmitterActive("muzzleFlash", false)
    animator.stopAllSounds("fireLoop")
    self.weapon:setStance(self.stances.idle)
  end
  
  --For randomness in pitch
  self.pitchPerlinNoise = sb.makePerlinSource({seed = math.random(0, 65535), type = "perlin"})
end

function NebKFBeamFire:update(dt, fireMode, shiftHeld)
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
  
  --Optional animation while firing
  if self.activeAnimation then
	if self.active == false and animator.animationState("body") == "active" then
	  animator.setAnimationState("body", "deactivate")
	end
  end
end

function NebKFBeamFire:fire()
  self.weapon:setStance(self.stances.fire)

  animator.playSound("fireStart")
  animator.playSound("fireLoop", -1)
  
  animator.setParticleEmitterActive("muzzleFlash", true)
  
  --Optional animation while firing
  if self.activeAnimation then
	self.active = true
	animator.setAnimationState("body", "activate")
  end

  local wasColliding = false
  while (self.fireMode == (self.activatingFireMode or self.abilitySlot) or (self.minFiringTime and self.timeSpentFiring < self.minFiringTime)) and status.overConsumeResource("energy", (self.energyUsage or 0) * self.dt) and not world.lineTileCollision(mcontroller.position(), self:firePosition()) and not (self.maxFiringTime and self.timeSpentFiring > self.maxFiringTime) do
    --Sound pitch variance
	local pitchVariance = (1 + (self.pitchPerlinNoise:get(os.clock()) * (self.pitchVariance or 0)))
	if self.scalingDamage then
	  local maxTime = self:calculateDamage()
	  pitchVariance = pitchVariance * ((math.min(maxTime, self.timeSpentFiring) / maxTime * (#self.baseDps * 0.75)) + 1)
	end
	animator.setSoundPitch("fireLoop", pitchVariance)
	
	local beamStart = self:firePosition()
    local beamEnd = vec2.add(beamStart, vec2.mul(vec2.norm(self:aimVector(self.inaccuracy or 0)), self.beamLength))
    local beamLength = self.beamLength
	local beamIsColliding = false
	
	--Count up the firing time
	self.timeSpentFiring = self.timeSpentFiring + self.dt

	--Do a line collision check on terrain
    local collidePoint = world.lineCollision(beamStart, beamEnd)
	if collidePoint then
	  beamIsColliding = true
	end
	
	if self.laserPiercing == false then
	  local targets = world.entityLineQuery(beamStart, beamEnd, {
		withoutEntityId = activeItem.ownerEntityId(),
		includedTypes = {"creature"},
		order = "nearest"
	  })
	  --Set the default distance to nearest target to max search distance
	  local nearestTargetDistance = beamLength
	  for _, target in ipairs(targets) do
		--Make sure we can damage the targeted entity
		if world.entityCanDamage(activeItem.ownerEntityId(), target) then
		  local targetPosition = world.entityPosition(target)
		  --Make sure we have line of sight on this entity
		  if not world.lineCollision(beamStart, targetPosition) then
			local targetDistance = world.magnitude(beamStart, targetPosition)
			--If the target currently being processed is closer than the nearest target found so far, make this target the nearest target
			if targetDistance < nearestTargetDistance then
			  nearestTargetDistance = targetDistance
			  local beamDirection = vec2.rotate({1, 0}, self.weapon.aimAngle)
			  beamDirection[1] = beamDirection[1] * mcontroller.facingDirection()
			  local beamVector = vec2.mul(beamDirection, nearestTargetDistance)
			  collidePoint = vec2.add(beamStart, beamVector)
			  beamIsColliding = true
			end
		  end
		end
	  end
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
		
		--If so configured, deal tile damage at the impact position		
		--Foreground
		if self.impactTileDamageForeground then
		  local tileDamage = self.impactTileDamageForeground * self.impactDamageTimeout
		  if self.impactDamageRadius then
			world.damageTileArea(collidePoint, self.impactDamageRadius, "foreground", mcontroller.position(), "blockish", tileDamage, self.impactHarvestLevel or 99)
			world.debugText(tileDamage / self.impactDamageTimeout, collidePoint, "yellow")
			world.debugPoint(collidePoint, "red")
		  else
			local beamVector = vec2.norm(world.distance(beamStart, beamEnd))
			local damagePoint = vec2.sub(collidePoint, vec2.mul(beamVector, 0.25))
			world.damageTiles({damagePoint}, "foreground", mcontroller.position(), "blockish", tileDamage, self.impactHarvestLevel or 99)
			world.debugText(tileDamage / self.impactDamageTimeout, damagePoint, "yellow")
			world.debugPoint(damagePoint, "red")
		  end
		end
		--Background
		if self.impactTileDamageBackground then
		  local tileDamage = self.impactTileDamageBackground * self.impactDamageTimeout
		  if self.impactDamageRadius then
			world.damageTileArea(collidePoint, self.impactDamageRadius, "background", mcontroller.position(), "blockish", tileDamage, self.impactHarvestLevel or 99)
			world.debugText(tileDamage / self.impactDamageTimeout, collidePoint, "yellow")
			world.debugPoint(collidePoint, "red")
		  else
			local beamVector = vec2.norm(world.distance(beamStart, beamEnd))
			local damagePoint = vec2.sub(collidePoint, vec2.mul(beamVector, 0.25))
			world.damageTiles({damagePoint}, "background", mcontroller.position(), "blockish", tileDamage, self.impactHarvestLevel or 99)
			world.debugText(tileDamage / self.impactDamageTimeout, damagePoint, "yellow")
			world.debugPoint(damagePoint, "red")
		  end
		end
		
		--Count down the impact timer again
		self.impactDamageTimer = self.impactDamageTimeout
	  end
    else
      animator.setParticleEmitterActive("beamCollision", false)
    end
	
	--Code for particles along the length of the beam
	animator.setParticleEmitterActive("beamParticles", true)
	animator.setParticleEmitterEmissionRate("beamParticles", beamLength * (self.beamParticleEmissionRate or 0.1))
	animator.resetTransformationGroup("beam")
	animator.scaleTransformationGroup("beam", {beamLength / 2, self.beamWidth or 1})
	animator.translateTransformationGroup("beam", vec2.add(self.weapon.muzzleOffset, {beamLength / 2, 0}))
	
	--Box collision type (uses beamWidth)
	if self.beamCollisionType == "box" then
	  local damagePoly = {
		vec2.add(self.weapon.muzzleOffset, {0, self.beamWidth/2}),
		vec2.add(self.weapon.muzzleOffset, {0, -self.beamWidth/2}),
		{self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2] - self.beamWidth/2},
		{self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2] + self.beamWidth/2}
	  }
	  self.weapon:setDamage(self.damageConfig, damagePoly, self.fireTime)
	
	--Taper collision type (uses beamWidth, tapers to a point)
	elseif self.beamCollisionType == "taper" then
	  local damagePoly = {
		vec2.add(self.weapon.muzzleOffset, {0, self.beamWidth/2}),
		vec2.add(self.weapon.muzzleOffset, {0, -self.beamWidth/2}),
		{self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]}
	  }
	  self.weapon:setDamage(self.damageConfig, damagePoly, self.fireTime)
	
	--Line collision type (default)
	elseif self.beamCollisionType == "line" or not self.beamCollisionType then
	  self.weapon:setDamage(self.damageConfig, {self.weapon.muzzleOffset, {self.weapon.muzzleOffset[1] + beamLength, self.weapon.muzzleOffset[2]}}, self.fireTime)
	end
	
	--Draw the beam
    self:drawBeam(beamEnd, collidePoint)

    coroutine.yield()
  end

  --Optional animation while firing
  if self.activeAnimation then
	self.active = false
  end
  
  self:reset()
  animator.playSound("fireEnd")

  self.cooldownTimer = self.fireTime
  self:setState(self.cooldown)
end

function NebKFBeamFire:drawBeam(endPos, didCollide)
  local newChain = copy(self.chain)
  newChain.startOffset = vec2.add(self.weapon.muzzleOffset, self.chain.startOffset or 0)
  newChain.endPosition = endPos
  
  --Optionally animate the chain beam
  if self.animatedChain then
    local chainFrameTimer = (self.timeSpentFiring) % self.chainAnimationTime
	
    local chainAnimationFrame = math.ceil(chainFrameTimer / self.chainAnimationTime * self.chainAnimationFrames)
	chainAnimationFrame = math.floor(chainFrameTimer / self.chainAnimationTime * self.chainAnimationFrames)
	
	if self.chain.startSegmentImage then
	  newChain.startSegmentImage = self.chain.startSegmentImage:gsub("<beamFrame>", chainAnimationFrame)
	end
	if self.offsetFrames then
	  newChain.segmentFrameCount = self.chainAnimationFrames
	  local segmentImages = {}
	  for i = 1, self.chainAnimationFrames do
	    table.insert(segmentImages, self.chain.segmentImage:gsub("<beamFrame>", ((chainAnimationFrame + i) % (self.chainAnimationFrames - 1)))) 
	  end
	  newChain.segmentImages = segmentImages
	else
	  newChain.segmentImage = self.chain.segmentImage:gsub("<beamFrame>", chainAnimationFrame)
	end
	if self.chain.endSegmentImage then
	  newChain.endSegmentImage = self.chain.endSegmentImage:gsub("<beamFrame>", chainAnimationFrame)
	end
  end
  
  --Optionally hueshift the chain beam
  if self.hueShiftFrequency then
    local saturationIntensity = (math.min(self.baseDps[#self.baseDps][1], self.timeSpentFiring) / self.baseDps[#self.baseDps][1] * 100) - 75
	local hueShift = "?hueshift=" .. (self.timeSpentFiring / self.hueShiftFrequency * 360) % 360 
	newChain.segmentImage = newChain.segmentImage:gsub("<hueShift>", hueShift) .. "?saturation=" .. (self.saturateBeamIntensity and saturationIntensity or 0)
	if newChain.startSegmentImage then
	  newChain.startSegmentImage = newChain.startSegmentImage:gsub("<hueShift>", hueShift) .. "?saturation=" .. (self.saturateBeamIntensity and saturationIntensity or 0)
	end
	if newChain.endSegmentImage then
	  newChain.endSegmentImage = newChain.endSegmentImage:gsub("<hueShift>", hueShift) .. "?saturation=" .. (self.saturateBeamIntensity and saturationIntensity or 0)
	end
  end
  
  if didCollide then
    newChain.endSegmentImage = nil
  end

  activeItem.setScriptedAnimationParameter("chains", {newChain})
end

function NebKFBeamFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
  self.weapon:updateAim()
  
  self.timeSpentFiring = 0

  util.wait(self.stances.cooldown.duration, function()

  end)
end

function NebKFBeamFire:calculateDamage()
  local lastTime = 0
  local baseDps = self.baseDps
  
  local currentTD
  local lastTD = {0, 0}
  if type(self.baseDps) == "table" then
	self.scalingDamage = true
	lastTime = self.baseDps[#self.baseDps][1]
	
	for _, damageTime in ipairs(self.baseDps) do
	  currentTD = damageTime
	  
	  if (self.timeSpentFiring < currentTD[1]) then
	    break
	  end

	  lastTD = damageTime
	end
  end

  if currentTD then
	local x = self.useDamageCeiling and math.min(lastTime, self.timeSpentFiring) or self.timeSpentFiring
	
	local scaleFactor = currentTD[1] - lastTD[1]
	local timeScaled = (x - lastTD[1]) / (currentTD[1] - lastTD[1])
	
	local damageDif = currentTD[2] - lastTD[2]
	local damageDifScaled = timeScaled * damageDif
	local targetDamage = damageDifScaled + lastTD[2]
	
	baseDps = targetDamage
  else
	baseDps = lastTD[2]
  end
  
  self.damageConfig.baseDamage = baseDps * self.fireTime
  
  return lastTime
end

function NebKFBeamFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function NebKFBeamFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function NebKFBeamFire:uninit()
  self:reset()
end

function NebKFBeamFire:reset()
  self.weapon:setDamage()
  activeItem.setScriptedAnimationParameter("chains", {})
  animator.setParticleEmitterActive("beamCollision", false)
  animator.setParticleEmitterActive("beamParticles", false)
  animator.setParticleEmitterActive("muzzleFlash", false)
  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireLoop")
  animator.setSoundPitch("fireLoop", 1)
  self.timeSpentFiring = 0
end

function Weapon:damageSource(damageConfig, damageArea, damageTimeout)
  if damageArea then
    local knockback = damageConfig.knockback
    if knockback and damageConfig.knockbackDirectional ~= false then
      knockback = knockbackMomentum(damageConfig.knockback, damageConfig.knockbackMode, self.aimAngle, self.aimDirection)
    end
    local damage = damageConfig.baseDamage * (self.ignoreMultipliers == false and (self.damageLevelMultiplier * activeItem.ownerPowerMultiplier()) or 1)

    local damageLine, damagePoly
    if #damageArea == 2 then
      damageLine = damageArea
    else
      damagePoly = damageArea
    end

    return {
      poly = damagePoly,
      line = damageLine,
      damage = damage,
      trackSourceEntity = damageConfig.trackSourceEntity,
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      damageSourceKind = damageConfig.damageSourceKind,
      statusEffects = damageConfig.statusEffects,
      knockback = knockback or 0,
      rayCheck = true,
      damageRepeatGroup = damageRepeatGroup(damageConfig.timeoutGroup),
      damageRepeatTimeout = damageTimeout or damageConfig.timeout
    }
  end
end
