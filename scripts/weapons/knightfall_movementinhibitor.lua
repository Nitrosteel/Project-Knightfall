-- Basic script that inhibits movement. Must be attached to an ability to be used. 
-- See 'syndicate_lukane-bloodhound' for reference.

local baseUpdate = GunFire.update or function() end
function GunFire:update(dt, fireMode, shiftHeld)
	baseUpdate(self, dt, fireMode, shiftHeld)

	if fireMode == self.triggerSlot then
		mcontroller.controlModifiers({
			runningSuppressed = not (self.allowRunning) or false,
			jumpingSuppressed = not (self.allowJumping) or false
		})
	end
end