require "/scripts/util.lua"

local oldUpdate = update
function update()
  if oldUpdate then oldUpdate() else localAnimator.clearDrawables() end

  local markerImages = animationConfig.animationParameter("markerImages") or {}
  for _, config in ipairs(markerImages) do
    localAnimator.addDrawable({image = config.image, position = config.position}, "overlay")
  end
end
