--[[
    X Living Business  |  by MR X  |  X Studio
    Discord: mr_xdev  (https://discord.com/users/1019985047178182758)
    Server logic. Every action is validated server-side (distance, ownership, amounts, rate limit).
]]

local RESOURCE = GetCurrentResourceName()
local cfgById, Businesses, Employees, Cooldowns = {}, {}, {}, {}

for _, b in ipairs(Config.Businesses) do cfgById[b.id] = b end

-- ─── Helpers ────────────────────────────────────────────────────────────────

local function log(msg)
    print(('^5[X Studio | %s]^7 %s'):format(RESOURCE, msg))
    if Config.Webhook and Config.Webhook ~= '' then
        PerformHttpRequest(Config.Webhook, function() end, 'POST', json.encode({
            username = 'X Living Business',
            embeds = { {
                title = 'X Living Business',
                description = msg,
                color = 3066993,
                footer = { text = 'X Studio | MR X' },
            } },
        }), { ['Content-Type'] = 'application/json' })
    end
end

local function dbg(...)
    if Config.Debug then print('^3[x_livingbusiness:debug]^7', ...) end
end

local function toAmount(v)
    v = math.floor(tonumber(v) or 0)
    if v < 1 or v > 1000000000 then return nil end
    return v
end

local function throttle(src)
    local now = GetGameTimer()
    if Cooldowns[src] and now - Cooldowns[src] < 500 then return true end
    Cooldowns[src] = now
    return false
end

local function near(src, cfg, extra)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - cfg.coords) <= Config.InteractDistance + (extra or 3.0)
end

local function save(id)
    local b = Businesses[id]
    if b then MySQL.update('UPDATE x_businesses SET funds = ?, level = ? WHERE id = ?', { b.funds, b.level, id }) end
end

local function roleOf(id, ident)
    local b = Businesses[id]
    if not b then return 'none' end
    if b.owner == ident then return 'owner' end
    if Employees[id] and Employees[id][ident] then return 'employee' end
    return 'other'
end

local function countOwned(ident)
    local n = 0
    for _, b in pairs(Businesses) do if b.owner == ident then n += 1 end end
    return n
end

local function employedAt(ident)
    for id, list in pairs(Employees) do if list[ident] then return id end end
end

local function employeeCount(id)
    local n = 0
    for _ in pairs(Employees[id] or {}) do n += 1 end
    return n
end

local function onlineMap()
    local map = {}
    for _, s in ipairs(GetPlayers()) do
        local src = tonumber(s)
        local ident = Bridge.GetIdentifier(src)
        if ident then map[ident] = src end
    end
    return map
end

local function registerStashes()
    if not Config.UseStash or GetResourceState('ox_inventory') ~= 'started' then return end
    for _, b in ipairs(Config.Businesses) do
        pcall(function()
            exports.ox_inventory:RegisterStash('xlb_' .. b.id, b.label .. ' Stash', Config.Stash.slots, Config.Stash.weight, false)
        end)
    end
end

-- ─── Startup ────────────────────────────────────────────────────────────────

CreateThread(function()
    local fw = Bridge.Init()

    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `x_businesses` (
        `id` VARCHAR(64) NOT NULL, `owner` VARCHAR(64) NOT NULL,
        `owner_name` VARCHAR(100) NOT NULL DEFAULT 'Unknown',
        `funds` BIGINT NOT NULL DEFAULT 0, `level` INT NOT NULL DEFAULT 1,
        `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `x_business_employees` (
        `business_id` VARCHAR(64) NOT NULL, `identifier` VARCHAR(64) NOT NULL,
        `name` VARCHAR(100) NOT NULL DEFAULT 'Unknown', `wage` INT NOT NULL DEFAULT 0,
        PRIMARY KEY (`business_id`, `identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]])

    for _, r in ipairs(MySQL.query.await('SELECT * FROM x_businesses') or {}) do
        if cfgById[r.id] then
            Businesses[r.id] = {
                owner = r.owner, ownerName = r.owner_name,
                funds = tonumber(r.funds) or 0,
                level = math.min(tonumber(r.level) or 1, #Config.Levels),
            }
        end
    end
    for _, r in ipairs(MySQL.query.await('SELECT * FROM x_business_employees') or {}) do
        if Businesses[r.business_id] then
            Employees[r.business_id] = Employees[r.business_id] or {}
            Employees[r.business_id][r.identifier] = { name = r.name, wage = r.wage }
        end
    end

    registerStashes()

    print('^5')
    print('  __  __ ____    __  __')
    print('  \\ \\/ /|  _ \\  \\ \\/ /   X Living Business v' .. GetResourceMetadata(RESOURCE, 'version', 0))
    print('   >  < | |_) |  >  <    by MR X  |  X Studio')
    print('  /_/\\_\\|____/  /_/\\_\\   Discord: mr_xdev')
    print(('  Framework: %s | Businesses: %d^7'):format(fw, #Config.Businesses))
end)

AddEventHandler('onResourceStart', function(res)
    if res == 'ox_inventory' then registerStashes() end
end)

AddEventHandler('playerDropped', function() Cooldowns[source] = nil end)

-- ─── Data for the menu ──────────────────────────────────────────────────────

lib.callback.register('xlb:getData', function(src, id)
    local cfg = cfgById[id]
    if not cfg or not near(src, cfg) then return nil end

    local ident = Bridge.GetIdentifier(src)
    local b = Businesses[id]
    local data = {
        id = id, label = cfg.label, price = cfg.price,
        owned = b ~= nil, role = roleOf(id, ident),
        maxLevel = #Config.Levels, useStash = Config.UseStash,
        sellRefund = math.floor(cfg.price * Config.SellRefundPercent / 100),
        refundPercent = Config.SellRefundPercent,
    }

    if b then
        data.ownerName = b.ownerName
        data.level = b.level
        data.income = Config.Levels[b.level].income
        data.maxEmployees = Config.Levels[b.level].maxEmployees
        data.nextLevel = Config.Levels[b.level + 1]
        if data.role == 'owner' then
            data.funds = b.funds
            data.employees = {}
            for i, e in pairs(Employees[id] or {}) do
                data.employees[#data.employees + 1] = { identifier = i, name = e.name, wage = e.wage }
            end
        elseif data.role == 'employee' then
            data.wage = Employees[id][ident].wage
        end
    end
    return data
end)

-- ─── Actions ────────────────────────────────────────────────────────────────

lib.callback.register('xlb:buy', function(src, id)
    if throttle(src) then return false, 'err_busy' end
    local cfg = cfgById[id]
    if not cfg or not near(src, cfg) then return false, 'err_far' end
    if Businesses[id] then return false, 'err_owned' end

    local ident = Bridge.GetIdentifier(src)
    if not ident then return false, 'err_generic' end
    if countOwned(ident) >= Config.MaxBusinessesPerPlayer then return false, 'err_limit' end
    if employedAt(ident) then return false, 'err_employed' end
    if not Bridge.Remove(src, cfg.price, 'x_livingbusiness:purchase') then return false, 'err_funds' end

    local name = Bridge.GetName(src)
    Businesses[id] = { owner = ident, ownerName = name, funds = 0, level = 1 }
    MySQL.insert('REPLACE INTO x_businesses (id, owner, owner_name, funds, level) VALUES (?, ?, ?, 0, 1)', { id, ident, name })
    log(('%s (%s) purchased %s for $%d'):format(name, ident, cfg.label, cfg.price))
    return true, 'ok_bought', { cfg.label }
end)

lib.callback.register('xlb:sell', function(src, id)
    if throttle(src) then return false, 'err_busy' end
    local cfg = cfgById[id]
    if not cfg or not near(src, cfg) then return false, 'err_far' end
    local b = Businesses[id]
    if not b or b.owner ~= Bridge.GetIdentifier(src) then return false, 'err_perm' end

    local payout = math.floor(cfg.price * Config.SellRefundPercent / 100) + b.funds
    Businesses[id], Employees[id] = nil, nil
    MySQL.query('DELETE FROM x_business_employees WHERE business_id = ?', { id })
    MySQL.query('DELETE FROM x_businesses WHERE id = ?', { id })
    Bridge.Add(src, payout, 'x_livingbusiness:sell')
    log(('%s sold %s and received $%d'):format(b.ownerName, cfg.label, payout))
    return true, 'ok_sold', { payout }
end)

lib.callback.register('xlb:deposit', function(src, id, amount)
    if throttle(src) then return false, 'err_busy' end
    local cfg, b = cfgById[id], Businesses[id]
    if not cfg or not b or not near(src, cfg) then return false, 'err_far' end
    if b.owner ~= Bridge.GetIdentifier(src) then return false, 'err_perm' end
    amount = toAmount(amount)
    if not amount then return false, 'err_amount' end
    if not Bridge.Remove(src, amount, 'x_livingbusiness:deposit') then return false, 'err_funds' end
    b.funds += amount
    save(id)
    return true, 'ok_deposit', { amount }
end)

lib.callback.register('xlb:withdraw', function(src, id, amount)
    if throttle(src) then return false, 'err_busy' end
    local cfg, b = cfgById[id], Businesses[id]
    if not cfg or not b or not near(src, cfg) then return false, 'err_far' end
    if b.owner ~= Bridge.GetIdentifier(src) then return false, 'err_perm' end
    amount = toAmount(amount)
    if not amount then return false, 'err_amount' end
    if b.funds < amount then return false, 'err_bfunds' end
    b.funds -= amount
    Bridge.Add(src, amount, 'x_livingbusiness:withdraw')
    save(id)
    return true, 'ok_withdraw', { amount }
end)

lib.callback.register('xlb:upgrade', function(src, id)
    if throttle(src) then return false, 'err_busy' end
    local cfg, b = cfgById[id], Businesses[id]
    if not cfg or not b or not near(src, cfg) then return false, 'err_far' end
    if b.owner ~= Bridge.GetIdentifier(src) then return false, 'err_perm' end
    local nextLevel = Config.Levels[b.level + 1]
    if not nextLevel then return false, 'err_maxlevel' end
    if b.funds < nextLevel.price then return false, 'err_bfunds' end
    b.funds -= nextLevel.price
    b.level += 1
    save(id)
    log(('%s upgraded %s to level %d'):format(b.ownerName, cfg.label, b.level))
    return true, 'ok_upgrade', { b.level }
end)

lib.callback.register('xlb:hire', function(src, id, targetId, wage)
    if throttle(src) then return false, 'err_busy' end
    local cfg, b = cfgById[id], Businesses[id]
    if not cfg or not b or not near(src, cfg) then return false, 'err_far' end
    local ident = Bridge.GetIdentifier(src)
    if b.owner ~= ident then return false, 'err_perm' end

    targetId = math.floor(tonumber(targetId) or 0)
    wage = math.floor(tonumber(wage) or -1)
    if wage < Config.MinWage or wage > Config.MaxWage then return false, 'err_amount' end
    if targetId <= 0 or targetId == src or not GetPlayerName(targetId) then return false, 'err_player' end

    local a, t = GetPlayerPed(src), GetPlayerPed(targetId)
    if not t or t == 0 or #(GetEntityCoords(a) - GetEntityCoords(t)) > 5.0 then return false, 'err_player' end

    local tIdent = Bridge.GetIdentifier(targetId)
    if not tIdent then return false, 'err_player' end
    if employedAt(tIdent) or countOwned(tIdent) > 0 then return false, 'err_employed' end
    if employeeCount(id) >= Config.Levels[b.level].maxEmployees then return false, 'err_employee_limit' end

    local accepted = lib.callback.await('xlb:confirmJob', targetId, cfg.label, wage)
    if not accepted then return false, 'err_declined' end

    -- re-check after the (possibly long) confirmation
    if not Businesses[id] or employedAt(tIdent) or employeeCount(id) >= Config.Levels[Businesses[id].level].maxEmployees then
        return false, 'err_generic'
    end

    local name = Bridge.GetName(targetId)
    Employees[id] = Employees[id] or {}
    Employees[id][tIdent] = { name = name, wage = wage }
    MySQL.insert('INSERT INTO x_business_employees (business_id, identifier, name, wage) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE wage = VALUES(wage), name = VALUES(name)', { id, tIdent, name, wage })
    log(('%s hired %s at %s (wage $%d)'):format(b.ownerName, name, cfg.label, wage))
    return true, 'ok_hired', { name }
end)

lib.callback.register('xlb:fire', function(src, id, identifier)
    if throttle(src) then return false, 'err_busy' end
    local cfg, b = cfgById[id], Businesses[id]
    if not cfg or not b or not near(src, cfg) then return false, 'err_far' end
    if b.owner ~= Bridge.GetIdentifier(src) then return false, 'err_perm' end
    if not Employees[id] or not Employees[id][identifier] then return false, 'err_generic' end
    Employees[id][identifier] = nil
    MySQL.query('DELETE FROM x_business_employees WHERE business_id = ? AND identifier = ?', { id, identifier })
    return true, 'ok_fired'
end)

lib.callback.register('xlb:setWage', function(src, id, identifier, wage)
    if throttle(src) then return false, 'err_busy' end
    local cfg, b = cfgById[id], Businesses[id]
    if not cfg or not b or not near(src, cfg) then return false, 'err_far' end
    if b.owner ~= Bridge.GetIdentifier(src) then return false, 'err_perm' end
    wage = math.floor(tonumber(wage) or -1)
    if wage < Config.MinWage or wage > Config.MaxWage then return false, 'err_amount' end
    if not Employees[id] or not Employees[id][identifier] then return false, 'err_generic' end
    Employees[id][identifier].wage = wage
    MySQL.update('UPDATE x_business_employees SET wage = ? WHERE business_id = ? AND identifier = ?', { wage, id, identifier })
    return true, 'ok_wage'
end)

lib.callback.register('xlb:quit', function(src, id)
    if throttle(src) then return false, 'err_busy' end
    local cfg = cfgById[id]
    if not cfg or not near(src, cfg) then return false, 'err_far' end
    local ident = Bridge.GetIdentifier(src)
    if roleOf(id, ident) ~= 'employee' then return false, 'err_perm' end
    Employees[id][ident] = nil
    MySQL.query('DELETE FROM x_business_employees WHERE business_id = ? AND identifier = ?', { id, ident })
    return true, 'ok_quit'
end)

lib.callback.register('xlb:stash', function(src, id)
    if throttle(src) then return false, 'err_busy' end
    local cfg = cfgById[id]
    if not Config.UseStash or not cfg or not near(src, cfg) then return false, 'err_far' end
    local role = roleOf(id, Bridge.GetIdentifier(src))
    if role ~= 'owner' and role ~= 'employee' then return false, 'err_perm' end
    exports.ox_inventory:forceOpenInventory(src, 'stash', 'xlb_' .. id)
    return true
end)

-- ─── Payout loop ────────────────────────────────────────────────────────────

local function payout()
    local online = onlineMap()
    for id, b in pairs(Businesses) do
        local level = Config.Levels[b.level]
        local staff = Employees[id] or {}
        local onlineStaff = 0
        for ident in pairs(staff) do if online[ident] then onlineStaff += 1 end end

        local income = level.income + onlineStaff * Config.IncomePerOnlineEmployee
        b.funds += income

        for ident, e in pairs(staff) do
            local src = online[ident]
            if src and e.wage > 0 and b.funds >= e.wage then
                b.funds -= e.wage
                Bridge.Add(src, e.wage, 'x_livingbusiness:wage')
                lib.notify(src, { title = 'X Living Business', type = 'success', description = ('Wage received: $%d'):format(e.wage) })
            end
        end

        save(id)
        local ownerSrc = online[b.owner]
        if ownerSrc then
            lib.notify(ownerSrc, { title = 'X Living Business', type = 'inform', description = ('Business income received: $%d'):format(income) })
        end
        dbg(id, 'income', income, 'funds', b.funds)
    end
end

CreateThread(function()
    while true do
        Wait(math.max(1, Config.PayoutIntervalMinutes) * 60000)
        payout()
    end
end)

-- ─── Exports ────────────────────────────────────────────────────────────────

exports('GetBusiness', function(id) return Businesses[id] end)
exports('IsOwner', function(src, id)
    local ident = Bridge.GetIdentifier(src)
    return ident ~= nil and roleOf(id, ident) == 'owner'
end)
exports('IsEmployee', function(src, id)
    local ident = Bridge.GetIdentifier(src)
    return ident ~= nil and roleOf(id, ident) == 'employee'
end)

-- ─── Admin commands (ACE: group.admin) ──────────────────────────────────────

lib.addCommand('xbizgive', {
    help = 'Give a business to a player',
    params = {
        { name = 'business', type = 'string', help = 'Business id from config' },
        { name = 'target', type = 'playerId', help = 'Server ID' },
    },
    restricted = 'group.admin',
}, function(source, args)
    local cfg = cfgById[args.business]
    local ident = Bridge.GetIdentifier(args.target)
    if not cfg or not ident then return print('Invalid business or player.') end
    local name = Bridge.GetName(args.target)
    Businesses[cfg.id] = { owner = ident, ownerName = name, funds = 0, level = 1 }
    Employees[cfg.id] = nil
    MySQL.query('DELETE FROM x_business_employees WHERE business_id = ?', { cfg.id })
    MySQL.insert('REPLACE INTO x_businesses (id, owner, owner_name, funds, level) VALUES (?, ?, ?, 0, 1)', { cfg.id, ident, name })
    log(('Admin %s gave %s to %s'):format(source, cfg.label, name))
end)

lib.addCommand('xbizreset', {
    help = 'Remove the owner of a business and clear its employees',
    params = { { name = 'business', type = 'string', help = 'Business id from config' } },
    restricted = 'group.admin',
}, function(source, args)
    if not cfgById[args.business] then return print('Invalid business.') end
    Businesses[args.business], Employees[args.business] = nil, nil
    MySQL.query('DELETE FROM x_business_employees WHERE business_id = ?', { args.business })
    MySQL.query('DELETE FROM x_businesses WHERE id = ?', { args.business })
    log(('Admin %s reset %s'):format(source, args.business))
end)
