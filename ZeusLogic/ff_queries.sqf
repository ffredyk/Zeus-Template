var_zeus_queries = [];

//---------- FUNCTION
//* Main module function
fnc_zeus_query =
{
	// Get all the passed parameters
	params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]];

	_pretties = [];
	_values = [];
	{
		_pretties pushBack (_x getOrDefault ["NAME", "No name query"]);
		_values pushBack (count _values);
	} forEach var_zeus_queries;
	
	[
		"Query list",
		[
			["List", "Review query", [_values,_pretties,0,5]]
		],
		{
			(_this #0) params ["_pick"]; //Dialog params
			(_this #1) params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]]; //Module params

			[_pick, objNull] call fnc_zeus_query_show;
		},
		{},
		_this
	] call zen_dialog_fnc_create;
};

//* Show query
fnc_zeus_query_show = 
{
	params [
		["_query", 0, [0,createHashMap]],
		["_respondTo", objNull, [objNull]]
	];

	//Select query
	if(typeName _query == typeName 0) then {_query = var_zeus_queries # _query};

	switch (_query getOrDefault ["TYPE", "NONE"]) do {
		case 0: { 
			_text = _query getOrDefault ["TEXT", "Nothing to show"];
			hint parseText _text;
		};
		case 1: {
			_text = _query getOrDefault ["TEXT", "Nothing to show"];
			[objNull, _text] call BIS_fnc_showCuratorFeedbackMessage;
		};
		case 2: {
			_builder = [];

			//Message
			_text = _query getOrDefault ["TEXT", "Nothing to show"];
			var_query_currentText = _text;
			_builder pushBack ["EDIT:MULTI", "Message:", [_text, {var_query_currentText},5]];

			//Yes/No answers
			_yes = _query getOrDefault ["ANSWER_YES", "Yes"];
			_no = _query getOrDefault ["ANSWER_NO", "No"];
			_builder pushBack ["TOOLBOX", "Pick:", [false, 1,2, [_yes,_no]]];

			[
				"Yes/No Query",
				_builder,
				{
					(_this #0) params ["_nil", "_yesno"]; //Dialog params
					(_this #1) params ["_query"]; //Dialog params

					_myQuery = createHashMapFromArray [
						["TYPE",0],
						["TEXT", format ["<t align='center'>Query Reponse</t><br><br>%1<br>%2<br>%3",profileName,
						_query getOrDefault [["ANSWER_NO", "ANSWER_YES"] select _yesno, "UNKNOWN"],
						"<t color='#00FF00'>Accepted"]]
					];
					[_myQuery] remoteExec ["fnc_zeus_query_add", (_query getOrDefault ["RESPONDTO", objNull])];
				},
				{},
				_this
			] call zen_dialog_fnc_create;
		};
		default { };
	};
};

//* Add new query
fnc_zeus_query_add = 
{
	params [
		["_query", createHashMap, [createHashMap]]
	];

	var_zeus_queries pushBack _query;
	[_query] call fnc_zeus_query_show;
};

//---------- MODULE
["[FE] Queries", "Query list", 
{
	_this call fnc_zeus_query;
}] call zen_custom_modules_fnc_register;

//* Add new query
["[FE] Queries", "Add query", 
{
	_targets = [];
	_pretties = [];
	{
		_zeusName = toArray str _x;
		_zeusName resize 4;
		_zeusName = toString _zeusName;
		if(_zeusName == "zeus") then 
		{
			_targets pushBack _x;
			_pretties pushBack (name _x);
		};
	} forEach allPlayers;

	[
		"Add new query",
		[
			["Combo", ["Target","Target of the query"], [_targets, _pretties, 0]],
			["Edit", ["Name","Name of the query"], [format ["Query from %1", profileName]]],
			["Toolbox", ["Type","What kind of query to send?"], [0, 1,3, ["Hint", "Message", "Yes/No"]]]
		],
		{
			(_this #0) params ["_target", "_name", "_type"]; //Dialog params
			(_this #1) params [["_position", [0,0,0], [[]], 3], ["_objectUnderCursor", objNull, [objNull]]]; //Module params

			//Send the query (logic preparation)
			_fnc_sendTheQuery = 
			{
				(_this #1) params ["_target", "_name", "_type"]; //Dialog params
				_params = (_this #0) - [0]; //Dialog 2 params

				_query = createHashMapFromArray [["TYPE", _type]];
				_query set ["NAME", _name];

				switch (_type) do {
					case 0: { 
						_query set ["TEXT", (_params #0)];
					};
					case 1: {
						_query set ["TEXT", (_params #0)];
					};
					case 2: {
						_query set ["TEXT", (_params #0)];
						_query set ["ANSWER_YES", (_params #1)];
						_query set ["ANSWER_NO", (_params #2)];
						_query set ["RESPONDTO", player];
					};
					default { };
				};

				[_query] remoteExec ["fnc_zeus_query_add", _target];
			};

			//Show second dialog
			_dialog = []; //builder
			switch (_type) do {
				case 0: { 
					_dialog pushBack ["Toolbox", "Type", [0,1,1,["Hint"]]];
					_dialog pushBack ["Edit:multi", "Message", [""]];
				};
				case 1: {
					_dialog pushBack ["Toolbox", "Type", [0,1,1,["Hint"]]];
					_dialog pushBack ["Edit:multi", "Message", [""]];
				};
				case 2: {
					_dialog pushBack ["Toolbox", "Type", [0,1,1,["Hint"]]];
					_dialog pushBack ["Edit:multi", "Message", [""]];
					_dialog pushBack ["Edit", "YES answer", ["Yes"]];
					_dialog pushBack ["Edit", "NO asnwer", ["No"]];
				};
				default { };
			};
			[ //dialog
				"Query information",
				_dialog,
				_fnc_sendTheQuery,
				{},
				_this #0
			] call zen_dialog_fnc_create;
		},
		{},
		_this
	] call zen_dialog_fnc_create;
}] call zen_custom_modules_fnc_register;