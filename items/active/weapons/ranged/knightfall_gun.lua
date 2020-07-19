require "/items/active/weapons/ranged/gun.lua"

baseInit = init
function init()
  baseInit()
  
  self.cursor = config.getParameter("cursor")
  
  if (self.cursor) then
    activeItem.setCursor(self.cursor)
  else
    activeItem.setCursor("/cursors/reticle0.cursor")
  end
end