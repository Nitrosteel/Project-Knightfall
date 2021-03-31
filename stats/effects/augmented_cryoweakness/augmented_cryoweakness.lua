function init()
  animator.setParticleEmitterOffsetRegion("icetrail", mcontroller.boundBox())
  animator.setParticleEmitterActive("icetrail", true)
  effect.setParentDirectives("fade=00BBFF=0.15")
  
  script.setUpdateDelta(5)
  
  self.tickDamagePercentage = 0.025
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
	
	effect.addStatModifierGroup({
			{ stat = "maxEnergy", amount = config.getParameter("energyModifier", -1) }
	})
  end
  
  effect.addStatModifierGroup({
		{ stat = "jumpModifier", amount = config.getParameter("jumpModifier", -1) }
  })
	
  effect.addStatModifierGroup({
		{ stat = "speedModifier", amount = config.getParameter("speedModifier", -1) }
  })
  
  mcontroller.controlModifiers({
      groundMovementModifier = 0.3,
      speedModifier = 0.5,
      airJumpModifier = 0.5
  })

  effect.setParentDirectives(string.format("fade=00AAAA=%.1f", self.tickTimer * 0.4))
end

function uninit()
end
