ESX = exports["es_extended"]:getSharedObject()
local RZWClientJobNotif = {}

function RZWClientJobNotif.SaveSinyal(data)
    TriggerServerEvent('rzw-jobnotif:savedata', data)
end
exports('SaveSinyal', RZWClientJobNotif.SaveSinyal)

-- Cara pemakaian exportnya adalah sebagai berikut:
-- Di script lain, Anda bisa memanggil fungsi SaveSinyal dengan menggunakan exports seperti ini:

-- exports['rzw-jobnotif']:SaveSinyal({Array})

-- Contoh:
-- exports['rzw-jobnotif']:SaveSinyal({
--     job = {
--         name = 'police',
--         label = 'Polisi'
--     },
--     deskripsi = 'Deskripsi Isi Disini',
--     icon = 'fa-solid fa-user',
--     target = PlayerId,
--     phone = "0123912312",
--     coords = vector3(0.0, 0.0, 0.0),
--     type = "sinyal", -- sinyal | pesan
-- })

RZWClientJobNotif.SetCoords = function (coords)
    SetNewWaypoint(coords.x, coords.y)
    lib.notify({
        title = 'Job Notif',
        description = 'Kordinat telah diatur ke lokasi korban.',
        type = 'success',
        showDuration = true,
        duration = 8000,
        position = 'top',
    })
end

RZWClientJobNotif.ActionNotif = function (data)
    local PlayerData = ESX.GetPlayerData()
    local ActionList  ={}
    table.insert(ActionList, {
        title = 'Kembali',
        icon = 'fa-solid fa-arrow-left',
        onSelect = function()
            RZWClientJobNotif.OpenNotif()
        end,
    })
    if data.type == 'pesan' then
        if not data.is_respon then
            table.insert(ActionList, {
                title = 'Respon Pesan',
                description = 'Respon Korban Ke Lokasi dan Set Lokasi Ke Korban',
                icon = 'fa-solid fa-reply',
                readOnly = data.is_respon,
                onSelect = function()
                    TriggerServerEvent('rzw-jobnotif:server:respon', data)
                end,
            })
        end
        table.insert(ActionList, {
            title = 'Isi Pesan',
            description = data.deskripsi,
            icon = 'fa-regular fa-message',
            readOnly = true,
        })
    elseif data.type == 'sinyal' then
        table.insert(ActionList, {
            title = 'Respon Korban',
            description = 'Respon Korban Ke Lokasi dan Set Lokasi Ke Korban',
            icon = 'fa-solid fa-reply',
            readOnly = data.is_respon,
            onSelect = function()
                TriggerServerEvent('rzw-jobnotif:server:respon', data)
            end,
        })
        table.insert(ActionList, {
            title = 'Set Coords',
            description = 'Set Kordinat Ke Korban',
            icon = 'fa-solid fa-location-crosshairs',
            readOnly = data.is_respon,
            onSelect = function()
                RZWClientJobNotif.SetCoords(json.decode(data.coords))
            end,
        })
    end
    table.insert(ActionList, {
        title = 'Copy Nomor HP '..(data.phone ~= nil and '' or ' ❌'),
        description = 'Nomor HP : '..(data.phone ~= nil and data.phone or 'Tidak Dikethui'),
        icon = 'fa-solid fa-phone',
        readOnly = (data.phone ~= nil and 0 or 1),
        onSelect = function()
            if data.phone ~= nil then
                lib.setClipboard(data.phone)
                lib.notify({
                    title = 'Phone Number',
                    description = 'Berhasil Disalin Ke Clipboard',
                    type = 'success',
                    showDuration = true,
                    duration = 6000,
                    position = 'top',
                })
            end
        end,
    })

    lib.registerContext({
        id = 'rzw_ActionNotif',
        title = data.nama,
        options = ActionList
    })
    lib.showContext('rzw_ActionNotif')
end

RZWClientJobNotif.OpenNotif = function ()
    local OptionsContext = {}
    local whitelisted = lib.callback.await('rzw-jobnotif:server:JobList', false, 'checked')
    if whitelisted then
        local getData, GetList = lib.callback.await('rzw-jobnotif:server:getList', false)
        for key, value in pairs(GetList) do
            table.insert(OptionsContext, {
                title = value.title,
                description = value.deskripsi,
                icon = RZWConfigJobNofit.JobData[whitelisted.name],
                readOnly = value.readOnly,
                onSelect = function()
                    RZWClientJobNotif.ActionNotif(value.data)
                end,
            })
        end
        if #OptionsContext <= 0 then
            lib.notify({
                title = 'Job Notif',
                description = 'Tidak ada data',
                type = 'error',
                showDuration = true,
                duration = 6000,
                position = 'top',
                icon = 'ban'
                -- icon = 'fa-solid fa-person-falling'
            })
            return
        end
        lib.registerContext({
            id = 'rzw_OpenNotif',
            title = 'Job Notif',
            options = OptionsContext
        })
        lib.showContext('rzw_OpenNotif')
    else
        local JobList = lib.callback.await('rzw-jobnotif:server:JobList', false, 'get')
        for key, value in pairs(JobList) do
            table.insert(OptionsContext, {
                title = value.label,
                description = "Kirim Pesan Ke Whitelist "..value.label,
                icon = RZWConfigJobNofit.JobData[value.name],
                onSelect = function()
                    local input = lib.inputDialog('Send Message To '..value.label, {
                        {type = 'textarea', label = 'Pesan', description = 'Masukan Pesan Yang Ingin Disampaikan'},
                    })
                    if input == nil or input[1] == nil then return end
                    local xPlayer = ESX.GetPlayerData()
                    local InputData = {
                        target = xPlayer.identifier,
                        name = xPlayer.name,
                        coords = GetEntityCoords(PlayerPedId()),
                        job = {
                            name = value.name,
                            label = value.label,
                        },
                        deskripsi = input[1],
                        type = 'pesan',
                    }
                    TriggerServerEvent('rzw-jobnotif:savedata', InputData)
                    lib.notify({
                        title = 'Job Notif',
                        description = 'Berhasil Mengirim Pesan Ke Pihak '..value.label,
                        type = 'success',
                        showDuration = true,
                        duration = 6000,
                        position = 'top-right',
                        style = {
                            borderRadius = "13px",
                            color = "#fff",
                        }
                    })
                end,
            })
        end
        lib.registerContext({
            id = 'rzw_JobMessage',
            title = 'Job Message',
            options = OptionsContext
        })
        lib.showContext('rzw_JobMessage')
    end
end

RegisterNetEvent('esx:setJob', function(job, lastJob)
    SendNUIMessage({
        action = "close",
    })
    local getData = lib.callback.await('rzw-jobnotif:server:getData', false)
    Wait(1500)
    SendNUIMessage({
        action = "update",
        data = {
            count = #getData
        }
    })
end)


RegisterNetEvent('rzw-jobnotif:notif')
AddEventHandler('rzw-jobnotif:notif', function(data)
    local PlayerData = ESX.GetPlayerData()
    if PlayerData.job.name == data.job.name then
        SendNUIMessage({
            action = "update",
            data = data
        })
        lib.notify({
            title = data.job.label..' Notification',
            description = data.deskripsi,
            type = 'warning',
            showDuration = true,
            duration = 10000,
            position = 'bottom-right',
            icon = data.icon
            -- icon = 'fa-solid fa-person-falling'
        })
    end
end)


RegisterNetEvent('rzw-spawn:client:FirstSpawn')
AddEventHandler('rzw-spawn:client:FirstSpawn', function()
    local getData = lib.callback.await('rzw-jobnotif:server:getData', false)
    local data = {}
    data.count = #getData
    SendNUIMessage({
        action = "update",
        data = data
    })
end)

RegisterCommand("jobnotif", function (playerId, args)
    local whitelisted = lib.callback.await('rzw-jobnotif:server:getData', false)
    if whitelisted then
        RZWClientJobNotif.OpenNotif()
    end
end, false)

RegisterNetEvent('rzw-spawn:client:jobnotif')
AddEventHandler('rzw-spawn:client:jobnotif', function()
    RZWClientJobNotif.OpenNotif()
end)