// ============================================================================
// LOGISTICS SYSTEM: SERVER RESPAWN DAEMON (V8 PER-PLAYER CLIENT DELEGATION)
// File: qm_serverRespawnManager.sqf
// Description: In V8, respawn position registration and cooldowns are managed
//              per-player on client machines via qm_clientRespawnManager.sqf
//              to support individual FOB cooldown timers and troop availability.
//              Server handles troop pool deductions and economy persistence.
// Called By: init.sqf (Executed during server initialization)
// ============================================================================

if (!isServer) exitWith {};

diag_log "[QUARTERMASTER]: Server Respawn Daemon initialized. Per-player client respawn engine active on clients.";
