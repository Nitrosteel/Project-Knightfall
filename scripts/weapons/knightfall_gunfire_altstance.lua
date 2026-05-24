-- Original script by Nebulox.
-- Modified by Nitrosteel, using Claude Sonnet 4.6.
--
-- Features:
--   * Alternate Stance Toggling
--   * Persistent Stance State
--   * Configurable Animation States
--
-- Last edited on 05/23/2026

require "/scripts/knightfall_util.lua" -- nebUtil

AltStanceGunFire = WeaponAbility:new()

function AltStanceGunFire:init()
  self.switchCooldownTimer = 0
  
  self.newAbilityLoaded = false
  self.abilityBackup = false
end

function AltStanceGunFire:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)
  
  self.switchCooldownTimer = math.max(0, self.switchCooldownTimer - dt)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) then
    self:setState(self.toggleStance)
  end
  
  if self.abilityBackup == false then
    --sb.jsonMerge() and copy() cause stack overflow
    self.abilityBackup = KnightfallUtil.backupAbility(self.weapon.abilities[self.adaptedAbilityIndex])
    if config.getParameter("newAbilityLoaded", false) then
      self:restoreStance()
    end
  end
end

function AltStanceGunFire:restoreStance()
  local abilityType = self.newAbilityLoaded and self.abilityBackup or self.newAbility
  self:adaptAbility(abilityType)
  
  self.newAbilityLoaded = true
  activeItem.setInstanceValue("newAbilityLoaded", self.newAbilityLoaded)
end

function AltStanceGunFire:toggleStance()
  local abilityType = self.newAbilityLoaded and self.abilityBackup or self.newAbility
  
  self:adaptAbility(abilityType)

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

  self.weapon:setStance(self.stances.swap)
  util.wait(self.stances.swap.duration / 2)
  
  local progress = 0
  util.wait(self.stances.swap.duration, function()
    local from = self.stances.swap.weaponOffset or {0,0}
    local to = self.weapon.abilities[self.adaptedAbilityIndex].stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {util.interpolateHalfSigmoid(progress, from[1], to[1]), util.interpolateHalfSigmoid(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(util.interpolateHalfSigmoid(progress, self.stances.swap.weaponRotation, self.weapon.abilities[self.adaptedAbilityIndex].stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(util.interpolateHalfSigmoid(progress, self.stances.swap.armRotation, self.weapon.abilities[self.adaptedAbilityIndex].stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.swap.duration))
  end)

  self.weapon:setStance(self.weapon.abilities[self.adaptedAbilityIndex].stances.idle)
  self.weapon:updateAim()
  
  self.switchCooldownTimer = self.switchCooldown or 0
end

function AltStanceGunFire:adaptAbility(abilityType)
  local ability = self.weapon.abilities[self.adaptedAbilityIndex]
  
  util.mergeTable(self.weapon.abilities[self.adaptedAbilityIndex], abilityType)
end

function AltStanceGunFire:uninit()
end