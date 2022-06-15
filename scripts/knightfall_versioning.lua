local ini = init or function() end

function init() ini()
	local currentVersion = 1

	if status.statusProperty( "kf_version" ) == nil then 
		status.setStatusProperty( "kf_version", 0 ) 
	end

	if status.statusProperty( "kf_version" ) < currentVersion then
		if player.hasCompletedQuest( "destroyruin" ) then
			player.setUniverseFlag( "outpost_knightfall_missionbeacon" )
		end
		status.setStatusProperty( "kf_version", currentVersion )
	end
end