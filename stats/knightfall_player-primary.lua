preNebKnightfall_applyDamageRequest = applyDamageRequest

function applyDamageRequest(damageRequest)
  world.sendEntityMessage(entity.id(), "neb_knightfall-lastDamageConfig", damageRequest)

  local oldDamageRequest = damageRequest
  if preNebKnightfall_applyDamageRequest then
    damageRequest = preNebKnightfall_applyDamageRequest(damageRequest)
  end
  return damageRequest
end