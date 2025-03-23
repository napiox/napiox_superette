ESX = exports['es_extended']:getSharedObject()

RegisterServerEvent('napiox:processPayment')
AddEventHandler('napiox:processPayment', function(method, total, items)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local success = false

    if method == 'Liquide' then
        if xPlayer.getMoney() >= total then
            xPlayer.removeMoney(total)
            success = true
        end
    elseif method == 'Carte bancaire' then
        if xPlayer.getAccount('bank').money >= total then
            xPlayer.removeAccountMoney('bank', total)
            success = true
        end
    end

    if success then
        for _, item in ipairs(items) do
            xPlayer.addInventoryItem(item.itemName, item.quantity)
        end
        TriggerClientEvent('esx:showNotification', source, 'Achat effectué avec succès !')
    else
        TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas assez d\'argent.')
    end
end)