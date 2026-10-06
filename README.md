# Alpha Gal Trait

Alpha Gal Trait adds an alpha-gal allergy trait to Project Zomboid Build 42. Eating red meat builds exposure and can cause delayed reactions based on how much was eaten. Small amounts might just make you feel sick, while a full serving can turn into a severe and potentially fatal reaction.

Chicken, turkey, fish, seafood, and other non-mammalian meats are excluded. Modded foods are also supported through automatic food-type/name detection and the compatibility API.

## 🥩 How reactions work

Eating red meat adds exposure based on the portion you actually eat. The reaction does not begin immediately. By default, symptoms start about **2 in-game hours after eating**.

The amount eaten determines which severity range the exposure reaches:

| Exposure | Example | Reaction tier | Default chance |
| --- | --- | --- | --- |
| Under 0.35 | Roughly a quarter serving | Mild | 65% |
| 0.35 to under 0.75 | Medium amount / partial serving | Moderate | 85% |
| 0.75+ | Full or near-full serving | Severe | 100% |

A full-strength red meat item such as ground beef, steak, pork, bacon, lamb, venison, etc. carries **1.0 exposure** for the whole item. Eating 25% of it gives about **0.25 exposure**, eating half gives about **0.50**, and eating the full item gives **1.0**.

Reaction chances, delay, severe reaction length, and exposure decay can all be changed in Sandbox Options.

## 🤢 Reaction stages

### Mild

A mild exposure can cause food sickness, stress, pain, and reduced endurance. It is meant to feel noticeable without immediately wrecking the character.

### Moderate

Moderate reactions push the symptoms further with more sickness, panic, pain, fatigue, and endurance loss.
### Severe

Severe reactions are the dangerous stage.

Once the reaction begins, symptoms progressively worsen instead of instantly dropping your stats. Over roughly **3 in-game hours by default**:

- body temperature rises
- health gradually falls toward 50%
- food sickness increases
- stress and panic increase
- pain and fatigue increase
- endurance steadily drops
- the moodles continue getting worse as the reaction progresses

At the end of a fatal severe reaction, the character displays:

> **I can't breathe....**

The line appears above the character, then the fatal stage happens a few seconds later.

## 🎬 Severe reaction preview

<img width="640" height="480" alt="1005(1) (2)" src="https://github.com/user-attachments/assets/d4ee9d8b-f552-4274-b3c5-6ae74b9cc546" />


## 🔎 Red meat detection

Vanilla red-meat foods are registered directly, including common beef, steak, burger, ground beef, pork, bacon, ham, sausage, lamb, mutton, venison, and rabbit items.

The mod also tries to recognize modded foods automatically using their Project Zomboid food type and item ID. Names containing things such as `beef`, `steak`, `pork`, `bacon`, `lamb`, `venison`, `deer`, `boar`, `bison`, `goat`, `rabbit`, or `veal` can be recognized without the other mod specifically supporting Alpha Gal Trait.

White-meat checks run first, so chicken, turkey, duck, poultry, fish, seafood, and similar foods are excluded.

Normal modded foods such as salads or other unrelated foods will not trigger the trait unless they are classified as red meat, explicitly registered, or inherit contamination from red-meat ingredients in a crafted recipe.

## 🍲 Crafted food contamination

Red-meat exposure can carry into crafted meals.

If contaminated ingredients are used in a recipe, the created food can inherit that contamination. This means removing the obvious piece of meat from a prepared meal does not necessarily make the resulting food safe.

## 🧩 Compatibility API

Mods can explicitly register custom red-meat foods:

```lua
require "AlphaGal/AlphaGalAPI"

AlphaGalAPI.registerRedMeat("MyMod.BisonSteak", 1.0)
```

Foods that should never trigger Alpha Gal can also be explicitly marked as white meat:

```lua
AlphaGalAPI.registerWhiteMeat("MyMod.SpecialChicken")
```

See `AlphaGalTrait/README_API.txt` for the full compatibility API, including contamination and vomiting hooks.

## ⚙️ Sandbox options

The mod currently includes settings for:

- Mild reaction chance
- Moderate reaction chance
- Severe reaction chance
- Reaction delay
- Severe reaction length
- Exposure decay per hour

The defaults are meant to make small amounts risky without guaranteeing a reaction, while a full red-meat serving is a serious threat.

## 📦 Installation

Download the latest release ZIP and extract the `AlphaGalTrait` folder into your Project Zomboid `mods` folder, then enable **Alpha Gal Trait** in the Mods menu.

## Current version

**1.0**
