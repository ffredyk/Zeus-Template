var_zeus_curveMode = 0;

var_zeus_curves = [];

//---------- FUNCTION
//* Main module function
fnc_zeus_curve =
{
	// Get all the passed parameters
	params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]];
	_position set [2,0]; //fix?? ZEN supplies weird altitudes

	_curator = getAssignedCuratorLogic player;

	private _moduleGroup = createGroup sideLogic; 
	_logic = _moduleGroup createUnit ["Curve_F", _position, [], 0, "NONE"];
	(getAssignedCuratorLogic player) addCuratorEditableObjects [[_logic], false];

	if(isNil "eh_zeus_curve_edit") then 
	{
		eh_zeus_curve_edit = _curator addEventHandler ["CuratorObjectEdited", {
			params ["_curator", "_entity"];

			if(_entity isKindOf "Curve_F" || _entity isKindOf "Key_F") then
			{
				_logic = (_entity getVariable ["LOGIC", objNull]);
				_entity setVariable ["RELPOS", _logic worldToModel (getPosWorld _entity)];
				var_zeus_curve_lastLogic = _logic;
				_entity call fnc_zeus_curve_update;

				//if(_logic == _entity) then {_entity setDir 0};
			};
		}];
	};
	if(isNil "eh_zeus_curve_place") then 
	{
		eh_zeus_curve_place = _curator addEventHandler ["CuratorObjectPlaced", {
			params ["_curator", "_entity"];

			if(_entity isKindOf "Curve_F") then
			{
				deleteVehicle _entity;

				//Info message
				[objNull, "ERROR: Curves can be created only by using module"
				] call BIS_fnc_showCuratorFeedbackMessage;
			};
			if(_entity isKindOf "Key_F") then
			{
				[_entity] call fnc_zeus_curve_key;
			}
		}];
	};
	if(isNil "eh_zeus_curve_delete") then 
	{
		eh_zeus_curve_delete = _curator addEventHandler ["CuratorObjectDeleted", {
			params ["_curator", "_entity"];

			if(_entity isKindOf "Curve_F") then
			{
				_data = _entity getVariable ["DATA", createHashMap];

				{
					deleteVehicle _x;
				} forEach (_data getOrDefault ["KEYS", []]);
				{
					[_curator, _x] call BIS_fnc_removeCuratorIcon;
				} forEach (_data getOrDefault ["ICONS", []]);

				var_zeus_curves = var_zeus_curves - [_entity];
			};
			if(_entity isKindOf "Key_F") then
			{
				_logic = _entity getVariable ["LOGIC", objNull];
				_data = _logic getVariable ["DATA", createHashMap];

				_data set ["KEYS", (_data getOrDefault ["KEYS", []]) - [_entity]];
				_logic setVariable ["DATA", _data];
				_logic call fnc_zeus_curve_update;
			}
		}];
	};
	if(isNil "ren_zeus_curve") then 
	{
		ren_zeus_curve = addMissionEventHandler ["Draw3D", {
			_objects = curatorSelected #0;

			_logic = objNull;
			if(
				{
					_logic = (_x getVariable ["LOGIC", _logic]); 
					(_x isKindOf "Curve_F" || _x isKindOf "Key_F")
				} count _objects > 0
			) then
			{
				_data = _logic getVariable ["DATA", createHashMap];
				_keys = _data getOrDefault ["KEYS", []];
				_posArr = [];
				{
					_iterations = _x getVariable ["WEIGHT", 1];
					_pos = getPos _x;

					for "_i" from 0 to _iterations step 1 do
					{ _posArr pushBack _pos };
				} forEach _keys;

				_curve = ([getPos _logic] + _posArr);
				_prev = 0 bezierInterpolation _curve;
				for "_current" from 0 to 1 step (0.5/((count _posArr)+1)) do 
				{
					_pos = _current bezierInterpolation _curve;
					drawLine3D [_prev, _pos, [0,1,0,1]];
					_prev = _pos;
				};
			};
		}];
	};

	[
		"Create new curve",
		[
			["EDIT", "Name", ["Custom curve"]]
		],
		{
			(_this #0) params ["_name"]; //Dialog params
			(_this #1) params ["_logic", "_curator"];

			_icon = [_curator, ["IconCurve", [1,1,1,1], getPos _logic, 0.7,0.7,0, _name]] call BIS_fnc_addCuratorIcon;

			_curve = createHashMapFromArray [
				["NAME", _name],
				["LOGIC",_logic],
				["KEYS", []],
				["ICONS", [_icon]]
			];
			_logic setVariable ["DATA", _curve];
			_logic setVariable ["LOGIC", _logic];
			var_zeus_curves pushBack _logic;

			var_zeus_curve_lastLogic = _logic;
		},
		{
			deleteVehicle ((_this #1) #0);
		},
		[_logic,_curator]
	] call zen_dialog_fnc_create;
};

fnc_zeus_curve_update =
{
	_logic = _this getVariable ["LOGIC", objNull];
	_data = _logic getVariable ["DATA", createHashMap];

	_icons = _data getOrDefault ["ICONS", []];
	_keys = _data getOrDefault ["KEYS", []];

	if(isNull _logic) exitWith 
	{
		[_this] call fnc_zeus_curve_key;
		_this call fnc_zeus_curve_update;
	};

	_curator = getAssignedCuratorLogic player;

	{
		[_curator, _x] call BIS_fnc_removeCuratorIcon;
	} forEach _icons;

	_icons = [];
	_icons pushBack ([_curator, ["IconCurve", [1,1,1,1], getPos _logic, 0.7,0.7,0, _data getOrDefault ["NAME", "No name curve"]]] call BIS_fnc_addCuratorIcon);

	{
		if(_logic == _this) then {
			_relPos = _x getVariable ["RELPOS", [0,0,2]];
			_x setPosWorld (_logic modelToWorld _relPos);
		};

		_icons pushBack ([_curator, ["IconKey", [1,1,1,1], getPos _x, 0.7,0.7,0, str _forEachIndex]] call BIS_fnc_addCuratorIcon);
	} forEach _keys;

	_data set ["ICONS", _icons];
	_logic setVariable ["DATA", _data];
};

fnc_zeus_curve_key =
{
	params [
		["_key", objNull, [objNull]],
		["_logic", var_zeus_curve_lastLogic, [objNull]]
	];

	if(isNull _logic) exitWith
	{
		deleteVehicle _key;

		//Info message
		[objNull, "ERROR: No logic previously selected"
		] call BIS_fnc_showCuratorFeedbackMessage;
	};

	_data = _logic getVariable ["DATA", createHashMap];
	_keys = _data getOrDefault ["KEYS", []];
	_keys pushBack _key;
	_data set ["KEYS", _keys];
	_logic setVariable ["DATA", _data];

	_key setVariable ["LOGIC", _logic];
	_key setVariable ["RELPOS", _logic worldToModel (getPosWorld _key)];
	_key call fnc_zeus_curve_update;
};


//---------- MODULE
//* Create
["[FE] Curves", "Create curve", 
{
	_this call fnc_zeus_curve;
}] call zen_custom_modules_fnc_register;

//* Play
["[FE] Curves", "Play on curve", 
{
	// Get all the passed parameters
	params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]];

	fnc_zeus_curve_play = 
	{
		params [
			["_object", objNull, [objNull]],
			["_curve", [], [[]]],
			["_time", 1, [1]]
		];

		if(local _object) then
		{
			_start = time;

			_doshit = true;
			while {_doshit} do
			{
				_progress = [linearConversion [_start, _start + _time, time, 0, 1, true]] call BIS_fnc_smoothStep;
				_current = _progress bezierInterpolation _curve;
				_object setPosASL _current;

				if(_progress >= 1) then {_doshit = false};
			};
		};
	};

	publicVariable "fnc_zeus_curve_play";

	if(!isNull _objectUnderCursor) then
	{
		_pretties = [];
		{
			_pretties pushBack ((_x getVariable ["DATA", createHashMap]) getOrDefault ["NAME", "No name curve"]);
		} forEach var_zeus_curves;

		[
			"Select options",
			[
				["COMBO", "Select curve", [var_zeus_curves, _pretties, 0]],
				["EDIT", "Completion time (seconds)", ["1"]]
			],
			{
				(_this #0) params ["_logic", "_time"];
				(_this #1) params ["_pos", "_obj"];
				
				//Curve build
				_data = _logic getVariable ["DATA", createHashMap];
				_keys = _data getOrDefault ["KEYS", []];
				_posArr = [];
				{
					_iterations = _x getVariable ["WEIGHT", 1];
					_pos = getPosASL _x;

					for "_i" from 0 to _iterations step 1 do
					{ _posArr pushBack _pos };
				} forEach _keys;

				_curve = ([getPosASL _logic] + _posArr);

				//Command
				[_obj, _curve, parseNumber _time] remoteExec ["fnc_zeus_curve_play", _obj];
			},
			{},
			_this
		] call zen_dialog_fnc_create;
	}
	else
	{
		//Info message
		[objNull, "ERROR: Needs to be placed on object"
		] call BIS_fnc_showCuratorFeedbackMessage;
	};
}] call zen_custom_modules_fnc_register;



//---------- CONTEXT MENU
//* Wrapper
[
	[
		"FE_Curves",
		"Curves",
		"",
		{}
	] call zen_context_menu_fnc_createAction,
	[],0
] call zen_context_menu_fnc_addAction;

//* Sub-item
[
	[
		"FE_Curves_AddKey",
		"Create new key",
		"",
		{
			//Context params
			params [["_position", [0,0,0], [[]]], ["_selObjects", [], [[]]], ["_selGroups", [], [[]]], ["_selWaypoints", [], [[]]], ["_selMarkers", [], [[]]], ["_hover", objNull, [objNull, grpNull, [], ""]], ["_args", [], [[]]]];

			_relObj = _selObjects #0;
			_pos = _relObj modelToWorld [0,0,2];
			_logic = _relObj getVariable ["LOGIC", objNull];
			
			_key = (group _logic) createUnit ["Key_F", _pos, [], 0, "NONE"];
			(getAssignedCuratorLogic player) addCuratorEditableObjects [[_key], false];

			[_key, _logic] call fnc_zeus_curve_key;
		},
		{
			_all = (_this #1);
			{_x isKindOf "Curve_F" || _x isKindOf "Key_F"} count _all > 0
		}
	] call zen_context_menu_fnc_createAction,
	["FE_Curves"],0
] call zen_context_menu_fnc_addAction;


//--------- ATTRIBUTES
//* Key multiplier attribute
[
    "Object",
    "Key weight",
    "zen_attributes_slider",
    [1, 30, 0, false],
    {
        {
            _x setVariable ["WEIGHT", _value];
			_x call fnc_zeus_curve_update;
        } forEach (curatorSelected select 0);
    },
    {_this getVariable ["WEIGHT", 1]},
    {_this isKindOf "Key_F"}
] call zen_attributes_fnc_addAttribute;

//* Curve name
[
    "Object",
    "Curve name",
    "zen_attributes_edit",
    nil,
    {
        {
			_data = _x getVariable ["DATA", createHashMap];
			_data set ["NAME", _value];
            _x setVariable ["DATA", _data];
			_x call fnc_zeus_curve_update;
        } forEach (curatorSelected select 0);
    },
    {(_this getVariable ["DATA", createHashMap]) getOrDefault ["NAME", ""]},
    {_this isKindOf "Curve_F"}
] call zen_attributes_fnc_addAttribute;

/*
["",true,
	[
		["Name","","zen_attributes_edit",[],
		{
			["zen_common_setName", [_entity, _value]] call CBA_fnc_globalEvent;

			if (isClass (configFile >> "CfgPatches" >> "ace_common")) then {
			[_entity] call ace_common_fnc_setName;
			};
		},{name _entity},{alive _entity && {_entity isKindOf "CAManBase"}},0],["Skill","","zen_attributes_slider",[0.2,1,0.1,true],
		{
			{
			["zen_common_setSkill", [_x, _value], _x] call CBA_fnc_targetEvent;
			} forEach call zen_common_fnc_getSelectedUnits;
		},{skill _entity},{alive _entity && {!isNull group _entity && {side _entity != sideLogic}}},0],["Health / Armor","","zen_attributes_slider",[0,1,0.1,true],{
private _damage = 1 - _value;
{
_x setDamage _damage;
} forEach (curatorSelected select 0);
},{1 - damage _entity},{alive _entity},0],["Fuel","","zen_attributes_slider",[0,1,0.1,true],{
{
["zen_common_setFuel", [_x, _value], _x] call CBA_fnc_targetEvent;
} forEach call zen_common_fnc_getSelectedVehicles;
},{fuel _entity},{alive _entity && {getNumber (configOf _entity >> "fuelCapacity") > 0}},0],["Ammunition","","zen_attributes_slider",[0,1,0.1,true],{
{
[_x, _value] call zen_common_fnc_setVehicleAmmo;
} forEach call zen_common_fnc_getSelectedVehicles;
},{_entity call zen_common_fnc_getVehicleAmmo},{alive _entity && {_entity call zen_common_fnc_getVehicleAmmo != -1}},0],["Rank","","zen_attributes_icons",[[["PRIVATE","\a3\Ui_f\data\GUI\Cfg\Ranks\private_gs.paa","STR_Private",11.25,0.5,1.5],["CORPORAL","\a3\Ui_f\data\GUI\Cfg\Ranks\corporal_gs.paa","STR_Corporal",13.25,0.5,1.5],["SERGEANT","\a3\Ui_f\data\GUI\Cfg\Ranks\sergeant_gs.paa","STR_Sergeant",15.25,0.5,1.5],["LIEUTENANT","\a3\Ui_f\data\GUI\Cfg\Ranks\lieutenant_gs.paa","STR_Lieutenant",17.25,0.5,1.5],["CAPTAIN","\a3\Ui_f\data\GUI\Cfg\Ranks\captain_gs.paa","STR_Captain",19.25,0.5,1.5],["MAJOR","\a3\Ui_f\data\GUI\Cfg\Ranks\major_gs.paa","STR_Major",21.25,0.5,1.5],["COLONEL","\a3\Ui_f\data\GUI\Cfg\Ranks\colonel_gs.paa","STR_Colonel",23.25,0.5,1.5]]],{
{
_x setUnitRank _value;
} forEach call zen_common_fnc_getSelectedUnits;
},{rank _entity},{alive _entity && {_entity isKindOf "CAManBase"}},0],["Stance","","zen_attributes_icons",[[["DOWN","\a3\Ui_f\data\IGUI\RscIngameUI\RscUnitInfo\SI_prone_ca.paa","STR_A3_RscAttributeUnitPos_Down_tooltip",13.25,0,2.5],["MIDDLE","\a3\Ui_f\data\IGUI\RscIngameUI\RscUnitInfo\SI_crouch_ca.paa","STR_A3_RscAttributeUnitPos_Crouch_tooltip",15.75,0,2.5],["UP","\a3\Ui_f\data\IGUI\RscIngameUI\RscUnitInfo\SI_stand_ca.paa","STR_A3_RscAttributeUnitPos_Up_tooltip",18.25,0,2.5],["AUTO","\a3\ui_f_curator\Data\default_ca.paa","STR_A3_RscAttributeUnitPos_Auto_tooltip",24,0.5,1.5]]],{
{
["zen_common_setUnitPos", [_x, _value], _x] call CBA_fnc_targetEvent;
} forEach call zen_common_fnc_getSelectedUnits;
},{toUpper unitPos _entity},{alive _entity && {_entity isKindOf "CAManBase"}},0],["Lock","","zen_attributes_combo",[[[0,["STR_3DEN_Attributes_Lock_Unlocked_text","STR_3DEN_Attributes_Lock_Unlocked_tooltip"],"\a3\modules_f\data\iconunlock_ca.paa"],[1,["STR_3DEN_Attributes_Lock_Default_text","STR_3DEN_Attributes_Lock_Default_tooltip"],"\a3\ui_f_curator\Data\default_ca.paa"],[2,["STR_3DEN_Attributes_Lock_Locked_text","STR_3DEN_Attributes_Lock_Locked_tooltip"],"\a3\modules_f\data\iconlock_ca.paa"],[3,["STR_zen_attributes_LockedForPlayers","STR_3DEN_Attributes_Lock_LockedForPlayer_tooltip"],["\a3\modules_f\data\iconlock_ca.paa",[0.7,0.1,0,1]]]]],{
{
["zen_common_lock", [_x, _value], _x] call CBA_fnc_targetEvent;
} forEach call zen_common_fnc_getSelectedVehicles;
},{locked _entity},{alive _entity && {_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}}},0],["Engine","","zen_attributes_icons",[[[false,"\x\zen\addons\attributes\ui\engine_off_ca.paa","STR_zen_common_Off",14.5,0.25,2],[true,"\x\zen\addons\attributes\ui\engine_on_ca.paa","STR_zen_common_On",19.5,0.25,2]]],{
{
["zen_common_engineOn", [_x, _value], _x] call CBA_fnc_targetEvent;
} forEach call zen_common_fnc_getSelectedVehicles;
},{isEngineOn _entity},{alive _entity && {_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}}},0],["Lights","","zen_attributes_icons",[[[false,"\x\zen\addons\attributes\ui\lights_off_ca.paa","STR_zen_common_Off",14.5,0.25,2],[true,"\x\zen\addons\attributes\ui\lights_on_ca.paa","STR_zen_common_On",19.5,0.25,2]]],{
{
["zen_common_setPilotLight", [_x, _value], _x] call CBA_fnc_targetEvent;
["zen_common_setCollisionLight", [_x, _value], _x] call CBA_fnc_targetEvent;


private _driver = driver _x;

if !(isNull _driver || {isPlayer _driver}) then {
["zen_common_disableAI", [_x, "LIGHTS"], _x] call CBA_fnc_targetEvent;
};
} forEach call zen_common_fnc_getSelectedVehicles;
},{isLightOn _entity},{alive _entity && {_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}}},0],["Plate Number","","zen_attributes_edit",{_this select [0, 15]},{
["zen_common_setPlateNumber", [_entity, _value], _entity] call CBA_fnc_targetEvent;
},{getPlateNumber _entity},{alive _entity && {isClass (configOf _entity >> "PlateInfos")}},0],["Respawn Position","Selects the side that is able to respawn on this object.","zen_attributes_icons",[[[WEST,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnPosition\west_ca.paa","STR_West",11.5,0.25,2,[0,0.3,0.6,1],{playableSlotsNumber west > 0 && {[west, _entity call BIS_fnc_objectSide] call BIS_fnc_areFriendly}}],[EAST,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnPosition\east_ca.paa","STR_East",14.5,0.25,2,[0.5,0,0,1],{playableSlotsNumber east > 0 && {[east, _entity call BIS_fnc_objectSide] call BIS_fnc_areFriendly}}],[GUER,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnPosition\guer_ca.paa","STR_Guerrila",17.5,0.25,2,[0,0.5,0,1],{playableSlotsNumber independent > 0 && {[independent, _entity call BIS_fnc_objectSide] call BIS_fnc_areFriendly}}],[CIV,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnPosition\civ_ca.paa","STR_Civilian",20.5,0.25,2,[0.4,0,0.5,1],{playableSlotsNumber civilian > 0 && {[civilian, _entity call BIS_fnc_objectSide] call BIS_fnc_areFriendly}}],[EMPTY,"\a3\Ui_F_Curator\Data\default_ca.paa","STR_sensoractiv_none",24,0.5,1.5]]],{
private _respawnPos = _entity getVariable ["zen_attributes_respawnPos", []];
_respawnPos call BIS_fnc_removeRespawnPosition;

if (_value isEqualTo sideEmpty) then {
_entity setVariable ["zen_attributes_respawnPos", nil, true];
} else {
_respawnPos = [_value, _entity] call BIS_fnc_addRespawnPosition;
_entity setVariable ["zen_attributes_respawnPos", _respawnPos, true];
};
},{
_entity getVariable ["zen_attributes_respawnPos", []] param [0, sideEmpty]
},{alive _entity && {canMove _entity} && {_entity isKindOf "AllVehicles"} && {!(_entity isKindOf "Animal")}},0],["Respawn Vehicle","Selects where the vehicle will respawn when it is destroyed.","zen_attributes_icons",[[[4,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnVehicle\west_ca.paa","STR_A3_RscAttributeRespawnVehicle_West_tooltip",11.5,0.25,2,[0,0.3,0.6,1],{playableSlotsNumber west > 0 && {[west, _entity call BIS_fnc_objectSide] call BIS_fnc_areFriendly}}],[3,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnVehicle\east_ca.paa","STR_A3_RscAttributeRespawnVehicle_East_tooltip",14,0.25,2,[0.5,0,0,1],{playableSlotsNumber east > 0 && {[east, _entity call BIS_fnc_objectSide] call BIS_fnc_areFriendly}}],[5,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnVehicle\guer_ca.paa","STR_A3_RscAttributeRespawnVehicle_Guer_tooltip",16.5,0.25,2,[0,0.5,0,1],{playableSlotsNumber independent > 0 && {[independent, _entity call BIS_fnc_objectSide] call BIS_fnc_areFriendly}}],[6,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnVehicle\civ_ca.paa","STR_A3_RscAttributeRespawnVehicle_Civ_tooltip",19,0.25,2,[0.4,0,0.5,1],{playableSlotsNumber civilian > 0 && {[civilian, _entity call BIS_fnc_objectSide] call BIS_fnc_areFriendly}}],[0,"\a3\Ui_F_Curator\Data\RscCommon\RscAttributeRespawnVehicle\start_ca.paa","STR_A3_RscAttributeRespawnVehicle_Start_tooltip",21.5,0.25,2],[-1,"\a3\Ui_F_Curator\Data\default_ca.paa","STR_Disabled",24,0.5,1.5]]],{
["zen_attributes_setVehicleRespawn", _this] call CBA_fnc_serverEvent;
},{
private _respawnID = [_entity, false] call BIS_fnc_moduleRespawnVehicle;

switch (_respawnID) do {
case 1;
case 7: {
_respawnID = 0;
};
case 2: {
_respawnID = [3, 4, 5, 6] param [(_entity call BIS_fnc_objectSide) call BIS_fnc_sideID, -1];
};
};

_respawnID
},{_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}},0],["States","","zen_attributes_checkboxes",[[[10,0,5.5,"STR_3DEN_Object_Attribute_AllowDamage_displayName"],[15.5,0,6.2,"STR_3DEN_Object_Attribute_EnableSimulation_displayName"],[21.7,0,4.3,"STR_3DEN_Object_Attribute_HideObject_displayName"]]],{
_value params ["_damage", "_simulation", "_hidden"];


private _states = [_damage, _simulation, !_hidden];

{
["zen_attributes_setObjectStates", [_x, _states]] call CBA_fnc_serverEvent;
} forEach (curatorSelected select 0);
},{
[isDamageAllowed _entity, simulationEnabled _entity, !isObjectHidden _entity]
},{true},0],
				["Execute","","zen_attributes_code",["zen_attributes_objectExecHistory","zen_attributes_objectExecMode","STR_zen_attributes_ExecObject_Tooltip",20,1000],
					{
						_value params ["_code", "_mode"];

						_code = compile _code;

						switch (_mode) do {
							case 0: {
								_entity call _code;
							};
							case 1: {
								["zen_common_execute", [_code, _entity], _entity] call CBA_fnc_targetEvent;
							};
							case 2: {
								["zen_common_execute", [_code, _entity]] call CBA_fnc_globalEvent;
							};
						};
					},
					{""},
					{serverCommandAvailable '#kick' || {!(missionNamespace getVariable ["ZEN_disableCodeExecution", false])}},0
				],
				["Key weight","","zen_attributes_slider",[1,30,1,false],
					{
						{
						_x setVariable ["WEIGHT", _value];
						} forEach call (curatorSelected select 0);
					},
					{_this getVariable ["WEIGHT", 1]},
					{{_this isKindOf "Key_F"}},0
				],
				["Curve name","","zen_attributes_edit",[],
					{
						{
							_data = _x getVariable ["DATA", createHashMap];
							_data set ["NAME", _value];
							_x setVariable ["DATA", _data];
						} forEach call (curatorSelected select 0);

						_this call fnc_zeus_curve_update;
					},
					{(_this getVariable ["DATA", createHashMap]) getOrDefault ["NAME", ""]},
					{{_this isKindOf "Curve_F"}},0
				]
],[["Arsenal","",{_entity call zen_common_fnc_openArsenal},{alive _entity && {_entity isKindOf "CAManBase"}},true],["Skills","",{[_entity, "Skills"] call zen_attributes_fnc_open},{alive _entity && {_entity isKindOf "CAManBase"}},false],["Abilities","",{[_entity, "Abilities"] call zen_attributes_fnc_open},{alive _entity && {_entity isKindOf "CAManBase"}},false],["Traits","",{[_entity, "Traits"] call zen_attributes_fnc_open},{alive _entity && {_entity isKindOf "CAManBase"}},false],["Sensors","",{[_entity, "Sensors"] call zen_attributes_fnc_open},{alive _entity && {_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}}},false],["Damage","",{
[_entity] call zen_damage_fnc_configure;
},{
alive _entity && {_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}}
},false],["Garage","",{_entity call zen_garage_fnc_openGarage},{alive _entity && {_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}}},true],["Inventory","",{
[_entity] call zen_inventory_fnc_configure;
},{
alive _entity && {getNumber (configOf _entity >> "maximumLoad") > 0}
},false],["Loadout","",{
[_entity] call zen_loadout_fnc_configure;
},{
alive _entity && {!(_entity call zen_loadout_fnc_getWeaponList isEqualTo [])}
},false],["Pylons","",{
_entity call zen_pylons_fnc_configure;
},{
alive _entity && {_entity call zen_common_fnc_hasPylons}
},false]]]
*/