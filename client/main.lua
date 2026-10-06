--[[
    X Living Business  |  by MR X  |  X Studio
    Client: blips, interaction points and ox_lib menus.
]]

lib.locale()

local busy = false

local function money(n)
    return '$' .. lib.math.groupdigits(n or 0)
end

local function notify(ok, key, args)
    lib.notify({
        title = locale('title'),
        type = ok and 'success' or 'error',
        description = locale(key or 'err_generic', table.unpack(args or {})),
    })
end

local function act(name, ...)
    local ok, key, args = lib.callback.await(name, false, ...)
    if key then notify(ok, key, args) end
    return ok
end

local openMenu

-- ─── Employee menus (owner) ─────────────────────────────────────────────────

local function employeeMenu(id, e, back)
    local ctx = 'xlb_emp_' .. id
    lib.registerContext({
        id = ctx,
        title = e.name,
        menu = back,
        onBack = function() end,
        options = {
            { title = locale('menu_setwage'), description = money(e.wage), icon = 'money-bill', onSelect = function()
                local input = lib.inputDialog(locale('menu_setwage'), { { type = 'number', label = locale('wage'), min = Config.MinWage, max = Config.MaxWage, default = e.wage, required = true } })
                if input then act('xlb:setWage', id, e.identifier, input[1]) end
                openMenu(id)
            end },
            { title = locale('menu_fire'), icon = 'user-xmark', onSelect = function()
                act('xlb:fire', id, e.identifier)
                openMenu(id)
            end },
        },
    })
    lib.showContext(ctx)
end

local function employeesMenu(id, d)
    local options = {
        { title = locale('menu_hire'), icon = 'user-plus', onSelect = function()
            local input = lib.inputDialog(locale('menu_hire'), {
                { type = 'number', label = locale('player_id'), min = 1, required = true },
                { type = 'number', label = locale('wage'), min = Config.MinWage, max = Config.MaxWage, default = 0, required = true },
            })
            if input then act('xlb:hire', id, input[1], input[2]) end
            openMenu(id)
        end },
    }
    for _, e in ipairs(d.employees or {}) do
        options[#options + 1] = {
            title = e.name, description = money(e.wage), icon = 'user',
            onSelect = function() employeeMenu(id, e, 'xlb_emps_' .. id) end,
        }
    end
    lib.registerContext({
        id = 'xlb_emps_' .. id,
        title = locale('menu_employees'),
        menu = 'xlb_main_' .. id,
        options = options,
    })
    lib.showContext('xlb_emps_' .. id)
end

-- ─── Main menu ──────────────────────────────────────────────────────────────

openMenu = function(id)
    local d = lib.callback.await('xlb:getData', false, id)
    if not d then return notify(false, 'err_far') end

    local ctx = 'xlb_main_' .. id
    local options = {}

    if not d.owned then
        options[#options + 1] = { title = locale('menu_buy'), description = locale('menu_buy_desc', lib.math.groupdigits(d.price)), icon = 'cart-shopping', onSelect = function()
            act('xlb:buy', id)
        end }
    else
        options[#options + 1] = { title = locale('menu_owner', d.ownerName), description = locale('menu_level', d.level, d.maxLevel) .. ' | ' .. locale('menu_income', lib.math.groupdigits(d.income)), icon = 'briefcase', readOnly = true }

        if d.role == 'owner' then
            options[#options + 1] = { title = locale('menu_funds'), description = money(d.funds), icon = 'sack-dollar', readOnly = true }
            options[#options + 1] = { title = locale('menu_deposit'), icon = 'arrow-down', onSelect = function()
                local input = lib.inputDialog(locale('menu_deposit'), { { type = 'number', label = locale('amount'), min = 1, required = true } })
                if input then act('xlb:deposit', id, input[1]) end
                openMenu(id)
            end }
            options[#options + 1] = { title = locale('menu_withdraw'), icon = 'arrow-up', onSelect = function()
                local input = lib.inputDialog(locale('menu_withdraw'), { { type = 'number', label = locale('amount'), min = 1, max = math.max(1, d.funds), required = true } })
                if input then act('xlb:withdraw', id, input[1]) end
                openMenu(id)
            end }
            if d.nextLevel then
                options[#options + 1] = { title = locale('menu_upgrade'), description = locale('menu_upgrade_desc', d.level + 1, lib.math.groupdigits(d.nextLevel.price)), icon = 'arrow-trend-up', onSelect = function()
                    act('xlb:upgrade', id)
                    openMenu(id)
                end }
            else
                options[#options + 1] = { title = locale('menu_upgrade'), description = locale('menu_upgrade_max'), icon = 'arrow-trend-up', disabled = true }
            end
            options[#options + 1] = { title = locale('menu_employees'), description = locale('menu_employees_desc', #d.employees, d.maxEmployees), icon = 'users', onSelect = function()
                employeesMenu(id, d)
            end }
            if d.useStash then
                options[#options + 1] = { title = locale('menu_stash'), icon = 'box-archive', onSelect = function() act('xlb:stash', id) end }
            end
            options[#options + 1] = { title = locale('menu_sell'), description = locale('menu_sell_desc', d.refundPercent), icon = 'tag', onSelect = function()
                local c = lib.alertDialog({ header = locale('confirm_sell_header'), content = locale('confirm_sell_body', d.label), centered = true, cancel = true })
                if c == 'confirm' then act('xlb:sell', id) end
            end }
        elseif d.role == 'employee' then
            options[#options + 1] = { title = locale('menu_wage', lib.math.groupdigits(d.wage)), icon = 'money-bill', readOnly = true }
            if d.useStash then
                options[#options + 1] = { title = locale('menu_stash'), icon = 'box-archive', onSelect = function() act('xlb:stash', id) end }
            end
            options[#options + 1] = { title = locale('menu_quit'), icon = 'door-open', onSelect = function() act('xlb:quit', id) end }
        end
    end

    lib.registerContext({ id = ctx, title = d.label, options = options })
    lib.showContext(ctx)
end

-- ─── Job offer confirmation (triggered by the owner via server) ─────────────

lib.callback.register('xlb:confirmJob', function(label, wage)
    local c = lib.alertDialog({
        header = locale('job_offer'),
        content = locale('job_offer_body', label, lib.math.groupdigits(wage)),
        centered = true, cancel = true,
    })
    return c == 'confirm'
end)

-- ─── Blips and interaction points ───────────────────────────────────────────

CreateThread(function()
    for _, b in ipairs(Config.Businesses) do
        if b.blip then
            local blip = AddBlipForCoord(b.coords.x, b.coords.y, b.coords.z)
            SetBlipSprite(blip, b.blip.sprite or 480)
            SetBlipColour(blip, b.blip.color or 2)
            SetBlipScale(blip, b.blip.scale or 0.8)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentSubstringPlayerName(b.label)
            EndTextCommandSetBlipName(blip)
        end

        lib.points.new({
            coords = b.coords,
            distance = Config.InteractDistance,
            onEnter = function() lib.showTextUI(locale('interact', b.label)) end,
            onExit = function() lib.hideTextUI() end,
            nearby = function(self)
                DrawMarker(2, b.coords.x, b.coords.y, b.coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.25, 0.25, 0.25, 255, 255, 255, 160, true, true, 2, false, nil, nil, false)
                if not busy and IsControlJustReleased(0, 38) then
                    busy = true
                    openMenu(b.id)
                    busy = false
                end
            end,
        })
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then lib.hideTextUI() end
end)
