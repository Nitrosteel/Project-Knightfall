--un momento de la patman
--ignore anything that sucks
--you probably shouldve gotten someone who doesnt suck to do this
--but it works so eat shit

require "/scripts/vec2.lua"
require "/scripts/util.lua"

local oldInit = init or function() end
local oldUpdate = update or function() end

function init()
	oldInit()
	
	self.scopeConfig = config.getParameter("scopeConfig", {})
	self.cameraPos = mcontroller.position()
	self.cameraReturnTimer = 0
end

function update(dt, fireMode, shiftHeld)
	oldUpdate(dt, fireMode, shiftHeld)
	
	if shiftHeld then
		if self.cameraReturnTimer == 0 then
			self.cameraPos = mcontroller.position()
		end
		self.cameraReturnTimer = 1
		
		local scaledMax = self.scopeConfig.maxDistance * (self.scopeConfig.scale or 1.5)
		local toCursor = world.magnitude(mcontroller.position(), activeItem.ownerAimPosition())
		local distance = util.lerp(math.min(scaledMax, toCursor) / scaledMax, 0, self.scopeConfig.maxDistance)
		
		local pos = vec2.rotate({distance, 0}, self.weapon.aimAngle)
		pos[1] = pos[1] * mcontroller.facingDirection()
		pos = vec2.add(mcontroller.position(), pos)
		
		--current + ((target - current) * speed)
		self.cameraPos = vec2.add(self.cameraPos, vec2.mul(vec2.sub(pos, self.cameraPos), self.scopeConfig.zoomSpeed or 0.2))
		
		moveCamera(self.cameraPos)
		
		world.debugLine(self.cameraPos, mcontroller.position(), "orange")
		
	elseif self.cameraReturnTimer > 0 then
		self.cameraReturnTimer = math.max(0, self.cameraReturnTimer - (dt / self.scopeConfig.returnTime or 0.25))
		
		if self.cameraReturnTimer == 0 then
			activeItem.setCameraFocusEntity(activeItem.ownerEntityId())
		else
			self.cameraPos = vec2.lerp(self.cameraReturnTimer, mcontroller.position(), self.cameraPos)
			moveCamera(self.cameraPos)
		end
	end
end

function moveCamera(pos)
	local params = {
		speed = 0,
		timeToLive = 0.1,
		onlyHitTerrain = true,
		movementSettings = { collisionEnabled = false }
	}
	local id = world.spawnProjectile("invisibleprojectile", pos, activeItem.ownerEntityId(), {0, 0}, false, params)
	activeItem.setCameraFocusEntity(id)
end