function init()
	animator.setParticleEmitterOffsetRegion("static", mcontroller.boundBox())
	animator.setParticleEmitterActive("static", true)
	animator.playSound("static")
	local directives = config.getParameter("directives")

	script.setUpdateDelta(7)

	if directives then
		effect.setParentDirectives(directives)
	end

	effect.addStatModifierGroup(
		{
			{ stat = "protection", effectiveMultiplier = config.getParameter("protectionModifier", 0.5) },
			{ stat = "jumpModifier", amount = -0.45 }
		}
	)
end

function update(dt)
	mcontroller.controlModifiers(
		{
			groundMovementModifier = 0.15,
			speedModifier = 0.25,
			airJumpModifier = 0.25
		}
	)
end

function uninit()

end
