if RequiredScript == "lib/managers/hudmanagerpd2" then
	HUDECMCounter = HUDECMCounter or class()

    function HUDECMCounter:init(hud)
		self._end_time = 0
		
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
    end

    function HUDECMCounter:update()
		--Update time/visibility
		local current_time = TimerManager:game():time()
		local t = self._end_time - current_time
		
		--only run everything when stealth is broken
		--was there a reason for fragtrane to not disable the timer outside of whisper mode? idk
		if (managers.groupai:state():whisper_mode()) then
			self._ecm_panel:set_visible(t > 0)
			
			if t > 0 then
				if (ECM2021.settings.chat_on_start and self._active_ecm == false) then
					if (self._pocket_ecm) then ECM2021:send_message("Pocket ECM has started!")
					else ECM2021:send_message("ECM effect has started!") end
				end
				--set an ECM being active here; other functions can set it to true if they don't want chat on start
				--for instance, joining midgame or sending the non-pager-blocking message
				self._active_ecm = true
				if (ECM2021.settings.display_tenths) then
					self._text:set_text(string.format("%.1f", t))
				else
					self._text:set_text(string.format("%.fs", t))
				end
				
				local threshold = tonumber(ECM2021.settings.time_threshold)
				if (ECM2021.settings.chat_on_time and not self._pocket_ecm and t < threshold and self._prevt >= threshold) then
					if (threshold ~= 1) then
						ECM2021:send_message("ECM has " .. threshold .. " seconds left!")
					else --1 seconds is cringe
						ECM2021:send_message("ECM has " .. threshold .. " second left!")
					end
				end
			else
				self._active_ecm = false
				if (ECM2021.settings.chat_on_end and self._prevt > 0) then
					if (self._pocket_ecm) then ECM2021:send_message("Pocket ECM has ended!")
					else ECM2021:send_message("ECM effect has ended!") end
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
		if new_end_time > managers.hud._hud_ecm_counter._end_time then
			managers.hud._hud_ecm_counter._end_time = new_end_time
			managers.hud:update_ecm_icons(battery_life_upgrade_lvl == 3)
			managers.hud._hud_ecm_counter._pocket_ecm = false
			if (ECM2021.settings.chat_on_pager and battery_life_upgrade_lvl ~= 3) then
				ECM2021:send_message("ECM placed does not block pagers!")
				managers.hud._hud_ecm_counter._active_ecm = true --don't send both messages
			end
		end
	end)
	
	--When playing as a client.
	Hooks:PostHook(ECMJammerBase, "sync_setup", "buuECM_post_ECMJammerBase_sync_setup", function(self, upgrade_lvl, ...)
	--	log("ECM: sync_setup")
		local new_end_time = TimerManager:game():time() + self:battery_life()
		if new_end_time > managers.hud._hud_ecm_counter._end_time then
			managers.hud._hud_ecm_counter._end_time = new_end_time
			managers.hud:update_ecm_icons(upgrade_lvl == 3)
			managers.hud._hud_ecm_counter._pocket_ecm = false
			if (ECM2021.settings.chat_on_pager and upgrade_lvl ~= 3) then
				ECM2021:send_message("ECM placed does not block pagers!")
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
		if new_end_time > managers.hud._hud_ecm_counter._end_time then
			managers.hud._hud_ecm_counter._end_time = new_end_time
			managers.hud:update_ecm_icons(true)
			managers.hud._hud_ecm_counter._pocket_ecm = true
		end
	end)
end