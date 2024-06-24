function init()
	animator.setParticleEmitterOffsetRegion("rageflames", mcontroller.boundBox())
	animator.setParticleEmitterActive("rageflames", true)
	animator.playSound("rage", 0)
	animator.playSound("ragereverb", 0)
	local directives = config.getParameter("directives")

	script.setUpdateDelta(5)

	if directives then
		effect.setParentDirectives(directives)
	end

	effect.addStatModifierGroup(
		{
			{ stat = "powerMultiplier", effectiveMultiplier = config.getParameter("damageModifier", 0.01) },
			{ stat = "maxHealth", effectiveMultiplier = config.getParameter("healthModifier", 0.7) },
			{ stat = "protection", amount = config.getParameter("protectionModifier", -5) }
		}
	)
end

function update(dt)

end

function uninit()
  
end
