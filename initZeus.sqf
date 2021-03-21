if (!isClass(configFile >> "CfgPatches" >> "zen_common")) then {hint "This mission utilizes Zeus Enhanced addon. Your client does not have this addon loaded"} //Addon check
else
{
	[] execVM "ZeusLogic\ff_dynSim.sqf" //Logic for Dynamic Simulation add-ins
};