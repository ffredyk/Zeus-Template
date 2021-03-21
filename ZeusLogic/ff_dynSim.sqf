//---------- FUNCTION
//* Main module function
fnc_zeus_dynsim =
{
	// Get all the passed parameters
	params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]];

	//Not used on any object
	if(isNull _objectUnderCursor) then
	{
		_rangePretty = ["50m","100m", "300m", "500m", "1000m", "1500m"];
		_rangeVals = [50,100,300,500,1000,1500];
		[
			"Dynamic Simulation",
			[
				["Combo", "Range", [_rangeVals,_rangePretty,0]],
				["Checkbox", ["Toggle dynamic simulation?", "When enabled, selected entities are simulated only when at certain distance from wake-enabled entities"], true],
				["Toolbox", ["Filter", "Which objects should the function affect?"], [0, 3, 3, ["Units", "Vehicles", "Objects", "Units/Vehicles", "Vehicles/Objects", "Units/Objects", "All"]]],
				["Checkbox", ["Include crew?", "Will iterate through vehicle crews"], true]
			],
			{
				(_this #0) params ["_range", "_on", "_picks", "_crew"]; //Dialog params
				(_this #1) params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]]; //Module params

				_filters =
				[
					["Man"],
					["LandVehicle", "Ship", "Air"],
					["Thing"],
					["Man", "LandVehicle", "Ship", "Air"],
					["LandVehicle", "Ship", "Air", "Thing"],
					["Man", "Thing"],
					["Man", "LandVehicle", "Ship", "Air", "Thing"]
				] select _picks;

				//Find all units in range and change dynsim
				_count = ([((nearestObjects [_position, _filters, _range]) - [player]), _on, _crew] call fnc_zeus_dynsim_logic) #0;

				//debug
				hint format ["nearestObjects %1", [_position, _filters, _range]];
				copyToClipboard format ["nearestObjects %1", [_position, _filters, _range]];

				//Info message
				[objNull, format ["DynSim %1 for %2 %3 (range: %4m)", 
					["off", "on"] select _on, 
					_count,
					["entity", "entities"] select (_count > 1),
					_range
				]] call BIS_fnc_showCuratorFeedbackMessage;
			},
			{},
			_this
		] call zen_dialog_fnc_create;
	}
	else //Dropped on object
	{
		_veh = vehicle _objectUnderCursor;
		_enable = !dynamicSimulationEnabled _veh;
		if(_veh isKindOf "Man") then 
		{
			(group _veh) enableDynamicSimulation _enable;
			_count = count (units (group _veh));

			[objNull, format ["DynSim %1 for %2 %3", 
				["off", "on"] select _enable, 
				_count,
				["entity", "entities"] select (_count > 1)
			]] call BIS_fnc_showCuratorFeedbackMessage;
		}
		else
		{
			_veh enableDynamicSimulation _enable;

			[objNull, format ["DynSim %1 for vehicle", 
				["off", "on"] select _enable
			]] call BIS_fnc_showCuratorFeedbackMessage;
		}
	}
};

//* Object parse logic
fnc_zeus_dynsim_logic =
{
	params [
		["_objects", [], [[]]],
		["_on", true, [true]],
		["_crew", true, [true]]
	];

	//Find all units in range and change dynsim
	_knownGroups = [];
	_count = 0;
	{
		if(_x isKindOf "Man") then //Unit
		{
			if(!((group _x) in _knownGroups)) then
			{
				(group _x) enableDynamicSimulation _on;
				_count = _count + (count units group _x);
				_knownGroups pushBack (group _x);
			};
		}
		else //Vehicle
		{
			//Change dynsim for the vehicle
			(_x) enableDynamicSimulation _on;
			_count = _count + 1;

			//Find crew
			if(_x isKindOf "AllVehicles" && _crew) then
			{
				//Gather all groups
				_groups = [];
				{
					_groups pushBack (group _x);
				} forEach crew _x;
				_groups = _groups arrayIntersect _groups; //Remove duplicates

				//Manage dynsim for each group inside the vehicle
				{
					(_x) enableDynamicSimulation _on;
					_count = _count + (count units _x);
				} forEach _groups;
			}
		};
	} forEach _objects;

	//Return: Count of objects & List of groups
	[_count, _knownGroups];
};


//---------- MODULE
["[FE] AI", "Dynamic Simulation", 
{
	_this call fnc_zeus_dynsim;
}] call zen_custom_modules_fnc_register;


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