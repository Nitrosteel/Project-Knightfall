require "/items/active/weapons/ranged/gun.lua"

oldInit = init
function init()
  oldInit()
  activeItem.setCursor("/cursors/knightfall_crosshair_sniper.cursor")
end
