-- Dota Royale Game Mode

if DotaRoyale == nil then
	DotaRoyale = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate
function Activate()
	GameRules.DotaRoyale = DotaRoyale()
	GameRules.DotaRoyale:InitGameMode()
end

function DotaRoyale:InitGameMode()
	print( "Dota Royale is loaded." )
	
	-- Set game rules
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 1 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 1 )
	GameRules:SetHeroRespawnEnabled( false )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetPreGameTime( 10.0 )
	GameRules:SetStrategyTime( 0.0 )
	GameRules:SetShowcaseTime( 0.0 )
	
	-- Define spawn zones for each player based on map coordinates
	self.SpawnZones = {
		-- Player 1 (Radiant) spawn zone - bottom area where they can deploy units
		[DOTA_TEAM_GOODGUYS] = {
			min = Vector(-2500, -3392, 128),  -- Bottom-left corner of spawn area
			max = Vector(2958, -1500, 128)    -- Top-right corner of spawn area
		},
		-- Player 2 (Dire) spawn zone - top area where they can deploy units
		[DOTA_TEAM_BADGUYS] = {
			min = Vector(-3058, 1500, 128),   -- Bottom-left corner of spawn area
			max = Vector(2958, 3392, 128)     -- Top-right corner of spawn area
		}
	}
	
	-- Register custom events
	CustomGameEventManager:RegisterListener("dota_royale_spawn_unit", Dynamic_Wrap(DotaRoyale, "OnSpawnUnit"))
	
	-- Listen for game state changes
	ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(DotaRoyale, "OnGameRulesStateChange"), self)
	
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
end

function DotaRoyale:OnGameRulesStateChange(keys)
	local newState = GameRules:State_Get()
	print("Game state changed to: " .. newState)
	
	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		print("Pre-game phase started")
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		print("Game started!")
	end
end

-- Check if a position is valid for spawning for a given team
function DotaRoyale:IsValidSpawnPosition(position, teamID)
	if not self.SpawnZones[teamID] then
		return false
	end
	
	local zone = self.SpawnZones[teamID]
	
	-- Check if position is within the spawn zone boundaries
	if position.x >= zone.min.x and position.x <= zone.max.x and
	   position.y >= zone.min.y and position.y <= zone.max.y then
		return true
	end
	
	return false
end

-- Handle spawn unit request from client
function DotaRoyale:OnSpawnUnit(eventData)
	print("OnSpawnUnit called")
	PrintTable(eventData)
	
	local playerID = eventData.PlayerID
	local heroName = eventData.hero_name
	local posX = eventData.x
	local posY = eventData.y
	local posZ = eventData.z or 128
	
	local player = PlayerResource:GetPlayer(playerID)
	if not player then
		print("Player not found")
		return
	end
	
	local teamID = PlayerResource:GetTeam(playerID)
	local spawnPosition = Vector(posX, posY, posZ)
	
	-- Validate spawn position
	if not self:IsValidSpawnPosition(spawnPosition, teamID) then
		print("Invalid spawn position for team " .. teamID)
		-- Send error message to client
		CustomGameEventManager:Send_ServerToPlayer(player, "dota_royale_spawn_error", {
			error = "Invalid spawn location"
		})
		return
	end
	
	-- Spawn the hero unit
	local unit = CreateUnitByName(heroName, spawnPosition, true, nil, nil, teamID)
	if unit then
		print("Unit spawned: " .. heroName .. " at position " .. tostring(spawnPosition))
		unit:SetControllableByPlayer(playerID, true)
		unit:SetOwner(player:GetAssignedHero())
		
		-- Make unit auto-attack move towards enemy base
		local moveTarget = self:GetEnemyBasePosition(teamID)
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = moveTarget,
			Queue = false
		})
	else
		print("Failed to spawn unit: " .. heroName)
	end
end

-- Get enemy base position for auto-attack move
function DotaRoyale:GetEnemyBasePosition(teamID)
	if teamID == DOTA_TEAM_GOODGUYS then
		return Vector(0, 3392, 195)  -- Move towards Dire side (top)
	else
		return Vector(0, -3392, 195) -- Move towards Radiant side (bottom)
	end
end

-- Evaluate the state of the game
function DotaRoyale:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		-- Game logic here
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end