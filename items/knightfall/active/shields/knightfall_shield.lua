require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  self.debug = true

  self.aimAngle = 0
  self.aimDirection = 1

  self.active = false
  self.cooldownTimer = config.getParameter("cooldownTime")
  self.activeTimer = 0

  self.level = config.getParameter("level", 1)
  self.alwaysOutside = config.getParameter("alwaysOutside")
  self.baseShieldHealth = config.getParameter("baseShieldHealth", 1)
  self.knockback = config.getParameter("knockback", 0)
  self.perfectBlockDirectives = config.getParameter("perfectBlockDirectives", "")
  self.perfectBlockTime = config.getParameter("perfectBlockTime", 0.2)
  self.minActiveTime = config.getParameter("minActiveTime", 0)
  self.cooldownTime = config.getParameter("cooldownTime")
  self.forceWalk = config.getParameter("forceWalk", false)

  self.shieldStats = config.getParameter("shieldStats", {})

  animator.setGlobalTag("directives", "")
  animator.setAnimationState("shield", "idle")
  activeItem.setOutsideOfHand(true)

  self.stances = config.getParameter("stances")
  setStance(self.stances.idle)

  message.setHandler("neb_knightfal-lastDamageConfig", function(_, _, config) 
    if self.active and entity.entityType() == "player" then
      processDamage(config)
    end
  end)

  updateAim()
end

function update(dt, fireMode, shiftHeld)
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  updateAim()

  if not self.active
    and fireMode == "primary"
    and self.cooldownTimer == 0
    and status.resourcePositive("shieldStamina") then

    raiseShield()
  end

  if self.active then
    self.activeTimer = self.activeTimer + dt

    if self.damageListener then self.damageListener:update() end

    if status.resourcePositive("perfectBlock") then
      animator.setGlobalTag("directives", self.perfectBlockDirectives)
    else
      animator.setGlobalTag("directives", "")
    end

    if self.forceWalk then
      mcontroller.controlModifiers({runningSuppressed = true})
    end

    if (fireMode ~= "primary" and self.activeTimer >= self.minActiveTime) or not status.resourcePositive("shieldStamina") then
      lowerShield()
    end
  end
end

function uninit()
  status.clearPersistentEffects(activeItem.hand() .. "Shield")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
end

function updateAim()
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  
  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  end
  activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

  if self.stance.allowFlip then
    self.aimDirection = aimDirection
  end
  activeItem.setFacingDirection(self.aimDirection)

  animator.setGlobalTag("hand", isNearHand() and "near" or "far")
  activeItem.setOutsideOfHand(self.alwaysOutside or isNearHand())
end

function isNearHand()
  return (activeItem.hand() == "primary") == (self.aimDirection < 0)
end

function setStance(stance)
  self.stance = stance
  self.relativeShieldRotation = util.toRadians(stance.shieldRotation) or 0
  self.relativeArmRotation = util.toRadians(stance.armRotation) or 0
end

function raiseShield()
  self.lastStamina = status.resource("shieldStamina")
  setStance(self.stances.raised)
  animator.setAnimationState("shield", "raised")
  animator.playSound("raiseShield")
  self.active = true
  self.activeTimer = 0
  status.setPersistentEffects(activeItem.hand().."Shield", {{stat = "shieldHealth", amount = shieldHealth()}})
  local shieldPoly = animator.partPoly("shield", "shieldPoly")
  activeItem.setItemShieldPolys({shieldPoly})

  if self.knockback > 0 then
    local knockbackDamageSource = {
      poly = shieldPoly,
      damage = 0,
      damageType = "Knockback",
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      knockback = self.knockback,
      rayCheck = true,
      damageRepeatTimeout = 0.25
    }
    activeItem.setItemDamageSources({ knockbackDamageSource })
  end

  if entity.entityType() == "npc" then
    self.damageListener = damageListener("damageTaken", function(notifications)
      for _, notification in pairs(notifications) do
        if notification.hitType == "ShieldHit" then
          processDamage(notification)
        end
      end
    end)
  end

  refreshPerfectBlock()
end

function refreshPerfectBlock()
  local perfectBlockTimeAdded = math.max(0, math.min(status.resource("perfectBlockLimit"), self.perfectBlockTime - status.resource("perfectBlock")))
  status.overConsumeResource("perfectBlockLimit", perfectBlockTimeAdded)
  status.modifyResource("perfectBlock", perfectBlockTimeAdded)
end

function lowerShield()
  self.lastStamina = nil
  self.aimAngle = self.stances.idle.aimAngle or self.aimAngle
  setStance(self.stances.idle)
  animator.setGlobalTag("directives", "")
  animator.setAnimationState("shield", "idle")
  animator.playSound("lowerShield")
  self.active = false
  self.activeTimer = 0
  status.clearPersistentEffects(activeItem.hand() .. "Shield")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
  self.cooldownTimer = self.cooldownTime
end

function shieldHealth()
  return self.baseShieldHealth * root.evalFunction("shieldLevelMultiplier", self.level)
end

function processDamage(notification)
  local percentDamage = self.lastStamina - status.resource("shieldStamina")
  status.setResource("shieldStamina", self.lastStamina > status.resource("shieldStamina") and self.lastStamina or status.resource("shieldStamina"))

  local damageKind = notification.damageSourceKind
  local resistance = self.shieldStats[damageKind] or 0
  local adjustedPercentDamage = percentDamage - (percentDamage * resistance)
  status.modifyResource("shieldStamina", -adjustedPercentDamage)

  if status.resourcePositive("perfectBlock") then
    animator.playSound("perfectBlock")
    animator.burstParticleEmitter("perfectBlock")
    refreshPerfectBlock()
  elseif status.resourcePositive("shieldStamina") then
    animator.playSound("block")
  else
    animator.playSound("break")
  end

  animator.setAnimationState("shield", "block")
  self.lastStamina = status.resource("shieldStamina")
end