ESX = nil

local appInfo = {
    identifier = "billing_app",
    name = "Faktura",
    description = "Dine faktura/bøder"
}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while GetResourceState("lb-phone") ~= "started" do
        Wait(500)
    end

    local added, errorMessage = exports["lb-phone"]:AddCustomApp({
        identifier = appInfo.identifier,
        name = appInfo.name,
        description = appInfo.description,
        defaultApp = true,
        ui = GetCurrentResourceName() .. "/web/build/index.html",
        icon = "https://cfx-nui-" .. GetCurrentResourceName() .. "/web/build/icon.png",
    })

    if not added then
        print("Could not add app:", errorMessage)
    end
end)

RegisterNUICallback("setupApp", function(data, cb)
    cb(lib.callback.await('st_billing_app:GetBills', false))
end)

RegisterNUICallback("payBill", function(data, cb)
	local bill_id = data.id

	ESX.TriggerServerCallback('esx_billing:payBill', function(playerBills)
		Citizen.Wait(500)
		exports["lb-phone"]:SendCustomAppMessage(appInfo.identifier, {
			action = "refreshBillings",
			billings = playerBills
		})
	end, bill_id)

    cb('ok')
end)

RegisterNetEvent("esx_billing:addBill", function()
    local playerBills = lib.callback.await('st_billing_app:GetBills', false)
    exports["lb-phone"]:SendCustomAppMessage(appInfo.identifier, {
        action = "refreshBillings",
        billings = playerBills
    })
end)
