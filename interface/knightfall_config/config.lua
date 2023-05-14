function init()
  local m = getmetatable''
  if m.knightfall_settings_dismiss then
    m.knightfall_settings_dismiss()
    m.knightfall_settings_dismiss = nil
    return pane.dismiss()
  end
  
  m.knightfall_settings_dismiss = pane.dismiss
  
	cfg = player.getProperty("knightfall_config", {})
	
	for k,v in pairs(config.getParameter("checkboxes", {})) do
		local checked = cfg[v.property]
		if checked == nil then checked = v.default or false end
		widget.setChecked(k, checked)
	end
	
	widget.setSliderValue("cooldownBarSlider", (cfg.cooldownBar_minTime or 0.75) * 100)
	widget.setText("cooldownBarSliderNumber", cfg.cooldownBar_minTime or "^gray;0.75")
end

function cooldownBar(name, data)
	cfg[data] = widget.getChecked(name)
	save()
end

function cooldownSlider(name, data)
	local n = math.floor(widget.getSliderValue(name) / 5) * 5 / 100
	cfg[data] = n
	widget.setText("cooldownBarSliderNumber", n)
	save()
end

function save()
	player.setProperty("knightfall_config", cfg)
end

function uninit()
  getmetatable''.knightfall_settings_dismiss = nil
end