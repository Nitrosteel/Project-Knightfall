
require "/items/active/weapons/melee/energymeleeweapon.lua"


-- Replaces energymeleeweapon.lua to consider the value of
--   self.weapon._stillActive to maintain blade active state
-- Used in cronus, but can also be used in other scripts.
-- Just added `or self.weapon._stillActive`.
function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)

  local nowActive = self.weapon._stillActive and true or self.weapon.currentAbility ~= nil
  if nowActive then
    if self.activeTimer == 0 and animator.animationState("blade") == "inactive" then
      animator.setAnimationState("blade", "extend")
    end
    self.activeTimer = self.activeTime
  elseif self.activeTimer > 0 then
    self.activeTimer = math.max(0, self.activeTimer - dt)
    if self.activeTimer == 0 then
      animator.setAnimationState("blade", "retract")
    end
  end
end