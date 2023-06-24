require "/items/active/weapons/ranged/abilities/flamethrower/flamethrower.lua"

--movement of the  flame thrower muzzle
function FlamethrowerAttack:firePosition()
  if self.muzzleOffset then
    return vec2.add(mcontroller.position(), activeItem.handPosition(vec2.add(self.weapon.muzzleOffset, self.muzzleOffset)))
  else
    return GunFire.firePosition(self)
  end
end