function init()
	UUID = sb.makeUuid()
	math.kf_config_id = UUID
	
	cfg = player.getProperty("knightfall_config", {})
	--sb.logInfo("knightfall - start %s", cfg)
	
	for k,v in pairs(config.getParameter("checkboxes", {})) do
		local checked = cfg[v.property]
		if checked == nil then checked = v.default or false end
		widget.setChecked(k, checked)
	end
	
	widget.setSliderValue("cooldownBarSlider", (cfg.cooldownBar_minTime or 0.75) * 100)
	widget.setText("cooldownBarSliderNumber", cfg.cooldownBar_minTime or "^gray;0.75")
end

function update(dt)
	--stops multiple windows being opened, badly
	if math.kf_config_id ~= UUID then
		if math.kf_config_id == "cum" then DONOTSAVE = true end
		math.kf_config_id = "cum"
		pane.dismiss()
		return
	end
end

function save()
	--sb.logInfo("knightfall - saved %s", cfg)
	player.setProperty("knightfall_config", cfg)
end

function dismissed()
	if not DONOTSAVE then save() end
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
