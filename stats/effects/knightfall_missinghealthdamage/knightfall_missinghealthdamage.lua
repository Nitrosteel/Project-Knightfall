
--[[--
  * knightfall_missinghealthdamage.lua
  * Applied status effect
  *
  * Instantly damages the entity for missingHealth * damageFactor.
  * (If for some reason the entity's health > maxHealth, the extra
  * health is used as the missingHealth value instead. No healing)
  *
  * Created by Lyrthras#7199 on 09/10/20
--]]--

--[[--
  === JSON fields ( * = required, - = optional ) ===
  - damageFactor - float: [def 0.5] damage to deal as percentage of missing health
--]]--

function init()
  script.setUpdateDelta(0)
  self.damageFactor = config.getParameter("damageFactor") or 0.5

  local damage = math.abs(status.resourceMax("health") - status.resource("health")) * self.damageFactor

  status.applySelfDamageRequest({
    damageType = "IgnoresDef",
    damage = damage,
    damageSourceKind = "default",
    sourceEntityId = effect.sourceEntity() or entity.id()
  })

  effect.expire()
end