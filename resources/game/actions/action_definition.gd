class_name ActionDefinition
extends Resource

@export var id: ActionTypes.Type

## Resource cost to perform this action. Maps ResourceTypes.Type → int.
## Empty means free (e.g. setup placements).
@export var base_cost: Dictionary[ResourceTypes.Type, int] = {}

## Where on the board the player clicks to execute this action.
@export var placement: PlacementType.Type = PlacementType.Type.NONE

## Which turn phases this action is available in.
@export var phases: Array[GamePhase.Phase] = []
