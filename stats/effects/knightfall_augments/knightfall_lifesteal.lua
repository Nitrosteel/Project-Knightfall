require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  animator.setParticleEmitterOffsetRegion("lifesteal", mcontroller.boundBox())

  script.setUpdateDelta(6)

  self.flashColor = config.getParameter("flashColor")
  self.flashValue = config.getParameter("flashValue") or 0
  self.colorTime = config.getParameter("flashTime") or 1
  self.cooldown = config.getParameter("cooldown") or 3
  self.gracePeriod = config.getParameter("gracePeriod") or self.cooldown or 3
  self.lifestealAmount = config.getParameter("stealAmount") or 25

  self.healPerProj = 5

  self.cooldownTimer = 0
  self.graceTimer = -255
  self.colorTimer = 0

  self.totalDmg = 0
end

function updateDamage(notifications)
  if self.cooldownTimer > 0 then return end
  for _, n in pairs(notifications) do
    if n.hitType == "Hit" then
      self.graceTimer = self.gracePeriod
      self.totalDmg = self.totalDmg + n.damageDealt
      if self.totalDmg >= self.lifestealAmount then
        triggerLifesteal(n)
        break
      end
    end
  end
end

function triggerLifesteal(notif)
  self.totalDmg = 0
  self.graceTimer = -255

  local added = status.giveResource("health", self.lifestealAmount)

  animator.burstParticleEmitter("lifesteal")
  status.addEphemeralEffect("knightfall_lifestolen", added / self.lifestealAmount)
  createProjectiles(notif, added)

  self.cooldownTimer = self.cooldown
  self.colorTimer = self.colorTime * (added / self.lifestealAmount)
end

function createProjectiles(notif, dmg)
  -- local from = notif.targetEntityId
  local pos = notif.position
  local count = math.ceil(dmg / self.healPerProj)
  for _= 1, count do
    local randVel = {-5 + math.random() * 10, -5 + math.random() * 10}
    world.spawnProjectile(
        "lifestealprojectile",
        pos,
        entity.id(),
        randVel,
        false,
        {}
    )
  end
end

function update(dt)
  if self.colorTimer > 0 then
    self.colorTimer = self.colorTimer - dt
    local val = self.flashValue * (self.colorTimer / self.colorTime)
    effect.setParentDirectives("fade=" .. self.flashColor .. "=" .. val)
  else
    effect.setParentDirectives("fade=" .. self.flashColor .."=0")
  end

  if self.graceTimer > -255 then
    if self.graceTimer <= 0 then
      -- reset accumulated damage
      self.totalDmg = 0
      self.graceTimer = -255
    else
      self.graceTimer = self.graceTimer - dt
    end
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = self.cooldownTimer - dt
  end

  if self.hitListener then
    self.hitListener:update()
  else
    self.hitListener = damageListener("inflictedDamage", updateDamage)
  end
end

function onExpire()

end
