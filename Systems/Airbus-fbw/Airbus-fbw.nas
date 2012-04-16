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
var G_force = 9.80665;
var KT2MS = 0.514444444;

# PATHS

var fcs = "/fdm/jsbsim/fcs/";
var input = "/controls/flight/";
var deg = "/orientation/";
var fbw_root = "/systems/fbw/";

var fbw = {
	
	init : func { 
		me.UPDATE_INTERVAL = 0.001; 
		me.loopid = 0; 


		me.active_pitch = 0;
		me.active_bank = 0;
		me.fix_pitch_gforce = 0;
		me.fix_pitch_rate = 0;
		me.fix_roll_rate = 0;
		me.stable_pitch = 0 ;
	

		## Initialize Control Surfaces

		setprop(fcs~"aileron-fbw-output", 0);
		setprop(fcs~"rudder-fbw-output", 0);
		setprop(fcs~"elevator-fbw-output", 0);

		## FBW Status

		setprop(fbw_root~"law", "NORMAL LAW");
		setprop(fbw_root~"mode", "Ground");
		
		## Flight envelope

		setprop(fbw_root~"limits/max-bank-soft", '33' );
		setprop(fbw_root~"limits/max-bank-hard", '67' );
	
		setprop(fbw_root~"limits/alpha-prot", '22');
		setprop(fbw_root~"limits/alpha-floor", '25');
		setprop(fbw_root~"limits/alpha-max", '30');
		setprop(fbw_root~"limits/alpha-min", '-15');

		setprop(fbw_root~"limits/max-pitch-rate", '15' );
		setprop(fbw_root~"limits/max-roll-rate", '15' );

		#setprop(fbw_root~"pitch-limit",30);
		#setprop(fbw_root~"bank-limit",33);
		#setprop(fbw_root~"bank-manual", 67);
		
		#setprop(fbw_root~"max-pitch-rate", 15);
		#setprop(fbw_root~"max-roll-rate", 15);
		
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

		me.law = getprop(fbw_root~"law");
		me.mode = getprop(fbw_root~"mode");
		me.condition = getprop("/systems/condition");


		me.pitch = getprop("/orientation/pitch-deg");
		me.bank = getprop("/orientation/roll-deg");
		me.agl = getprop("/position/altitude-agl-ft");

		## Alpha Protection Limits
		me.alpha_prot = getprop(fbw_root~"/limits/alpha-prot");
		me.alpha_floor = getprop(fbw_root~"/limits/alpha-floor");
		me.alpha_max =  getprop(fbw_root~"/limits/alpha-max");
		me.alpha_min = getprop(fbw_root~"/limits/alpha-min");
		me.max_roll_rate = getprop(fbw_root~"/limits/max-roll-rate");
		me.max_pitch_rate = getprop(fbw_root~"/limits/max-pitch-rate");
		me.min_pitch_gforce = getprop("/limits/max-negative-g");
		me.max_pitch_gforce = getprop("/limits/max-positive-g");

		## Bank Limit Setting
		me.bank_limit_soft = getprop(fbw_root~"/limits/max-bank-soft");
		me.bank_limit_hard = getprop(fbw_root~"/limits/max-bank-hard");

		#me.pitch_limit = getprop(fbw_root~"pitch-limit");
		#me.bank_limit = getprop(fbw_root~"bank-limit");
		#me.manual_bank = getprop(fbw_root~"bank-manual");
		
		me.stick_pitch = getprop(input~ "elevator");
		me.stick_roll = getprop(input~ "aileron");

		## AP status
		me.autopilot = getprop("/autopilot/settings/engaged");


	}, 
	get_alpha_prot : func{
		if (me.pitch <=  me.alpha_min) return 'alpha_min';
		else if (me.pitch >= me.alpha_prot and me.pitch < me.alpha_floor) return 'alpha_prot';
		else if (me.pitch >= me.alpha_floor and me.pitch < me.alpha_max) return 'alpha_floor';
		else if (me.pitch >= me.alpha_max) return 'alpha_max';
	},

	airbus_law : func {

		# Decide which law to use according to system condition
		
		#if (me.condition == 1)
		#	me.law = "ALTERNATE LAW";
		#elsif (me.condition == 2)
		#	me.law = "DIRECT LAW";
		#elsif (me.condition == 3)
		#	me.law = "MECH BACKUP";
			
		## Check for abnormal attitude
		if(!me.autopilot) {
	
			if ((me.pitch >= 60) or (me.pitch <= -30) or (math.abs(me.bank) >= 80))
				me.law = "ABNORMAL ALTERNATE LAW";
			else
				me.law = "NORMAL LAW";
		}
		else {
			me.law = "AP";
		}		

		setprop(fbw_root~"law", me.law);

	},
	flight_mode : func {

		var prev_mode = "Ground";

		if (me.agl > 250) prev_mode = "Flight";
		else if (me.agl > 50 and !getprop("/gear/gear/wow")) prev_mode = "Flare";

		# Find out the current flight phase (Ground/Flight/Flare)
						
		if ((me.agl > 250) or ((prev_mode == "Flare") and (me.agl > 50))) me.mode = "Flight";
		else if ((prev_mode == "Flight") and (me.agl <= 50)) me.mode = "Flare";
		else if (getprop("/gear/gear/wow")) me.mode = "Ground";
		else me.mode = "Takeoff";

		#me.mode = "Ground";
		setprop(fbw_root~"mode", me.mode);

	},
	law_ap : func {

		# not direct, not active. Don't active PIDs
		me.active_bank = 0;
		me.active_pitch = 0;
		
		me.protect_mode = 0;
		
	},
	law_normal : func {
		# Protection
		
		if ((me.pitch > me.alpha_prot) or (me.pitch < me.alpha_min) or (math.abs(me.bank) > me.bank_limit_soft)) {
		
			me.set_active_ailerons();
			me.set_active_elevator();
			
			me.protect_mode = 1;
		
		} else {
		
			me.protect_mode = 0;
	
			# Ground Mode
	
			if (me.mode == "Ground") {
		
				me.set_direct_ailerons();
				me.set_direct_elevator();
		
			# Flight Mode
		
			} else if (me.mode == "Flight") {
			
				me.set_active_ailerons();
				me.set_active_elevator();
			
			# Flare Mode
			
			} else {
			
				# STILL HAVE SOME WORK HERE. Atm, we'll just shift to direct control.
				
				me.set_direct_ailerons();
				me.set_direct_elevator();
			
			}
		
		}
	},
	law_direct : func {
		me.set_direct_ailerons();
		me.set_direct_elevator();
	},
	law_alternate : func {
		## Flight Envelope Protection is NOT offered
	
		# Ground Mode
		if (me.mode == "Ground") {
		
			me.set_direct_ailerons();
			me.set_direct_elevator();

		# Flight Mode
		} elsif (me.mode == "Flight") {
		
			# Load Factor Control if gears are retracted, else direct control
		
			if (getprop("controls/gear/gear-down")) {
		
				me.set_direct_ailerons();
				me.set_direct_elevator();
			
			} else {
		
				me.set_active_ailerons();
				me.set_active_elevator();
		
			}


		# Flare Mode
		} else {
		
			# STILL HAVE SOME WORK HERE. Atm, we'll just shift to direct control.
			
			me.set_direct_ailerons();
			me.set_direct_elevator();
		}
	
	},
	law_abnormal_alternate : func {

		# Ground Mode
		if (me.mode == "Ground") {
		
			me.set_direct_elevator();
	

		# Flight Mode
		} elsif (me.mode == "Flight") {
		
			# Load Factor Control if gears are retracted, else direct control
		
			if (getprop("controls/gear/gear-down")) {
		
				me.set_direct_elevator();
			
			} else {
		
				me.set_active_elevator();
		
			}
		}
					
		me.set_direct_ailerons();
	},
	flight_envelope : func {

			# once limits are passed, start calculating counter roll_rate, bank_rate and gforce
			# every degree passed from limit add more counter force.
			# this forces are just added to final outputs
			# easy! just need tunning with formulas
	

			# PITCH AXIS
			

			# Alpha Prot
			if (me.pitch > me.alpha_prot) {
			
				me.fix_pitch_rate = (me.max_pitch_rate/4) * (me.alpha_prot - me.pitch);
				me.fix_pitch_gforce = (me.min_pitch_gforce/4) * (me.pitch - me.alpha_prot);
				if (me.pitch > me.alpha_floor) {
					#retract speed brakes and engess on full
					setprop("/controls/engines/engine[0]/throttle", 1);
					setprop("/controls/engines/engine[1]/throttle", 1);
					setprop("/controls/flight/speedbreak-lever", 0);
				}
			
			# Alpha min
			} elsif (me.pitch < me.alpha_min) {
			
				me.fix_pitch_rate = (me.max_pitch_rate/4) * (me.alpha_min - me.pitch);
				me.fix_pitch_gforce = (me.max_pitch_gforce/4) * (me.alpha_min - me.pitch);
			
			} 

			
			# ROLL AXIS 
			
			if (me.bank > me.bank_limit_soft) {
			
				me.fix_roll_rate = (me.bank_limit_soft - me.bank)/33 * me.max_roll_rate;
			
			} elsif (me.bank < -1 * me.bank_limit_soft) {
			
				me.fix_roll_rate = (-1 * me.bank_limit_soft - me.bank)/33 * me.max_roll_rate;
			
			}
	},
	#neutralize_trim : func(stab) {
	#
	#	var trim_prop = "/controls/flight/" ~ stab ~ "-trim";
	#	
	#	var trim = getprop(trim_prop);
	#	
	#	if (trim > 0.005)
	#		setprop(trim_prop, trim - 0.01);
	#	elsif (trim < -0.005)
	#		setprop(trim_prop, trim + 0.01);
	#
	#},

	set_direct_elevator : func {
		me.active_pitch = 0;
		setprop(fcs~"elevator-fbw-output", getprop("/controls/flight/elevator"));
				
	},
	set_direct_ailerons : func {
		me.active_bank = 0;
		setprop(fcs~"aileron-fbw-output", getprop("/controls/flight/aileron"));
	},
	set_direct_rudder : func {
		setprop(fcs~"rudder-fbw-output", getprop(fcs~"rudder-cmd-norm"));
	},

	set_active_elevator : func {
		me.active_pitch = 1;

		# FLY-BY-WIRE Servo Control

		# Convert Stick Position into target G-Force
		
		## Pitch Rate Control
		
		
		#Proper neutral
		if(math.abs(me.stick_pitch) <= 0.02) {
			me.stick_pitch = 0;
			#me.fix_pitch_rate = -1 * getprop("orientation/pitch-rate-degps") * math.abs(me.stable_pitch - me.pitch/0.5);
			me.fix_pitch_rate = me.stable_pitch - me.pitch;
			#me.fix_pitch_gforce = (me.fix_pitch_rate*DEG2RAD) * (getprop("velocities/airspeed-kt") * KT2MS) / G_force;
			me.fix_pitch_gforce = (me.stable_pitch - me.pitch) * 0.05;
			if (me.fix_pitch_gforce >= 0.15) me.fix_pitch_gforce = 0.15;
			else if (me.fix_pitch_gforce <= -0.15) me.fix_pitch_gforce = -0.15;
			#me.actual_pitch_rate = (me.actual_G * G_force) / (me.groundspeedkt * KT2MS);
		} else {
			me.stable_pitch = me.pitch;
		}
		
		

		me.pitch_gforce = (me.stick_pitch * -1.75) + 1 + me.fix_pitch_gforce;
		
		me.pitch_rate = (me.stick_pitch * -1 * me.max_pitch_rate) + me.fix_pitch_rate;
		
		
		## Set G-forces to properties for xml to read
		
		setprop(fbw_root~"elevator/target-pitch-gforce", me.pitch_gforce);
		setprop(fbw_root~"elevator/target-pitch-rate", me.pitch_rate);
		setprop(fbw_root~"elevator/fix-pitch-gforce", me.fix_pitch_gforce);
		setprop(fbw_root~"elevator/fix-pitch-rate", me.fix_pitch_rate);

	},
	set_active_ailerons : func {
		me.active_bank = 1;

		# FLY-BY-WIRE Servo Control

		#Proper neutral
		if(math.abs(me.stick_roll) <= 0.02) me.stick_roll = 0;
		## Roll Rate Control
		
		me.roll_rate = (me.stick_roll * me.max_roll_rate) + me.fix_roll_rate;
		
		## Set G-forces to properties for xml to read

		setprop(fbw_root~"ailerons/target-roll-rate", me.roll_rate);

		setprop(fbw_root~"ailerons/fix-roll-rate", me.fix_roll_rate);
	},
	set_pids : func {
		## Activate PIDs
		# PITCH
		if (me.active_pitch) {
		
			# Load Factor over 210 kts
			
			if (getprop("/velocities/airspeed-kt") > 210) {
				
				setprop(fbw_root~"elevator/PID-pitch-rate", 0);
				setprop(fbw_root~"elevator/PID-load-factor", 1);
				
			} else {
			
				setprop(fbw_root~"elevator/PID-pitch-rate", 1);
				setprop(fbw_root~"elevator/PID-load-factor", 0);
			
			}
		
		} else {
			setprop(fbw_root~"elevator/PID-pitch-rate", 0);
			setprop(fbw_root~"elevator/PID-load-factor", 0);

		}
		
		# BANK
		if (me.active_bank) {
			setprop(fbw_root~"ailerons/PID-roll-rate", 1);
		} else {
			setprop(fbw_root~"ailerons/PID-roll-rate", 0);
		}

		# RUDDER
		if (!me.autopilot)
			setprop(fcs~"rudder-fbw-output", getprop(fcs~"rudder-cmd-norm"));
	},
	update : func {

		# Update vars from property tree
		me.get_state();

		# Decide which law to use according to system condition
		me.airbus_law();
		
		# Find out the current flight phase (Ground/Flight/Flare)
		me.flight_mode();



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


		if (me.law == "NORMAL LAW") me.law_normal();
		else if (me.law == "AP") me.law_ap();
		else if (me.law == "ALTERNATE LAW") me.law_alternate();
		else if (me.law == "ABNORMAL ALTERNATE LAW") me.law_abnormal_alternate();
		else if (me.law == "DIRECT LAW") law_direct();
		else if (me.law == "MECHANICAL BACKUP") law_mechanical_backup();
		else law_direct(); #if other direct

		


		# Load Limit and Flight Envelope Protection
		if (me.protect_mode) me.flight_envelope();
		else {
			me.fix_pitch_gforce = 0;
			me.fix_pitch_rate = 0;
			me.fix_roll_rate = 0;
		}
		

##################################################################### 
		## Activate PIDs
		me.set_pids();
		


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
