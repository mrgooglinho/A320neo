
# <!-- =============================================================== -->
# <!--   Fly By Wire, Logic                                            -->
# <!--     Author:    Jon A. Ortuondo (Bicyus)                         -->
# <!--     for:       Airbus     A320neo                               -->
# <!-- =============================================================== -->


print("Initializing Fly By Wire System for " ~ getprop("sim/aero"));

## Initialize with FBW Activated

var fbw_root = "/autopilot/fbw/";			# Root Property tree

setprop(fbw_root~"engaged", 1);
setprop(fbw_root~"law", 'normal');
setprop(fbw_root~"mode", 'Ground');

setprop(fbw_root~"protections/overspeed", 0);
setprop(fbw_root~"protections/alpha-prot", 0);	# max on stick neutral
setprop(fbw_root~"protections/alpha-floor", 0);	# TOGA thrust
setprop(fbw_root~"protections/alpha-max", 0);	# FULL STICK deflect
setprop(fbw_root~"protections/alpha-min", 0);
setprop(fbw_root~"protections/stall", 0);
setprop(fbw_root~"protections/bank", 0);
setprop(fbw_root~"protections/windshear", 0);

setprop(fbw_root~"autotrim/elevator", 0);
setprop(fbw_root~"autotrim/rudder", 0);
setprop(fbw_root~"autotrim/ailerons", 0);

# XML setting
setprop("/limits/fbw/max-bank-angle-soft", 33 );
setprop("/limits/fbw/max-bank-angle-hard", 67 );	
setprop("/limits/fbw/max-roll-speed", 0.261799387); # max 0.261799387 rad_sec, 15 deg_sec
setprop("/limits/fbw/alpha-prot", 19);
setprop("/limits/fbw/alpha-floor", 25);
setprop("/limits/fbw/alpha-max", 30);
setprop("/limits/fbw/alpha-min", -15);





# <!-- =============================================================== -->
# <!--   Functions                                                     -->
# <!-- =============================================================== -->
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

	var on_ground = func() {
		if (getprop("/gear/gear[0]/wow") and getprop("/gear/gear[1]/wow") and getprop("/gear/gear[2]/wow") )
			{ return true; }
		else
			{ return false; }
	}






	


	var Update_law = func {
	# Flight mode
		if (altitudeagl >= '500') {
			 var mode = 'Flight'; var engaged = 1; 
		} elseif (on_ground()) {
				var mode = 'Ground';
				var engaged = 0;
		} else {
			 var mode = 'Transition'; var engaged = 0; 
		}

	# Law mode
	# 
		if (in_range(pitch, [alpha_min,alpha_prot]);)
			{ var law = 'AOA'; }
		else 
			{ var law = 'Normal'; }

		setprop(fbw_root~"law", law);
		setprop(fbw_root~"mode", mode);
	}


