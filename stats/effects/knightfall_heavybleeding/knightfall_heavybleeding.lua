function init() 
  effect.setParentDirectives("fade="..config.getParameter("color").."=0.5")

  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)

  effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.20}
  })

  script.setUpdateDelta(5)

  self.tickTime = 0.5
  self.tickTimer = self.tickTime
  self.tickDamagePercentage = 0.01

  status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = 10,
      damageSourceKind = "default",
      sourceEntityId = entity.id()
    })
end

function update(dt)
  mcontroller.controlModifiers({
	groundMovementModifier = 0.40,
	speedModifier = 0.30,
	airJumpModifier = 0.50
  })

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    self.tickDamagePercentage = self.tickDamagePercentage + 0.01
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.min(math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1, 100),
        damageSourceKind = "default",
        sourceEntityId = entity.id()
      })
  end

  effect.setParentDirectives(string.format("fade=AA0000=%.1f", self.tickTimer * 0.4))
end

function onExpire()
  status.addEphemeralEffect("knightfall_bleeding")
end
