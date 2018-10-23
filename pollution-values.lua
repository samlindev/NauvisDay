local function getExtraPollution(label, name)
	if extraPollution[label] then
		if extraPollution[label][name] then
			return extraPollution[label][name]
		end
		if extraPollution[label]["*"] then
			return extraPollution[label]["*"]
		end
		if extraPollution[label]["HAS_WILDCARD"] then
			for card,value in pairs(extraPollution[label]) do
				if string.find(card, "_*", 1, true) then
					local look = string.sub(card, 1, -3)
					--log("Looking for '" .. look .. "' in '" .. name .. "'")
					if string.find(name, look, 1, true) then
						return value
					end
				end
			end
		end
	end
	return nil
end

function increaseEmissionValues()
	local repl = {}
	for _,name in pairs(pollutionIncreaseExclusion) do
		log("Excluding " .. name .. " from pollution increase")
		repl[name] = 1
	end
	pollutionIncreaseExclusion = repl --turn into table for fast lookup

	local coalBurners = {"boiler", "furnace", "mining-drill", "assembling-machine"}--, "inserter", "car", "locomotive"} these do not have emissions params; do they even pollute? (reddit says no)
	for idx,label in pairs(coalBurners) do
		for k,obj in pairs(data.raw[label]) do
			if pollutionIncreaseExclusion[k] ~= 1 then
				--log(serpent.block("Checking candidate coal burner '" .. k .. "'"))
				if obj.energy_source.type == "burner" and obj.energy_source.fuel_category == "chemical" then
					--log(serpent.block("ID'ed coal burner '" .. k .. "', increasing emissions " .. coalPollutionScale .. "x"))
					if obj.energy_source.emissions then
						obj.energy_source.emissions = obj.energy_source.emissions*coalPollutionScale
						--log(serpent.block("Success"))
					else
						--log(serpent.block("Entity had no emissions parameter. Entity: "))
						--log(serpent.block(obj))
					end
				end
			end
		end
	end

	for name,tree in pairs(data.raw["tree"]) do
		if tree.emissions_per_tick and not string.find(name, "dead") then
			--log(serpent.block("Checking candidate coal burner '" .. k .. "'"))
			--log(serpent.block("ID'ed coal burner '" .. k .. "', increasing emissions " .. pollutionScale*coalPollutionScale .. "x"))
			tree.emissions_per_tick = tree.emissions_per_tick*10
		end
	end

	local polluters = {"assembling-machine", "pump", "mining-drill", "furnace", "boiler"} --assembly also includes chem plant, refinery, centrifuge
	for idx,label in pairs(polluters) do
		for k,obj in pairs(data.raw[label]) do
			if pollutionIncreaseExclusion[k] ~= 1 then
				--log(serpent.block("Checking candidate polluter '" .. k .. "'"))
				log(serpent.block("ID'ed polluter '" .. k .. "', increasing emissions " .. pollutionScale .. "x"))
				if obj.energy_source.emissions then
					obj.energy_source.emissions = obj.energy_source.emissions*pollutionScale
					if label == "mining-drill" then
						obj.energy_source.emissions = obj.energy_source.emissions*miningPollutionScale
						log(serpent.block("ID'ed mining polluter '" .. k .. "', increasing emissions again " .. miningPollutionScale .. "x"))
					end
					--log(serpent.block(extraPollution[label]))
					local f = getExtraPollution(label, k)
					if f then
						obj.energy_source.emissions = obj.energy_source.emissions*f
						log(serpent.block("ID'ed 'extra' polluter '" .. k .. "', increasing emissions again " .. f .. "x"))
					end
					--log(serpent.block("Success"))
				else
					--log(serpent.block("Entity had no emissions parameter. Entity: "))
					--log(serpent.block(obj))
				end
			end
		end
	end

	for k,obj in pairs(data.raw.fire) do
		--log(serpent.block("Checking candidate polluter '" .. k .. "'"))
		--log(serpent.block("ID'ed polluter '" .. k .. "', increasing emissions " .. pollutionScale*firePollutionScale .. "x"))
		if obj.emissions_per_tick then
			obj.emissions_per_tick = obj.emissions_per_tick*pollutionScale*firePollutionScale
		end
		--log(serpent.block("Success"))
	end
	
	for k,obj in pairs(data.raw.recipe) do
		if recipePollutionIncreases[k] then
			if not obj.emissions_multiplier then obj.emissions_multiplier = 1 end
			obj.emissions_multiplier = obj.emissions_multiplier*recipePollutionIncreases[k]
			log("Increasing recipe '" .. k .. "' emissions by " .. recipePollutionIncreases[k] .. "x")
		end
	end
end