_G.ECM2021 = _G.ECM2021 or {}
ECM2021._path = ModPath
ECM2021._data_path = SavePath .. 'ecm2021.txt'
ECM2021.settings = {
	display_tenths = true,
	pager_priority = true,
	blink_when_low = true,
	blink_intensity = 50,
	blink_frequency = 1.5,
	chat_on_start = 1,
	chat_on_time = 1,
	chat_on_pager = 1,
	chat_on_end = 1,
	time_threshold = 5
}
ECM2021._playing_the_game = false
ECM2021._old_autochat = 1

function ECM2021:Load()
	local file = io.open(ECM2021._data_path, 'r')
	if file then
		for k, v in pairs(json.decode(file:read('*all')) or {}) do
			--log the old global chat settings and keep them out of the new settings file
			--the old options were found; this means we have to do a conversion, so set old autochat to a minimum of 2
			if ((k == "autochat_as_host" or k == "autochat_as_client") and ECM2021._old_autochat == 1) then ECM2021._old_autochat = 2 end
			if (k == "autochat_as_host") then
				if (v and ECM2021._old_autochat ~= 4) then ECM2021._old_autochat = 3 end
			elseif (k == "autochat_as_client") then
				if (v) then ECM2021._old_autochat = 4 end
			else
				ECM2021.settings[k] = v
			end
		end
		file:close()
	end
end

function ECM2021:ConvertOldSettings()
	--old_autochat = 1 means the old settings aren't in the file
	if (ECM2021._old_autochat == 1) then return end
	
	--check if each chat setting used to be true, if they were, then set them to "Send To Self" at minimum
	if (ECM2021.settings["chat_on_start"]) then ECM2021.settings["chat_on_start"] = ECM2021._old_autochat end
	if (ECM2021.settings["chat_on_time"]) then ECM2021.settings["chat_on_time"] = ECM2021._old_autochat end
	if (ECM2021.settings["chat_on_pager"]) then ECM2021.settings["chat_on_pager"] = ECM2021._old_autochat end
	if (ECM2021.settings["chat_on_end"]) then ECM2021.settings["chat_on_end"] = ECM2021._old_autochat end
	
end

function ECM2021:Save()
	local file = io.open(ECM2021._data_path, 'w+')
	if file then
		file:write(json.encode(ECM2021.settings))
		file:close()
	end
end

function ECM2021:send_message(msg, option)
	--Not Stealth, post-game screen, or Don't Send option
	if (not managers.groupai:state():whisper_mode() or not ECM2021._playing_the_game or option == 1) then return end
	--Send To Self option
	local sendit = false
	--Send as Host or Send as Client option
	if (Network:is_server() and option >= 3) then sendit = true end
	--Send as Client option
	if (not Network:is_server() and option == 4) then sendit = true end

	if (sendit) then
		managers.chat:send_message(1,'?',msg)
	else
		managers.chat:_receive_message(1, "ECM Timer", msg, Color("09b1db"))
	end
end