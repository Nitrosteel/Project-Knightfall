require "/items/active/weapons/ranged/gunfire.lua"

-- Overrides default gunfire burst function to include cooldown
local baseBurst = GunFire.burst
function GunFire:burst()
  baseBurst(self)
  self:setState(self.cooldown)
end
