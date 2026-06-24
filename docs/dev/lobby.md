# Lobby Design

## Overview

When a host clicks "Host Game" they are taken to a lobby screen where they configure
the game and wait for players to join via a room code. Joiners enter the code from
the main menu and land on the same lobby screen in a read-only config state.

## Room Code

- 6-character alphanumeric (A-Z, 0-9), randomly generated on lobby creation
- Stored as Steam lobby metadata: `Steam.setLobbyData(lobby_id, "code", code)`
- Joiners search via `Steam.addRequestLobbyDataFilter("code", code)` + `Steam.requestLobbyList()`
- No collision detection — 36^6 (~2 billion) combinations makes collisions negligible at friend-group scale

## Steam Lobby Settings

| Setting | Value |
|---|---|
| Lobby type | `LOBBY_TYPE_PUBLIC` (required for code-based search) |
| Max members | 4 |
| Destroyed when | Host disconnects (Steam handles automatically) |

## Join Flow

```
Host clicks "Host Game"
  → lobby_manager creates Steam lobby
  → lobby_manager generates room code, sets as lobby metadata
  → Lobby scene opens, room code displayed at top

Joiner clicks "Join Game"
  → Inline dialog on main menu: text field + Join button
  → lobby_manager calls requestLobbyList with code filter
  → "Connecting..." animation shown while searching
  → On lobby found: join it, transition to Lobby scene
  → On not found / error: show error message, return to main menu
```

## Lobby Screen Layout

```
┌─────────────────────────────────────────────────────────┐
│  < BACK          LOBBY            Code: K7X2MQ  [Copy]  │
├──────────────────┬──────────────────────────────────────┤
│  PLAYERS         │                                       │
│  ┌────────────┐  │         GameConfigPanel               │
│  │ Bob  🟥    │  │    (host interactive, clients locked) │
│  │ Alice   🟦 │  │                                       │
│  │ ...        │  │                                       │
│  └────────────┘  │                                       │
│                  │                                       │
│  [  START GAME  ]│                                       │
│  (host only)     │                                       │
└──────────────────┴──────────────────────────────────────┘
```

- Each player row: editable name + color swatch (own row only)
- Start button visible to all, enabled for host only (min 2 players + board selected)
- Back button: leave lobby, return to main menu

## Player Identity on Join

- Name: defaults to Steam persona name; if taken, append incrementing number (e.g. `Connor2`)
- Color: auto-assigned to first available color in palette order
- Players can change their own name and color freely after joining
- Changes are broadcast to all lobby members in real time via lobby metadata

## Color Rules

- First come first served — color is claimed when a player joins
- A player can switch to any unclaimed color
- No two players can hold the same color at the same time
- If a player leaves, their color is freed immediately

## Real-Time Config Sync

When the host changes board, expansions, house rules, or victory points:
1. Host serializes the current config to JSON
2. Host calls `Steam.setLobbyData(lobby_id, "config", json_string)`
3. All clients receive `lobby_data_update` signal
4. Clients deserialize and refresh their GameConfigPanel display

## Disconnection Handling

- **Joiner disconnects**: removed from player list, color freed, host notified
- **Host disconnects**: Steam destroys the lobby; all clients receive disconnect signal, return to main menu with message "Host left the lobby"
- **Connecting animation**: shown on joiner side from "Join" press until lobby entry confirmed or error

## Lobby Metadata Keys

| Key | Value | Set by |
|---|---|---|
| `code` | 6-char alphanumeric room code | Host on creation |
| `config` | JSON-serialized game config | Host on any config change |
| `player_{index}_name` | Player display name | Each player |
| `player_{index}_color` | Player color enum int | Each player |

## New Files

| File | Purpose |
|---|---|
| `scripts/networking/lobby_manager.gd` | Steam lobby create/join/leave, code generation, metadata sync |
| `scripts/networking/lobby.gd` | Lobby screen UI logic |
| `scenes/lobby.tscn` | Lobby scene (PlayerPanel + GameConfigPanel) |

## Modified Files

| File | Change |
|---|---|
| `scripts/scenes/main/main.gd` | Wire Host/Join buttons to lobby flow |
| `scenes/main.tscn` | Add join dialog (text field + button) |
