function init()
	animator.setParticleEmitterOffsetRegion("heat", mcontroller.boundBox())
	animator.setParticleEmitterActive("heat", true)
	animator.playSound("heat")
	local directives = config.getParameter("directives")

	script.setUpdateDelta(5)

	if directives then
		effect.setParentDirectives(directives)
	end

	effect.addStatModifierGroup(
		{
			{ stat = "fireResistance", effectiveMultiplier = config.getParameter("fireResistanceModifier", 0.5) },
			{ stat = "jumpModifier", amount = -0.85 }
		}
	)
end

function update(dt)
	mcontroller.controlModifiers(
		{
			groundMovementModifier = 0.65,
			speedModifier = 0.75,
			airJumpModifier = 0.75
		}
	)
end

function uninit()
  
end
