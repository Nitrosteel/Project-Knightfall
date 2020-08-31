require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  script.setUpdateDelta(12)

  self.damageThres = config.getParameter("damageThres") or 10
  self.pixelAmount = config.getParameter("pixelAmount") or 2
  self.pickupDelay = config.getParameter("pickupDelay") or 0.5

  self.totalDmg = 0
end

function updateDamage(notifications)
  local lastN
  for _, n in pairs(notifications) do
    if n.hitType == "Hit" then
      self.totalDmg = self.totalDmg + n.damageDealt
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
  local pos = notif.position
  local randVel = {-10 + math.random() * 20, math.random() * 15}
  world.spawnItem(
      "money",
      mcontroller.position(),
      pixels,
      {},
      randVel,
      0.5
  )
end

function update(dt)
  if self.hitListener then
    self.hitListener:update()
  else
    self.hitListener = damageListener("inflictedDamage", updateDamage)
  end
end