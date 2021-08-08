local oldInit = init or function() end
local oldUpdate = update or function() end

local bars = {}

function init()
	oldInit()
	
	message.setHandler("kf_bars", function(_, isLocal, timer, y, colors, bg)
		if isLocal then
			timer = math.min(math.max(timer, 0), 1)
			colors = colors or {"#888", "#FFF"}
			local color = colors[timer == 0 and 2 or 1]
			
			table.insert(bars, {image = bg, position = {0, y}, fullbright = true, centered = true})
			table.insert(bars, {line = {{-1, y}, {1, y}}, width = 2, color = "#29292980", fullbright = true})
			table.insert(bars, {line = {{-1, y}, {-1 + (2 * (1 - timer)), y}}, width = 2, color = color, fullbright = true})
		end
	end)
end

function update(dt)
	oldUpdate(dt)
	
	for i,bar in ipairs(bars) do
		localAnimator.addDrawable(bar, "overlay+"..i)
	end
	bars = {}
end
