class_name BoardCache

var tiles: TypedCache = TypedCache.new(Variant.Type.TYPE_VECTOR2I, TileMetadata)
var numbers: TypedCache = TypedCache.new(Variant.Type.TYPE_VECTOR2I, NumberMetadata)
var ports: TypedCache = TypedCache.new(Variant.Type.TYPE_VECTOR2I, PortMetadata)
