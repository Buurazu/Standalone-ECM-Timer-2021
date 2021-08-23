if RequiredScript == "lib/managers/hudmanagerpd2" then
	HUDECMCounter = HUDECMCounter or class()

    function HUDECMCounter:init(hud)
		self._end_time = 0
		self._nonpager_end_time = 0
		
	    self._hud_panel = hud.panel
	    self._ecm_panel = self._hud_panel:panel({
		    name = "ecm_counter_panel",
		    visible = false,
		    w = 200,
		    h = 200
	    })

	    self._ecm_panel:set_top(50)
        self._ecm_panel:set_right(self._hud_panel:w() + 11)

	    local ecm_box = HUDBGBox_create(self._ecm_panel, { w = 38, h = 38, },  {})

	    self._text = ecm_box:text({
		    name = "text",
		    text = "0",
		    valign = "center",
		    align = "center",
		    vertical = "center",
		    w = ecm_box:w(),
		    h = ecm_box:h(),
		    layer = 1,
		    color = Color.white,
		    font = tweak_data.hud_corner.assault_font,
		    font_size = tweak_data.hud_corner.numhostages_size * 0.9
	    })

	    local ecm_icon = self._ecm_panel:bitmap({
		    name = "ecm_icon",
		    texture = "guis/textures/pd2/skilltree/icons_atlas",
		    texture_rect = { 1 * 64, 4 * 64, 64, 64 },
		    valign = "top",
			color = Color.white,
		    layer = 1,
		    w = ecm_box:w(),
		    h = ecm_box:h()	
	    })
	    ecm_icon:set_right(ecm_box:parent():w())
	    ecm_icon:set_center_y(ecm_box:h() / 2)
		ecm_box:set_right(ecm_icon:left())
        
		local pagers_texture, pagers_rect = tweak_data.hud_icons:get_icon_data("pagers_used")
		local pager_icon = self._ecm_panel:bitmap({
		    name = "pager_icon",
		    texture = pagers_texture,
		    texture_rect = pagers_rect,
		    valign = "top",
			visible = false,
			color = Color.white,
		    layer = 2,
		    w = ecm_box:w() / 2,
		    h = ecm_box:h() / 2
	    })
		pager_icon:set_right(self._ecm_panel:w() - 20 )
		pager_icon:set_center_y(ecm_box:h())
		
		self._prevt = 0
		self._active_ecm = false
		self._pocket_ecm = false
		self._pager_block = false
		
		ECM2021._playing_the_game = true
    end

    function HUDECMCounter:update()
		--Update time/visibility
		local current_time = TimerManager:game():time()
		local t = self._end_time - current_time
		--when a pager-blocking ECM expires, check if we have a non-pager-blocking ECM end time queued up
		if (t < 0) then
			t = self._nonpager_end_time - current_time
			if (t > 0) then
				--these lines should only play if there was an active pager ecm going, because when there isn't, we set _end_time already
				ECM2021:send_message("Pager block effect has ended!", ECM2021.settings.chat_on_end)
				self._end_time = self._nonpager_end_time
				self._pocket_ecm = false
				managers.hud:update_ecm_icons(false)
			end
		end
		
		--hacker dodge skill check, it might be slightly relevant thing to have on this when things are loud
		--(or remaining ecm feedback time)
		--t = managers.player:get_activate_temporary_expire_time("temporary", "pocket_ecm_kill_dodge") - current_time
		
		--only run everything when stealth is broken
		--was there a reason for fragtrane to not disable the timer outside of whisper mode? idk
		if (managers.groupai:state():whisper_mode()) then
			self._ecm_panel:set_visible(t > 0)
			
			if t > 0 then
				if (self._active_ecm == false) then
					if (self._pocket_ecm) then ECM2021:send_message("Pocket ECM has started!", ECM2021.settings.chat_on_start)
					else ECM2021:send_message("ECM effect has started!", ECM2021.settings.chat_on_start) end
				end
				--set an ECM being active here; other functions can set it to true if they don't want chat on start
				--for instance, joining midgame or sending the non-pager-blocking message
				self._active_ecm = true
				if (ECM2021.settings.display_tenths) then
					self._text:set_text(string.format("%.1f", t))
				else
					--old rounding text
					--self._text:set_text(string.format("%.fs", t))
					self._text:set_text(math.ceil(t) .. "s")
				end
				
				--does it have to be tonumbered?
				local threshold = tonumber(ECM2021.settings.time_threshold)
				local freq = ECM2021.settings.blink_frequency
				local intensity = ECM2021.settings.blink_intensity
				if (t < threshold and ECM2021.settings.blink_when_low) then
					--turn our color into a value between 0 and (frequency / 2), going up and down
					local red = (threshold - t) % freq
					if (red > freq/2) then red = freq - red end
					--now turn it into a value between 0 and 1
					red = red / (freq/2)
					--now turn it into a value between 255 and 0 (minimum based on intensity percentage)
					red = math.floor(255 - red * (255 * intensity/100))
					self._text:set_color(Color("ff" .. string.format("%02x", red) .. string.format("%02x", red)))
				else
					self._text:set_color(Color.white)
				end
				if (not self._pocket_ecm and t < threshold and self._prevt >= threshold) then
					if (threshold ~= 1) then
						ECM2021:send_message("ECM has " .. threshold .. " seconds left!", ECM2021.settings.chat_on_time)
					else --1 seconds is cringe
						ECM2021:send_message("ECM has " .. threshold .. " second left!", ECM2021.settings.chat_on_time)
					end
				end
			else
				self._active_ecm = false
				if (self._prevt > 0) then
					if (self._pocket_ecm) then ECM2021:send_message("Pocket ECM has ended!", ECM2021.settings.chat_on_end)
					else ECM2021:send_message("ECM effect has ended!", ECM2021.settings.chat_on_end) end
				end
			end
		else --no longer in whisper mode
			self._ecm_panel:set_visible(false)
		end
		self._prevt = t
    end

	function HUDECMCounter:update_icons(jam_pagers)
        local pager_icon = self._ecm_panel:child("pager_icon")
        pager_icon:set_visible(jam_pagers)
		self._pager_block = jam_pagers
    end

	--Init
	Hooks:PostHook(HUDManager, "_setup_player_info_hud_pd2", "buuECM_post_HUDManager__setup_player_info_hud_pd2", function(self)
		self._hud_ecm_counter = HUDECMCounter:new(managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2))
	end)
	
	--Update ECM timer
	Hooks:PostHook(HUDManager, "update", "buuECM_post_HUDManager_update", function(self)
		self._hud_ecm_counter:update()
	end)

	function HUDManager:update_ecm_icons(jam_pagers)
        self._hud_ecm_counter:update_icons(jam_pagers)
    end

elseif RequiredScript == "lib/units/equipment/ecm_jammer/ecmjammerbase" then
	
	--When playing as host.
	Hooks:PostHook(ECMJammerBase, "setup", "buuECM_post_ECMJammerBase_setup", function(self, battery_life_upgrade_lvl, ...)
	--	log("ECM: setup")
		local new_end_time = TimerManager:game():time() + self:battery_life()
		--a new pager-blocking ECM will always have a longer end time than non-pager-blocking, so no need to check that
		if new_end_time > managers.hud._hud_ecm_counter._end_time then
			if (ECM2021.settings.pager_priority and battery_life_upgrade_lvl ~= 3) then
				managers.hud._hud_ecm_counter._nonpager_end_time = new_end_time
				if (managers.hud._hud_ecm_counter._pager_block == false or managers.hud._hud_ecm_counter._active_ecm == false) then
					managers.hud._hud_ecm_counter._end_time = new_end_time
					managers.hud:update_ecm_icons(battery_life_upgrade_lvl == 3)
				end
			else
				managers.hud._hud_ecm_counter._end_time = new_end_time
				managers.hud:update_ecm_icons(battery_life_upgrade_lvl == 3)
			end
			managers.hud._hud_ecm_counter._pocket_ecm = false
			if (battery_life_upgrade_lvl ~= 3) then
				ECM2021:send_message("ECM placed does not block pagers!", ECM2021.settings.chat_on_pager)
				managers.hud._hud_ecm_counter._active_ecm = true --don't send both messages
			end
		end
	end)
	
	--When playing as a client.
	Hooks:PostHook(ECMJammerBase, "sync_setup", "buuECM_post_ECMJammerBase_sync_setup", function(self, upgrade_lvl, ...)
	--	log("ECM: sync_setup")
		local new_end_time = TimerManager:game():time() + self:battery_life()
		--a new pager-blocking ECM will always have a longer end time than non-pager-blocking, so no need to check that
		if new_end_time > managers.hud._hud_ecm_counter._end_time then
			if (ECM2021.settings.pager_priority and upgrade_lvl ~= 3) then
				managers.hud._hud_ecm_counter._nonpager_end_time = new_end_time
				if (managers.hud._hud_ecm_counter._pager_block == false or managers.hud._hud_ecm_counter._active_ecm == false) then
					managers.hud._hud_ecm_counter._end_time = new_end_time
					managers.hud:update_ecm_icons(upgrade_lvl == 3)
				end
			else
				managers.hud._hud_ecm_counter._end_time = new_end_time
				managers.hud:update_ecm_icons(upgrade_lvl == 3)
			end
			managers.hud._hud_ecm_counter._pocket_ecm = false
			if (upgrade_lvl ~= 3) then
				ECM2021:send_message("ECM placed does not block pagers!", ECM2021.settings.chat_on_pager)
				managers.hud._hud_ecm_counter._active_ecm = true --don't send both messages
			end
			
		end
	end)
	
	--For joining mid-ECM
	Hooks:PostHook(ECMJammerBase, "update", "buuECM_ECMJammerBase_update", function(self, unit, t, ...)
		--log("ECM: update")
		if (managers.hud._hud_ecm_counter._end_time == 0) then
			local new_end_time = TimerManager:game():time() + self:battery_life()
			managers.hud._hud_ecm_counter._end_time = new_end_time
			managers.hud:update_ecm_icons(false) --not sure if you can check for pager blocking / 30s battery life now, doesn't matter really
			managers.hud._hud_ecm_counter._active_ecm = true
			managers.hud._hud_ecm_counter._pocket_ecm = false
		end
	end)
	
elseif RequiredScript == "lib/units/beings/player/playerinventory" then
	--Pocket ECMs
	Hooks:PostHook(PlayerInventory, "_start_jammer_effect", "buuECM_post_PlayerInventory__start_jammer_effect", function(self, end_time)
		local new_end_time = end_time or TimerManager:game():time() + self:get_jammer_time()
		--need to check if this 6 second pager block should take precedence over a non-pager-block ECM
		if new_end_time > managers.hud._hud_ecm_counter._end_time or
		(ECM2021.settings.pager_priority and managers.hud._hud_ecm_counter._pager_block == false) then
			managers.hud._hud_ecm_counter._end_time = new_end_time
			managers.hud:update_ecm_icons(true)
			managers.hud._hud_ecm_counter._pocket_ecm = true
		end
	end)
elseif RequiredScript == "lib/utils/accelbyte/telemetry" then
	--Stop sending chat during end of heist (thanks Rex)
	Hooks:PostHook(Telemetry, "on_end_heist", "ECM2021_on_end_heist", function(self)
		ECM2021._playing_the_game = false
	end)
end