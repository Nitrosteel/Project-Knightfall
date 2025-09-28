syndicate_krokodyl_chargeState = {}

function syndicate_krokodyl_chargeState.enter()
  if not hasTarget() then return nil end

  return {
    facingDirection = 1,
    collided = false,
    chargeTimer = 0,

    targetSpeed = config.getParameter("syndicate_krokodyl_chargeState.targetSpeed"),
    timeToReachTargetSpeed = config.getParameter("syndicate_krokodyl_chargeState.timeToReachTargetSpeed"),
    animStateToSpeed = config.getParameter("syndicate_krokodyl_chargeState.animStateToSpeed"),

    chargeTimeout = config.getParameter("syndicate_krokodyl_chargeState.chargeTimeout"),
    collisionProjectileType = config.getParameter("syndicate_krokodyl_chargeState.collisionProjectileType"),
    collisionProjectileParameters = config.getParameter("syndicate_krokodyl_chargeState.collisionProjectileParameters"),
    tileXRayCast = config.getParameter("syndicate_krokodyl_chargeState.tileXRayCast"),

    chargeDamageConfig = config.getParameter("syndicate_krokodyl_chargeState.chargeDamageConfig")
  }
end

function syndicate_krokodyl_chargeState.enteringState(stateData)
  playSound("charge")
  setActiveSkillName("syndicate_krokodyl_chargeState")
  stateData.facingDirection = mcontroller.facingDirection()
  self.charging = false
end

function syndicate_krokodyl_chargeState.update(dt, stateData)
  if not hasTarget() then return true end
  mcontroller.controlFace(stateData.facingDirection)

  if stateData.collided then
    local spawnPosition = vec2.add(mcontroller.position(), {stateData.tileXRayCast * stateData.facingDirection, -4})
    local params = stateData.collisionProjectileParameters
    params.power = scalePower(params.power or 1)
    world.spawnProjectile(stateData.collisionProjectileType, spawnPosition, entity.id(), {stateData.facingDirection, 0}, false, params)
    mcontroller.setVelocity({5 * -stateData.facingDirection, 15})

    updateDamageSources(nil)

    stateData.collided = false
    self.charging = false
    animator.setAnimationState("movement", "off")
    mcontroller.controlFace(stateData.facingDirection * -1)
    return true
  else
    self.charging = true

    stateData.chargeTimer = stateData.chargeTimer + dt
    if stateData.chargeTimer >= stateData.chargeTimeout then
      return true
    end
    
    local position = mcontroller.position()
    stateData.collided = world.lineTileCollisionPoint(position, vec2.add(position, {stateData.tileXRayCast * stateData.facingDirection, 0}))
    world.debugPoint(vec2.add(position, {stateData.tileXRayCast * stateData.facingDirection, 0}), "red")
    
    speedFactor = math.min(stateData.chargeTimer, stateData.timeToReachTargetSpeed) / stateData.timeToReachTargetSpeed
    mcontroller.setXVelocity(speedFactor * stateData.targetSpeed * mcontroller.facingDirection())

    for animState, speedCheck in pairs(stateData.animStateToSpeed) do 
      if speedCheck and (animator.animationState("movement") ~= animState and vec2.mag(mcontroller.velocity()) > speedCheck) then
        stateData.animStateToSpeed[animState] = nil
        animator.setAnimationState("movement", animState)
      end
    end

    local newConfig = sb.jsonMerge(stateData.chargeDamageConfig, {})
    newConfig.damage = scalePower(newConfig.damage) * (1 + speedFactor)
    updateDamageSources(newConfig, true)
  end
end

function syndicate_krokodyl_chargeState.leavingState(stateData)
  animator.stopAllSounds("charge")
  setActiveSkillName()
  self.charging = false
  animator.setAnimationState("movement", "off")
end