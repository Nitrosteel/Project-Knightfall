require "/scripts/vec2.lua"

local oldInit = init or function() end
local oldUpdate = update or function() end

function init()
	oldInit()
	
	streakActions = config.getParameter("streakActions")
	
	if streakActions then
		for _,action in ipairs(streakActions) do
			if action.time then
				action._timer = action.time
			end
		end
	end
end

function update(dt)
	oldUpdate(dt)
	
	-- skip first update so trail doesnt spawn behind
	-- terrible fix but i dont care
	if not skipped then
		skipped = true
		return
	end
	
	if streakActions and not world.pointTileCollision(mcontroller.position()) then
		local a = {}
		
		for _,action in ipairs(streakActions) do
			if action.time then
				action._timer = math.max(action._timer - dt, 0)
				if action._timer == 0 then
					a[#a+1] = action
					action._timer = action.time
				end
			else
				a[#a+1] = action
			end
		end
		
		if #a > 0 then
			world.spawnProjectile("knightfall_spawnstreak", mcontroller.position(), nil, mcontroller.velocity(), false, {actionOnReap = a})
		end
	end
end
