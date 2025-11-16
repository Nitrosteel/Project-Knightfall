function init()
  animator.setParticleEmitterOffsetRegion("rageflames", mcontroller.boundBox())
  animator.setParticleEmitterActive("rageflames", true)
  animator.playSound("rage", 0)
  animator.playSound("ragereverb", 0)
	
  local directives = config.getParameter("directives")
  if directives then
	effect.setParentDirectives(directives)
  end
	
  script.setUpdateDelta(5)
  
  self.damageModifier = config.getParameter("damageModifier", 0.01)
  self.maxHealthModifier = config.getParameter("maxHealthModifier", 0.7)
  self.protectionModifier = config.getParameter("protectionModifier", -5)

  effect.addStatModifierGroup({
	{ stat = "powerMultiplier", effectiveMultiplier = self.damageModifier },
	{ stat = "maxHealth", effectiveMultiplier = self.maxHealthModifier },
	{ stat = "protection", amount = self.protectionModifier }
  })
end

function update(dt)
end

function uninit()
end