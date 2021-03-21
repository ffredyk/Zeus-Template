if (!isClass(configFile >> "CfgPatches" >> "zen_common")) then {hint "This mission utilizes Zeus Enhanced addon. Your client does not have this addon loaded"} //Addon check
else
{
	[] execVM "ZeusLogic\ff_dynSim.sqf"; //Dynamic Simulation add-ins
	[] execVM "ZeusLogic\ff_utils.sqf"; //Utils add-ins
	[] execVM "ZeusLogic\ff_queries.sqf"; //Query logic system add-ins
};

fnc_zeusMessage = 
{
	params [
		["_message", "", [""]],
		["_type", 0, [0]]
	];

	switch (_type) do {
		case 0: { [objNull, _message] call BIS_fnc_showCuratorFeedbackMessage};
		default { hint parseText _message };
	};
};