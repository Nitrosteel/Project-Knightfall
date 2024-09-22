function init()
	statModifierGroup = effect.addStatModifierGroup({})
	self.damageFactor = config.getParameter("damageFactor") or 2
end

function update(dt)
	effect.setStatModifierGroup(statModifierGroup, {
		{ 
			stat = "powerMultiplier", 
			effectiveMultiplier = math.abs(1 + (self.damageFactor - (status.resourcePercentage("health") * self.damageFactor)))
		}
	})
end