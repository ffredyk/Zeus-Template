//---------- FUNCTION
//* Main module function
fnc_zeus_respawnPlayers =
{
	// Get all the passed parameters
	params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]];

	
	[
		"Respawn Players",
		[
			["Owners", "Who to respawn?", [[blufor],[],[],2]]
		],
		{
			(_this #0) params ["_who"]; //Dialog params
			(_this #1) params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]]; //Module params

			_count = 0;

			//Hold dead units
			_dead = (allDeadMen apply {if(isPlayer _x) then {_x} else {objNull}}) - [objNull]; //Filter only players
			_filtered = [];

			{
				_unit = _x;

				//Sides
				{
					if(side _unit == _x) then {_filtered pushBack _unit};
				} forEach (_who #0);

				//Groups
				{
					if(group _unit == _x) then {_filtered pushBack _unit};
				} forEach (_who #1);
			} forEach _dead;

			//Units
			_filtered append (_who #2);

			//Broadcast command to force respawn
			{
				[1] remoteExec ["setPlayerRespawnTime", _x];
			} forEach _filtered;
			
			//Info message
			[objNull, format ["Respawn forced on %1 dead players", 
				_count
			]] call BIS_fnc_showCuratorFeedbackMessage;
		},
		{},
		_this
	] call zen_dialog_fnc_create;
};

//---------- MODULE
["[FE] Mission", "Force player respawn", 
{
	_this call fnc_zeus_respawnPlayers;
}] call zen_custom_modules_fnc_register;

/*
//---------- CONTEXT MENU
//* Wrapper
[
	[
		"FE_DynSim",
		"Dynamic Simulation",
		"",
		{}
	] call zen_context_menu_fnc_createAction,
	[],0
] call zen_context_menu_fnc_addAction;

//* Sub-item
[
	[
		"FE_DynSim_Object",
		"Toggle for selected",
		"",
		{
			//Context params
			params [["_position", [0,0,0], [[]]], ["_selObjects", [], [[]]], ["_selGroups", [], [[]]], ["_selWaypoints", [], [[]]], ["_selMarkers", [], [[]]], ["_hover", objNull, [objNull, grpNull, [], ""]], ["_args", [], [[]]]];

			//Sanity check - one non-dynsim unit corrupts entire selected pool
			_toggle = ({!dynamicSimulationEnabled _x} count (_selObjects arrayIntersect _selGroups) != 0);

			[
				"Dynamic simulation",
				[
					["Checkbox", ["Toggle dynamic simulation?", "When enabled, selected entities are simulated only when at certain distance from wake-enabled entities"], _toggle],
					["Checkbox", ["Include crew?", "Will iterate through vehicle crews"], true]
				],
				{
					(_this #0) params ["_on", "_crew"]; //Dialog params
					(_this #1) params [["_position", [0,0,0], [[]]], ["_selObjects", [], [[]]], ["_selGroups", [], [[]]], ["_selWaypoints", [], [[]]], ["_selMarkers", [], [[]]], ["_hover", objNull, [objNull, grpNull, [], ""]], ["_args", [], [[]]]]; //Context params


					//Find all units in range and change dynsim
					_ret = [_selObjects, _on, _crew] call fnc_zeus_dynsim_logic;
					_count = _ret #0;

					//Change all selected groups aswell (if they weren't affected in the first iteration)
					{
						_x enableDynamicSimulation _on;
						_count = _count + (count units _x);
					} forEach (_selGroups - (_ret #1)); //Remove groups affected in the first iteration


					//Info message
					[objNull, format ["DynSim %1 for %2 %3", 
						["off", "on"] select _on, 
						_count,
						["entity", "entities"] select (_count > 1)
					]] call BIS_fnc_showCuratorFeedbackMessage;
				},
				{},
				_this
			] call zen_dialog_fnc_create;
		},
		{
			//Check: No unit/group selected and no hover
			_all = (_this #1) + (_this #2);
			count _all > 0 || !isNull (_this #5)
		}
	] call zen_context_menu_fnc_createAction,
	["FE_DynSim"],0
] call zen_context_menu_fnc_addAction;

//* Sub-item
[
	[
		"FE_DynSim_Range",
		"Toggle in range",
		"",
		{
			//Context args
			params [["_position", [0,0,0], [[]]], ["_selObjects", [], [[]]], ["_selGroups", [], [[]]], ["_selWaypoints", [], [[]]], ["_selMarkers", [], [[]]], ["_hover", objNull, [objNull, grpNull, [], ""]], ["_args", [], [[]]]];

			[_position, objNull] call fnc_zeus_dynsim;
		},
		{true}
	] call zen_context_menu_fnc_createAction,
	["FE_DynSim"],0
] call zen_context_menu_fnc_addAction;
*/