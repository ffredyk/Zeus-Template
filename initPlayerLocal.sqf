_zeusName = toArray str player;
_zeusName resize 4;
_zeusName = toString _zeusName;
if(_zeusName == "zeus") then
{
	[] execVM "initZeus.sqf";
};

waitUntil {local player && {getClientStateNumber > 8}}; //In mission