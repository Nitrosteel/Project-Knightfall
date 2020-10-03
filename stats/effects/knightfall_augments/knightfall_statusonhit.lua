require "/scripts/status.lua"

--[[--
  * knightfall_statusonhit.lua
  * Augment status effect
  *
  * Attacks directly inflicted to an enemy with > 0 damage
  * applies specified status effects on that enemy, optionally
  * goes on cooldown. With a cooldown, only one enemy is
  * afflicted at a time.
  *
  * Created by Lyrthras#7199 on 09/26/20
  * Merged neb-knightfall_statusonhit.lua into this.
--]]--

--[[--
  === JSON fields ( * = required, - = optional ) ===
  - statusEffects - array[statusEffects]: [def {}] an array of status effects to apply on the enemy.
  - cooldown      - float: [def 0] cooldown between status applications. If > 0, only one enemy is hit.
--]]--

function init()
  script.setUpdateDelta(12)
  self.statusEffects = config.getParameter("statusEffects", {})
  self.cooldown = config.getParameter("cooldown", 0)

  self.cooldownTimer = self.cooldown

  self.listener = damageListener("inflictedDamage", function(notifications)
    if self.cooldownTimer > 0 then return end
    self.cooldownTimer = self.cooldown

    for _, n in pairs(notifications) do
      if n.hitType == "Hit" and n.healthLost > 0 then
        for _, effect in ipairs(self.statusEffects) do
          world.sendEntityMessage(n.targetEntityId, "applyStatusEffect", effect, nil, entity.id())
        end
        -- only apply to one enemy
        if self.cooldown > 0 then return end
      end
    end
  end)
end

function update(dt)
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  self.listener:update()
end
