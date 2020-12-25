require "/scripts/status.lua"

--By Nebulox
--Damage reduction hook

local neb_avatarAugment_init = init
function init(...)
  self.powerModifier = config.getParameter("damagePercent", 0)
  effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})
  
  return neb_avatarAugment_init(self, ...)
end