function init()
	animator.burstParticleEmitter("debris")
	animator.playSound("break")
	self.border = config.getParameter("border")

	if self.border then
		effect.setParentDirectives("border="..self.border)
	end

	effect.addStatModifierGroup(
		{
			{ stat = "protection", effectiveMultiplier = config.getParameter("protectionModifier", 0.5) }
		}
	)
end

function update(dt)
end

function uninit()
end
