###############################
## AIRBUS FLY-BY-WIRE SYSTEM ##
###############################
## Written by Narendran      ##
###############################

# CONSTANTS

var RAD2DEG = 57.2957795;
var DEG2RAD = 0.0174532925;

# PATHS

var fcs = "/fdm/jsbsim/fcs/";
var input = "/controls/flight/";
var deg = "/orientation/";

var fbw_loop = {
	
	init : func { 
		me.UPDATE_INTERVAL = 0.001; 
		me.loopid = 0; 

		# fbw.reset();

		## Initialize Control Surfaces

		setprop("/fdm/jsbsim/fcs/aileron-fbw-output", 0);
		setprop("/fdm/jsbsim/fcs/rudder-fbw-output", 0);
		setprop("/fdm/jsbsim/fcs/elevator-fbw-output", 0);
		
		setprop("/fbw/pitch-limit",20);
		setprop("/fbw/bank-limit",33);

		me.reset(); 
	},  #Init Function end

	update : func {

		# Convert Stick Position into target G-Force
		
		var stick_pitch = getprop(input~ "elevator");
		var stick_roll = getprop(input~ "aileron");
		
		## Pitch Rate Control
		
		var pitch_gforce = (stick_pitch * -1.75) + 1;
		
		## Roll Rate Control
		
		var roll_rate = (stick_roll * 30);
		
		## Set G-forces to properties for xml to read
		
		setprop("/fbw/target-pitch-gforce", pitch_gforce);
		setprop("/fbw/target-roll-rate", roll_rate);
		
		# Limit Pitch and Bank Angles
		
		var pitch = getprop(deg~ "pitch-deg");
		var bank = getprop(deg~ "roll-deg");
		
		var pitch_limit = getprop("/fbw/pitch-limit");
		var bank_limit = getprop("/fbw/bank-limit");
		
		# Pitch Limit
		
		if ((pitch <= -1 * pitch_limit) and (stick_pitch >= 0)) {
		
			setprop("/fbw/target-pitch", -1 * pitch_limit);
			setprop("/fbw/pitch-hold", 1);
		
		} elsif ((pitch >= pitch_limit) and (stick_pitch <= 0)) {
		
			setprop("/fbw/target-pitch", pitch_limit);
			setprop("/fbw/pitch-hold", 1);
		
		} else
			setprop("/fbw/pitch-hold", 0);
			
		# Bank Limit
		
		if ((bank <= -1 * bank_limit) and (stick_roll <= 0)) {
		
			setprop("/fbw/target-bank", -1 * bank_limit);
			setprop("/fbw/bank-hold", 1);
		
		} elsif ((bank >= bank_limit) and (stick_roll >= 0)) {
		
			setprop("/fbw/target-bank", bank_limit);
			setprop("/fbw/bank-hold", 1);
		
		} else
			setprop("/fbw/bank-hold", 0);
			
		# Turn off FBW when bank or pitch limiters are active
			
		if (getprop("/fbw/pitch-hold"))
			setprop("/fbw/active-pitch", 0);
		else
			setprop("/fbw/active-pitch", 1);
			
		if (getprop("/fbw/bank-hold"))
			setprop("/fbw/active-bank", 0);
		else
			setprop("/fbw/active-bank", 1);

	}, # Update Fuction end

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
###
# END fwb_loop var
###

fbw_loop.init();
print("Airbus Fly-by-wire Initialized");
