require "/scripts/vec2.lua"

function init()  
  self.bounceFactor = config.getParameter("bounceFactor", 1) * -1
  self.entityBounces = config.getParameter("entityBounces", -1)
end

function update(dt)
end

function hit(entityId)
  if (self.entityBounces == -1) or (self.entityBounces > 0) then
	local estimatedPosition = vec2.mul(mcontroller.position(), mcontroller.velocity())--vec2.norm({math.abs(mcontroller.xVelocity()), math.abs(mcontroller.yVelocity())}))
	local angle = math.atan(estimatedPosition[2] - world.entityPosition(entityId)[2], estimatedPosition[1] - world.entityPosition(entityId)[1])

	sb.logInfo("Current Angle: %s", angle)
	--angle < highest and angle > lowest
	--divides the check into an X, where the entity position is the middle

	--Vertical
	local topQuarter = (angle < (3 * math.pi/4)) and (angle > (math.pi/4))
	local bottomQuarter = (angle < (-math.pi/4)) and (angle > (3 * -math.pi/4))
  
	--Horizontal
	local rightQuarter = (angle < (math.pi/4)) and (angle > (-math.pi/4))
	local leftQuarter = (angle < (3 * -math.pi/4)) and (angle > (-math.pi)) or (angle < (math.pi)) and (angle > (3 * math.pi/4))

	--Check where we are, and reflect our vector accordingly
	if rightQuarter or leftQuarter then
    mcontroller.setXVelocity(mcontroller.xVelocity() * self.bounceFactor)
	elseif topQuarter or bottomQuarter then
	  mcontroller.setYVelocity(mcontroller.yVelocity() * self.bounceFactor)
	end
	if self.entityBounces > 0 then
      self.entityBounces = self.entityBounces - 1
    end
  end
end
