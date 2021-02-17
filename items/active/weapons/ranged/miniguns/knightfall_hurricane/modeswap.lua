
require "/scripts/util.lua"

--[[--
  * modeswap.lua
  * Ability script (class: ModeSwap)
  *
  * Simply merges this ability's "altMode" parameters to the primary ability's parameters,
  * stores the original so it can be completely reverted.
  *
  * Needed are: "switch" stance, "switch" sound
  * Optionally: "switchOff" stance, "switchOff" sound
  * Defines a "modeSwap" global tag that switches between "alt" and ""
  *
  * Created by Lyrthras#7199 on 02/15/21
--]]--

--[[--
  === JSON fields ( * = required, - = optional ) ===
  * altMode   - table: contains the parameters to override the weapon's parameters into
--]]--


ModeSwap = WeaponAbility:new()

function ModeSwap:init()
  self.inAltMode = config.getParameter("inAltMode", false)

  self.otherAbility = self.weapon.abilities[self.baseAbilityIndex or 1]

  self.altMode = sb.jsonMerge(jobject(), self.altMode)
  self.baseMode = jobject()   -- super secret scripting substance

  for key in pairs(self.altMode) do
    self.baseMode[key] = self.otherAbility[key]
  end

  self:swapAbility()

  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
end

function ModeSwap:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  if not self.weapon.currentAbility and self.fireMode == (self.activatingFireMode or self.abilitySlot) then
    self:setState(self.switch)
  end
end

function ModeSwap:switch()
  self.inAltMode = not self.inAltMode
  activeItem.setInstanceValue("inAltMode", self.inAltMode)

  self:swapAbility()
  animator.playSound(not self.inAltMode and animator.hasSound("switchOff") and "switchOff" or "switch")

  local stance = self.inAltMode and self.stances.switch or (self.stances.switchOff or self.stances.switch)
  self.weapon:setStance(stance)

  util.wait(stance.duration)
end


-- Remember that to-do in util.lua for this same function?
-- Welp... looks like I gotta implement it myself
-- (I think)
local function mergeTable(t1, t2)
  for k, v in pairs(t2) do
    if type(v) == "table" and type(t1[k]) == "table" then
      mergeTable(t1[k] or {}, v)
    else
      t1[k] = v
    end
  end

  -- implement null-setting
  local mt = getmetatable(t2)
  local nulls = mt and mt.__typehint == 2 and mt.__nils or {}
  for k in pairs(nulls) do
    t1[k] = nil
  end

  return t1
end

function ModeSwap:swapAbility()
  mergeTable(self.otherAbility, self.inAltMode and self.altMode or self.baseMode)
  animator.setGlobalTag("modeSwap", self.inAltMode and "alt" or "")
end

function ModeSwap:uninit()
end
