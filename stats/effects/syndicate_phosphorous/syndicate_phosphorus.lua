function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  effect.setParentDirectives("fade=fff696=0.2")

  script.setUpdateDelta(5)

  self.tickTime = 0.5
  self.tickTimer = self.tickTime
  self.damage = 2

  status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = 2,
      damageSourceKind = "fire",
      sourceEntityId = entity.id()
    })
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    self.damage = self.damage + 2
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.damage,
        damageSourceKind = "fire",
        sourceEntityId = entity.id()
      })
  end
end

function onExpire()

end
