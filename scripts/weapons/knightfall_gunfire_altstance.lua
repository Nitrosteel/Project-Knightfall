-- Original script by Nebulox.
-- Modified by Nitrosteel, using Claude Sonnet 4.6.
--
-- Features:
--   * Alternate Stance Toggling
--   * Persistent Stance State
--   * Configurable Animation States
--   * Automatic Muzzle Offset Compensation
--   * Switch Cooldown
--
-- Last edited on 05/23/2026

require "/scripts/knightfall_util.lua"

AltStanceGunFire = WeaponAbility:new()

function AltStanceGunFire:init()
  self.newAbilityLoaded = false
  self.abilityBackup = false
  self.baseMuzzleOffset = nil
  self.baseOffset = nil
  self.switchCooldownTimer = 0

  -- Frozen snapshots used as resolve sources. These are never mutated after init.
  self._cleanNewAbility = nil
  self._cleanBackup = nil
  self._cleanLoadStance = nil
end

function AltStanceGunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.switchCooldownTimer = math.max(0, self.switchCooldownTimer - dt)

  if not self.weapon.currentAbility
    and self.fireMode == (self.activatingFireMode or self.abilitySlot)
    and self.switchCooldownTimer == 0 then
    self:setState(self.toggleStance)
  end

  if self.abilityBackup == false then
    --sb.jsonMerge() and copy() cause stack overflow
    self.abilityBackup = KnightfallUtil.backupAbility(self.weapon.abilities[self.adaptedAbilityIndex])
    self.baseMuzzleOffset = {self.weapon.muzzleOffset[1], self.weapon.muzzleOffset[2]}
    self.baseOffset = config.getParameter("baseOffset", {0, 0})

    -- The live ability's stances already have baseOffset baked in by Starbound's weapon
    -- initialisation. We snapshot a copy with baseOffset subtracted back out, giving us
    -- raw relative offsets. resolveStance then adds the correct base cleanly each toggle
    -- without ever double-adding it.
    self._cleanBackup = KnightfallUtil.backupAbility(self.abilityBackup)
    if self._cleanBackup.stances then
      for _, stance in pairs(self._cleanBackup.stances) do
        if stance.weaponOffset then
          stance.weaponOffset = {
            stance.weaponOffset[1] - self.baseOffset[1],
            stance.weaponOffset[2] - self.baseOffset[2]
          }
        end
      end
    end

    self._cleanNewAbility = KnightfallUtil.backupAbility(self.newAbility)
    if self.stances and self.stances.swap then
      self._cleanLoadStance = KnightfallUtil.backupAbility(self.stances.swap)
    end

    -- Always start in primary stance on pickup regardless of saved state.
    activeItem.setInstanceValue("newAbilityLoaded", false)
  end
end

function AltStanceGunFire:toggleStance()
  local abilityType = self.newAbilityLoaded and self._cleanBackup or self._cleanNewAbility

  self:adaptAbility(abilityType)
  self:applyMuzzleOffset(abilityType)

  self.newAbilityLoaded = (not self.newAbilityLoaded)
  activeItem.setInstanceValue("newAbilityLoaded", self.newAbilityLoaded)
  
  animator.playSound("swap")

  if self.loadAnimationStates and self.newAbilityLoaded then
    for part, state in pairs(self.loadAnimationStates) do
      animator.setAnimationState(part, state)
    end
  elseif self.unloadAnimationStates and not self.newAbilityLoaded then
    for part, state in pairs(self.unloadAnimationStates) do
      animator.setAnimationState(part, state)
    end
  end

  local resolvedLoad = self:resolveStance(self._cleanLoadStance, self.altBaseOffset or self.baseOffset)

  self.weapon:setStance(resolvedLoad)
  util.wait(resolvedLoad.duration / 2)

  local progress = 0
  util.wait(resolvedLoad.duration, function()
    local from = resolvedLoad.weaponOffset or {0, 0}
    local to = self.weapon.abilities[self.adaptedAbilityIndex].stances.idle.weaponOffset or {0, 0}
    self.weapon.weaponOffset = {util.interpolateHalfSigmoid(progress, from[1], to[1]), util.interpolateHalfSigmoid(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(util.interpolateHalfSigmoid(progress, resolvedLoad.weaponRotation, self.weapon.abilities[self.adaptedAbilityIndex].stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(util.interpolateHalfSigmoid(progress, resolvedLoad.armRotation, self.weapon.abilities[self.adaptedAbilityIndex].stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / resolvedLoad.duration))
  end)

  self.weapon:setStance(self.weapon.abilities[self.adaptedAbilityIndex].stances.idle)
  self.weapon:updateAim()

  self.switchCooldownTimer = self.switchCooldown or 0
end

-- Returns a new table with weaponOffset resolved as base + relative offset.
-- Never modifies the source stance table.
function AltStanceGunFire:resolveStance(stance, base)
  local resolved = {}
  for k, v in pairs(stance) do
    resolved[k] = v
  end
  local rel = stance.weaponOffset or {0, 0}
  resolved.weaponOffset = {base[1] + rel[1], base[2] + rel[2]}
  return resolved
end

-- Builds a fully resolved copy of abilityType (stances included) then merges it
-- into the live ability. Always resolves from frozen clean snapshots.
function AltStanceGunFire:adaptAbility(abilityType)
  local base = (abilityType == self._cleanBackup)
    and self.baseOffset
    or (self.altBaseOffset or self.baseOffset)

  local resolved = {}
  for k, v in pairs(abilityType) do
    resolved[k] = v
  end

  if abilityType.stances then
    resolved.stances = {}
    for name, stance in pairs(abilityType.stances) do
      resolved.stances[name] = self:resolveStance(stance, base)
    end
  end

  util.mergeTable(self.weapon.abilities[self.adaptedAbilityIndex], resolved)
end

-- Shifts muzzleOffset by the delta between the incoming ability's base and the
-- primary base. Reverting to the backup naturally restores the original muzzleOffset.
function AltStanceGunFire:applyMuzzleOffset(abilityType)
  if not self.baseMuzzleOffset then return end

  local incomingBase = (abilityType == self._cleanBackup)
    and self.baseOffset
    or (self.altBaseOffset or self.baseOffset)

  local dx = incomingBase[1] - self.baseOffset[1]
  local dy = incomingBase[2] - self.baseOffset[2]

  self.weapon.muzzleOffset = {
    self.baseMuzzleOffset[1] + dx,
    self.baseMuzzleOffset[2] + dy
  }
end

function AltStanceGunFire:uninit()
end