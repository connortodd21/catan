class_name PortDeck
extends Resource

@export var ports : Array[PortIconDefinition] = []

func get_def(port_type: PortTypes.Type) -> PortIconDefinition:
	for port_def in ports:
		if port_def.resource_type == port_type:
			return port_def
	return null
