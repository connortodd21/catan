class_name Player

enum Color { RED, BLUE, WHITE, ORANGE }

var player_name: String = ""
var color: Color = Color.RED

var resource_hand: Dictionary = {
	TerrainTypes.Type.WOOD: 0,
	TerrainTypes.Type.BRICK: 0,
	TerrainTypes.Type.SHEEP: 0,
	TerrainTypes.Type.WHEAT: 0,
	TerrainTypes.Type.ROCK: 0,
}

var settlements_remaining: int = 5
var cities_remaining: int = 4
var roads_remaining: int = 15
var victory_points: int = 0
