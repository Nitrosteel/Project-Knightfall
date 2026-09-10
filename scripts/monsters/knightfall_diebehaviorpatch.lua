-- Script provided by Void Eye.

local oldDie = die or function() end

function die()
  if self.deathBehavior then
    local board = self.deathBehavior:blackboard()
    board:setEntity("self", entity.id())
    board:setPosition("self", mcontroller.position())
    board:setNumber("dt", script.updateDt())
    board:setNumber("facingDirection", self.facingDirection or mcontroller.facingDirection())
  end

  oldDie()
end