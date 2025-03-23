ESX = exports["es_extended"]:getSharedObject()
local isShopOpen = false
local playerPed = PlayerPedId()
local nearbyShop = nil
local lastCheckTime = 0
local helpNotificationShown = false
local lastDistance = math.huge

local function CreateShopPed(shop)
    local pedModel = GetHashKey(shop.pedModel)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Citizen.Wait(100)
    end

    local ped = CreatePed(4, pedModel, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.pedHeading, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(blip, shop.blipSprite)
    SetBlipColour(blip, shop.blipColor)
    SetBlipScale(blip, shop.blipScale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(shop.name)
    EndTextCommandSetBlipName(blip)

    return ped
end

local function CheckNearbyShop()
    local playerCoords = GetEntityCoords(playerPed)
    for i, shop in ipairs(Config.Shops) do
        local distance = #(playerCoords - vector3(shop.coords.x, shop.coords.y, shop.coords.z))
        if distance < 2.0 then
            return i, distance
        end
    end
    return nil, nil
end

Citizen.CreateThread(function()
    local peds = {}
    for _, shop in ipairs(Config.Shops) do
        table.insert(peds, CreateShopPed(shop))
    end

    while true do
        Citizen.Wait(0)  -- Très court pour maintenir la réactivité

        local currentShop, currentDistance = CheckNearbyShop()
        
        if currentShop then
            -- Plus près on réduit l'attente pour une réponse rapide
            if currentDistance < 10.0 then
                Citizen.Wait(5)
            else
                -- Si trop loin, augmenter l'attente pour optimiser la performance
                Citizen.Wait(5)
            end
        else
            -- Si pas proche, attendre plus longtemps pour économiser des ressources
            Citizen.Wait(1000)
        end

        if currentShop and not isShopOpen and not helpNotificationShown then
            ESX.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ pour ouvrir la supérette")
            helpNotificationShown = true
        elseif not currentShop and helpNotificationShown then
            helpNotificationShown = false
        end

        if currentShop and not isShopOpen then
            if IsControlJustPressed(0, 38) then
                SetNuiFocus(true, true)
                SendNUIMessage({
                    type = 'openShop',
                    items = Config.Items,
                    serverLogo = Config.ServerLogo
                })
                isShopOpen = true
            end
        elseif isShopOpen and IsControlJustPressed(0, 322) then
            SetNuiFocus(false, false)
            SendNUIMessage({ type = 'closeShop' })
            isShopOpen = false
        end
    end
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    isShopOpen = false
    cb('ok')
end)

RegisterNUICallback('pay', function(data, cb)
    TriggerServerEvent('napiox:processPayment', data.method, data.total, data.items)
    cb('ok')
end)
