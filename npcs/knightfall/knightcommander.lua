--By Silver Sokolova

require "/scripts/actions/dialog.lua"

function init()
  npc.setInteractive(true)
  if not entity.uniqueId() then
    npc.setUniqueId(sb.makeUuid())
  end
  knightfall_questToGive = config.getParameter("quest")
end

function interact(args)
  mcontroller.controlFace(args.sourcePosition[1] > mcontroller.xPosition() and 1 or -1)

  world.sendEntityMessage(args.sourceId, "knightfall_raidquestprompt", entity.uniqueId(), entity.id(), knightfall_questToGive)

  sayToEntity({
    dialogType = "dialog.converse",
    dialog = nil,
    entity = args.sourceId,
    tags = {}
  })
end

--Version for hooking into bmain.lua
--[[
local originalInit = init or function() end

function init() originalInit()
  knightfall_npcType = npc.npcType()
  knightfall_questToGive = config.getParameter("quest")

  if knightfall_npcType == "knightfall_knightcommander" then
    if not entity.uniqueId() then
      npc.setUniqueId(sb.makeUuid())
    end

    local originalHandleInteract = handleInteract or function() end    
    handleInteract = function(args)
      world.sendEntityMessage(args.sourceId, "knightfall_raidquestprompt", entity.uniqueId(), entity.id(), knightfall_questToGive)

      sayToEntity({
        dialogType = "dialog.converse",
        dialog = nil,
        entity = args.sourceId,
        tags = {}
      })

      return originalHandleInteract(args) --This line optional
    end
  end
end
]]
