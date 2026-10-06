<p align="center">
  <img src="assets/logo.png" alt="MR X" width="220">
</p>

<h1 align="center">X Living Business</h1>

<p align="center">
  A player-owned business system for FiveM — buy, manage, upgrade and staff businesses that earn income while your city lives.<br>
  <b>Developed by MR X &nbsp;•&nbsp; Published by X Studio</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue" alt="version">
  <img src="https://img.shields.io/badge/FiveM-Lua%205.4-orange" alt="fivem">
  <img src="https://img.shields.io/badge/Qbox%20%7C%20QBCore%20%7C%20ESX-supported-success" alt="frameworks">
  <img src="https://img.shields.io/badge/ox__lib-required-lightgrey" alt="ox_lib">
  <img src="https://img.shields.io/badge/license-Commercial-black" alt="license">
</p>

---

## ✨ Features

- 🏢 **Buy & sell businesses** — configurable price, blip and location; owners get a configurable refund when selling
- 💰 **Business funds** — owners deposit / withdraw money, funds pay for upgrades and employee wages
- 📈 **Upgrade levels** — each level raises passive income and the employee cap
- 👥 **Employees** — hire nearby players (they must accept), set / change wages, fire, or let them quit
- ⏱️ **Automatic payouts** — every cycle each business earns income (bonus per online employee) and pays wages
- 📦 **Shared stash** — optional `ox_inventory` stash for owner and employees
- 🔌 **Framework bridge** — Qbox, QBCore, ESX or standalone (`ox_inventory` money item), auto-detected
- 🔒 **Server-side validation** — distance, ownership, amounts and rate limiting on every action
- 🧾 **Logging** — console and optional Discord webhook
- 🌍 **Localization** — all text lives in `locales/*.json`
- 🧩 **Exports & admin commands** for integrations

## 📦 Requirements

| Dependency | Notes |
| --- | --- |
| [ox_lib](https://github.com/overextended/ox_lib) | required |
| [oxmysql](https://github.com/overextended/oxmysql) | required |
| Qbox / QBCore / ESX | optional (standalone mode needs `ox_inventory`) |
| [ox_inventory](https://github.com/overextended/ox_inventory) | optional — stash and standalone money |

## 🚀 Installation

1. Drop the `x_livingbusiness` folder into your `resources` directory.
2. Import `sql/install.sql` (the resource also creates the tables on first start).
3. Add to `server.cfg` **after** `ox_lib`, `oxmysql` and your framework:
   ```cfg
   ensure ox_lib
   ensure oxmysql
   ensure x_livingbusiness
   ```
4. Open `config.lua` and adjust framework, businesses, levels and payouts.
5. (Optional) set your language: `setr ox:locale "en"`.
6. Grant admin commands in `server.cfg` if needed: `add_ace group.admin command allow`.

## ⚙️ Configuration

Everything lives in [`config.lua`](config.lua).

| Option | Description |
| --- | --- |
| `Framework` | `auto`, `qbox`, `qb`, `esx`, `standalone` |
| `PayAccount` | `bank` or `cash` |
| `PayoutIntervalMinutes` | Income / wage cycle length |
| `IncomePerOnlineEmployee` | Bonus income per online employee per cycle |
| `SellRefundPercent` | % of purchase price refunded on sale |
| `MaxBusinessesPerPlayer` | Ownership cap |
| `MinWage` / `MaxWage` | Wage limits per cycle |
| `UseStash` / `Stash` | `ox_inventory` stash toggle and size |
| `Webhook` | Discord webhook URL for logs |
| `Levels` | Upgrade price, income and employee cap per level |
| `Businesses` | Id, label, price, coords and blip for each business |

> Business `id`s are stored in the database — never rename one after players own it.

## 🎮 Usage

Walk to a business blip and press **E**.

- **Not owned:** purchase it.
- **Owner:** manage funds, upgrade, hire / fire / set wages, open the stash, sell.
- **Employee:** view your wage, open the stash, quit.

### Commands (ACE `group.admin`)

| Command | Description |
| --- | --- |
| `/xbizgive <business> <serverId>` | Assign a business to a player |
| `/xbizreset <business>` | Remove the owner and employees |

### Server exports

```lua
exports.x_livingbusiness:GetBusiness('x_burger')        -- table or nil
exports.x_livingbusiness:IsOwner(source, 'x_burger')    -- boolean
exports.x_livingbusiness:IsEmployee(source, 'x_burger') -- boolean
```

## 🔐 Security notes

- All money, ownership and distance checks happen on the server; the client only sends requests.
- The stash is opened server-side for owner/employees only. As with any `ox_inventory` stash registered without groups, review your inventory-side access rules if you need stricter guarantees.
- Never commit your webhook URL to a public repository.

## 🗂️ Project structure

```
x_livingbusiness/
├─ assets/logo.png
├─ client/main.lua
├─ server/bridge.lua      # framework abstraction
├─ server/main.lua
├─ locales/en.json
├─ sql/install.sql
├─ config.lua
├─ fxmanifest.lua
├─ LICENSE
└─ CHANGELOG.md
```

## ❓ FAQ

**Does it work without a framework?** Yes — set `Framework = 'standalone'`; it uses the `ox_inventory` `money` item.

**Can I add a business?** Add an entry to `Config.Businesses` with a unique `id` and restart the resource.

**Can I add a language?** Copy `locales/en.json` to `locales/<code>.json`, translate it, and set `setr ox:locale "<code>"`.

## 💬 Support

- Developer: **MR X**
- Studio: **X Studio**
- Discord: **mr_xdev** — <https://discord.com/users/1019985047178182758>

Please include your server artifact version, framework and console errors when requesting support.

## 📄 License

Commercial license — see [LICENSE](LICENSE). © X Studio / MR X. All rights reserved.

<p align="center"><sub>Made with ❤️ by MR X • X Studio</sub></p>
