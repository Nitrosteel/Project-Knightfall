function init()
  animator.setParticleEmitterOffsetRegion("chronoParticles", mcontroller.boundBox())
  animator.setParticleEmitterActive("chronoParticles", true)
  effect.setParentDirectives("fade=c7c7c7=0.4")

  script.setUpdateDelta(5)

  self.tickTime = 0.3
  self.tickTimer = self.tickTime
  self.damage = 10

  status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = 10,
      damageSourceKind = "ice",
      sourceEntityId = entity.id()
    })
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    self.damage = self.damage + 10
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.damage,
        damageSourceKind = "ice",
        sourceEntityId = entity.id()
      })
  end
end

function onExpire()
end
