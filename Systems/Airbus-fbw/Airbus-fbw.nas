###############################
## AIRBUS FLY-BY-WIRE SYSTEM ##
###############################
## Written by Narendran      ##
###############################

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

var fbw_loop = {
	
	init : func { 
		me.UPDATE_INTERVAL = 0.001; 
		me.loopid = 0; 

		# fbw.reset();

		## Initialize Control Surfaces

		setprop("/fdm/jsbsim/fcs/aileron-fbw-output", 0);
		setprop("/fdm/jsbsim/fcs/rudder-fbw-output", 0);
		setprop("/fdm/jsbsim/fcs/elevator-fbw-output", 0);
		
		setprop("/fbw/pitch-limit",30);
		setprop("/fbw/bank-limit",33);
		setprop("/fbw/bank-manual", 67);
		
		setprop("/fbw/max-pitch-rate", 15);
		setprop("/fbw/max-roll-rate", 15);
		
		setprop("/fbw/active-law", "NORMAL LAW");
		setprop("/fbw/flight-phase", "Ground Mode");
		
		# This should be moved to 'failures.nas' but as I haven't written it yet, we'll just keep the systems working fine at all times. (0 - all working | 1 - moderate failures | 2 - major failures | 3 - elec/hyd failure)
		
		setprop("/systems/condition", 0);
				
		# Servo Control Modes (0 - direct | 1 - fbw)
		# Servo Protection Modes (0 - off | 1 - protect)
		# Servo Working (0 - not working/use mech backup | 1 - working)
		
		setprop("/fbw/stable/elevator", 0);
		setprop("/fbw/stable/aileron", 0);
		
		# The Stabilizer (Trimmers) are used to maintain pitch and/or bank angle when the control stick is brought to the center. The active fbw controls "try" to maintain 0 pitch-rate/roll-rate/1g but if by any chance (for example during turbulence) the attitude's changed, the stabilizer can get it back to the original attitude
		
		# Stabilizer works ONLY in NORMAL LAW Flight Mode

		me.reset(); 
	},  #Init Function end

	update : func {
	
		# Decide which law to use according to system condition
		
		var law = "NORMAL LAW";
		var condition = getprop("/systems/condition");
		
		if (condition == 1)
			law = "ALTERNATE LAW";
		elsif (condition == 2)
			law = "DIRECT LAW";
		elsif (condition == 3)
			law = "MECH BACKUP";
			
		## Check for abnormal attitude

		var pitch = getprop("/orientation/pitch-deg");
		var bank = getprop("/orientation/roll-deg");
		
		if ((pitch >= 60) or (pitch <= -30) or (math.abs(bank) >= 80))
			law = "ABNORMAL ALTERNATE LAW";
			
		setprop("/fbw/active-law", law);
		
#####################################################################
			
		# Find out the current flight phase (Ground/Flight/Flare)
		
		var phase = getprop("/fbw/flight-phase");
		var agl = getprop("/position/altitude-agl-ft");
				
		if ((agl > 250) or ((phase == "Flare Mode") and (agl > 50)))
			setprop("/fbw/flight-phase", "Flight Mode");
			
		if ((phase == "Flight Mode") and (agl <= 50))
			setprop("/fbw/flight-phase", "Flare Mode");
			
		if (getprop("/gears/gear/wow"))
			setprop("/fbw/flight-phase", "Ground Mode");
			
#####################################################################

		var law = getprop("/fbw/active-law");
		var mode = getprop("/fbw/flight-phase");
		var pitch_limit = getprop("/fbw/pitch-limit");
		var bank_limit = getprop("/fbw/bank-limit");
		var manual_bank = getprop("/fbw/bank-manual");
		
		var stick_pitch = getprop(input~ "elevator");
		var stick_roll = getprop(input~ "aileron");
		
#####################################################################

		# Dis-engage Fly-by-wire input modification if autopilot is engaged

		if (getprop("/autopilot/settings/engaged")) {
		
			setprop("/fbw/control/aileron", 0);
			setprop("/fbw/control/elevator", 0);
			
			setprop("/fbw/protect-mode", 0);
		
		} else {
		
######## NORMAL LAW #################################################
		
		if (law == "NORMAL LAW") {
		
			# Protection
			
			if ((pitch > pitch_limit) or (pitch < -0.5 * pitch_limit) or (math.abs(bank) > bank_limit)) {
			
				setprop("/fbw/control/aileron", 0);
				setprop("/fbw/control/elevator", 0);
				
				setprop("/fbw/protect-mode", 1);
			
			} else {
			
				setprop("/fbw/protect-mode", 0);
		
				# Ground Mode
		
				if (mode == "Ground Mode") {
			
					setprop("/fbw/control/aileron", 0);
					setprop("/fbw/control/elevator", 0);
			
				# Flight Mode
			
				} elsif (mode == "Flight Mode") {
				
					setprop("/fbw/control/elevator", 1);
					setprop("/fbw/control/aileron", 1);
				
					if (math.abs(stick_pitch) >= 0.02) {
					
						# setprop("/fbw/control/elevator", 1);
						setprop("/fbw/stable/elevator", 0);
					
					} else {
					
						if (getprop("/fbw/stable/elevator") != 1) {
						
							setprop("/fbw/stable/pitch-deg", pitch);
							
							# setprop("/fbw/control/elevator", 0);
							setprop("/fbw/stable/elevator", 1);
						
						}
						
					}
					
					if (math.abs(stick_roll) >= 0.02) {
					
						# setprop("/fbw/control/aileron", 1);
						setprop("/fbw/stable/aileron", 0);
						
					} else {
					
						if (getprop("/fbw/stable/aileron") == 0) {
						
							setprop("/fbw/stable/bank-deg", bank);
							
							# setprop("/fbw/control/aileron", 0);
							setprop("/fbw/stable/aileron", 1);
						
						}
										
					}
				
				# Flare Mode
				
				} else {
				
					# STILL HAVE SOME WORK HERE. Atm, we'll just shift to direct control.
					
					setprop("/fbw/control/aileron", 0);
					setprop("/fbw/control/elevator", 0);
				
				}
			
			}
		
		}
		
######## ALTERNATE LAW ##############################################

		elsif (law == "ALTERNATE LAW") {
		
			## Flight Envelope Protection is NOT offered
		
			# Ground Mode
		
			if (mode == "Ground Mode") {
			
				setprop("/fbw/control/aileron", 0);
				setprop("/fbw/control/elevator", 0);
		
			# Flight Mode
		
			} elsif (mode == "Flight Mode") {
			
			# Load Factor Control if gears are retracted, else direct control
			
			if (getprop("controls/gear/gear-down")) {
			
				setprop("/fbw/control/aileron", 0);
				setprop("/fbw/control/elevator", 0);
				
			} else {
			
				setprop("/fbw/control/aileron", 1);
				setprop("/fbw/control/elevator", 1);
			
			}
			
			# Flare Mode
			
			} else {
			
				# STILL HAVE SOME WORK HERE. Atm, we'll just shift to direct control.
				
				setprop("/fbw/control/aileron", 0);
				setprop("/fbw/control/elevator", 0);
			
			}
		
		}

######## ABNORMAL ALTERNATE LAW #####################################

		elsif (law == "ABNORMAL ALTERNATE LAW") {
		
			# Ground Mode
		
			if (mode == "Ground Mode") {
			
				setprop("/fbw/control/elevator", 0);
		
			# Flight Mode
		
			} elsif (mode == "Flight Mode") {
			
			# Load Factor Control if gears are retracted, else direct control
			
			if (getprop("controls/gear/gear-down")) {
			
				setprop("/fbw/control/elevator", 0);
				
			} else {
			
				setprop("/fbw/control/elevator", 1);
			
			}
			
			}
						
			setprop("/fbw/control/aileron", 0);
		
		}
		
######## DIRECT LAW #################################################

		elsif (law == "DIRECT LAW") {
		
			setprop("/fbw/control/aileron", 0);
			setprop("/fbw/control/elevator", 0);
		
		}

######## MECHANICAL BACKUP ##########################################

		# COME BACK LATER
		
#####################################################################

		} # End of Autopilot Check
		
		# Load Limit and Flight Envelope Protection
		
		var pitch = getprop(deg~ "pitch-deg");
		var bank = getprop(deg~ "roll-deg");
		
		if (getprop("/fbw/protect-mode")) {
		
			 # PITCH AXIS
			 
			 if ((pitch > pitch_limit) and (stick_pitch <= 0)) {
			 
			 	setprop("/fbw/target-pitch", pitch_limit);
				setprop("/fbw/pitch-hold", 1);
			 
			 } elsif ((pitch < -0.5 * pitch_limit) and (stick_pitch >= 0)) {
			 
			 	setprop("/fbw/target-pitch", -0.5 * pitch_limit);
				setprop("/fbw/pitch-hold", 1);
			 
			 } else
			 	
			 	setprop("/fbw/pitch-hold", 0);
			 
			 # ROLL AXIS 
			 
			 if ((stick_roll >= 0.5) and (bank > manual_bank)) {
			 
			 	setprop("/fbw/target-bank", manual_bank);
				setprop("/fbw/bank-hold", 1);
			 
			 } elsif ((stick_roll <= -0.5) and (bank < -1 * manual_bank)) {
			 
			 	setprop("/fbw/target-bank", -1 * manual_bank);
				setprop("/fbw/bank-hold", 1);
			 
			 } elsif ((stick_roll < 0.5) and (stick_roll >= 0) and (bank > bank_limit)) {
			 
			 	setprop("/fbw/target-bank", bank_limit);
				setprop("/fbw/bank-hold", 1);
			 
			 } elsif ((stick_roll > -0.5) and (stick_roll <= 0) and (bank < -1 * bank_limit)) {
			 
			 	setprop("/fbw/target-bank", -1 * bank_limit);
				setprop("/fbw/bank-hold", 1);
			 
			 } else
			 
			 	setprop("/fbw/bank-hold", 0);
		
		}
		
#####################################################################

		# DIRECT Servo Control (just simple copying)
		
		if (getprop("/fbw/control/aileron") == 0)
				
			setprop("/fdm/jsbsim/fcs/aileron-fbw-output", getprop("/controls/flight/aileron"));
			
		if (getprop("/fbw/control/elevator") == 0)
		
			setprop("/fdm/jsbsim/fcs/elevator-fbw-output", getprop("/controls/flight/elevator"));
		
#####################################################################

		# FLY-BY-WIRE Servo Control

		# Convert Stick Position into target G-Force
		
		## Pitch Rate Control
		
		var pitch_gforce = (stick_pitch * -1.75) + 1;
		
		var pitch_rate = (stick_pitch * -1 * getprop("/fbw/max-pitch-rate"));
		
		## Roll Rate Control
		
		var roll_rate = (stick_roll * getprop("/fbw/max-roll-rate"));
		
		## Set G-forces to properties for xml to read
		
		setprop("/fbw/target-pitch-gforce", pitch_gforce);
		setprop("/fbw/target-roll-rate", roll_rate);
		setprop("/fbw/target-pitch-rate", pitch_rate);
		
		if (getprop("/fbw/control/elevator")) {
		
			# Load Factor over 210 kts
			
			if (getprop("/velocities/airspeed-kt") > 210) {
				
				setprop("/fbw/elevator/pitch-rate", 0);
				setprop("/fbw/elevator/load-factor", 1);
				
			} else {
			
				setprop("/fbw/elevator/pitch-rate", 1);
				setprop("/fbw/elevator/load-factor", 0);
			
			}
		
		}

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
