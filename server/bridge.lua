--[[
    X Living Business  |  by MR X  |  X Studio
    Framework bridge: QBox / QBCore / ESX / standalone (ox_inventory money item)
]]

Bridge = {}

local fw, QBCore, ESX

local function started(name)
    return GetResourceState(name) == 'started'
end

local function detect()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if started('qbx_core') then return 'qbox' end
    if started('qb-core') then return 'qb' end
    if started('es_extended') then return 'esx' end
    return nil
end

function Bridge.Init()
    local tries = 0
    fw = detect()
    while not fw and tries < 30 do
        Wait(500)
        tries += 1
        fw = detect()
    end
    fw = fw or 'standalone'

    if fw == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif fw == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
    end

    return fw
end

local function getPlayer(src)
    if fw == 'qbox' then return exports.qbx_core:GetPlayer(src) end
    if fw == 'qb' then return QBCore.Functions.GetPlayer(src) end
    if fw == 'esx' then return ESX.GetPlayerFromId(src) end
end

local function account()
    if fw == 'esx' and Config.PayAccount == 'cash' then return 'money' end
    return Config.PayAccount
end

function Bridge.GetIdentifier(src)
    if fw == 'qbox' or fw == 'qb' then
        local p = getPlayer(src)
        return p and p.PlayerData.citizenid
    elseif fw == 'esx' then
        local p = getPlayer(src)
        return p and p.identifier
    end
    return GetPlayerIdentifierByType(src, 'license')
end

function Bridge.GetName(src)
    if fw == 'qbox' or fw == 'qb' then
        local p = getPlayer(src)
        if p and p.PlayerData.charinfo then
            return ('%s %s'):format(p.PlayerData.charinfo.firstname, p.PlayerData.charinfo.lastname)
        end
    elseif fw == 'esx' then
        local p = getPlayer(src)
        if p then return p.getName() end
    end
    return GetPlayerName(src) or 'Unknown'
end

function Bridge.GetBalance(src)
    if fw == 'qbox' or fw == 'qb' then
        local p = getPlayer(src)
        return p and p.PlayerData.money[account()] or 0
    elseif fw == 'esx' then
        local p = getPlayer(src)
        if not p then return 0 end
        if account() == 'bank' then return p.getAccount('bank').money end
        return p.getMoney()
    end
    return exports.ox_inventory:GetItemCount(src, 'money') or 0
end

function Bridge.Remove(src, amount, reason)
    if amount <= 0 or Bridge.GetBalance(src) < amount then return false end
    if fw == 'qbox' or fw == 'qb' then
        return getPlayer(src).Functions.RemoveMoney(account(), amount, reason) ~= false
    elseif fw == 'esx' then
        local p = getPlayer(src)
        if account() == 'bank' then p.removeAccountMoney('bank', amount, reason) else p.removeMoney(amount, reason) end
        return true
    end
    return exports.ox_inventory:RemoveItem(src, 'money', amount) and true or false
end

function Bridge.Add(src, amount, reason)
    if amount <= 0 then return false end
    if fw == 'qbox' or fw == 'qb' then
        return getPlayer(src).Functions.AddMoney(account(), amount, reason) ~= false
    elseif fw == 'esx' then
        local p = getPlayer(src)
        if account() == 'bank' then p.addAccountMoney('bank', amount, reason) else p.addMoney(amount, reason) end
        return true
    end
    return exports.ox_inventory:AddItem(src, 'money', amount) and true or false
end
