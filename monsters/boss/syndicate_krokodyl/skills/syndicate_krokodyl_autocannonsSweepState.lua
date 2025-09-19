syndicate_krokodyl_autocannonsSweepState = {}

function syndicate_krokodyl_autocannonsSweepState.enter()
  if not hasTarget() then return nil end

  return {
    timer = 0,
    totalTime = config.getParameter("syndicate_krokodyl_autocannonsSweepState.totalTime", 2.5),
    anglePoints = config.getParameter("syndicate_krokodyl_autocannonsSweepState.anglePoints", {0, 90, 0}),
    
    projectileType = config.getParameter("syndicate_krokodyl_autocannonsSweepState.projectileType"),
    projectileParameters = config.getParameter("syndicate_krokodyl_autocannonsSweepState.projectileParameters"),
    projectileCount = config.getParameter("syndicate_krokodyl_autocannonsSweepState.projectileCount"),
    inaccuracy = config.getParameter("syndicate_krokodyl_autocannonsSweepState.inaccuracy"),
    fireTime = config.getParameter("syndicate_krokodyl_autocannonsSweepState.fireTime"),
    fireTimer = config.getParameter("syndicate_krokodyl_autocannonsSweepState.fireTime")
  }
end

function syndicate_krokodyl_autocannonsSweepState.enteringState(stateData)
  setActiveSkillName("syndicate_krokodyl_autocannonsSweepState")
end

function syndicate_krokodyl_autocannonsSweepState.update(dt, stateData)
  if targetIsBehind() then return true end

  if stateData.timer < stateData.totalTime then
    local t = stateData.timer / stateData.totalTime
    self.targetAutocannonAngle = syndicate_krokodyl_autocannonsSweepState.easeStuff(t, math.rad(stateData.anglePoints[1]), math.rad(stateData.anglePoints[2]), math.rad(stateData.anglePoints[3]))
    stateData.timer = stateData.timer + dt

    self.currentAutocannonAngle = syndicate_krokodyl_utlities.rotateAngle(self.currentAutocannonAngle or 0, self.targetAutocannonAngle, dt, 25)

    animator.resetTransformationGroup("autocannons")
    local rotCentre = animator.partPoint("autocannons", "rotationCentre")
    rotCentre[1] = rotCentre[1] * mcontroller.facingDirection()
    animator.rotateTransformationGroup("autocannons", self.currentAutocannonAngle, rotCentre)
      
    stateData.fireTimer = math.max(stateData.fireTimer - dt, 0)
    if stateData.fireTimer == 0 then
      animator.setAnimationState("autocannons", "firing")
      animator.burstParticleEmitter("autocannonMuzzleFlash")
      playSound("autocannonFire")

      fireProjectile(
        stateData,
        syndicate_krokodyl_autocannonsSweepState.firePosition(),
        syndicate_krokodyl_autocannonsSweepState.aimVector(stateData)
      )

      stateData.fireTimer = stateData.fireTime
    end
  else
    return true
  end
end

function syndicate_krokodyl_autocannonsSweepState.firePosition()
  return vec2.add(mcontroller.position(), animator.partPoint("autocannons", "muzzlePoint"))
end

function syndicate_krokodyl_autocannonsSweepState.aimVector(stateData)
  local aimVector = vec2.rotate({1, 0}, self.currentAutocannonAngle + sb.nrand(stateData.inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function syndicate_krokodyl_autocannonsSweepState.easeStuff(ratio, a1, a2, a3)
  return interp.ranges(ratio, {
    {0.5, interp.sin, a1, a2},                         -- ease in
    {1.0, interp.sin, a2, a3}          -- ease out
  })
end

function syndicate_krokodyl_autocannonsSweepState.leavingState(stateData)
  setActiveSkillName()
end