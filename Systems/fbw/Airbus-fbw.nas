
# <!-- =============================================================== -->
# <!--   Fly By Wire, Logic                                            -->
# <!--     Author:    Jon A. Ortuondo (Bicyus)                         -->
# <!--     for:       Airbus     A320neo                               -->
# <!-- =============================================================== -->

## Initialize with FBW deactivated

print(getprop("sim/aero")~": Initializing Fly By Wire System");

var fbw_root = "/autopilot/fbw/";			# Root Property tree

## Create Vars and Propertyes
props.globals.initNode(fbw_root~"engaged", 0, 'BOOL');
setprop(fbw_root~"law", 'normal');
setprop(fbw_root~"mode", 'Ground');
props.globals.initNode(fbw_root~"protections/overspeed", 0, 'BOOL');
props.globals.initNode(fbw_root~"protections/alpha-prot", 0, 'BOOL');	# max on stick neutral
props.globals.initNode(fbw_root~"protections/alpha-floor", 0, 'BOOL');	# TOGA thrust
props.globals.initNode(fbw_root~"protections/alpha-max", 0, 'BOOL');	# FULL STICK deflect
props.globals.initNode(fbw_root~"protections/alpha-min", 0, 'BOOL');
props.globals.initNode(fbw_root~"protections/stall", 0, 'BOOL');
props.globals.initNode(fbw_root~"protections/bank", 0, 'BOOL');
props.globals.initNode(fbw_root~"protections/windshear", 0, 'BOOL');
props.globals.initNode(fbw_root~"autotrim/elevator", 0, 'BOOL');
props.globals.initNode(fbw_root~"autotrim/rudder", 0, 'BOOL');
props.globals.initNode(fbw_root~"autotrim/ailerons", 0, 'BOOL');


# XML setting
setprop("/limits/fbw/max-bank-angle-soft", '33' );
setprop("/limits/fbw/max-bank-angle-hard", '67' );	
setprop("/limits/fbw/max-roll-speed", '0.261799387'); # max 0.261799387 rad_sec, 15 deg_sec
setprop("/limits/fbw/alpha-prot", '19');
setprop("/limits/fbw/alpha-floor", '25');
setprop("/limits/fbw/alpha-max", '30');
setprop("/limits/fbw/alpha-min", '-15');


## Position and Orientation

var altitudeagl = getprop("/position/altitude-agl-ft");
var altitudemsl = getprop("/position/altitude-ft");
var pitch = getprop("/orientation/pitch-deg");
var roll = getprop("/orientation/roll-deg");

## Alpha Protection Limits
var alpha_prot = getprop("/limits/fbw/alpha-prot");
var alpha_floor = getprop("/limits/fbw/alpha-floor");
var alpha_max =  getprop("/limits/fbw/alpha-max");
var alpha_min = getprop("/limits/fbw/alpha-min");



# <!-- =============================================================== -->
# <!--   Functions                                                     -->
# <!-- =============================================================== -->

	##
	# a wrapper to determine if a value is within a certain range
	# usage:in_range(1,[min,max] );
	# e.g.: in_range(1, [-1,+1] );
	#
	var in_range = func(value, range) {
		var min=range[0];
		var max=range[1];
		return ((value <= min) and (value >= max));
	}
	
	var on_ground = func {
		if(getprop("/gear/gear/wow")) return 1;
	}
	

	# Test Protections
	#
	var get_prot_alpha = func {
		var pitch = getprop("/orientation/pitch-deg");
		
		if (pitch <= alpha_min)  setprop(fbw_root~"protections/alpha-min", 1);
		else {
			setprop(fbw_root~"protections/alpha-min", 0);

			if (pitch >= alpha_prot) {
				setprop(fbw_root~"protections/alpha-prot", 1); 

				if (pitch >= alpha_floor) {
					setprop(fbw_root~"protections/alpha-floor", 1);

					if (pitch >= alpha_max)  setprop(fbw_root~"protections/alpha-max", 1);
					else setprop(fbw_root~"protections/alpha-max", 0);

					}

				else setprop(fbw_root~"protections/alpha-floor", 0);

				} #alpha-prot if close

			else setprop(fbw_root~"protections/alpha-prot", 0);

			} #Alpha-min else close
	} # get_prot_alpha func close
	
	

	

	var Update_law = func {
	# Flight mode
		if ((getprop("/position/altitude-agl-ft")) >= '100') {var mode = 'Flight'; var engaged = 1; } 
		else if ( on_ground()) {var mode = 'Ground';var engaged = 0;}
		else {var mode = 'Transition'; var engaged = 0; }

	# Law mode
	# 
		var pitch = getprop("/orientation/pitch-deg");
		if (pitch <= alpha_min or pitch >= alpha_prot){ var law = 'AOA'; get_prot_alpha()}
		else { var law = 'Normal'; }


	# Triger Protections
	#
		get_prot_alpha();
	# Output Props
	#
		setprop(fbw_root~"law", law);
		setprop(fbw_root~"mode", mode);
		setprop(fbw_root~"engaged", engaged);
	}



# <!-- =============================================================== -->
# <!--   Execute Loops                                                 -->
# <!-- =============================================================== -->

var loop = func {
	print("this line appears once every two seconds");
	Update_law ();

	settimer(loop, 1);
}

loop();        # start loop


