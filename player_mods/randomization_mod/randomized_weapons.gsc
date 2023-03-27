#include common_scripts\utility; 
#include maps\mp\gametypes_zm\_hud_util; 

init() // entry point
{
	level thread onplayerconnect(); 
	level thread onroundchange(); 
}

onplayerconnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onplayerspawned(); 
	}
}

onplayerspawned()
{
	self endon("disconnect");
	self thread showweaponmonitor(); 
}

showweaponmonitor()
{
	self.primaryWeaponText = self createFontString("Objective", 1.5); 
	self.primaryWeaponText setPoint("TOPLEFT",undefined,0,0); 
	self.secondaryWeaponText = self createFontString("Objective", 1.5); 
	self.secondaryWeaponText setPoint("TOPLEFT",undefined,0,20); 
	
	// Show initial starting weapon
	self.primaryWeaponText setText("Primary Weapon: " + self getweaponslistprimaries()[0]); 
	
	for(;;)
	{
		level waittill("randomized_weapons"); 
		self.primaryWeaponText setText("Primary Weapon: " + self getweaponslistprimaries()[0]); 
		self.secondaryWeaponText setText("Secondary Weapon " + self getweaponslistprimaries()[1]); 
	}
}

onroundchange()
{
	for(;;)
	{
		self waittill("start_of_round");
		foreach(player in level.players)
		{ 
			oldLoadout = player getweaponslistprimaries(); 
			
			// Generate new loadout
			newLoadout = generatenewloadout(oldLoadout); 
			
			// Swap them
			for(weaponIndex = 0; weaponIndex < oldLoadout.size; weaponIndex++)
			{
				// Print weapons to log
				weaponSlot = "";
				if(weaponIndex == 0)
				{
					weaponSlot = "primary";
				}
				else
				{
					weaponSlot = "secondary";
				}
				Println(player.name + "'s new " + weaponSlot + ": " + newLoadout[weaponIndex]);
				
				player takeweapon(oldLoadout[weaponIndex]);
				player giveweapon(newLoadout[weaponIndex]); 
			}
			
			// Sound notification for players
			self notify ("randomized_weapons");
		}
	}
}

generatenewloadout(oldLoadoutNames)
{
	// Get list of weapons from map
	mapWeaponsList = array_copy(level.zombie_weapons); 
	
	// Weapon validity flag
	isLoadoutInvalid = true; 
	
	// New loadout weapon names
	newLoadoutWeaponNames = []; 
	
	do{
		// Create a random weapon list
		randomizedWeaponsList = array_randomize(mapWeaponsList); 
		
		// Create a new loadout
		newLoadoutWeapons = []; 
		
		// Assign a random primary/secondary to loadout
		for(weaponIndex = 0; weaponIndex < oldLoadoutNames.size; weaponIndex++)
		{
			newLoadoutWeapons[weaponIndex] = randomizedWeaponsList[weaponIndex]; 
		}
		
		// Check to see if loadout is valid
		if(isvalidloadout(oldLoadoutNames, newLoadoutWeapons))
		{
			// Weapon is valid 
			isLoadoutInvalid = false; 
			
			for(weaponIndex = 0; weaponIndex < newLoadoutWeapons.size; weaponIndex++)
			{
				// Get current weapon
				currentWeapon = newLoadoutWeapons[weaponIndex];
				
				// Get its normal (or non-pack-a-punch name)
				normalWeaponName = currentWeapon.weapon_name; 
		
				// Get upgraded name
				upgradedWeaponName = currentWeapon.upgrade_name; 
				
				// Now randomly chose the normal or pack-a-punch weapon for use
				selectableWeaponNames = [];
				selectableWeaponNames[0] = normalWeaponName;
				selectableWeaponNames[1] = upgradedWeaponName;
			
				newLoadoutWeaponNames[weaponIndex] = random(selectableWeaponNames); 
			}
		}
		
		// If the loadout isn't valid
		// generate a new one and try again. 
	}while(isLoadoutInvalid); 
	
	// Return new random weapon
	return newLoadoutWeaponNames;
}

isvalidloadout(oldLoadoutNames, newLoadoutWeapons)
{
	for(newLoadoutIndex = 0; newLoadoutIndex < newLoadoutWeapons.size; newLoadoutIndex++)
	{
		// Fetch current weapon
		currentWeapon = newLoadoutWeapons[newLoadoutIndex]; 
		
		// Get its normal (or non-pack-a-punch name)
		normalWeaponName = currentWeapon.weapon_name; 
		
		// Get upgraded name (or pack-a-punched name)
		upgradedWeaponName = currentWeapon.upgrade_name; 
		
		// If the upgraded (pack-a-punch) name is defined
		// then the weapon is a valid firearm (not a throwable or buildable)
		if(isdefined(upgradedWeaponName))
		{
			// Check to see if a loadout weapon has already been used
			for(oldLoadoutIndex = 0; oldLoadoutIndex < oldLoadoutNames.size; oldLoadoutIndex++)
			{
				oldLoadoutName = oldLoadoutNames[oldLoadoutIndex];
				if(oldLoadoutName == normalWeaponName || oldLoadoutName == upgradedWeaponName)
				{
					return false; 
				}
			}
			
		}else
		{
			return false; 
		}
	}
	return true; 
}