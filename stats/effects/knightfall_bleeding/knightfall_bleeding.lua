function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  
  color = config.getParameter("color")
  
  tickTime = config.getParameter("tickTime") or 0
  tickTimer = 0

  tickDamagePercentage = config.getParameter("tickDamagePercentage")
  tickDamageIncrement = config.getParameter("tickDamageIncrement") or 0
  maximumTickDamagePercentage = config.getParameter("maximumTickDamagePercentage") or 1
  minimumTickDamage = config.getParameter("minimumTickDamage") or 0
  damageSourceKind = config.getParameter("damageSourceKind") or "default"
  maximumDamage = config.getParameter("maximumDamage")
  damageTaken = 0
end

function update(dt)
  tickTimer = math.max(0, tickTimer - dt)
  
  if tickTimer == 0 and damageTaken <= maximumDamage then
    tickTimer = tickTime
     
    local damage = math.max(math.ceil(status.resourceMax("health") * tickDamagePercentage), minimumTickDamage)
    damageTaken = damageTaken + damage
     
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = damage,
      damageSourceKind = damageSourceKind,
      sourceEntityId = entity.id()
    })
    
    tickDamagePercentage = math.max(0, math.min(maximumTickDamagePercentage, tickDamagePercentage + tickDamageIncrement))
  end
  
  effect.setParentDirectives(string.format("fade=%s=%.1f", color, (tickTimer / tickTime) * 0.8))
end