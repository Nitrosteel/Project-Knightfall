require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/util/propstore.lua"

--[[--
  * knightfall_lifesteal.lua
  * Augment status effect
  *
  * Attacks (beyond a damage threshold) will heal the entity for a flat amount or
  * a percentage of max health. The damage is accumulated and lifesteal triggers
  * once the amount goes over damageThres. 'Orbs' will fly towards the entity, but
  * these are only for visual effect and would not heal (health is added instantly)
  *
  * Created by Lyrthras#7199 on 08/28/20
  * v1.1 [09/02/20] - added percentage mode, check if hit entity is an
  *                   enemy, cooldown on init to prevent re-equipping
  *                   exploit, added damageThres and maxProjs parameter
  * v1.2 [12/23/20] - Added PropStore cooldown saving to avoid reequip exploits.
  *                   Also fixed isEnemy check so this can also work on monsters/npcs.
--]]--

--[[--
  === JSON fields ( * = required, - = optional ) ===
  [ Mechanics ]
  - cooldown    - float:  [def 5] seconds between lifesteals. (Damage is not accumulated on cooldown)
  - stealAmount - float:  [def 10] isPercent=false: flat amount to heal; isPercent=true: percentage of maximum health to heal.
  - isPercent   - bool:   [def false] false if stealAmount is a flat value, true if it's a percentage.
  - damageThres - int:    [def 25] lifesteal triggers when accumulated damage goes above this value.
  - gracePeriod - float:  [def cooldown or 3] seconds without inflicting damage before accumulated damage resets.

  [ Visual ]
  - flashColor  - string: [def "000000"] color (in hex) of the visual blink on the entity.
  - flashValue  - float:  [def 0] value between 0 and 1, how the flash color should mix. 1 would make the entity solid-color, 0 disables it.
  - flashTime   - float:  [def 1] how long the flash effect would last.
  - maxProjs    - int:    [def 5] how many orbs would spawn on lifesteal. 0 to disable.
--]]--

function init()
  script.setUpdateDelta(6)
  animator.setParticleEmitterOffsetRegion("lifesteal", mcontroller.boundBox())

  self.flashColor = config.getParameter("flashColor") or "000000"
  self.flashValue = config.getParameter("flashValue") or 0
  self.colorTime = config.getParameter("flashTime") or 1
  self.cooldown = config.getParameter("cooldown") or 5
  self.gracePeriod = config.getParameter("gracePeriod") or self.cooldown or 3
  self.damageThres = config.getParameter("damageThres") or 25
  self.lifestealAmount = config.getParameter("stealAmount") or 10
  self.isPercent = config.getParameter("isPercent")  -- default nil/false
  self.maxProjectiles = config.getParameter("maxProjs") or 5

  self.totalDmg = 0

  -- self.cooldownTimer = self.cooldown
  self.graceTimer = -255
  self.colorTimer = -255

  self.propStore = PropStore.new("lifesteal", self)
  self.propStore:recall("cooldownTimer", 0)
end

function isEnemy(notif)
  local selfTeam = entity.damageTeam()
  local otherTeam = world.entityDamageTeam(notif.targetEntityId)
  local opposing = otherTeam and    -- check if other entity exists
      ((selfTeam.type == "friendly" and otherTeam.type == "enemy") or
      (selfTeam.type == "enemy" and otherTeam.type == "friendly"))       -- never bother with passives
  return opposing and selfTeam.team ~= otherTeam.team
end

function updateDamage(notifications)
  if self.cooldownTimer > 0 then return end
  for _, n in pairs(notifications) do
    if n.hitType == "Hit" and isEnemy(n) then
      self.graceTimer = self.gracePeriod
      self.totalDmg = self.totalDmg + n.healthLost
      if self.totalDmg >= self.damageThres then
        triggerLifesteal(n)
        break
      end
    end
  end
end

function triggerLifesteal(notif)
  self.graceTimer = -255

  local amount = self.isPercent and
      --[[-- status.resourceMax("health") * self.lifestealAmount / 100 or --]]--
	  self.totalDmg * self.lifestealAmount / 100 or
      self.lifestealAmount

  local healed = status.giveResource("health", amount) / amount

  self.totalDmg = 0

  animator.burstParticleEmitter("lifesteal")
  status.addEphemeralEffect("knightfall_lifesteal_staticon", healed)
  createProjectiles(notif, healed)

  self.cooldownTimer = self.cooldown
  self.colorTimer = self.colorTime * healed
end

function createProjectiles(notif, healed)
  if self.maxProjectiles < 1 then return end
  local pos = notif.position
  local count = math.ceil(healed * self.maxProjectiles)
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
  elseif self.colorTimer > -255 then
    effect.setParentDirectives("fade=" .. self.flashColor .."=0")
    self.colorTimer = -255
  end

  if self.graceTimer > 0 then
    self.graceTimer = self.graceTimer - dt
  elseif self.graceTimer > -255 then
    -- reset accumulated damage
    self.totalDmg = 0
    self.graceTimer = -255
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

function uninit()
  self.propStore:uninit()
end
