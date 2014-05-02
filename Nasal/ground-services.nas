var door = aircraft.door.new("/services/deicing_truck/crane", 20);
var door3 = aircraft.door.new("/services/deicing_truck/deicing", 20);

var RAD2DEG = 57.3;

var ground_services = {
	init : func {
		me.UPDATE_INTERVAL = 0.1;
	me.loopid = 0;
	
	me.ice_time = 0;
	
	
	# Fuel Truck
	
	setprop("/services/fuel-truck/enable", 0);
	setprop("/services/fuel-truck/connect", 0);
	setprop("/services/fuel-truck/transfer", 0);
	setprop("/services/fuel-truck/clean", 0);
	setprop("/services/fuel-truck/request-kg", 0);	
	
	# Set them all to 0 if the aircraft is not stationary
	
	if (getprop("/velocities/groundspeed-kt") > 10) {
		
		setprop("/services/fuel-truck/enable", 0);
		
	}
	
	

	me.reset();
	},
	update : func {		
			
		# Fuel Truck Controls
		
		if (getprop("/services/fuel-truck/enable") and getprop("/services/fuel-truck/connect")) {
		
			if (getprop("/services/fuel-truck/request-kg") > 19000) {
			
				screen.log.write("Maximum fuel capacity is 19000 kg!", 1, 0, 0);
				setprop("/services/fuel-truck/request-kg", 19000);
				
				
			}
			
			if (getprop("/services/fuel-truck/transfer")) {
			
				if (getprop("consumables/fuel/total-fuel-kg") < getprop("/services/fuel-truck/request-kg")) {
					setprop("/consumables/fuel/tank[1]/level-kg", getprop("/consumables/fuel/tank[1]/level-kg") + 5);
					setprop("/consumables/fuel/tank[2]/level-kg", getprop("/consumables/fuel/tank[2]/level-kg") + 20);
					setprop("/consumables/fuel/tank[3]/level-kg", getprop("/consumables/fuel/tank[3]/level-kg") + 35);
					setprop("/consumables/fuel/tank[4]/level-kg", getprop("/consumables/fuel/tank[4]/level-kg") + 20);
					setprop("/consumables/fuel/tank[5]/level-kg", getprop("/consumables/fuel/tank[5]/level-kg") + 5);
				} else {
					setprop("/services/fuel-truck/transfer", 0);
					screen.log.write("Re-fueling complete! Have a nice flight... :)", 1, 1, 1);
				}				
			
			}
			
			if (getprop("/services/fuel-truck/clean")) {
			
				if (getprop("consumables/fuel/total-fuel-kg") > 90) {
				
					setprop("/consumables/fuel/tank[1]/level-kg", getprop("/consumables/fuel/tank[1]/level-kg") - 80);
					setprop("/consumables/fuel/tank[2]/level-kg", getprop("/consumables/fuel/tank[2]/level-kg") - 80);
					setprop("/consumables/fuel/tank[3]/level-kg", getprop("/consumables/fuel/tank[3]/level-kg") - 80);
					setprop("/consumables/fuel/tank[4]/level-kg", getprop("/consumables/fuel/tank[4]/level-kg") - 80);
					setprop("/consumables/fuel/tank[5]/level-kg", getprop("/consumables/fuel/tank[5]/level-kg") - 80);
				
				} else {
					setprop("/services/fuel-truck/clean", 0);
					screen.log.write("Finished draining the fuel tanks...", 1, 1, 1);
				}	
			
			}
		
		}
		
		
	
	},
	reset : func {
		me.loopid += 1;
		me._loop_(me.loopid);
	},
	_loop_ : func(id) {
		id == me.loopid or return;
		me.update();
		settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
	}
};



setlistener("sim/signals/fdm-initialized", func {
	ground_services.init();
	print("Ground Services ..... Initialized");
});
