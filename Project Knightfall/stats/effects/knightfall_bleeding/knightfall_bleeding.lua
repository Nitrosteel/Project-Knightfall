function init()
	effect.setParentDirectives("fade="..config.getParameter("color").."=0.5")
	
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.10}
  })

  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.01
  self.tickTime = 0.35
  self.tickTimer = self.tickTime
end

function update(dt)
 mcontroller.controlModifiers({
	groundMovementModifier = 0.50,
	speedModifier = 0.50,
	airJumpModifier = 0.75
  })

  self.tickTimer = self.tickTimer - dt
  
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.min(math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1, 30),
        damageSourceKind = "default",
        sourceEntityId = entity.id()
      })
  end

  effect.setParentDirectives(string.format("fade=AA0000=%.1f", self.tickTimer * 0.4))
end

function uninit()

end
