Alpha Gal Trait - compatibility API

Build target: Project Zomboid 42.20+

Custom red meat
===============
Load the API from shared Lua and register your item's full type:

require "AlphaGal/AlphaGalAPI"
AlphaGalAPI.registerRedMeat("MyMod.BisonSteak", 1.0)

The second value is trigger strength. 1.0 is a normal full red-meat serving. A value of 0.5 is half as strong.

If a custom item looks like red meat to the automatic classifier but should never trigger Alpha Gal:

AlphaGalAPI.registerWhiteMeat("MyMod.SpecialChicken")

Crafted food
============
Evolved recipes and legacy recipes are handled automatically.

For a Build 42 craftRecipe with its own OnCreate callback, call this after the recipe creates its output:

require "AlphaGal/AlphaGalAPI"
AlphaGalAPI.propagateCraftRecipe(craftRecipeData)

You can also set or read contamination directly:

AlphaGalAPI.setContamination(foodItem, 1.0)
local amount = AlphaGalAPI.getContamination(foodItem)

alphaGalContamination is stored in the food item's modData and represents the exposure contained in the entire item. Eating 25% of an item carrying 1.0 contamination gives 0.25 exposure.

Vomiting compatibility
======================
The base mod does not force a vomiting animation. A mod with its own vomiting system can register a handler with AlphaGalAPI.registerVomitingHandler(handler). The handler receives the player and either "moderate" or "severe" as the severity string.
