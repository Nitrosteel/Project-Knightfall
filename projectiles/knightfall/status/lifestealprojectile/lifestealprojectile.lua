require "/scripts/vec2.lua"

function init()
  self.controlMovement = config.getParameter("controlMovement")
end

function update(dt)
  local target = world.entityPosition(projectile.sourceEntity())
  if not target then projectile.die() end

  local offset = world.distance(target, mcontroller.position())
  if vec2.mag(offset) < 3 then projectile.die() end

  mcontroller.approachVelocity(
      vec2.mul(vec2.norm(offset), self.controlMovement.maxSpeed),
      self.controlMovement.controlForce
  )
end

