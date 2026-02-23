class_name TerrainTypes

enum Type {
	WOOD,
	BRICK,
	SHEEP,
	WHEAT,
	ROCK,
	DESERT,
	WATER,
	FISH_2_3_11_12,
	FISH_4_10,
	GOLD,
	FOG
}


static var tile_type_to_str = { 
	Type.WOOD: "Wood",
	Type.BRICK: "Brick",
	Type.SHEEP: "Sheep",
	Type.WHEAT: "Wheat",
	Type.ROCK: "Rock",
	Type.DESERT: "Desert",
	Type.WATER: "Water",
	Type.FISH_2_3_11_12: "Fish_2_3_11_12",
	Type.FISH_4_10: "Fish_4_10",
	Type.GOLD: "Gold",
	Type.FOG: "Fog"
}


static func type_to_str(terrainType: Type) -> String:
	if terrainType in tile_type_to_str.keys():
		return tile_type_to_str[terrainType]
	return ""
