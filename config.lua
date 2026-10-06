--[[
    X Living Business  |  by MR X  |  X Studio
    Discord: mr_xdev  (https://discord.com/users/1019985047178182758)
]]

Config = {}

Config.Debug = false

-- 'auto' | 'qbox' | 'qb' | 'esx' | 'standalone'
-- standalone uses the ox_inventory "money" item as currency.
Config.Framework = 'auto'

-- Account used for purchases and payouts. 'bank' or 'cash'
Config.PayAccount = 'bank'

-- Language: set the convar  setr ox:locale "en"  in server.cfg (files live in /locales).

Config.InteractDistance = 2.0          -- distance to see the prompt and interact
Config.PayoutIntervalMinutes = 30      -- how often businesses generate income and pay wages
Config.IncomePerOnlineEmployee = 150   -- bonus income per online employee each cycle
Config.SellRefundPercent = 60          -- % of purchase price refunded when selling
Config.MaxBusinessesPerPlayer = 1
Config.MinWage = 0
Config.MaxWage = 2000                  -- per payout cycle

-- Optional Discord webhook for logs (leave '' to disable)
Config.Webhook = ''

-- Shared business stash (requires ox_inventory)
Config.UseStash = true
Config.Stash = { slots = 50, weight = 100000 }

-- Upgrade levels. Level 1 is the starting level (price is ignored for it).
Config.Levels = {
    { price = 0,      income = 400,  maxEmployees = 2 },
    { price = 25000,  income = 900,  maxEmployees = 4 },
    { price = 60000,  income = 1600, maxEmployees = 6 },
    { price = 120000, income = 2600, maxEmployees = 10 },
}

-- Add as many businesses as you like. `id` must be unique and never change once in use.
-- Coordinates below are examples - move them wherever you want.
Config.Businesses = {
    {
        id = 'x_burger',
        label = 'Burger Joint',
        price = 150000,
        coords = vec3(-1194.2, -892.3, 13.9),
        blip = { sprite = 106, color = 2, scale = 0.8 },
    },
    {
        id = 'x_tequila',
        label = 'Tequi-la-la Club',
        price = 300000,
        coords = vec3(-564.2, 275.9, 83.1),
        blip = { sprite = 121, color = 27, scale = 0.8 },
    },
    {
        id = 'x_seafood',
        label = 'Seafood Restaurant',
        price = 220000,
        coords = vec3(-1834.3, -1190.9, 14.3),
        blip = { sprite = 93, color = 3, scale = 0.8 },
    },
}
