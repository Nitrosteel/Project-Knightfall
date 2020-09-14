require "/scripts/status.lua"

--[[--
  * knightfall_statusinflicter.lua
  * Augment status effect
  *
  * Attacks directly inflicted to enemies with > 0 damage
  * applies specified status effects on those enemies.
  *
  * Note:
  * inflictedStatuses is an array of status effects, with the same structure
  * as projectileParams statusEffects, so what works for projectiles would
  * also work here.
  *
  * Created by Lyrthras#7199 on 09/11/20
--]]--

--[[--
  === JSON fields ( * = required, - = optional ) ===
  - inflictedStatuses - array[statusEffects]: [def {}] an array of status effects to apply on the enemy.
--]]--


function init()
  script.setUpdateDelta(15)

  self.projectileParams = {
    statusEffects = config.getParameter("inflictedStatuses") or {},

    timeToLive = 0.25,
    power = 0,
    damagePoly = { {-1,0}, {0,1}, {1,0}, {0,-1} },
    piercing = true,
    damageTeam = { team = entity.damageTeam().team, type = "friendly" }
  }
end

function updateDamage(notifications)
  for _, n in pairs(notifications) do
    if n.hitType == "Hit" and world.entityCanDamage(entity.id(), n.targetEntityId) and n.healthLost > 0 then
      trigger(n)
    end
  end
end

function trigger(notif)
  world.spawnProjectile(
      "invisibleprojectile",
      notif.position,
      entity.id(),
      {0,0},
      false,
      self.projectileParams
  )
end

function update(dt)
  if self.hitListener then
    self.hitListener:update()
  else
    self.hitListener = damageListener("inflictedDamage", updateDamage)
  end
end
