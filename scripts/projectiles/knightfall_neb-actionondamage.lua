function init()
  self.actionOnDamage = config.getParameter("actionOnDamage", nil)
end

function hit(entityId)
  --Optionally perform projectile actions on hit
  if self.actionOnDamage then
	for _, action in pairs(self.actionOnDamage) do
	  projectile.processAction(action)
	end
  end
end

--Function that gets called on the projectile's death
function destroy()
end