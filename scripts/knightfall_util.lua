if not KnightfallUtil then
  KnightfallUtil = {}

  function KnightfallUtil.copyTable(table, count)
    local ret = {}
    for k, v in pairs(table) do
      if type(v) == "table" then
        if count > 10 then
          ret[k] = KnightfallUtil.copyTable(v, count + 1)
        end
      else
        ret[k] = v
      end
    end
    return ret
  end

  --Backup an ability
  function KnightfallUtil.backupAbility(abilityToBackup)
    local ret = {}
    for k, v in pairs(abilityToBackup) do
      if k == "stances" then
        ret["stances"] = KnightfallUtil.copyTable(abilityToBackup["stances"], 11)
      elseif type(v) == "table" then
        if v ~= "weapon" then
          ret[k] = KnightfallUtil.copyTable(v, 3);
        end
      else
        ret[k] = v;
      end
    end
    return ret;
  end
end