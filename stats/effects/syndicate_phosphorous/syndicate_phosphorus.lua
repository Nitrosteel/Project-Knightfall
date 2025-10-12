function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  animator.playSound("burn", -1)
  
  local directives = config.getParameter("directives")
  if directives then
	effect.setParentDirectives(directives)
  end

  script.setUpdateDelta(5)

  self.tickTime = config.getParameter("tickTime", 0.5)
  self.tickDamage = config.getParameter("tickDamage", 2)
  self.tickDamageIncrement = config.getParameter("tickDamageIncrement", 5)
  self.tickTimer = self.tickTime
  
  applyHeatDamage(self.tickDamage)
end

function update(dt)
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    self.tickDamage = self.tickDamage + self.tickDamageIncrement
    applyHeatDamage(self.tickDamage)
  end
end

function applyHeatDamage(amount)
  status.applySelfDamageRequest({
    damageType = "IgnoresDef",
    damage = amount,
    damageSourceKind = "fire",
    sourceEntityId = entity.id()
  })
end

function onExpire()
end