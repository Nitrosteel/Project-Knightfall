require "/scripts/status.lua"

--By Nebulox
--Status on hit

function init()
  self.statusEffects = config.getParameter("statusEffects", {})
  self.damageGivenListener = damageListener("inflictedDamage", function(notifications)
    for _, notification in pairs(notifications) do
      for statusEffect in ipairs(statusEffects) do
		world.sendEntityMessage(notification.targetEntityId, "applyStatusEffect", statusEffect)
	  end
	end
  end)
end

function update(dt)
  self.damageGivenListener:update()
end

function uninit()
end

function onExpire()
end