syndicate_krokodyl_laserBlastState = {}

function syndicate_krokodyl_laserBlastState.enter()
  if not hasTarget() then return nil end

  return {
    chargeTimer = 0,
    chargeTime = config.getParameter("syndicate_krokodyl_laserBlastState.chargeTime", 2.5),
    delayTime = config.getParameter("syndicate_krokodyl_laserBlastState.delayTime", 2.5),

    reticleSpawnDelay = config.getParameter("syndicate_krokodyl_laserBlastState.reticleSpawnDelay", 3),
    reticleFrames = config.getParameter("syndicate_krokodyl_laserBlastState.reticleFrames"),
    reticleImage = config.getParameter("syndicate_krokodyl_laserBlastState.reticleImage"),

    projectileType = config.getParameter("syndicate_krokodyl_laserBlastState.projectileType"),
    projectileParameters = config.getParameter("syndicate_krokodyl_laserBlastState.projectileParameters"),
    projectileCount = config.getParameter("syndicate_krokodyl_laserBlastState.projectileCount"),
    
    inaccuracy = config.getParameter("syndicate_krokodyl_laserBlastState.inaccuracy"),
    rotateSpeed = config.getParameter("syndicate_krokodyl_laserBlastState.rotateSpeed"),
    aimAngleMinMax = config.getParameter("syndicate_krokodyl_laserBlastState.aimAngleMinMax"),

    cooldownTimer = 0,
    cooldownTime = config.getParameter("syndicate_krokodyl_laserBlastState.cooldownTime", 2.5),
    
    stateToChargePercent = config.getParameter("syndicate_krokodyl_laserBlastState.stateToChargePercent"),
    triggeredStates = {}
  }
end

function syndicate_krokodyl_laserBlastState.enteringState(stateData)
  playSound("laserChargeup")
  setActiveSkillName("syndicate_krokodyl_laserBlastState")
end

function syndicate_krokodyl_laserBlastState.update(dt, stateData)
  if status.resourcePercentage("health") <= 0 then
	  return true
  end
  
  if not self.targetId or not world.entityExists(self.targetId) or not self.targetPosition then
    animator.stopAllSounds("laserChargeup")
    animator.stopAllSounds("laserCannonFire")
    animator.stopAllSounds("laserWarning")
    animator.setParticleEmitterActive("laserCannonMuzzleFlash", false)
    animator.setAnimationState("laser_cannon", "idle")
    animator.resetTransformationGroup("lasercannon")
    monster.setAnimationParameter("markerImages", nil)
    return true
  end
  
  if stateData.chargeTimer then
    stateData.chargeTimer = stateData.chargeTimer + dt
    
    if targetIsBehind() then 
	    animator.stopAllSounds("laserChargeup")
      return true 
    end

    for state, timeThreshold in pairs(stateData.stateToChargePercent) do
      local ratio = stateData.chargeTimer / stateData.chargeTime
      if ratio >= timeThreshold and not stateData.triggeredStates[state] then
        animator.setAnimationState("laser_cannon", state)
        stateData.triggeredStates[state] = true
      end
    end

    if stateData.chargeTimer < (stateData.chargeTime - stateData.delayTime) then
      if stateData.chargeTimer > stateData.reticleSpawnDelay then
        local currentFrame = math.min(math.floor(math.min(((stateData.chargeTimer - stateData.reticleSpawnDelay) / (stateData.chargeTime - stateData.delayTime - stateData.reticleSpawnDelay)), 1) * stateData.reticleFrames), stateData.reticleFrames)
		
        if not stateData.alertSent then
          playSound("laserWarning")
          stateData.alertSent = true
        end
		
        local reticleConfig = {
          image = stateData.reticleImage:gsub("<frame>", currentFrame),
          position = self.targetPosition
        }
        monster.setAnimationParameter("markerImages", {reticleConfig})
      end

      local angleVec = world.distance(self.targetPosition, mcontroller.position())
      self.targetLaserCannonAngle = math.atan(angleVec[2], math.abs(angleVec[1]))

      if stateData.aimAngleMinMax then
        local baseAngle = self.targetLaserCannonAngle
        self.targetLaserCannonAngle = util.clamp(self.targetLaserCannonAngle or 0, math.rad(stateData.aimAngleMinMax[1]), math.rad(stateData.aimAngleMinMax[2]))
        
        if self.targetLaserCannonAngle ~= baseAngle then
          canFire = false
        end
      end

      self.currentLaserCannonAngle = syndicate_krokodyl_utlities.rotateAngle(self.currentLaserCannonAngle or 0, self.targetLaserCannonAngle, dt, stateData.rotateSpeed or 1)

      animator.resetTransformationGroup("lasercannon")
      local rotCentre = animator.partPoint("laser_cannon", "rotationCentre")
      rotCentre[1] = rotCentre[1] * mcontroller.facingDirection()
      animator.rotateTransformationGroup("lasercannon", self.currentLaserCannonAngle, rotCentre)
	  
    elseif stateData.chargeTimer > stateData.chargeTime then
	    animator.stopAllSounds("laserChargeup")
	    animator.setParticleEmitterActive("laserCannonMuzzleFlash", true)
      playSound("laserCannonFire")
      animator.setAnimationState("laser_cannon", "firing1")
      stateData.chargeTimer = nil

      stateData.projectileParameters.power = scalePower(stateData.projectileParameters.power or 1)

      fireProjectile(
        stateData,
        syndicate_krokodyl_laserBlastState.firePosition(),
        syndicate_krokodyl_laserBlastState.aimVector(stateData)
      )
    end
  elseif stateData.cooldownTimer then
    if stateData.cooldownTimer > stateData.delayTime then
      self.targetLaserCannonAngle = 0
      self.currentLaserCannonAngle = syndicate_krokodyl_utlities.rotateAngle(self.currentLaserCannonAngle or 0, self.targetLaserCannonAngle, dt, (stateData.rotateSpeed/2) or 1)

      animator.resetTransformationGroup("lasercannon")
      local rotCentre = animator.partPoint("laser_cannon", "rotationCentre")
      rotCentre[1] = rotCentre[1] * mcontroller.facingDirection()
      animator.rotateTransformationGroup("lasercannon", self.currentLaserCannonAngle, rotCentre)
    end

    if not stateData.overheating then
      animator.setAnimationState("laser_cannon", "firing1_post")
      stateData.overheating = true
    end
	
    monster.setAnimationParameter("markerImages", nil)
    stateData.cooldownTimer = stateData.cooldownTimer + dt

    if stateData.cooldownTimer > stateData.cooldownTime then
      stateData.cooldownTimer = nil
    end
  else
    monster.setAnimationParameter("markerImages", nil)
    return true
  end
end

function syndicate_krokodyl_laserBlastState.firePosition()
  return vec2.add(mcontroller.position(), animator.partPoint("laser_cannon", "muzzlePoint"))
end

function syndicate_krokodyl_laserBlastState.aimVector(stateData)
  local aimVector = vec2.rotate({1, 0}, self.currentLaserCannonAngle + sb.nrand(stateData.inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function syndicate_krokodyl_laserBlastState.leavingState(stateData)
  setActiveSkillName()
  
  animator.stopAllSounds("laserChargeup")
  animator.stopAllSounds("laserCannonFire")
  animator.stopAllSounds("laserWarning")

  animator.setParticleEmitterActive("laserCannonMuzzleFlash", false)

  animator.resetTransformationGroup("lasercannon")
  animator.setAnimationState("laser_cannon", "idle")

  monster.setAnimationParameter("markerImages", nil)

  self.currentLaserCannonAngle = 0
  self.targetLaserCannonAngle = 0
end
