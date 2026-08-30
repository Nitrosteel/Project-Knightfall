-- Created by Nebulox

require "/scripts/vec2.lua"

function init()
  self.targetRandSpeed = config.getParameter("targetRandSpeed", {50, 150})
  self.zeroApproachFactor = config.getParameter("zeroApproachFactor", 400)
  
  local targetSpeed = math.random(self.targetRandSpeed[1], self.targetRandSpeed[2])
  local currentVelocity = mcontroller.velocity()
  local newVelocity = vec2.mul(vec2.norm(currentVelocity), targetSpeed)
  mcontroller.setVelocity(newVelocity)
  
  self.finalVel = vec2.mul(newVelocity, 0.1)
end

function update()
  if config.getParameter("forceKillOnImpact") and (projectile.collision() or mcontroller.isCollisionStuck() or mcontroller.isColliding()) then
    projectile.die()
  end
  
  mcontroller.approachVelocity(self.finalVel, self.zeroApproachFactor)
end
