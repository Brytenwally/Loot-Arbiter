**LootArbiter**

Automated Loot Distribution for Eluna
LootArbiter identifies player specializations and automatically moves loot to the person receiving the largest stat upgrade.

***Requires Azerothcore and Azerothcore ALE***


**Core Features**


Auto-Spec Detection: Detects roles via talents and stats (e.g., Cat vs. Bear, Ele vs. Enh).  
Smart Scoring: Uses custom stat weights to calculate the best "Improvement Score" for gear.  
Forge-Safe: Implements a 200ms transfer delay to prevent crashes with Lichforged/Titanforged systems. 
Safety Filters: Blocks illogical transfers, such as 2H weapons going to Shield-based specs.  


**Setup**


Drop Loot Arbiter.lua into your lua_scripts folder.
(Optional) Edit MASTER_WEIGHTS at the top of the file to tune your scaling.
Reload Eluna or restart your worldserver.


**HIGHLY EXPLOITABLE**


Strongly recommend only using it with Playerbots/Friends, not really for public use, will introduce more safety checks and options later.
