require "/scripts/util.lua"
require "/scripts/status.lua"

--[[--
  * knightfall_pixelmaker.lua
  * Augment status effect
  *
  * Attacks (beyond a damage threshold) will give the entity an amount of pixels.
  *
  * Created by Lyrthras#7199 on 08/29/20
  * v1.1 [09/02/20] - check if attacked entity is an enemy, fixed
  *                   bug where pickupDelay parameter was ignored.
--]]--

--[[--
  === JSON fields ( * = required, - = optional ) ===
  - damageThres - int:   [def 10] Accumulated damage above this will grant pixelAmount pixels.
  - pixelAmount - int:   [def 1] amount of pixels to grant per damageThres damage.
  - pickupDelay - float: [def 0] delay in seconds before the spawned pixels can be collected.
  - onMonster   - bool:  [def false] spawn the pixels on the monster attacked instead.
--]]--

function init()
  script.setUpdateDelta(12)

  self.damageThres = config.getParameter("damageThres") or 10
  self.pixelAmount = config.getParameter("pixelAmount") or 1
  self.pickupDelay = config.getParameter("pickupDelay") or 0
  self.onMonster   = config.getParameter("onMonster")  -- default nil/false

  self.totalDmg = 0
end

function isEnemy(notif)
  local selfTeam = entity.damageTeam()
  local otherTeam = world.entityDamageTeam(notif.targetEntityId)
  return otherTeam and selfTeam.team ~= otherTeam.team and otherTeam.type == "enemy" or false
end

function updateDamage(notifications)
  local lastN
  for _, n in pairs(notifications) do
    if n.hitType == "Hit" and isEnemy(n) then
      self.totalDmg = self.totalDmg + n.healthLost
      lastN = n
    end
  end
  if lastN and self.totalDmg >= self.damageThres then
    trigger(lastN)
  end
end

function trigger(notif)
  local pixels = self.pixelAmount * math.floor(self.totalDmg / self.damageThres)
  self.totalDmg = math.floor(self.totalDmg % self.damageThres)

  local monPos = notif.position
  local randVel = self.pickupDelay > 0 and
      {-10 + math.random() * 20, math.random() * 15} or
      {0, 0}

  world.spawnItem(
      "money",
      self.onMonster and monPos or mcontroller.position(),
      pixels,
      {},
      randVel,
      self.pickupDelay
  )
end

function update(dt)
  if self.hitListener then
    self.hitListener:update()
  else
    self.hitListener = damageListener("inflictedDamage", updateDamage)
  end
end