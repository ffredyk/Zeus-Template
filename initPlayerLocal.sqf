_zeusName = toArray str player;
_zeusName resize 4;
_zeusName = toString _zeusName;
if(_zeusName == "zeus") then
{
	[] execVM "initZeus.sqf";
};

waitUntil {local player && {getClientStateNumber > 8}}; //In mission

fnc_surviveAnticrash =
{
	params [
		["_data", createHashMap]
	];

	player setPosASL (_data get "POS");
	player setDir (_data get "DIR");
	player setUnitLoadout (_data get "LOADOUT");
};

player setVariable ["PNAME", profileName, true];
[player] remoteExec ["fnc_queryAnticrash",2];