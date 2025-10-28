"use strict";

var DotaRoyaleHUD = (function() {
	var isDragging = false;
	var draggedCard = null;
	var draggedHeroName = "";
	
	// Available heroes for spawning (start with just a few)
	var availableHeroes = [
		{ name: "npc_dota_hero_axe", displayName: "Axe" },
		{ name: "npc_dota_hero_crystal_maiden", displayName: "Crystal Maiden" },
		{ name: "npc_dota_hero_juggernaut", displayName: "Juggernaut" },
		{ name: "npc_dota_hero_pudge", displayName: "Pudge" }
	];
	
	function Initialize() {
		$.Msg("Dota Royale HUD Initialized");
		
		// Create hero cards
		CreateHeroCards();
		
		// Register for custom game events
		GameEvents.Subscribe("dota_royale_spawn_error", OnSpawnError);
		
		// Set up mouse event listeners
		GameUI.SetMouseCallback(OnMouseEvent);
	}
	
	function CreateHeroCards() {
		var container = $("#HeroCardsContainer");
		if (!container) {
			$.Msg("Error: HeroCardsContainer not found");
			return;
		}
		
		// Clear existing cards
		container.RemoveAndDeleteChildren();
		
		// Create a card for each hero
		for (var i = 0; i < availableHeroes.length; i++) {
			var hero = availableHeroes[i];
			CreateHeroCard(container, hero);
		}
	}
	
	function CreateHeroCard(container, hero) {
		var card = $.CreatePanel("Panel", container, "HeroCard_" + hero.name);
		card.AddClass("HeroCard");
		card.SetAttributeString("hero_name", hero.name);
		card.SetPanelEvent("onmouseactivate", function() {
			OnCardMouseDown(card, hero);
		});
		
		// Hero image
		var image = $.CreatePanel("DOTAHeroImage", card, "");
		image.AddClass("HeroCardImage");
		image.heroimagestyle = "icon";
		image.heroname = hero.name;
		
		// Hero name label
		var nameLabel = $.CreatePanel("Label", card, "");
		nameLabel.AddClass("HeroCardName");
		nameLabel.text = hero.displayName;
	}
	
	function OnCardMouseDown(card, hero) {
		$.Msg("Card clicked: " + hero.name);
		isDragging = true;
		draggedCard = card;
		draggedHeroName = hero.name;
		
		// Visual feedback
		card.AddClass("dragging");
		
		// Show spawn zone indicator
		var indicator = $("#SpawnZoneIndicator");
		if (indicator) {
			indicator.AddClass("active");
		}
	}
	
	function OnMouseEvent(eventName, arg) {
		if (eventName === "pressed") {
			// Mouse button pressed - handled by card click
		} else if (eventName === "released") {
			// Mouse button released - try to spawn
			if (isDragging) {
				OnCardDragEnd();
			}
		}
		
		return false; // Return false to allow default mouse handling
	}
	
	function OnCardDragEnd() {
		$.Msg("Drag ended");
		
		if (!isDragging || !draggedCard) {
			return;
		}
		
		// Get world position under cursor
		var mousePos = GameUI.GetCursorPosition();
		var worldPos = Game.ScreenXYToWorld(mousePos[0], mousePos[1]);
		
		if (worldPos && worldPos.length >= 3) {
			$.Msg("Attempting to spawn at: " + worldPos[0] + ", " + worldPos[1] + ", " + worldPos[2]);
			
			// Send spawn request to server
			GameEvents.SendCustomGameEventToServer("dota_royale_spawn_unit", {
				PlayerID: Players.GetLocalPlayer(),
				hero_name: draggedHeroName,
				x: worldPos[0],
				y: worldPos[1],
				z: worldPos[2]
			});
		} else {
			$.Msg("Could not get world position");
		}
		
		// Reset dragging state
		isDragging = false;
		if (draggedCard) {
			draggedCard.RemoveClass("dragging");
		}
		draggedCard = null;
		draggedHeroName = "";
		
		// Hide spawn zone indicator
		var indicator = $("#SpawnZoneIndicator");
		if (indicator) {
			indicator.RemoveClass("active");
		}
	}
	
	function OnSpawnError(data) {
		$.Msg("Spawn Error: " + data.error);
		
		// Show error notification to player
		GameEvents.SendEventClientSide("dota_hud_error_message", {
			splitscreenplayer: 0,
			reason: 80,
			message: data.error
		});
	}
	
	// Initialize when the panel loads
	(function() {
		$.Schedule(0.1, Initialize);
	})();
	
	return {
		Initialize: Initialize
	};
})();

