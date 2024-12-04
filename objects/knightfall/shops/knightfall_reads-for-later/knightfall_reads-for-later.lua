-- Made by Silver Sokolova.

function init()
	object.setInteractive(true)
	self.isPopulated = config.getParameter("isPopulated")
 
	local storePool = root.createTreasure(config.getParameter("storePool"), world.threatLevel())
	self.interactData = config.getParameter("interactData")
	
	for _, item in pairs (storePool) do
		self.interactData.items[#self.interactData.items + 1] = { item = item.name }
	end
	
	object.setConfigParameter("interactData", self.interactData)
	object.setConfigParameter("isPopulated", true)
end