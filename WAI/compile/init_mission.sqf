if(isServer) then {
	private ["_validspot","_mission","_aitype","_type","_color","_dot","_position","_marker","_name"];
	if (count _this == 1) exitWith {
		waitUntil {markerready};
		markerready = false;
		if(use_blacklist) then {
			safepos				= [getMarkerPos "center",5,7000,(_this select 0),0,0.5,0,blacklist];
		} else {
			safepos				= [getMarkerPos "center",0,5000,(_this select 0),0,0.5,0];
		};
		_position = safepos call BIS_fnc_findSafePos;
		//diag_log("Checking markers: " + str(wai_mission_markers));
		for "_i" from 0 to 1000 do {
			_position = safepos call BIS_fnc_findSafePos;
			_validspot = true;
			{
				if (getMarkerColor _x == "") exitWith {};
				if ([_position, 50, 20] call isSlope) 				exitWith {_validspot = false;}; //diag_log("WAI: Invalid Position (Slope)"); 
				if ([_position, wai_near_water] call isNearWater) 	exitWith {_validspot = false;}; //diag_log("WAI: Invalid Position (Water)");
				if ([_position, wai_near_town] call isNearTown) 	exitWith {_validspot = false;}; //diag_log("WAI: Invalid Position (Town)"); 
				if ([_position, wai_near_road] call isNearRoad) 	exitWith {_validspot = false;}; //diag_log("WAI: Invalid Position (Road)");
				//diag_log(format["WAI: Marker loop %1 %2 %3:%4 distance %5.", _i, _position, _x, (getMarkerPos _x), (_position distance (getMarkerPos _x))]);
				if ((_position distance (getMarkerPos _x)) < wai_mission_spread) exitWith {_validspot = false;}; //diag_log(format["WAI: Invalid Position (Marker:%1)", _x]); 
			} forEach wai_mission_markers;
			//diag_log("Loop complete, valid position: " +str(_validspot));
			if (_validspot) exitWith { };
		};
		_position
	};

	_position 	= _this select 0;
	_difficulty = _this select 1;
	_name		= _this select 2;
	_type		= _this select 3;
	_mines		= _this select 4;
	
	_mission 	= count wai_mission_data;
	//diag_log("WAI: Starting Mission number " + str(_mission + 1));
	wai_mission_data = wai_mission_data + [[0,_type,[]]];


	if (_type == "MainHero" || _type == "SideHero") then { _aitype = "Bandit"; };
	if (_type == "MainBandit" || _type == "SideBandit") then { _aitype = "Hero"; };


	if(wai_enable_minefield && _mines) then {
		call {
			if (_difficulty == "easy") exitWith {_mines = [_position,25,50,10] call minefield;};
			if (_difficulty == "medium") exitWith {_mines = [_position,50,75,25] call minefield;};
			if (_difficulty == "hard") exitWith {_mines = [_position,50,100,50] call minefield;};
			if (_difficulty == "extreme") exitWith {_mines = [_position,50,100,75] call minefield;};
		};
		wai_mission_data select _mission set [2, _mines];
	};
	
	_marker 	= "";
	_dot 		= "";
	_color		= "ColorBlack";
	
	call {
		if (_difficulty == "Easy")		exitWith {_color = "ColorGreen"};
		if (_difficulty == "Medium")	exitWith {_color = "ColorYellow"};
		if (_difficulty == "Hard")		exitWith {_color = "ColorOrange"};
		if (_difficulty == "Extreme") 	exitWith {_color = "ColorRed"};
	};
	
	call {
		if (_aitype == "Bandit")	exitWith { _name = "[H] " + _name; };
		if (_aitype == "Hero")		exitWith { _name = "[B] " + _name; };
		if (_aitype == "Special")	exitWith { _name = "[S] " + _name; };
	};

	[_position, _color, _name, _mission] spawn {
		_position	= _this select 0;
		_color 		= _this select 1;
		_name 		= _this select 2;
		_mission 	= _this select 3;
		_running 	= true;
		while {_running} do {
			_type	= (wai_mission_data select _mission) select 1;
			_marker 		= createMarker [_type, _position];
			_marker 		setMarkerColor _color;
			_marker 		setMarkerShape "ELLIPSE";
			_marker 		setMarkerBrush "Solid";
			_marker 		setMarkerSize [300,300];
			_marker 		setMarkerText _name;
			_dot 			= createMarker [_type + "dot", _position];
			_dot 			setMarkerColor "ColorBlack";
			_dot 			setMarkerType "mil_dot";
			_dot 			setMarkerText _name;

			sleep 1;
			deleteMarker 	_marker;
			deleteMarker 	_dot;
			_running = (typeName (wai_mission_data select _mission) == "ARRAY");
		};
	};
	
	//diag_log("WAI: Mission Data: " + str(wai_mission_data));
	markerready = true;
	_mission
};