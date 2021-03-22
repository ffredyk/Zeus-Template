//----------------- Crash revive logic
var_anticrashPlayers = createHashMap;
[] spawn
{
	while {true} do
	{
		sleep 5;

		{
			if(alive _x) then
			{
				var_anticrashPlayers set [getPlayerUID _x,
					createHashMapFromArray [
						["POS", getPosASL _x],
						["DIR", getDir _x],
						["LOADOUT", getUnitLoadout _x],
						["LASTUPDATE", diag_tickTime]
					]
				];
			};
		} forEach allPlayers;
	};
};

fnc_queryAnticrash =
{
	params [
		["_player", objNull, [objNull]]
	];

	_data = var_anticrashPlayers getOrDefault [getPlayerUID _player, createHashMapFromArray [["LASTUPDATE", 0]]];
	_howLong = diag_tickTime - (_data get "LASTUPDATE");

	if(_howLong < (1000* 60* 10)) then
	{
		_query = createHashMapFromArray [
			["TYPE", 1],
			["NAME", format ["Player %1 return after crash", _player getVariable ["PNAME", "No-name"]]],
			["TEXT", format ["Player %1 crashed more than 10 minutes ago, system cancelled his automatic after-crash teleport to prevent unwanted behaviour.<br>Press SPACE to respond to his ping", _player getVariable ["PNAME", "No-name"]]]
		]; 

		[_query] remoteExec ["fnc_zeus_query_add", 0];
	}
	else
	{
		[_data] remoteExec ["fnc_surviveAnticrash", _player];
	};
};