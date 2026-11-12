# Profession Recipe Profit

WoW Forever addon that shows estimated crafting profit using [Auctionator](https://www.curseforge.com/wow/addons/auctionator) prices:

- **Profession window**: Cost / Value / Profit under the selected recipe's reagents, plus a profit tag on each recipe row.
- **Trainer**: profit lines on the tooltip of trainable recipes.
- **Recipe items**: profit lines on recipe tooltips (bags, AH, vendors).

Profit = output AH price × quantity × 0.95 (AH cut) − reagent cost. Reagent cost uses the cheaper of the AH price and the merchant price Auctionator has seen (Auctionator records a vendor's prices when you open it). `?` / "unpriced" means some reagents have no price yet, so cost is understated.

Recipe items and trainer entries are matched to recipes by name, using an index built the first time you open each profession window (rebuilt only when that profession's recipe count changes). Until then, recipe tooltips show a hint.

## Commands

- `/prp` — open options (also under Options → AddOns): toggle tooltip Cost/Value/Profit lines and recipe-list profit
- `/prp status` — list indexed professions
- `/prp debug` — toggle debug output (how recipe items/trainer entries were resolved)

## Development

Mirror the addon into the game's AddOns folder and keep it synced while you edit:

```bash
powershell -ExecutionPolicy Bypass -File scripts/watch.ps1
```

Pass `-AddOnsPath "<path>\Interface\AddOns"` to target a different install. It deploys to `AddOns\ProfessionRecipeProfit`, skipping `scripts/` and dot-files.
