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
(Optional) Drop bis_data.lua alongside it to enable the BiS override pass — items on a spec's BiS/Alt list will route to that spec ahead of pure stat-weight comparison. Regenerate from upstream with `python3 tools/build_bis_data.py` (pulls from lgallucci/LoonBestInSlot WotLK + TBC branches).
(Optional) Edit MASTER_WEIGHTS at the top of the file to tune your scaling.
Reload Eluna or restart your worldserver.


**HIGHLY EXPLOITABLE**


Strongly recommend only using it with Playerbots/Friends, not really for public use, will introduce more safety checks and options later.
