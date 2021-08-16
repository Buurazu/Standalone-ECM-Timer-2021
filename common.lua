_G.ECM2021 = _G.ECM2021 or {}
ECM2021._path = ModPath
ECM2021._data_path = SavePath .. 'ecm2021.txt'
ECM2021.settings = {
	display_tenths = true,
	chat_on_start = false,
	chat_on_time = false,
	chat_on_pager = false,
	chat_on_end = false,
	time_threshold = 3
}

function ECM2021:Load()
	local file = io.open(ECM2021._data_path, 'r')
	if file then
		for k, v in pairs(json.decode(file:read('*all')) or {}) do
			ECM2021.settings[k] = v
		end
		file:close()
	end
end

function ECM2021:Save()
	local file = io.open(ECM2021._data_path, 'w+')
	if file then
		file:write(json.encode(ECM2021.settings))
		file:close()
	end
end