syndicate_krokodyl_utlities = {}

function syndicate_krokodyl_utlities.rotateAngle(angle, target, dt, speed)
  local function sign(x)
    return (x > 0 and 1) or (x < 0 and -1) or 0
  end

  local diff = (target - angle)
  
  local maxStep = (speed or 1) * dt
  if math.abs(diff) <= maxStep then
    return target
  end
  
  return (angle + sign(diff) * maxStep)
end

function bossReset()
  for _, entityId in pairs(self.bossSummons or {}) do
    if world.entityExists(entityId) then
      world.sendEntityMessage(entityId, "despawn")
    end
  end
end
