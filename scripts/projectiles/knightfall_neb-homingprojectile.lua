require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.targetSpeed = config.getParameter("targetHomingSpeed") or vec2.mag(mcontroller.velocity())
  self.searchDistance = config.getParameter("searchRadius", 200)
  self.homingStyle = config.getParameter("homingStyle")
  if self.homingStyle == "controlVelocity" then
	  self.controlForce = config.getParameter("baseHomingControlForce", 2) * self.targetSpeed
  elseif self.homingStyle == "rotateToTarget" then
    self.rotationRate = config.getParameter("rotationRate")
    self.trackingLimit = config.getParameter("trackingLimit")
  end

  self.countdownTimer = config.getParameter("homingStartDelay")
  self.snapAfterDelay = config.getParameter("snapAfterDelay")
end

function update(dt)
  if self.countdownTimer and self.countdownTimer > 0 then
    self.countdownTimer = math.max(0, self.countdownTimer - dt)

    return
  end

  local targets = scanTargets()

  if #targets > 0 then
    local currentVelocity = mcontroller.velocity()
    local newVelocity = vec2.mul(vec2.norm(currentVelocity), self.targetSpeed)
    mcontroller.setVelocity(newVelocity)
  end

  local trackedTarget
  for _, target in ipairs(targets) do
    if entity.entityInSight(target) and world.entityCanDamage(projectile.sourceEntity(), target) then
      trackedTarget = target
      
      break
      return
    end
  end

  if trackedTarget then
    local targetPos = world.entityPosition(trackedTarget)
    local myPos = mcontroller.position()
    local dist = world.distance(targetPos, myPos)

    if self.countdownTimer == 0 then
      mcontroller.setVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed))
      
      self.countdownTimer = nil
    end

    if self.homingStyle == "controlVelocity" then
      mcontroller.approachVelocity(vec2.mul(vec2.norm(dist), self.targetSpeed), self.controlForce)
    elseif self.homingStyle == "rotateToTarget" then
      local vel = mcontroller.velocity()
      local angle = vec2.angle(vel)
      local toTargetAngle = util.angleDiff(angle, vec2.angle(dist))
      
      if math.abs(toTargetAngle) > self.trackingLimit then
        return
      end

      local rotateAngle = math.max(dt * -self.rotationRate, math.min(toTargetAngle, dt * self.rotationRate))

      vel = vec2.rotate(vel, rotateAngle)
      mcontroller.setVelocity(vel)
    end
  end
end

function scanTargets()
  local targets = world.entityQuery(mcontroller.position(), self.searchDistance, {
    withoutEntityId = projectile.sourceEntity(),
    includedTypes = {"creature"},
    order = "nearest"
  })
  return targets
end