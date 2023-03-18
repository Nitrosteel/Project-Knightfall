require "/items/active/weapons/ranged/abilities/altfire.lua"

-- burst gun firing animation thing
local baseMuzzleFlash = AltFireAttack.muzzleFlash
function AltFireAttack:muzzleFlash()
  baseMuzzleFlash(self)
  
  if self.fireAnimationStates then
    for k,v in pairs(self.fireAnimationStates) do
      animator.setAnimationState(k, v)
    end
  end
end