function init()
  targetMaterialKind = status.statusProperty("targetMaterialKind")
  damageMultiplier = 1.0
  if not (targetMaterialKind == "robotic") then --reduce effect damage dealt by 50% if not robotic
	damageMultiplier = 0.5
  end
  
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  
  script.setUpdateDelta(5)
  
  self.tickDamagePercentage = 0.025
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  
  effect.addStatModifierGroup({
    {stat = "protection", amount = config.getParameter("protectionModifier", -1)}
  })
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = damageMultiplier * (math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1),
      damageSourceKind = "poison",
      sourceEntityId = entity.id()
    })
  end

  effect.setParentDirectives(string.format("fade=00AA00=%.1f", self.tickTimer * 0.4))
end

function uninit()
end
