function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  effect.setParentDirectives("fade=FF8800=0.2")

  script.setUpdateDelta(5)

  self.tickTime = 0.3
  self.tickTimer = self.tickTime
  self.damage = 10

  status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = 10,
      damageSourceKind = "fire",
      sourceEntityId = entity.id()
    })
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    self.damage = self.damage + 5
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.damage,
        damageSourceKind = "fire",
        sourceEntityId = entity.id()
      })
  end
end

function onExpire()
  status.addEphemeralEffect("burning")
end
