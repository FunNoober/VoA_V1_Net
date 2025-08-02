# VoA_V1_Net
The code for the first iteration of Violence of Action. This repo does not include models, sounds, textures, occlusion information, light map information, or any other non-code assets. Any and all personal information has been anonymized.

I feel comfortable sharing this because the code is outdated, and built around a more fragile architecture, along with not reflecting the current state of the singleplayer or multiplayer of this project.

**This is not enough to compile, or otherwise gain or generate a playable copy of the Violence of Action multiplayer**

Incorporating, or otherwise "copying" the code of this project directly into another project is prohibited. The code may be used for research and/or educational purposes, and/or to use as a point of reference when teaching.

## Architecture
The first iteration of Violence of Action relies very heavily on a peer-to-peer, non-server-authoritative architecture, leaving it open to cheaters, unauthorized modifications, and desync. The architecture is also built heavily around Godot's built in multiplayer nodes, such as the `MultiplayerSpawner` and `MultiplerSynchronizer` nodes.

Violence of Action V1 is also built with multiplayer-first, meaning that it is very difficult to extend the game to include a singleplayer.