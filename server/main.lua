local cached_players = {}

RegisterServerEvent('esx_billing:sendBill')
AddEventHandler('esx_billing:sendBill', function(playerId, sharedAccountName, label, amount, note)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local xTarget = ESX.GetPlayerFromId(playerId)
	if note == nil then note = "" end

	if amount < 0 then
		print('esx_billing: ' .. GetPlayerName(_source) .. ' tried sending a negative bill!')
		return
	end

	if xTarget == nil then
		print('esx_billing: ' .. playerId .. ' is offline!')
		return
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', sharedAccountName, function(account)
		if account == nil then
			print('esx_billing: ' .. sharedAccountName .. ' is an invalid account!')
			return
		end

		MySQL.query('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)', {
			['@identifier']  = xTarget.identifier,
			['@sender']      = xPlayer.identifier,
			['@target_type'] = 'society',
			['@target']      = sharedAccountName,
			['@label']       = label,
			['@amount']      = amount
		}, function(rowsChanged)
			local billingType = sharedAccountName == "society_police" and "bøde" or "faktura"
			exports["lb-phone"]:SendNotification(xTarget.source, {
				app = "billing_app",
				title = ("Modtaget %s"):format(billingType),
				content = ("Du har modtaget en %s på %s,- DKK"):format(billingType, amount),
			})
			
			if cached_players[xTarget.identifier] then
				local label = ""
				local jobName = sharedAccountName:gsub("society_", "")
				if ESX.GetJobs()[jobName] then
					local labelname = ESX.GetJobs()[jobName].label
					label = ("%s"):format(labelname)
				end

				local amountLabel = ("%s,- DKK"):format(GroupDigits(amount))

				table.insert(cached_players[xTarget.identifier], {
					id = rowsChanged.insertId,
					identifier = xTarget.identifier,
					sender = xPlayer.identifier,
					targetType = 'society',
					target = sharedAccountName,
					label = label,
					amount = amountLabel
				})
			end

			TriggerClientEvent("esx_billing:addBill", xTarget.source)
			TriggerEvent("esx_billing:addBill", rowsChanged.insertId, sharedAccountName, amount, xTarget, xPlayer)
		end)
	end)
end)

lib.callback.register('st_billing_app:GetBills', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	local billings = {}

	local esxJobs = ESX.GetJobs()
	local response = MySQL.query.await('SELECT * FROM `billing` WHERE `identifier` = ?', { xPlayer.identifier })
	if response then
		for i = 1, #response do
			local row = response[i]

			local label = ""
			local jobName = row.target:gsub("society_", "")
			if esxJobs[jobName] then
				local labelname = esxJobs[jobName].label
				label = ("%s"):format(labelname)
			end

			local amountLabel = ("%s,- DKK"):format(GroupDigits(row.amount))

			table.insert(billings, {
				id = row.id,
				identifier = row.identifier,
				sender = row.sender,
				targetType = row.target_type,
				target = row.target,
				label = label,
				amount = amountLabel
			})
		end
	end

	cached_players[xPlayer.identifier] = deepcopy(billings)

    return billings
end)

ESX.RegisterServerCallback('esx_billing:getBills', function(source, cb, reOpen)
	local xPlayer = ESX.GetPlayerFromId(source)
	local time = os.nanotime()

	if reOpen then
		Debug(("Sended %s bills to %s - In %s ms"):format(#cached_players[xPlayer.identifier], xPlayer.identifier, (os.nanotime() - time) / 1000000))
		cb(cached_players[xPlayer.identifier])
	end

	if not reOpen then
		MySQL.query('SELECT * FROM billing WHERE identifier = @identifier', {
			["@identifier"] = xPlayer.identifier
		}, function(result)
			local bills = {}

			if result[1] then
				for i=1, #result, 1 do
					table.insert(bills, {
						id         = result[i].id,
						identifier = result[i].identifier,
						sender     = result[i].sender,
						targetType = result[i].target_type,
						target     = result[i].target,
						label      = result[i].label,
						amount     = result[i].amount
					})
				end
			end

			cached_players[xPlayer.identifier] = deepcopy(bills)
			Debug(("Send %s bills to %s - In %s ms"):format(#cached_players[xPlayer.identifier], xPlayer.identifier, (os.nanotime() - time) / 1000000))

			cb(bills)
		end)
	end
end)

ESX.RegisterServerCallback('esx_billing:getTargetBills', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	MySQL.query('SELECT * FROM billing WHERE identifier = @identifier', {
		["@identifier"] = xPlayer.identifier
	}, function(result)
		local bills = {}

		if result[1] then
			for i=1, #result, 1 do
				table.insert(bills, {
					id         = result[i].id,
					identifier = result[i].identifier,
					sender     = result[i].sender,
					targetType = result[i].target_type,
					target     = result[i].target,
					label      = result[i].label,
					amount     = result[i].amount
				})
			end
		end

		cb(bills)
	end)
end)

ESX.RegisterServerCallback('esx_billing:payBill', function(source, cb, id)
	local xPlayer = ESX.GetPlayerFromId(source)
	local time = os.nanotime()

	MySQL.query('SELECT * FROM billing WHERE id = @id', {
		['@id'] = id
	}, function(result)
		if not result[1] then
			return cb(cached_players[xPlayer.identifier])
		end

		local sender = result[1].sender
		local targetType = result[1].target_type
		local target = result[1].target
		local amount = result[1].amount
		local label = result[1].label

		local xTarget = ESX.GetPlayerFromIdentifier(sender)
		if targetType ~= 'player' then
			TriggerEvent('esx_addonaccount:getSharedAccount', target, function(account)
				if xPlayer.getAccount('bank').money >= amount then
					MySQL.query('DELETE from billing WHERE id = @id', {
						['@id'] = id
					}, function(rowsChanged)
						xPlayer.removeAccountMoney('bank', amount)
						account.addMoney(amount)

						if cached_players[xPlayer.identifier] ~= nil then
							local playerBills = cached_players[xPlayer.identifier]
							for k,v in pairs(playerBills) do
								if v.id == id then table.remove(cached_players[xPlayer.identifier], k) end
							end
						end

						local billingType = target == "society_police" and "bøde" or "faktura"
						exports["lb-phone"]:SendNotification(xPlayer.source, {
							app = "billing_app",
							title = "Betalt faktura",
							content = ("Du har betalt en %s på %s,- DKK"):format(billingType, GroupDigits(amount)),
						})

						if xTarget ~= nil then
							exports["lb-phone"]:SendNotification(xTarget.source, {
								app = "billing_app",
								title = "Betalt faktura",
								content = ("Du har fået betaling på en %s på %s,- DKK"):format(billingType, GroupDigits(amount)),
							})
						end

						TriggerEvent("esx_billing:paidBill", id, target, amount, xPlayer, sender)
						Debug(("%s paid %s,- DKK (%s) to %s - In %s ms"):format(xPlayer.identifier, GroupDigits(amount), id, account.name, (os.nanotime() - time) / 1000000))

						cb(cached_players[xPlayer.identifier])
					end)
				else
					TriggerClientEvent('esx:showNotification', xPlayer.source, "Du har ikke penge til dette.")
					cb(cached_players[xPlayer.identifier])
				end
			end)
		end
	end)
end)

payCity = function(amount)
	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_city', function(account)
		account.addMoney(amount)
	end)
end

AddEventHandler('playerDropped', function(reason)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	if xPlayer then
		if cached_players[xPlayer.identifier] ~= nil then
			cached_players[xPlayer.identifier] = nil
		end
	end
end)
