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
  - selfEffects   - array[statusEffects]: [def {}] an array of status effects to apply on the player.
  - cooldown      - float: [def 0] cooldown between status applications. If > 0, only one enemy is hit.

  Note: array[statusEffects] can be an array of strings or statusEffect definitions, e.g.:
  "statusEffects" : [ "burning", "stasis", "wet" ],  or
  "statusEffects" : [ {"effect" : "burning", "duration" : 1}, {"effect" : "wet"} ],  or a mix:
  "statusEffects" : [ "burning", "stasis", {"effect" : "wet", "duration" : 1} ],
--]]--

function init()
  script.setUpdateDelta(12)
  self.statusEffects = config.getParameter("statusEffects", {})
  self.selfEffects = config.getParameter("selfEffects", {})
  self.cooldown = config.getParameter("cooldown", 0)

  self.cooldownTimer = self.cooldown

  self.listener = damageListener("inflictedDamage", function(notifications)
    if self.cooldownTimer > 0 then return end
    self.cooldownTimer = self.cooldown

    -- apply selfEffects
    apply(self.selfEffects, entity.id(), entity.id())

    for _, n in pairs(notifications) do
      if n.hitType == "Hit" and n.healthLost > 0 then
        apply(self.statusEffects, n.targetEntityId, entity.id())

        -- only apply to one enemy
        if self.cooldown > 0 then return end
      end
    end
  end)
end

function apply(statusEffects, targetId, sourceId)
  for _, effect in ipairs(statusEffects) do
    local name = effect
    local duration
    if type(effect) == "table" then
      name = effect.effect
      duration = effect.duration
    end
    world.sendEntityMessage(targetId, "applyStatusEffect", name, duration, sourceId)
  end
end

function update(dt)
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  self.listener:update()
end
