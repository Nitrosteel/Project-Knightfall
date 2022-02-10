local oldInit = init or function() end
local oldUpdate = update or function() end

local bars = {}
local barCfg = {
	length = 2, --in tiles
	width = 2, --in pixels
	image = "/scripts/knightfall_reloadbar.png",
	behindColor = "#29292980"
}

function init()
	oldInit()
	
	barCfg.height = (root.imageSize(barCfg.image)[2] / 8) + 0.125
	
	message.setHandler("kf_bars", function(_, isLocal, newBar)
		if isLocal and newBar then
			if type(newBar[1]) == "table" then
				for _,b in ipairs(newBar) do
					bars[#bars+1] = b
				end
			else
				bars[#bars+1] = newBar
			end
		end
	end)
end

function update(dt)
	oldUpdate(dt)
	
	local Y = 2.25
	for i = #bars, 1, -1 do
		local bar = bars[i]
		
		local y = Y + barCfg.height / 2
		Y = Y + barCfg.height
		
		local x1 = barCfg.length / -2
		local x2 = -x1
		
		localAnimator.addDrawable({image = barCfg.image, position = {0, y}, fullbright = true, centered = true}, "overlay+1000")
		localAnimator.addDrawable({line = {{x1, y}, {x2, y}}, width = barCfg.width, fullbright = true, color = barCfg.behindColor}, "overlay+1000")
		
		x2 = x1 + (barCfg.length * bar[1])
		localAnimator.addDrawable({line = {{x1, y}, {x2, y}}, width = barCfg.width, fullbright = true, color = bar[2]}, "overlay+1000")
		
		if bar[3] then
			localAnimator.addDrawable({line = {{x1, y}, {x2, y}}, width = barCfg.width, fullbright = true, color = bar[3]}, "overlay+1000")
		end
	end
	bars = {}
end
