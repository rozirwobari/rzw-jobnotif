ESX = exports["es_extended"]:getSharedObject()


Citizen.CreateThread(function()
    MySQL.query(
        [[
            CREATE TABLE IF NOT EXISTS `rzw_jobnotif` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `identifier` varchar(150) NOT NULL,
                `nama` mediumtext NOT NULL,
                `job` varchar(50) NOT NULL,
                `deskripsi` longtext DEFAULT NULL,
                `coords` mediumtext NOT NULL,
                `phone` varchar(50) DEFAULT NULL,
                `respon_name` mediumtext DEFAULT NULL,
                `respon_identifier` varchar(150) DEFAULT NULL,
                `type` varchar(50) DEFAULT NULL,
                `is_respon` int(1) NOT NULL DEFAULT 0,
                `create_at` datetime NOT NULL DEFAULT current_timestamp(),
                PRIMARY KEY (`id`)
            );
        ]]
        , {}, function(result)
            if result and result.warningStatus == 0 then
                print("^1[rzw-jobnotif] Table rzw_jobnotif Tidak Ditemukan!, Sedang Membaut Table...^0")
                Wait(3000)
                print("^2[rzw-jobnotif] Table rzw_jobnotif Berhasil Dibuat.^0")
            else
                print("^2[rzw-jobnotif] Table rzw_jobnotif Sudah Tersedia.^0")
            end
        end)
end)


RegisterServerEvent('rzw-jobnotif:savedata')
AddEventHandler('rzw-jobnotif:savedata', function(datas, data)
    if data.target == nil then
        local xTarget = ESX.GetPlayerFromId(source)
        return DropPlayer(xTarget.source, '[RZW-JOBNOTIF] Exploit Trigger `rzw-jobnotif:savedata`')
    end
    local xTarget = ESX.GetPlayerFromIdentifier(data.target)
    if xTarget ~= nil then
        local users = MySQL.query.await('SELECT * FROM users WHERE identifier = ?', {
            xTarget.identifier,
        })

        MySQL.query.await('INSERT INTO rzw_jobnotif (identifier, nama, job, deskripsi, coords, phone, type) VALUES (?,?,?,?,?,?,?)', {
            xTarget.identifier,
            xTarget.name,
            data.job.name,
            data.deskripsi,
            json.encode(data.coords),
            users[1].phone_number or data.phone,
            data.type,
        })
        Wait(1500)
        local getData = MySQL.query.await('SELECT * FROM rzw_jobnotif WHERE job = ? AND is_respon = ?', {
            data.job.name,
            0
        })
        data.count = #getData
        for _, playerId in ipairs(GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer.job.name == data.job.name then
                TriggerClientEvent('rzw-jobnotif:notif', xPlayer.source, data)
            end
        end
    end
end)

RegisterServerEvent('rzw-jobnotif:server:respon')
AddEventHandler('rzw-jobnotif:server:respon', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if data.id == nil then
        return DropPlayer(xPlayer.source, '[RZW-JOBNOTIF] Exploit Trigger `rzw-jobnotif:server:respon`')
    end
    local getData = MySQL.query.await('SELECT * FROM rzw_jobnotif WHERE id = ?', {
        data.id,
    })
    if #getData > 0 then
        local dataKorban = getData[1]
        if dataKorban.is_respon == 1 then
            return TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Job Notif',
                description = 'Sinyal Sudah Direspon Oleh '..dataKorban.respon_name,
                type = 'error'
            })
        else
            MySQL.query.await('UPDATE rzw_jobnotif SET is_respon = ?, respon_name = ?, respon_identifier = ? WHERE id = ?', {
                1,
                xPlayer.name,
                xPlayer.identifier,
                data.id,
            })
            return TriggerClientEvent('ox_lib:notify', xPlayer.source, {
                title = 'Job Notif',
                description = 'Menuju Lokasi Korban Sekarang',
                type = 'success'
            })
        end
    end
end)

lib.callback.register('rzw-jobnotif:server:getData', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local getData = MySQL.query.await('SELECT * FROM rzw_jobnotif WHERE job = ? AND is_respon = ?', {
        xPlayer.job.name,
        0
    })
    return getData
end)

function getTimeAgo(timestamp)
    local currentTime = os.time()
    local timeDiff = os.difftime(currentTime, timestamp)
    
    local secondsInMinute = 60
    local secondsInHour = 3600
    local secondsInDay = 86400
    local secondsInMonth = 2592000
    local secondsInYear = 31536000

    if timeDiff < secondsInMinute then
        return math.floor(timeDiff) .. " detik yang lalu"
    elseif timeDiff < secondsInHour then
        return math.floor(timeDiff / secondsInMinute) .. " menit yang lalu"
    elseif timeDiff < secondsInDay then
        return math.floor(timeDiff / secondsInHour) .. " jam yang lalu"
    elseif timeDiff < secondsInMonth then
        return math.floor(timeDiff / secondsInDay) .. " hari yang lalu"
    elseif timeDiff < secondsInYear then
        return math.floor(timeDiff / secondsInMonth) .. " bulan yang lalu"
    else
        return math.floor(timeDiff / secondsInYear) .. " tahun yang lalu"
    end
end

lib.callback.register('rzw-jobnotif:server:getList', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local OptionsContext = {}
    local getData = MySQL.query.await('SELECT *, UNIX_TIMESTAMP(create_at) as create_at_timestamp FROM rzw_jobnotif WHERE job = ? ORDER BY id DESC', {
        xPlayer.job.name,
    })

    for key, value in pairs(getData) do
        table.insert(OptionsContext, {
            title = value.nama..(value.is_respon == 1 and ' ✅' or '')..' ['..(value.type == 'pesan' and '💬' or '📡')..']',
            deskripsi = 'Mengirim '..string.gsub(value.type, "^%l", string.upper)..' '..getTimeAgo(value.create_at_timestamp)..(value.is_respon == 1 and '\nDirespon Oleh '..value.respon_name or ''),
            readOnly = (value.is_respon == 1 and true or false),
            data = value
        })
    end
    return getData, OptionsContext
end)

lib.callback.register('rzw-jobnotif:server:JobList', function(source, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if type == 'checked' then
        local getData = MySQL.query.await('SELECT * FROM jobs WHERE name = ?', {
            xPlayer.job.name,
        })
        if #getData >= 1 and getData[1].whitelisted then
            return getData[1]
        end
        return false
    elseif type == 'get' then
        local getData = MySQL.query.await('SELECT * FROM jobs WHERE whitelisted = ?', {
            1,
        })
        return getData
    end
end)