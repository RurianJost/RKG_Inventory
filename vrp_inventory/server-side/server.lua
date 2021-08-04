local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local Tools = module("vrp","lib/Tools")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

vRPN = {}
Tunnel.bindInterface("vrp_inventory",vRPN)
Proxy.addInterface("vrp_inventory",vRPN)

local idgens = Tools.newIDGenerator()

local vthirst = 0
local vhunger = 0

vGARAGE = Tunnel.getInterface("vrp_garages")
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEBHOOK
-----------------------------------------------------------------------------------------------------------------------------------------
local webhookequipar = "" 
local webhookenviar = ""
local webhookdropar = ""

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIÁVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local actived = {}
local bandagem = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOCHILA
-----------------------------------------------------------------------------------------------------------------------------------------
function vRPN.Mochila()
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local inventario = {}
		local inv = vRP.getInventory(user_id)
		for k,v in pairs(inv) do
			if vRP.itemBodyList(k) then

			table.insert(inventario,{ amount = parseInt(v.amount), name = vRP.itemNameList(k), index = vRP.itemIndexList(k), key = k, type = vRP.itemTypeList(k), peso = vRP.getItemWeight(k), desc = vRP.itemDescList(k) })

			end
		end
		return inventario,vRP.getInventoryWeight(user_id),vRP.getInventoryMaxWeight(user_id)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SENDITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRPN.sendItem(itemName,amount)
	local source = source
	if itemName then
		local user_id = vRP.getUserId(source)
		local nplayer = vRPclient.getNearestPlayer(source,2)
		local nuser_id = vRP.getUserId(nplayer)
		local identity = vRP.getUserIdentity(user_id)
		local identitynu = vRP.getUserIdentity(nuser_id)
		if nuser_id and vRP.itemIndexList(itemName) and itemName ~= "identidade" then
			if parseInt(amount) > 0 then
				if vRP.getInventoryWeight(nuser_id) + vRP.getItemWeight(itemName) * amount <= vRP.getInventoryMaxWeight(nuser_id) then
					if vRP.tryGetInventoryItem(user_id,itemName,amount) then
						vRP.giveInventoryItem(nuser_id,itemName,amount)
						vRPclient._playAnim(source,true,{{"mp_common","givetake1_a"}},false)
						--TriggerClientEvent("Notify",source,"enviar","Você enviou <b>"..vRP.format(parseInt(amount)).."x</b> de <b>"..vRP.itemNameList(itemName).."</b>")

						SendWebhookMessage(webhookenviar,"```ini\n[ID]: "..user_id.." "..identity.name.." - "..identity.firstname.." \n[ENVIOU]: "..vRP.format(amount).." "..vRP.itemNameList(itemName).." \n[PARA]: ( "..nuser_id.." ) "..identitynu.name.." "..identitynu.firstname.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
						
						--TriggerClientEvent("Notify",source,"receber","Você recebeu <b>"..vRP.format(parseInt(amount)).."x</b> de <b>"..vRP.itemNameList(itemName).."</b>")
						vRPclient._playAnim(nplayer,true,{{"mp_common","givetake1_a"}},false)
						TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
						TriggerClientEvent('vrp_inventory:Update',nplayer,'updateMochila')
						return true
					end
				end
			else
				local inv = vRP.getInventory(user_id)
				for k,v in pairs(inv) do
					if itemName == k then
						if vRP.getInventoryWeight(nuser_id) + vRP.getItemWeight(itemName) * parseInt(v.amount) <= vRP.getInventoryMaxWeight(nuser_id) then
							if vRP.tryGetInventoryItem(user_id,itemName,parseInt(v.amount)) then
								vRP.giveInventoryItem(nuser_id,itemName,parseInt(v.amount))
								vRPclient._playAnim(source,true,{{"mp_common","givetake1_a"}},false)
								--TriggerClientEvent("Notify",source,"enviar","Você enviou <b>"..vRP.format(parseInt(amount)).."x</b> de <b>"..vRP.itemNameList(itemName).."</b>")

								SendWebhookMessage(webhookenviar,"```ini\n[ID]: "..user_id.." "..identity.name.." - "..identity.firstname.." \n[ENVIOU]: "..vRP.format(parseInt(v.amount)).." "..vRP.itemNameList(itemName).." \n[PARA]: ( "..nuser_id.." ) "..identitynu.name.." "..identitynu.firstname.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

								--TriggerClientEvent("Notify",source,"receber","Você recebeu <b>"..vRP.format(parseInt(amount)).."x</b> de <b>"..vRP.itemNameList(itemName).."</b>")
								vRPclient._playAnim(nplayer,true,{{"mp_common","givetake1_a"}},false)
								TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
								TriggerClientEvent('vrp_inventory:Update',nplayer,'updateMochila')
								return true
							end
						end
					end
				end
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPITEM
-----------------------------------------------------------------------------------------------------------------------------------------
function vRPN.dropItem(itemName,amount)
	local source = source
	if itemName then
		local user_id = vRP.getUserId(source)
		local identity = vRP.getUserIdentity(user_id)
		local x,y,z = vRPclient.getPosition(source)
		if parseInt(amount) > 0 and vRP.tryGetInventoryItem(user_id,itemName,amount) then
			TriggerEvent("DropSystem:create",itemName,amount,x,y,z,3600)
			vRPclient._playAnim(source,true,{{"pickup_object","pickup_low"}},false)

			SendWebhookMessage(webhookdropar,"```ini\n[ID]: "..user_id.." - "..identity.name.." "..identity.firstname.." \n[DROPOU]: "..vRP.itemNameList(itemName).." \n[QUANTIDADE]: "..vRP.format(parseInt(amount)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

			TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
			--TriggerClientEvent("Notify",source,"enviar","Você enviou <b>"..vRP.format(parseInt(amount)).."x</b> de <b>"..vRP.itemNameList(itemName).."</b>")
			return true
		else
			local data = vRP.getUserDataTable(user_id)
			for k,v in pairs(data.inventory) do
				if itemName == k then
					if vRP.tryGetInventoryItem(user_id,itemName,parseInt(v.amount)) then
						TriggerEvent("DropSystem:create",itemName,parseInt(v.amount),x,y,z,3600)
						vRPclient._playAnim(source,true,{{"pickup_object","pickup_low"}},false)

						SendWebhookMessage(webhookdropar,"```ini\n[ID]: "..user_id.." - "..identity.name.." "..identity.firstname.." \n[DROPOU]: "..vRP.itemNameList(itemName).." \n[QUANTIDADE]: "..vRP.format(parseInt(amount)).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

						TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
						--TriggerClientEvent("Notify",source,"enviar","Você enviou <b>"..vRP.format(parseInt(amount)).."x</b> de <b>"..vRP.itemNameList(itemName).."</b>")
						return true
					end
				end
			end
		end
	end
	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANDAGEM
-----------------------------------------------------------------------------------------------------------------------------------------
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5000)
		for k,v in pairs(bandagem) do
			if v > 0 then
				bandagem[k] = v - 5
				if v == 0 then
					bandagem[k] = nil
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- USEITEM
-----------------------------------------------------------------------------------------------------------------------------------------
local pick = {}
local blips = {}
function vRPN.useItem(itemName,type,ramount)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id and ramount ~= nil and parseInt(ramount) >= 0 and not actived[user_id] and actived[user_id] == nil then
		if type == "usar" then
			if itemName == "bandagem" then
				vida = vRPclient.getHealth(source)
				if vida > 101 and vida < 400 then
					if bandagem[user_id] == 0 or not bandagem[user_id] then
						if vRP.tryGetInventoryItem(user_id,"bandagem",1) then
							actived[user_id] = true
							vRPclient._CarregarObjeto(source,"amb@world_human_clipboard@male@idle_a","idle_c","v_ret_ta_firstaid",49,60309)
							TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
							TriggerClientEvent('cancelando',source,true)
							TriggerClientEvent("progress",source,60000,"bandagem")
							SetTimeout(60000,function()
								actived[user_id] = nil
								bandagem[user_id] = 60
								TriggerClientEvent('bandagem',source)
								TriggerClientEvent('cancelando',source,false)
								vRPclient._DeletarObjeto(source)
								--TriggerClientEvent("Notify",source,"sucesso","Bandagem utilizada com sucesso.",8000)
							end)
						end
					else
						TriggerClientEvent("Notify",source,"importante","Você precisa aguardar <b>"..bandagem[user_id].." segundos</b> para utilizar outra Bandagem.",8000)
					end
				else
					TriggerClientEvent("Notify",source,"negado","Você não pode utilizar de vida cheia ou nocauteado.",8000)
				end
			elseif itemName == "mochila" then
				if vRP.tryGetInventoryItem(user_id,"mochila",1) then
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					vRP.varyExp(user_id,"physical","strength",650)
					--TriggerClientEvent("Notify",source,"sucesso","Mochila utilizada com sucesso.",8000)
				end
			elseif itemName == "cerveja" then
				if vRP.tryGetInventoryItem(user_id,"cerveja",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					TriggerClientEvent('cancelando',source,true)
					vRPclient._CarregarObjeto(source,"amb@world_human_drinking@beer@male@idle_a","idle_a","prop_amb_beer_bottle",49,28422)
					TriggerClientEvent("progress",source,30000,"bebendo")
					SetTimeout(30000,function()
						actived[user_id] = nil
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						TriggerClientEvent('cancelando',source,false)
						vRPclient._DeletarObjeto(source)
						--TriggerClientEvent("Notify",source,"sucesso","Cerveja utilizada com sucesso.",8000)
					end)
				end
			elseif itemName == "tequila" then
				if vRP.tryGetInventoryItem(user_id,"tequila",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					TriggerClientEvent('cancelando',source,true)
					vRPclient._CarregarObjeto(source,"amb@world_human_drinking@beer@male@idle_a","idle_a","prop_amb_beer_bottle",49,28422)
					TriggerClientEvent("progress",source,30000,"bebendo")
					SetTimeout(30000,function()
						actived[user_id] = nil
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						TriggerClientEvent('cancelando',source,false)
						vRPclient._DeletarObjeto(source)
						--TriggerClientEvent("Notify",source,"sucesso","Tequila utilizada com sucesso.",8000)
					end)
				end
			elseif itemName == "vodka" then
				if vRP.tryGetInventoryItem(user_id,"vodka",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					TriggerClientEvent('cancelando',source,true)
					vRPclient._CarregarObjeto(source,"amb@world_human_drinking@beer@male@idle_a","idle_a","prop_amb_beer_bottle",49,28422)
					TriggerClientEvent("progress",source,30000,"bebendo")
					SetTimeout(30000,function()
						actived[user_id] = nil
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						TriggerClientEvent('cancelando',source,false)
						vRPclient._DeletarObjeto(source)
						--TriggerClientEvent("Notify",source,"sucesso","Vodka utilizada com sucesso.",8000)
					end)
				end
			elseif itemName == "whisky" then
				if vRP.tryGetInventoryItem(user_id,"whisky",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					TriggerClientEvent('cancelando',source,true)
					vRPclient._CarregarObjeto(source,"amb@world_human_drinking@beer@male@idle_a","idle_a","p_whiskey_notop",49,28422)
					TriggerClientEvent("progress",source,30000,"bebendo")
					SetTimeout(30000,function()
						actived[user_id] = nil
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						TriggerClientEvent('cancelando',source,false)
						vRPclient._DeletarObjeto(source)
						--TriggerClientEvent("Notify",source,"sucesso","Whisky utilizado com sucesso.",8000)
					end)
				end
			elseif itemName == "conhaque" then
				if vRP.tryGetInventoryItem(user_id,"conhaque",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					TriggerClientEvent('cancelando',source,true)
					vRPclient._CarregarObjeto(source,"amb@world_human_drinking@beer@male@idle_a","idle_a","prop_amb_beer_bottle",49,28422)
					TriggerClientEvent("progress",source,30000,"bebendo")
					SetTimeout(30000,function()
						actived[user_id] = nil
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						TriggerClientEvent('cancelando',source,false)
						vRPclient._DeletarObjeto(source)
						--TriggerClientEvent("Notify",source,"sucesso","Conhaque utilizado com sucesso.",8000)
					end)
				end
			elseif itemName == "agua" then
				if vRP.tryGetInventoryItem(user_id,"agua",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					TriggerClientEvent('cancelando',source,true)
					vRPclient._CarregarObjeto(source,"amb@world_human_drinking@beer@male@idle_a","idle_a","prop_amb_beer_bottle",49,28422)
					TriggerClientEvent("progress",source,30000,"bebendo")
					SetTimeout(30000,function()
						actived[user_id] = nil
						--vRPclient.playScreenEffect(source,"RaceTurbo",180)
						--vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						--vthirst = 20
						--vRP.varyThirst(user_id,vthirst)
						TriggerClientEvent('cancelando',source,false)
						vRPclient._DeletarObjeto(source)
						--TriggerClientEvent("Notify",source,"sucesso","Agua utilizado com sucesso.",8000)
					end)
				end
			elseif itemName == "absinto" then
				if vRP.tryGetInventoryItem(user_id,"absinto",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					TriggerClientEvent('cancelando',source,true)
					vRPclient._CarregarObjeto(source,"amb@world_human_drinking@beer@male@idle_a","idle_a","prop_amb_beer_bottle",49,28422)
					TriggerClientEvent("progress",source,30000,"bebendo")
					SetTimeout(30000,function()
						actived[user_id] = nil
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						TriggerClientEvent('cancelando',source,false)
						vRPclient._DeletarObjeto(source)
						--TriggerClientEvent("Notify",source,"sucesso","Absinto utilizado com sucesso.",8000)
					end)
				end
			elseif itemName == "identidade" then
				local nplayer = vRPclient.getNearestPlayer(source,2)
				if nplayer then
					local identity = vRP.getUserIdentity(user_id)
					if identity then
						TriggerClientEvent("Identity2",nplayer,identity.name,identity.firstname,identity.user_id,identity.registration)
					end
				end
			elseif itemName == "maconha" then
				if vRP.tryGetInventoryItem(user_id,"maconha",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					vRPclient._playAnim(source,true,{{"mp_player_int_uppersmoke","mp_player_int_smoke"}},true)
					TriggerClientEvent("progress",source,10000,"fumando")
					SetTimeout(10000,function()
						actived[user_id] = nil
						vRPclient._stopAnim(source,false)
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
					--	TriggerClientEvent("Notify",source,"sucesso","Maconha utilizada com sucesso.",8000)
						TriggerClientEvent("vrp_sound:source",source,'love',0.5)
					end)
				end
			elseif itemName == "cocaina" then
				if vRP.tryGetInventoryItem(user_id,"cocaina",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					vRPclient._playAnim(source,true,{{"mp_player_int_uppersmoke","mp_player_int_smoke"}},true)
					TriggerClientEvent('cancelando',source,true)
					TriggerClientEvent("progress",source,10000,"cheirando")
					SetTimeout(10000,function()
						actived[user_id] = nil
						vRPclient._stopAnim(source,false)
						TriggerClientEvent('cancelando',source,false)
						vRPclient.playScreenEffect(source,"RaceTurbo",120)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",120)
						--TriggerClientEvent("Notify",source,"sucesso","Cocaína utilizada com sucesso.",8000)
					end)
				end
			elseif itemName == "metanfetamina" then
				if vRP.tryGetInventoryItem(user_id,"metanfetamina",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					vRPclient._playAnim(source,true,{{"mp_player_int_uppersmoke","mp_player_int_smoke"}},true)
					TriggerClientEvent("progress",source,10000,"fumando")
					SetTimeout(10000,function()
						actived[user_id] = nil
						vRPclient._stopAnim(source,false)
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						--TriggerClientEvent("Notify",source,"sucesso","Metanfetamina utilizada com sucesso.",8000)
					end)
				end	
			elseif itemName == "lsd" then
				if vRP.tryGetInventoryItem(user_id,"lsd",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					vRPclient._playAnim(source,true,{{"mp_player_int_uppersmoke","mp_player_int_smoke"}},true)
					TriggerClientEvent("progress",source,10000,"tomando")
					SetTimeout(10000,function()
						actived[user_id] = nil
						vRPclient._stopAnim(source,false)
						vRPclient.playScreenEffect(source,"RaceTurbo",180)
						vRPclient.playScreenEffect(source,"DrugsTrevorClownsFight",180)
						--TriggerClientEvent("Notify",source,"sucesso","LSD utilizado com sucesso.",8000)
					end)
				end
			elseif itemName == "capuz" then
				if vRP.getInventoryItemAmount(user_id,"capuz") >= 1 then
					local nplayer = vRPclient.getNearestPlayer(source,2)
					if nplayer then
						vRPclient.setCapuz(nplayer)
						vRP.closeMenu(nplayer)
						--TriggerClientEvent("Notify",source,"sucesso","Capuz utilizado com sucesso.",8000)
					end
				end
			elseif itemName == "energetico" then
				if vRP.tryGetInventoryItem(user_id,"energetico",1) then
					actived[user_id] = true
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					TriggerClientEvent('cancelando',source,true)
					vRPclient._CarregarObjeto(source,"amb@world_human_drinking@beer@male@idle_a","idle_a","prop_energy_drink",49,28422)
					TriggerClientEvent("progress",source,20000,"bebendo")
					SetTimeout(20000,function()
						actived[user_id] = nil
						TriggerClientEvent('energeticos',source,true)
						TriggerClientEvent('cancelando',source,false)
						vRPclient._DeletarObjeto(source)
						--TriggerClientEvent("Notify",source,"sucesso","Energético utilizado com sucesso.",8000)
					end)
					SetTimeout(60000,function()
						TriggerClientEvent('energeticos',source,false)
						TriggerClientEvent("Notify",source,"importante","O efeito do energético passou e o coração voltou a bater normalmente.",8000)
					end)
				end
			elseif itemName == "lockpick" then
				local vehicle,vnetid,placa,vname,lock,banned,trunk,model,street = vRPclient.vehList(source,7)
				local policia = vRP.getUsersByPermission("policia.perm")
				if #policia < 0 then
					--TriggerClientEvent("Notify",source,"negado","Número insuficiente de policiais no momento para iniciar o roubo.")
					return true
				end
				if vRP.hasPermission(user_id,"policia.perm") then
					TriggerEvent("setPlateEveryone",placa)
					vGARAGE.vehicleClientLock(-1,vnetid,lock)
					TriggerClientEvent("vrp_sound:source",source,'lock',0.5)
					return
				end
				if vRP.getInventoryItemAmount(user_id,"lockpick") >= 1 and vRP.tryGetInventoryItem(user_id,"lockpick",1) and vehicle then
					actived[user_id] = true
					if vRP.hasPermission(user_id,"polpar.perm") then
						actived[user_id] = nil
						TriggerEvent("setPlateEveryone",placa)
						vGARAGE.vehicleClientLock(-1,vnetid,lock)
						return
					end

					TriggerClientEvent('cancelando',source,true)
					vRPclient._playAnim(source,false,{{"amb@prop_human_parking_meter@female@idle_a","idle_a_female"}},true)
					TriggerClientEvent("progress",source,30000,"roubando")
					SetTimeout(30000,function()
						actived[user_id] = nil
						TriggerClientEvent('cancelando',source,false)
						vRPclient._stopAnim(source,false)

						if math.random(100) >= 50 then
							TriggerEvent("setPlateEveryone",placa)
							vGARAGE.vehicleClientLock(-1,vnetid,lock)
							TriggerClientEvent("vrp_sound:source",source,'lock',0.5)
						else
							--TriggerClientEvent("Notify",source,"negado","Roubo do veículo falhou e as autoridades foram acionadas.",8000)
							local policia = vRP.getUsersByPermission("policia.perm")
							local x,y,z = vRPclient.getPosition(source)
							for k,v in pairs(policia) do
								local player = vRP.getUserSource(parseInt(v))
								if player then
									async(function()
										local id = idgens:gen()
										vRPclient._playSound(player,"CONFIRM_BEEP","HUD_MINI_GAME_SOUNDSET")
										TriggerClientEvent('Notify',player,"policia","Roubo na "..street.." do veículo "..model.." de placa "..placa.." verifique o ocorrido.")
										pick[id] = vRPclient.addBlip(player,x,y,z,10,5,"Ocorrência",0.5,false)
										SetTimeout(20000,function() vRPclient.removeBlip(player,pick[id]) idgens:free(id) end)
									end)
								end
							end
						end
					end)
				end
			elseif itemName == "masterpick" then
				local vehicle,vnetid,placa,vname,lock,banned,trunk,model,street = vRPclient.vehList(source,7)
				local policia = vRP.getUsersByPermission("policia.perm")
				if #policia < 5 then
					TriggerClientEvent("Notify",source,"negado","Número insuficiente de policiais no momento para iniciar o roubo.")
					return true
				end
				if vRP.hasPermission(user_id,"policia.perm") then
					TriggerEvent("setPlateEveryone",placa)
					vGARAGE.vehicleClientLock(-1,vnetid,lock)
					TriggerClientEvent("vrp_sound:source",source,'lock',0.5)
					return
				end
				if vRP.getInventoryItemAmount(user_id,"masterpick") >= 1 and vRP.tryGetInventoryItem(user_id,"masterpick",1) and vehicle then
					actived[user_id] = true
					if vRP.hasPermission(user_id,"polpar.perm") then
						actived[user_id] = nil
						TriggerEvent("setPlateEveryone",placa)
						vGARAGE.vehicleClientLock(-1,vnetid,lock)
						return
					end

					TriggerClientEvent('cancelando',source,true)
					vRPclient._playAnim(source,false,{{"amb@prop_human_parking_meter@female@idle_a","idle_a_female"}},true)
					TriggerClientEvent("progress",source,60000,"roubando")
					SetTimeout(60000,function()
						actived[user_id] = nil
						TriggerClientEvent('cancelando',source,false)
						vRPclient._stopAnim(source,false)
						TriggerEvent("setPlateEveryone",placa)
						vGARAGE.vehicleClientLock(-1,vnetid,lock)
						TriggerClientEvent("vrp_sound:source",source,'lock',0.5)
						TriggerClientEvent("Notify",source,"importante","Roubo do veículo concluído e as autoridades foram acionadas.",8000)
						local policia = vRP.getUsersByPermission("policia.perm")
						local x,y,z = vRPclient.getPosition(source)
						for k,v in pairs(policia) do
							local player = vRP.getUserSource(parseInt(v))
							if player then
								async(function()
									local id = idgens:gen()
									vRPclient._playSound(player,"CONFIRM_BEEP","HUD_MINI_GAME_SOUNDSET")
									TriggerClientEvent('Notify',player,"policia","Roubo na "..street.." do veículo "..model.." de placa "..placa.." verifique o ocorrido.")
									pick[id] = vRPclient.addBlip(player,x,y,z,10,5,"Ocorrência",0.5,false)
									SetTimeout(20000,function() vRPclient.removeBlip(player,pick[id]) idgens:free(id) end)
								end)
							end
						end
					end)
				end
			elseif itemName == "militec" then
				if not vRPclient.isInVehicle(source) then
					local vehicle = vRPclient.getNearestVehicle(source,3.5)
					if vehicle then
						if vRP.hasPermission(user_id,"mecanico.perm") then
							actived[user_id] = true
							TriggerClientEvent('cancelando',source,true)
							vRPclient._playAnim(source,false,{{"mini@repair","fixing_a_player"}},true)
							TriggerClientEvent("progress",source,30000,"reparando motor")
							SetTimeout(30000,function()
								actived[user_id] = nil
								TriggerClientEvent('cancelando',source,false)
								TriggerClientEvent('repararmotor',source,vehicle)
								vRPclient._stopAnim(source,false)
							end)
						else
							if vRP.tryGetInventoryItem(user_id,"militec",1) then
								actived[user_id] = true
								TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
								TriggerClientEvent('cancelando',source,true)
								vRPclient._playAnim(source,false,{{"mini@repair","fixing_a_player"}},true)
								TriggerClientEvent("progress",source,30000,"reparando motor")
								SetTimeout(30000,function()
									actived[user_id] = nil
									TriggerClientEvent('cancelando',source,false)
									TriggerClientEvent('repararmotor',source,vehicle)
									vRPclient._stopAnim(source,false)
								end)
							end
						end
					end
				end	
			elseif itemName == "repairkit" then
				if not vRPclient.isInVehicle(source) then
					local vehicle = vRPclient.getNearestVehicle(source,3.5)
					if vehicle then
						if vRP.hasPermission(user_id,"mecanico.perm") then
							actived[user_id] = true
							TriggerClientEvent('cancelando',source,true)
							vRPclient._playAnim(source,false,{{"mini@repair","fixing_a_player"}},true)
							TriggerClientEvent("progress",source,30000,"reparando veículo")
							SetTimeout(30000,function()
								actived[user_id] = nil
								TriggerClientEvent('cancelando',source,false)
								TriggerClientEvent('reparar',source)
								vRPclient._stopAnim(source,false)
							end)
						else
							if vRP.tryGetInventoryItem(user_id,"repairkit",1) then
								actived[user_id] = true
								TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
								TriggerClientEvent('cancelando',source,true)
								vRPclient._playAnim(source,false,{{"mini@repair","fixing_a_player"}},true)
								TriggerClientEvent("progress",source,30000,"reparando veículo")
								SetTimeout(30000,function()
									actived[user_id] = nil
									TriggerClientEvent('cancelando',source,false)
									TriggerClientEvent('reparar',source)
									vRPclient._stopAnim(source,false)
								end)
							end
						end
					end
				end
			elseif itemName == "notebook" then
				if vRPclient.isInVehicle(source) then
					local vehicle,vnetid,placa,vname,lock,banned = vRPclient.vehList(source,7)
					if vehicle and placa then
						actived[user_id] = true
						vGARAGE.freezeVehicleNotebook(source,vehicle)
						TriggerClientEvent('cancelando',source,true)
						TriggerClientEvent("progress",source,59500,"removendo rastreador")
						SetTimeout(60000,function()
							actived[user_id] = nil
							TriggerClientEvent('cancelando',source,false)
							local placa_user_id = vRP.getUserByRegistration(placa)
							if placa_user_id then
								local player = vRP.getUserSource(placa_user_id)
								if player then
									vGARAGE.removeGpsVehicle(player,vname)
								end
							end
						end)
					end
				end
			elseif itemName == "placa" then
				if vRPclient.isInVehicle(source) then
					if vRP.tryGetInventoryItem(user_id,"placa",1) then
						TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
						TriggerClientEvent('cancelando',source,true)
						TriggerClientEvent("progress",source,60000,"clonando")
						SetTimeout(60000,function()
							TriggerClientEvent('cancelando',source,false)
							TriggerClientEvent("cloneplates",source)
							--TriggerClientEvent("Notify",source,"sucesso","Placa clonada com sucesso.",8000)
						end)
					end
				end
			elseif itemName == "colete" then
				if vRP.tryGetInventoryItem(user_id,"colete",1) then
					vRPclient.setArmour(source,100)
					vRPclient._playAnim(source,true,{{"clothingshirt","try_shirt_positive_d"}},false)
					SetTimeout(3000,function()
						vRPclient._stopAnim(source,false)
						TriggerClientEvent('cancelando',source,false)
					end)
					TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
					--TriggerClientEvent("Notify",source,"sucesso","Colete equipado com sucesso.",8000)
				end	
			elseif itemName == "morfina" then -- vrp_inventory:Update
				local paramedico = vRP.getUsersByPermission("paramedico.permissao")
				if parseInt(#paramedico) < 1 then
					local nplayer = vRPclient.getNearestPlayer(source,2)
					if nplayer then
						if vRPclient.isComa(nplayer) then
							if vRP.tryGetInventoryItem(user_id,"morfina",1) then
								TriggerClientEvent('cancelando',source,true)
								vRPclient._playAnim(source,false,{{"amb@medic@standing@tendtodead@base","base"},{"mini@cpr@char_a@cpr_str","cpr_pumpchest"}},true)
								TriggerClientEvent("progress",source,30000,"reanimando")
								SetTimeout(30000,function()
									vRPclient.networkRessurection(nplayer)
									vRPclient._stopAnim(source,false)
									TriggerClientEvent('cancelando',source,false)
								end)
							end
						else
							TriggerClientEvent("Notify",source,"importante","A pessoa precisa estar em coma para prosseguir.",8000)
						end
					end
				end
			elseif itemName == "pneu" then
				local sourece = source
				if not vRPclient.inVehicle(source) then
					local vehicle,vehNet = vRPclient.vehList(source,5)
					if vehicle then
						if vRP.tryGetInventoryItem(user_id,"pneu",1) then
							vRPclient._playAnim(source,false,{{"mini@repair","fixing_a_player"}},true)
							TriggerClientEvent("progress",source,20000,"Arrumando Pneu")
							SetTimeout(20000,function()					
								TriggerClientEvent('rkg:repararPneu',-1,vehNet)
								vRPclient._stopAnim(source,false)
							end)
							Citizen.Wait(0)
						end			
					end
				end
			end
-----------------------------------------------------------------------------------------------------------------------------------------
-- EQUIPAR
-----------------------------------------------------------------------------------------------------------------------------------------
		elseif type == "equipar" then
			if vRP.tryGetInventoryItem(user_id,itemName,1) then
				local weapons = {}
				local identity = vRP.getUserIdentity(user_id)
				weapons[string.gsub(itemName,"wbody|","")] = { ammo = 0 }
				vRPclient._giveWeapons(source,weapons)

				SendWebhookMessage(webhookequipar,"```ini\n[ID]: "..user_id.." - "..identity.name.." "..identity.firstname.." \n[EQUIPOU]: "..vRP.itemNameList(itemName).." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

				TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
			end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RECARREGAR
-----------------------------------------------------------------------------------------------------------------------------------------
		elseif type == "recarregar" then
			local uweapons = vRPclient.getWeapons(source)
			local weaponuse = string.gsub(itemName,"wammo|","")
			local weaponusename = "wammo|"..weaponuse
			local identity = vRP.getUserIdentity(user_id)
			if uweapons[weaponuse] then
				local itemAmount = 0
				local data = vRP.getUserDataTable(user_id)
				for k,v in pairs(data.inventory) do
					if weaponusename == k then
						if v.amount > 250 then
							v.amount = 250
						end

						itemAmount = v.amount

						if vRP.tryGetInventoryItem(user_id, weaponusename, parseInt(v.amount)) then
							local weapons = {}
							weapons[weaponuse] = { ammo = v.amount }
							itemAmount = v.amount
							vRPclient._giveWeapons(source,weapons,false)
							
							local quantidaItem = vRP.format(parseInt(amount))
							SendWebhookMessage(webhookequipar,"```prolog\n[ID]"..user_id.."\n[EQUIPOU]: Munição")
							
							TriggerClientEvent('vrp_inventory:Update',source,'updateMochila')
						end
					end
				end
			end
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYERLEAVE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("vRP:playerLeave",function(user_id,source)
	actived[parseInt(user_id)] = nil
end)