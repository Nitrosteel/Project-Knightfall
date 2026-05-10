-- Basic script that inhibits movement. Must be attached to an ability to be used. 
-- See 'syndicate_lukane-bloodhound' for reference.

local function movementUpdate(baseUpdate)
  return function(self, dt, fireMode, shiftHeld)
    baseUpdate(self, dt, fireMode, shiftHeld)

    if fireMode == self.triggerSlot then
      mcontroller.controlModifiers({
        runningSuppressed = not (self.allowRunning) or false,
        jumpingSuppressed = not (self.allowJumping) or false
      })
    end
  end
end

if KFGunFire then
  KFGunFire.update = movementUpdate(KFGunFire.update or function() end)
end
if GunFire then
  GunFire.update = movementUpdate(GunFire.update or function() end)
end