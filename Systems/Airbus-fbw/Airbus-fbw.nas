##################################
## AIRBUS FLY-BY-WIRE SYSTEM    ##
##################################
## Written by Narendran and Jon ##
##################################

# FLIGHT CONTROL LAWS -
## Normal Law
## Alternate Law
## Abnormal Alternate Law
## Direct Law
## Mechanical Backup

# CONSTANTS

var RAD2DEG = 57.2957795;
var DEG2RAD = 0.0174532925;

# PATHS

var fcs = "/fdm/jsbsim/fcs/";
var input = "/controls/flight/";
var deg = "/orientation/";
var fbw_root = "/fbw/";

var fbw = {
	
	init : func { 
		me.UPDATE_INTERVAL = 0.001; 
		me.loopid = 0; 


		me.active_pitch = 0;
		me.active_bank = 0;

		# fbw.reset();

		## Initialize Control Surfaces

		setprop(fcs~"aileron-fbw-output", 0);
		setprop(fcs~"rudder-fbw-output", 0);
		setprop(fcs~"elevator-fbw-output", 0);

		## FBW Status

		setprop(fbw_root~"active-law", "NORMAL LAW");
		setprop(fbw_root~"flight-phase", "Ground Mode");
		
		## Flight envelope

		setprop("/limits/fbw/max-bank-soft", '33' );
		setprop("/limits/fbw/max-bank-hard", '67' );	
		setprop("/limits/fbw/max-roll-speed", '0.261799387'); # max 0.261799387 rad_sec, 15 deg_sec
		setprop("/limits/fbw/alpha-prot", '19');
		setprop("/limits/fbw/alpha-floor", '25');
		setprop("/limits/fbw/alpha-max", '30');
		setprop("/limits/fbw/alpha-min", '-15');

		setprop(fbw_root~"pitch-limit",30);
		setprop(fbw_root~"bank-limit",33);
		setprop(fbw_root~"bank-manual", 67);
		
		setprop(fbw_root~"max-pitch-rate", 15);
		setprop(fbw_root~"max-roll-rate", 15);
		
		# This should be moved to 'failures.nas' but as I haven't written it yet, we'll just keep the systems working fine at all times. (0 - all working | 1 - moderate failures | 2 - major failures | 3 - elec/hyd failure)
		
		setprop("/systems/condition", 0);
				
		# Servo Control Modes (0 - direct | 1 - fbw)
		# Servo Protection Modes (0 - off | 1 - protect)
		# Servo Working (0 - not working/use mech backup | 1 - working)
		
		props.globals.initNode(fbw_root~"stable/elevator", 0);
		props.globals.initNode(fbw_root~"stable/aileron", 0);
		
		# The Stabilizer (Trimmers) are used to maintain pitch and/or bank angle when the control stick is brought to the center. The active fbw controls "try" to maintain 0 pitch-rate/roll-rate/1g but if by any chance (for example during turbulence) the attitude's changed, the stabilizer can get it back to the original attitude
		
		# Stabilizer works ONLY in NORMAL LAW Flight Mode

		me.reset(); 
	},  #Init Function end


	get_state : func{

		#me.law = "NORMAL LAW";

		me.law = getprop(fbw_root~"active-law");
		me.mode = getprop(fbw_root~"flight-phase");
		me.condition = getprop("/systems/condition");


		me.pitch = getprop("/orientation/pitch-deg");
		me.bank = getprop("/orientation/roll-deg");
		me.agl = getprop("/position/altitude-agl-ft");

		me.pitch_limit = getprop(fbw_root~"pitch-limit");
		me.bank_limit = getprop(fbw_root~"bank-limit");
		me.manual_bank = getprop(fbw_root~"bank-manual");
		
		me.stick_pitch = getprop(input~ "elevator");
		me.stick_roll = getprop(input~ "aileron");

	}, 
	get_alpha_prot : func{
		if (me.pitch <=  me.alpha_min) return 'alpha_min';
		else if (me.pitch >= me.alpha_prot and me.pitch < me.alpha_floor) return 'alpha_prot';
		else if (me.pitch >= me.alpha_floor and me.pitch < me.alpha_max) return 'alpha_floor';
		else if (me.pitch >= me.alpha_max) return 'alpha_max';
	},

	#get_aircraft : func {

	#},
	airbus_law : func {

		# Decide which law to use according to system condition
		
		if (me.condition == 1)
			me.law = "ALTERNATE LAW";
		elsif (me.condition == 2)
			me.law = "DIRECT LAW";
		elsif (me.condition == 3)
			me.law = "MECH BACKUP";
			
		## Check for abnormal attitude

		if ((me.pitch >= 60) or (me.pitch <= -30) or (math.abs(me.bank) >= 80))
			me.law = "ABNORMAL ALTERNATE LAW";
			
		setprop("/fbw/active-law", me.law);

	},
	flight_phase : func {

		# Find out the current flight phase (Ground/Flight/Flare)
						
		if ((me.agl > 250) or ((me.mode == "Flare Mode") and (me.agl > 50))) me.mode = "Flight Mode";
		else if ((me.mode == "Flight Mode") and (me.agl <= 50)) me.mode = "Flare Mode";
		else if (getprop("/gear/gear/wow")) me.mode = "Ground Mode";

		setprop(fbw_root~"flight-phase", me.mode);

	},
	law_normal : func {
		# Protection
		
		if ((me.pitch > me.pitch_limit) or (me.pitch < -0.5 * me.pitch_limit) or (math.abs(me.bank) > me.bank_limit)) {
		
			me.active_bank = 0;
			me.active_pitch = 0;
			
			me.protect_mode = 1;
		
		} else {
		
			me.protect_mode = 0;
	
			# Ground Mode
	
			if (me.mode == "Ground Mode") {
		
				me.active_bank = 0;
				me.active_pitch = 0;
		
			# Flight Mode
		
			} elsif (me.mode == "Flight Mode") {
			
				me.active_pitch = 1;
				me.active_bank = 1;


				## Active Stable PIDs on neutral jokes
			
				#if (math.abs(me.stick_pitch) >= 0.02) {
				
				#	# me.active_pitch = 1;
				#	setprop(fbw_root~"stable/elevator", 0);
				
				#} else {
				
				#	if (getprop(fbw_root~"stable/elevator") != 1) {
					
				#		setprop(fbw_root~"stable/pitch-deg", me.pitch);
						
				#		# me.active_pitch = 0;
				#		setprop(fbw_root~"stable/elevator", 1);
					
				#	}
					
				#}

				## Active Stable PIDs on neutral jokes

				#if (math.abs(me.stick_roll) >= 0.02) {
				
					# me.active_bank = 1;
				#	setprop(fbw_root~"stable/aileron", 0);
					
				#} else {
				
				#	if (getprop(fbw_root~"stable/aileron") == 0) {
					
				#		setprop(fbw_root~"stable/bank-deg", me.bank);
						
						# me.active_bank = 0;
				#		setprop(fbw_root~"stable/aileron", 1);
					
				#	}
									
				#}
			
			# Flare Mode
			
			} else {
			
				# STILL HAVE SOME WORK HERE. Atm, we'll just shift to direct control.
				
				me.active_bank = 0;
				me.active_pitch = 0;
			
			}
		
		}
	},
	law_direct : func {
		me.active_bank = 0;
		me.active_pitch = 0;
	},
	law_alternate : func {
		## Flight Envelope Protection is NOT offered
	
		# Ground Mode
		if (me.mode == "Ground Mode") {
		
			me.active_bank = 0;
			me.active_pitch = 0;

		# Flight Mode
		} elsif (me.mode == "Flight Mode") {
		
			# Load Factor Control if gears are retracted, else direct control
		
			if (getprop("controls/gear/gear-down")) {
		
				me.active_bank = 0;
				me.active_pitch = 0;
			
			} else {
		
				me.active_bank = 1;
				me.active_pitch = 1;
		
			}


		# Flare Mode
		} else {
		
			# STILL HAVE SOME WORK HERE. Atm, we'll just shift to direct control.
			
			me.active_bank = 0;
			me.active_pitch = 0;
		}
	
	},
	law_abnormal_alternate : func {

		# Ground Mode
		if (me.mode == "Ground Mode") {
		
			me.active_pitch = 0;
	

		# Flight Mode
		} elsif (me.mode == "Flight Mode") {
		
			# Load Factor Control if gears are retracted, else direct control
		
			if (getprop("controls/gear/gear-down")) {
		
				me.active_pitch = 0;
			
			} else {
		
				me.active_pitch = 1;
		
			}
		}
					
		me.active_bank = 0;
	},
	flight_envelope : func {
			# PITCH AXIS
			 
			if ((me.pitch > me.pitch_limit) and (me.stick_pitch <= 0)) {
			
				setprop(fbw_root~"target-pitch", me.pitch_limit);
				setprop(fbw_root~"pitch-hold", 1);
			
			} elsif ((me.pitch < -0.5 * me.pitch_limit) and (me.stick_pitch >= 0)) {
			
				setprop(fbw_root~"target-pitch", -0.5 * me.pitch_limit);
				setprop(fbw_root~"pitch-hold", 1);
			
			} else
				
				setprop(fbw_root~"pitch-hold", 0);
			
			# ROLL AXIS 
			
			if ((me.stick_roll >= 0.5) and (me.bank > me.manual_bank)) {
			
				setprop(fbw_root~"target-bank", me.manual_bank);
				setprop(fbw_root~"bank-hold", 1);
			
			} elsif ((me.stick_roll <= -0.5) and (me.bank < -1 * me.manual_bank)) {
			
				setprop(fbw_root~"target-bank", -1 * me.manual_bank);
				setprop(fbw_root~"bank-hold", 1);
			
			} elsif ((me.stick_roll < 0.5) and (me.stick_roll >= 0) and (me.bank > me.bank_limit)) {
			
				setprop(fbw_root~"target-bank", me.bank_limit);
				setprop(fbw_root~"bank-hold", 1);
			
			} elsif ((me.stick_roll > -0.5) and (me.stick_roll <= 0) and (me.bank < -1 * me.bank_limit)) {
			
				setprop(fbw_root~"target-bank", -1 * me.bank_limit);
				setprop(fbw_root~"bank-hold", 1);
			
			} else
			
				setprop(fbw_root~"bank-hold", 0);

	},
	neutralize_trim : func(stab) {
	
		var trim_prop = "/controls/flight/" ~ stab ~ "-trim";
		
		var trim = getprop(trim_prop);
		
		if (trim > 0.005)
			setprop(trim_prop, trim - 0.01);
		elsif (trim < -0.005)
			setprop(trim_prop, trim + 0.01);
	
	},

	update : func {

		# Update vars from property tree
		me.get_state();

		# Decide which law to use according to system condition
		me.airbus_law();
		
		# Find out the current flight phase (Ground/Flight/Flare)
		me.flight_phase();



		# Bring Stabilizers to 0 gradually when stabilizer mode is turned off
		
		#if (getprop("/fbw/stable/elevator") != 1)
		#	me.neutralize_trim("elevator");
		#	
		#if (getprop("/fbw/stable/aileron") != 1)
		#	me.neutralize_trim("aileron");

########################### PRECAUTIONS #############################

		# Reset Stabilizers when out of NORMAL LAW Flight Mode
		
		#if ((me.law != "NORMAL LAW") or (me.mode != "Flight Mode")) {
		#
		#	setprop("/controls/flight/aileron-trim", 0);
		#	setprop("/controls/flight/elevator-trim", 0);
		#
		#}
		
#####################################################################


		# Dis-engage Fly-by-wire input modification if autopilot is engaged

		if (getprop("/autopilot/settings/engaged")) {
		
			me.active_bank = 0;
			me.active_pitch = 0;
			
			me.protect_mode = 0;
		
		} else {
			if (me.law == "NORMAL LAW") me.law_normal();
			elsif (me.law == "ALTERNATE LAW") me.law_alternate();
			elsif (me.law == "ABNORMAL ALTERNATE LAW") me.law_abnormal_alternate();
			elsif (me.law == "DIRECT LAW") law_direct();
			elsif (me.law == "MECHANICAL BACKUP") law_mechanical_backup();
		} # End of Autopilot Check
		


		# Load Limit and Flight Envelope Protection
		if (me.protect_mode) me.flight_envelope();
		
#####################################################################

		# DIRECT Servo Control (just simple copying)
		
		if (!me.active_bank)
				
			setprop(fcs~"aileron-fbw-output", getprop("/controls/flight/aileron"));
			
		if (!me.active_pitch)
		
			setprop(fcs~"elevator-fbw-output", getprop("/controls/flight/elevator"));


		setprop(fcs~"rudder-fbw-output", getprop(fcs~"rudder-cmd-norm"));
		
#####################################################################

		# FLY-BY-WIRE Servo Control

		# Convert Stick Position into target G-Force
		
		## Pitch Rate Control
		
		#Proper neutral
		if(math.abs(me.stick_pitch) <= 0.02) me.stick_pitch = 0;
		if(math.abs(me.stick_roll) <= 0.02) me.stick_roll = 0;

		me.pitch_gforce = (me.stick_pitch * -1.75) + 1;
		
		me.pitch_rate = (me.stick_pitch * -1 * getprop(fbw_root~"max-pitch-rate"));
		
		## Roll Rate Control
		
		me.roll_rate = (me.stick_roll * getprop(fbw_root~"max-roll-rate"));
		
		## Set G-forces to properties for xml to read
		
		setprop(fbw_root~"target-pitch-gforce", me.pitch_gforce);
		setprop(fbw_root~"target-roll-rate", me.roll_rate);
		setprop(fbw_root~"target-pitch-rate", me.pitch_rate);
		
		## Activate PIDs
		if (me.active_pitch) {
		
			# Load Factor over 210 kts
			
			if (getprop("/velocities/airspeed-kt") > 210) {
				
				setprop(fbw_root~"elevator/pitch-rate", 0);
				setprop(fbw_root~"elevator/load-factor", 1);
				
			} else {
			
				setprop(fbw_root~"elevator/pitch-rate", 1);
				setprop(fbw_root~"elevator/load-factor", 0);
			
			}
		
		}
		
		if (me.active_bank) setprop(fbw_root~"control/aileron", 1);
		else setprop(fbw_root~"control/aileron", 0);

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
# END fwb var
###

fbw.init();
print("Airbus Fly-by-wire Initialized");
