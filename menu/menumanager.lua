local key = ModPath .. '	' .. RequiredScript
if _G[key] then return else _G[key] = true end



Hooks:Add('LocalizationManagerPostInit', 'LocalizationManagerPostInit_ECM2021', function(loc)
	loc:load_localization_file(ECM2021._path .. 'menu/english.txt', false)
end)

Hooks:Add('MenuManagerInitialize', 'MenuManagerInitialize_ECM2021', function(menu_manager)

	MenuCallbackHandler.ECMOptionsCheckbox = function(this, item)
		ECM2021.settings[item:name()] = item:value() == 'on'
	end

	MenuCallbackHandler.ECMOptionsValue = function(this, item)
		ECM2021.settings[item:name()] = math.floor(item:value())
	end
	
	MenuCallbackHandler.ECMOptionsMulti = function(this, item)
		ECM2021.settings[item:name()] = item:value()
	end

	MenuCallbackHandler.ECMOptionsSave = function(this, item)
		ECM2021:Save()
	end

	ECM2021:Load()

	MenuHelper:LoadFromJsonFile(ECM2021._path .. 'menu/options.txt', ECM2021, ECM2021.settings)

end)
