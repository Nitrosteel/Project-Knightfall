function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  
  script.setUpdateDelta(5)
  
  self.tickDamagePercentage = 0.025
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
  
  statHandler = effect.addStatModifierGroup({})
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = math.floor(status.resourceMax("health") * self.tickDamagePercentage) + 1,
        damageSourceKind = "poison",
        sourceEntityId = entity.id()
    })
  end
  
  timer = (timer or 0) + dt
  effect.setStatModifierGroup(statHandler, {{stat = "protection", effectiveMultiplier = math.max(0.0, 1.0 - timer)}})

  effect.setParentDirectives(string.format("fade=00AA00=%.1f", self.tickTimer * 0.4))
end

function uninit()
  if statHandler then
    effect.removeStatModifierGroup(statHandler)
    statHandler = nil
  end
end
