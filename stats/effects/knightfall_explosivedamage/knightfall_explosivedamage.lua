require "/scripts/status.lua"

--[[--
  Checks the unit's max health. If it's bigger than the baseline, then augments the basedamage dealt by increasing it based on their max health. Else it does nothing.
--]]--

function init()
	script.setUpdateDelta(0)
	self.damageCoefficient = config.getParameter("damageCoefficient") or 0.5
	self.damageBaseline = config.getParameter("damageBaseline") or 100
	self.maxHealth = math.abs(status.resourceMax("health"))
	self.basedamage = config.getParameter("basedamage") or 100

	if self.maxHealth > self.damageBaseline then
		local adjustedHealthFactor = self.maxHealth - self.damageBaseline
		local damageMultiplier = adjustedHealthFactor * self.damageCoefficient
		local damageAdjusted = damageMultiplier * 0.01
		local totalDamage = self.basedamage * damageAdjusted

		local source = effect.sourceEntity()
		if source then
			world.sendEntityMessage(source, "knightfall_explosivedamage", totalDamage, status.resource("health"))
		end

		status.applySelfDamageRequest(
			{
				damageType = "damage",
				damage = totalDamage * 0.5,
				damageSourceKind = "default",
				sourceEntityId = source or entity.id()
			}
		)

		status.applySelfDamageRequest(
			{
				damageType = "damage",
				damage = totalDamage * 0.5,
				damageSourceKind = "fire",
				sourceEntityId = source or entity.id()
			}
		)

		effect.expire()
	else 
		effect.expire()
	end
end
