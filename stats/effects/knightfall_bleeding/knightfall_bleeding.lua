function init()
  local material = status.statusProperty("targetMaterialKind")
  if material == "stone" or material == "robotic" then
    self.cancelDamage = true
    effect.expire()
    animator.setParticleEmitterActive("drips", false)
    return
  end

  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)

  self.color = config.getParameter("color", "AA0000")

  self.tickTime = config.getParameter("tickTime", 1.0)
  self.tickTimer = self.tickTime
  self.tickDamagePercentage = config.getParameter("tickDamagePercentage", 0.01)
  self.tickDamageIncrement = config.getParameter("tickDamageIncrement", 0)
  self.maximumTickDamagePercentage = config.getParameter("maximumTickDamagePercentage", 0.05)
  self.minimumTickDamage = config.getParameter("minimumTickDamage", 0)
  self.maximumDamage = config.getParameter("maximumDamage", 50)
  self.damageSourceKind = config.getParameter("damageSourceKind", "default")

  self.visualTime = config.getParameter("visualTime", 0.5)
  self.visualTimer = self.visualTime
  self.fadeIntensity = 0.6
end

function update(dt)
  if self.cancelDamage then
    effect.setParentDirectives()
    return
  end

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime

    local baseHealth = status.resourceMax("health")
    local damage = math.max(math.ceil(baseHealth * self.tickDamagePercentage), self.minimumTickDamage)
    damage = math.min(damage, self.maximumDamage)

    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damageSourceKind = self.damageSourceKind,
      damage = damage,
      sourceEntityId = entity.id()
    })

    self.tickDamagePercentage = math.min(
      self.tickDamagePercentage + self.tickDamageIncrement,
      self.maximumTickDamagePercentage
    )
  end

  self.visualTimer = self.visualTimer - dt
  if self.visualTimer <= 0 then
    self.visualTimer = self.visualTime
  end

  local pulse = math.abs(math.sin((self.visualTimer / self.visualTime) * math.pi))
  local intensity = pulse * self.fadeIntensity
  effect.setParentDirectives(string.format("fade=%s=%.2f", self.color, intensity))
end

function uninit()
  animator.setParticleEmitterActive("drips", false)
  effect.setParentDirectives()
end