function init()
  script.setUpdateDelta(0)
  self.damageFactor = config.getParameter("damageFactor") or 0.5

  local damage = math.abs(world.entityHealth(effect.sourceEntity())[2]) * self.damageFactor
	
  local source = effect.sourceEntity()
  if source then
	world.sendEntityMessage(source, "knightfall_maxhealthdamage", damage, status.resource("health"))
  end

  status.applySelfDamageRequest({
    damageType = "IgnoresDef",
    damage = damage,
    damageSourceKind = "default",
    sourceEntityId = source or entity.id()
  })

  effect.expire()
end