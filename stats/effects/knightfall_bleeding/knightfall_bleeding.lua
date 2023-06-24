function init()
  targetMaterialKind = status.statusProperty("targetMaterialKind")
  if (targetMaterialKind == "stone" or targetMaterialKind == "robotic") then
	cancelDamage = true
	effect.expire()
  end
  
  if not cancelDamage then
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
  else
	animator.setParticleEmitterActive("drips", false)
  end
  
  color = config.getParameter("color")
  
  tickTime = config.getParameter("tickTime") or 0
  tickTimer = 0

  tickDamagePercentage = config.getParameter("tickDamagePercentage")
  tickDamageIncrement = config.getParameter("tickDamageIncrement") or 0
  maximumTickDamagePercentage = config.getParameter("maximumTickDamagePercentage") or 1
  minimumTickDamage = config.getParameter("minimumTickDamage") or 0
  damageSourceKind = config.getParameter("damageSourceKind") or "default"
  maximumDamage = config.getParameter("maximumDamage")
end

function update(dt)
  tickTimer = math.max(0, tickTimer - dt)
  
  if not cancelDamage then
	if tickTimer == 0 then
		tickTimer = tickTime
     
		local damage = math.max(math.ceil(status.resourceMax("health") * tickDamagePercentage), minimumTickDamage)
     
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = math.min(damage, maximumDamage),
			damageSourceKind = damageSourceKind,
			sourceEntityId = entity.id()
		})
    
		tickDamagePercentage = math.max(0, math.min(maximumTickDamagePercentage, tickDamagePercentage + tickDamageIncrement))
	end
  
	effect.setParentDirectives(string.format("fade=%s=%.1f", color, (tickTimer / tickTime) * 0.8))
  else
	animator.setParticleEmitterActive("drips", false)
  end
end