
require "/scripts/util.lua"

--[[
"Titanslayer"
- Empowers the Cronus with red energy and extending the blade.
- While empowered, attacks deal bonus 7.5% max health damage on hit. Attacks also have a farther reach, and can stun enemies.
Attacks no longer spawn projectiles.
- Each attack you deal consumes a flat amount of energy and 15% of your max health.
- While empowered, gain the Lifesteal buff.
- Empowerment lasts until you're dead, or after 20 seconds.

 @Lyrthras#7199
 DateTime: 10/01/2020 10:11 PM (Completed 11/11/2020) (darn that was quite a long time :pensive:)

]]--

-- Class to hook into
-- Cronus melee combo hook
local Classname = "NebsCombo"

Class = _ENV[Classname]
if not Class then error("Hook used without '"..Classname.."'. Or maybe fix the order, hooks are last.") return end

local _init = Class.init
function Class:init()
  _init(self)

  if not (self.empowerment and self.empowerment.duration) then
    error("cronus_empowerment script included without empowerment object, or specified duration.")
  end
  self.empoweredTimer = 0

  self._og = {}
  self._og.statusEffects = {}
  for i, v in ipairs(self.stepDamageConfig) do
    self._og.statusEffects[i] = copy(v.statusEffects) or {}
  end
end

local _update = Class.update
function Class:update(dt, fireMode, shiftHeld)
  _update(self, dt, fireMode, shiftHeld)

  if not self.weapon.currentAbility and self.empoweredTimer == 0 and fireMode == "alt" then
    -- TODO trigger transition
    self.empoweredTimer = self.empowerment.duration
    self:setState(self.empower)
  end

  if self.empoweredTimer > 0 then
    self.empoweredTimer = math.max(0, self.empoweredTimer - dt)
    if self.empoweredTimer == 0 then
      self:clearEmpowerment()
      self.weapon._stillActive = false
    else
      -- tell the hook that the energyblade still needs to be active
      self.weapon._stillActive = true
    end
  end
end

function Class:empower()
  self.weapon:setStance(self.stances.empower)

  util.wait(self.stances.empower.durationBefore)

  animator.playSound("empower")
  animator.setGlobalTag("isEmpowered", "emp-")
  if animator.animationState("blade") == "active" then
    animator.setAnimationState("blade", "retract-to-transform")
  elseif animator.animationState("blade") == "transform" then
    animator.setAnimationState("handle", "transform")
    animator.setAnimationState("handleFullbright", "transform")
  else
    animator.setAnimationState("blade", "transform")
    animator.setAnimationState("handle", "transform")
    animator.setAnimationState("handleFullbright", "transform")
  end

  util.wait(self.stances.empower.durationAfter)

  self._og.energyUsage = self.energyUsage
  self.energyUsage = self.empowerment.energyUsage or self.energyUsage
  self.noProjectiles = self.empowerment.noProjectiles

  self.onAttackStatusEffect = self.empowerment.onAttackStatusEffect
  status.setPersistentEffects("cronus_empowerment", self.empowerment.selfStatusEffects or {})

  for _, v in ipairs(self.stepDamageConfig) do
    for _, e in ipairs(self.empowerment.enemyStatusEffects) do
      table.insert(v.statusEffects, e)
    end
  end
end

function Class:clearEmpowerment()
  self.energyUsage = self._og.energyUsage or self.energyUsage
  self.damageConfig.statusEffects = self._og.statusEffects or self.damageConfig.statusEffects

  self.noProjectiles = nil
  self.onAttackStatusEffect = nil

  status.clearPersistentEffects("cronus_empowerment")

  if animator.animationState("handle") == "empowered" then
    animator.setAnimationState("blade", "retract")
  elseif animator.animationState("blade") == "revert" then
    animator.setAnimationState("handle", "revert")
    animator.setAnimationState("handleFullbright", "revert")
  end
  animator.setGlobalTag("isEmpowered", "")

  for i, v in ipairs(self.stepDamageConfig) do
    local og = copy(self._og.statusEffects[i])
    if og then
      v.statusEffects = og
    end
  end
end

-- added `self.noProjectiles` check,
--  `self.onAttackStatusEffect` application
function Class:fire()
  local stance = self.stances["fire"..self.comboStep]

  self.weapon:setStance(stance)
  self.weapon:updateAim()

  if self.onAttackStatusEffect then
    status.addEphemeralEffects(self.onAttackStatusEffect)
  end

  local animStateKey = self.animKeyPrefix .. (self.comboStep > 1 and "fire"..self.comboStep or "fire")
  animator.setAnimationState("swoosh", animStateKey)
  animator.playSound(animStateKey)

  local swooshKey = self.animKeyPrefix .. (self.elementalType or self.weapon.elementalType) .. "swoosh"
  animator.setParticleEmitterOffsetRegion(swooshKey, self.swooshOffsetRegions[self.comboStep])
  animator.burstParticleEmitter(swooshKey)

  -- Options for projectiles - heya neb here defiant really wanted this so i made it, DEFIANT I HOPE YOURE HAPPY!
  if stance.projectile and not self.noProjectiles then
    local firePosition = vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("blade", "projectileFirePoint") or {0,0}))
    local params = stance.projectileParameters or {}
    params.power = stance.projectileDamage * config.getParameter("damageLevelMultiplier")
    params.powerMultiplier = activeItem.ownerPowerMultiplier()
    params.speed = util.randomInRange(params.speed)

    world.debugPoint(firePosition, "red")

    if not world.lineTileCollision(mcontroller.position(), firePosition) then
      for i = 1, (stance.projectileCount or 1) do
        local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(stance.projectileInaccuracy or 0, 0) + (stance.projectileAimAngleOffset or 0))
        aimVector[1] = aimVector[1] * mcontroller.facingDirection()

        world.spawnProjectile(
            stance.projectile,
            firePosition,
            activeItem.ownerEntityId(),
            aimVector,
            false,
            params
        )
      end
    end
  end

  util.wait(stance.duration, function()
    if self.empoweredTimer > 0 then
      local xoff = self.empowerment.damageAreaOffset[1]
      local yoff = self.empowerment.damageAreaOffset[2]
      --animator.translateTransformationGroup("swoosh", vec2.rotate(self.empowerment.damageAreaOffset, -self.weapon.relativeWeaponRotation))
      animator.scaleTransformationGroup("swoosh", self.empowerment.damageAreaScale)
    end

    self.weapon:setDamage(self.stepDamageConfig[self.comboStep], partDamageArea("swoosh"))
  end)

  if self.comboStep < self.comboSteps then
    self.comboStep = self.comboStep + 1
    self:setState(self.wait)
  elseif self.stances.comboSpin then
    self:setState(self.comboSpin)
  end
end

local _uninit = Class.uninit
function Class:uninit(all)
  _uninit(self, all)
  if all then
    self:clearEmpowerment()
  end
end