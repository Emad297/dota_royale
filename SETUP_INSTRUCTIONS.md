# Dota Royale - Drag & Drop Spawning System Setup

## Directory Structure

Your project is now properly organized for Dota 2 Workshop Tools:

```
dota_royale/
├── content/
│   └── dota_addons/
│       └── dota_royale/
│           ├── maps/           # Your .vmap files
│           ├── materials/      # Source textures (.tga, .psd, etc.)
│           └── particles/      # Particle effect files
├── game/
│   ├── panorama/              # UI files (XML, CSS, JS)
│   ├── resource/              # Localization and UI config
│   └── scripts/
│       ├── npc/               # Hero/item/ability definitions
│       └── vscripts/          # Lua game logic
└── .gitignore
```

**Junctions Created:**
- `D:\SteamLibrary\...\content\dota_addons\dota_royale` → Your content folder
- `D:\SteamLibrary\...\game\dota_addons\dota_royale` → Your game folder

## What Has Been Implemented

### 1. Server-Side (Lua)
**File: `game/scripts/vscripts/addon_game_mode.lua`**

- Game mode class renamed from `CAddonTemplateGameMode` to `DotaRoyale`
- Set up 1v1 game (1 player per team)
- Defined spawn zones for both players:
  - **Radiant (DOTA_TEAM_GOODGUYS)**: X: -1000 to 1000, Y: -2000 to -500
  - **Dire (DOTA_TEAM_BADGUYS)**: X: -1000 to 1000, Y: 500 to 2000
- Spawn validation system - checks if player is placing units in their allowed zone
- Auto-attack move - spawned units automatically move toward enemy base
- Custom event listener: `dota_royale_spawn_unit`

### 2. Client-Side (Panorama UI)
**Files Created:**
- `game/panorama/layout/custom_game/dota_royale_hud.xml` - UI structure
- `game/panorama/styles/custom_game/dota_royale_hud.css` - Styling
- `game/panorama/scripts/custom_game/dota_royale_hud.js` - Drag & drop logic

**Features:**
- Skill bar at bottom of screen with hero cards
- 4 default heroes: Axe, Crystal Maiden, Juggernaut, Pudge
- Click and drag hero cards
- Visual feedback during dragging
- Converts screen position to world position
- Sends spawn request to server
- Error notifications if spawn fails

### 3. UI Configuration
**File: `game/resource/flash3/custom_ui.txt`**
- Registered the custom Panorama HUD

## What You Need to Do

### Step 1: Adjust Spawn Zone Coordinates
Open `game/scripts/vscripts/addon_game_mode.lua` and find the `SpawnZones` definition (around line 37).

**You need to:**
1. Go into your map editor and note down the world coordinates for:
   - Player 1's spawn area (bottom half of their side of the arena)
   - Player 2's spawn area (bottom half of their side of the arena)
2. Update the `min` and `max` Vector values for both teams

**To find coordinates in Hammer:**
- Click on the map at the corner points
- Look at the bottom status bar for X, Y, Z coordinates
- The spawn zones should cover roughly the bottom third to half of each player's side

Example:
```lua
self.SpawnZones = {
    [DOTA_TEAM_GOODGUYS] = {
        min = Vector(-800, -2500, 128),  -- Your actual bottom-left corner
        max = Vector(800, -1000, 128)    -- Your actual top-right corner
    },
    [DOTA_TEAM_BADGUYS] = {
        min = Vector(-800, 1000, 128),   -- Your actual bottom-left corner
        max = Vector(800, 2500, 128)     -- Your actual top-right corner
    }
}
```

### Step 2: Test the Game
1. Launch Dota 2 Workshop Tools
2. Open your addon in the Workshop Tools
3. Press F5 or click "Launch Dota" to test
4. Start a game with 2 players (or use test mode)

### Step 3: What to Look For
When testing, you should see:
- A dark skill bar at the bottom of the screen
- 4 hero cards (Axe, Crystal Maiden, Juggernaut, Pudge) with portraits
- Click and drag a hero card onto the map
- If you place it in your spawn zone, a hero should spawn there
- If you place it outside your zone, you'll see an error message
- Spawned heroes should automatically move toward the enemy base

### Step 4: Console Debugging
Open the console (`) and look for messages:
- "Dota Royale is loaded." - Server started
- "Dota Royale HUD Initialized" - UI loaded
- "Card clicked: npc_dota_hero_X" - When you click a card
- "Attempting to spawn at: X, Y, Z" - When you release
- "Unit spawned: X at position Y" - Success
- "Invalid spawn position for team X" - Out of bounds

### Step 5: Optional Map Setup
For visual clarity in the map editor, you might want to:
1. Add different colored tiles or textures to clearly mark spawn zones
2. Add walls or barriers at the spawn zone boundaries
3. Add spawn point entities for the player heroes (one for each team)

## How the System Works

1. **Player clicks** a hero card in the UI
2. **Player drags** cursor to desired location on the map
3. **Player releases** mouse button
4. **Client** converts screen coordinates to world position using `Game.ScreenXYToWorld()`
5. **Client** sends custom event `dota_royale_spawn_unit` to server with position and hero name
6. **Server** validates the position is within player's spawn zone
7. **Server** spawns the hero unit at that position
8. **Server** issues attack-move command toward enemy base
9. Unit automatically engages enemies as it moves

## Next Steps (Future Features)
After this is working, we can add:
- Mana/cost system for spawning heroes
- Cooldowns for hero cards
- More heroes with different roles
- Health bars for towers/bases
- Win/lose conditions
- Elixir regeneration (like Clash Royale)
- Visual spawn zone boundaries on the map
- Better drag preview (ghost unit following cursor)

## Troubleshooting

**If UI doesn't appear:**
- Check console for errors
- Make sure custom_ui.txt is properly formatted
- Verify file paths are correct

**If spawning doesn't work:**
- Check console for "Invalid spawn position" messages
- Verify spawn zone coordinates match your map
- Make sure you're testing with correct team assignment

**If heroes spawn but don't move:**
- Check that enemy base position coordinates are correct
- Verify hero AI is not disabled in game mode settings

