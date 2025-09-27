--Not really an attack, just some idle time between attacks
syndicate_krokodyl_laserSweepState = {}

function syndicate_krokodyl_laserSweepState.enter()
  if not hasTarget() then return nil end

  return {
    chargeTimer = 0,
    chargeTime = config.getParameter("syndicate_krokodyl_laserSweepState.chargeTime", 2.5),

    fireTimer = 0,
    fireTime = config.getParameter("syndicate_krokodyl_laserSweepState.fireTime", 2.5),

    cooldownTimer = 0,
    cooldownTime = config.getParameter("syndicate_krokodyl_laserSweepState.cooldownTime", 2.5),
     
    beamAnimationTime = config.getParameter("syndicate_krokodyl_laserSweepState.beamAnimationTime", 1),
    beamFrames = config.getParameter("syndicate_krokodyl_laserSweepState.beamFrames", 1),
    beamChain = config.getParameter("syndicate_krokodyl_laserSweepState.beamChain"),
    beamDamageConfig = config.getParameter("syndicate_krokodyl_laserSweepState.beamDamageConfig")
  }
end

function syndicate_krokodyl_laserSweepState.enteringState(stateData)
  playSound("laserBeamStart")
  setActiveSkillName("syndicate_krokodyl_laserSweepState")
  animator.setAnimationState("laser_cannon", "charging4")
end

function syndicate_krokodyl_laserSweepState.update(dt, stateData)
  if stateData.chargeTimer then
    stateData.chargeTimer = stateData.chargeTimer + dt

    local angleVec = world.distance(self.targetPosition, mcontroller.position())
    self.targetLaserCannonAngle = math.atan(angleVec[2], math.abs(angleVec[1]))
    self.currentLaserCannonAngle = syndicate_krokodyl_utlities.rotateAngle(self.currentLaserCannonAngle or 0, self.targetLaserCannonAngle, dt, stateData.rotateSpeed or 1)
    
    if targetIsBehind() then return true end

    updateDamageSources(nil)
    monster.setAnimationParameter("chains", nil)
    
    if animator.animationState("laser_cannon") ~= "firing2_pre" and stateData.chargeTimer > (stateData.chargeTime - 0.09) then
	  animator.setParticleEmitterActive("laserCannonMuzzleFlash", true)
	  playSound("laserBeamLoop")
      animator.setAnimationState("laser_cannon", "firing2_pre")
    end

    if stateData.chargeTimer > stateData.chargeTime then
      stateData.chargeTimer = nil
      local newDamageConfig = sb.jsonMerge(stateData.beamDamageConfig, {})
      newDamageConfig.poly = flipPoly(stateData.beamDamageConfig.poly)
      newDamageConfig.damage = scalePower(stateData.beamDamageConfig.damage)
      updateDamageSources(newDamageConfig, false)
    end
  elseif stateData.fireTimer then
    stateData.fireTimer = stateData.fireTimer + dt

    monster.setAnimationParameter("chains", {syndicate_krokodyl_laserSweepState.drawBeam(stateData)})

    if stateData.fireTimer > stateData.fireTime then
	  animator.stopAllSounds("laserBeamLoop")
	  playSound("laserBeamEnd")
      animator.setAnimationState("laser_cannon", "firing2_post")
      stateData.fireTimer = nil
    end
  elseif stateData.cooldownTimer then
    stateData.cooldownTimer = stateData.cooldownTimer + dt

    updateDamageSources(nil)
    monster.setAnimationParameter("chains", nil)

    if stateData.cooldownTimer > stateData.cooldownTime then
      stateData.cooldownTimer = nil
    end
  else
    updateDamageSources(nil)
    monster.setAnimationParameter("chains", nil)
    return true
  end
end

function syndicate_krokodyl_laserSweepState.drawBeam(stateData)
  local newChain = copy(stateData.beamChain)

  local totalFrames = stateData.beamFrames
  local frameIndex = math.floor(stateData.fireTimer / stateData.beamAnimationTime) % totalFrames
  local currentFrame = frameIndex + 1

  if newChain.startSegmentImage then
    newChain.startSegmentImage = newChain.startSegmentImage:gsub("<frame>", currentFrame)
  end
  newChain.segmentImage = newChain.segmentImage:gsub("<frame>", currentFrame)
  if newChain.endSegmentImage then
    newChain.endSegmentImage = newChain.endSegmentImage:gsub("<frame>", currentFrame)
  end
  
  return newChain
end

function syndicate_krokodyl_laserSweepState.leavingState(stateData)
  setActiveSkillName()
  updateDamageSources(nil)
  animator.setParticleEmitterActive("laserCannonMuzzleFlash", false)
  animator.setAnimationState("laser_cannon", "idle")
  monster.setAnimationParameter("chains", nil)
end