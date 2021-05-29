local oldInit = init or function() end
local oldUpdate = update or function() end

function init()
	oldInit()
	
	streakActions = config.getParameter("streakActions")
	
	if streakActions then
		for _,action in ipairs(streakActions) do
			if action.time then
				action.timer = action.time
			end
		end
	end
end

function update(dt)
	oldUpdate(dt)
	
	if streakActions and not world.pointTileCollision(mcontroller.position()) then
		for _,action in ipairs(streakActions) do
			if action.time then
				action.timer = math.max(action.timer - dt, 0)
				if action.timer == 0 then
					projecitle.processAction(action)
					action.timer = action.time
				end
			else
				projectile.processAction(action)
			end
		end
	end
end
