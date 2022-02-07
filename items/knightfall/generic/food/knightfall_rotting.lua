function ageItem(baseItem, aging)
  if baseItem.parameters.timeToRot then
    baseItem.parameters.timeToRot = baseItem.parameters.timeToRot - aging

    baseItem.parameters.tooltipFields = baseItem.parameters.tooltipFields or {}
    baseItem.parameters.tooltipFields.rotTimeLabel = getRotTimeDescription(baseItem.parameters.timeToRot)

    if baseItem.parameters.timeToRot <= 0 then
      local itemConfig = root.itemConfig(baseItem.name)
      return {
        name = itemConfig.config.rottedItem or root.assetJson("/items/rotting.config:rottedItem"),
        count = baseItem.count,
        parameters = {}
      }
    end
  end

  return baseItem
end

function getRotTimeDescription(rotTime)
  local descList = root.assetJson("/items/knightfall/generic/food/knightfall_rotting.config:rotTimeDescriptions")
  for i, desc in ipairs(descList) do
    if rotTime <= desc[1] then return desc[2] end
  end
  return descList[#descList]
end
