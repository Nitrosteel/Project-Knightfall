require "/items/active/weapons/ranged/gunfire.lua"

-- Overrides default gunfire burst function to include cooldown
local baseBurst = GunFire.burst
function GunFire:burst()
  baseBurst(self)
  self:setState(self.cooldown)
end

-- burst gun firing animation thing
local baseMuzzleFlash = GunFire.muzzleFlash
function GunFire:muzzleFlash()
  baseMuzzleFlash(self)
  
  if self.fireAnimationStates then
    for k,v in pairs(self.fireAnimationStates) do
      animator.setAnimationState(k, v)
    end
  end
end