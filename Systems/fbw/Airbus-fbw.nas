# <!-- =============================================================== -->
# <!--   FG Airbus Fly By Wire                                         -->
# <!--     Author:    Jon A. Ortuondo (Bicyus)                         -->
# <!--     for:       Airbus     A320neo                               -->
# <!--     derived from:       Boeing 787-8 FBW                        -->
# <!-- =============================================================== -->

# CONSTANTS

var RAD2DEG = 57.2957795;
var DEG2RAD = 0.0174532925;
var G_force = 9.80665;
var KT2MS = 0.514444444;

var fbw = {

	init : func{

		me.stabpitch = 0;
		me.stabroll = 0;


		## Initialize with FBW Activated
		me.fcs_root = "/fdm/jsbsim/fcs/";
		me.fbw_root = "/autopilot/fbw/";

		## Create Vars and Propertyes
		props.globals.initNode(me.fbw_root~"engaged", 1, 'BOOL'); # Electronic work
		props.globals.initNode(me.fbw_root~"active", 0, 'BOOL'); # it is operating
		setprop(me.fbw_root~"law", 'normal');
		setprop(me.fbw_root~"mode", 'Ground');
		props.globals.initNode(me.fbw_root~"stabroll", 0, 'BOOL');
		props.globals.initNode(me.fbw_root~"stabpitch", 0, 'BOOL');
		props.globals.initNode(me.fbw_root~"protections/overspeed", 0, 'BOOL');
		props.globals.initNode(me.fbw_root~"protections/alpha-prot", 0, 'BOOL');	# max on stick neutral
		props.globals.initNode(me.fbw_root~"protections/alpha-floor", 0, 'BOOL');	# TOGA thrust
		props.globals.initNode(me.fbw_root~"protections/alpha-max", 0, 'BOOL');	# FULL STICK deflect
		props.globals.initNode(me.fbw_root~"protections/alpha-min", 0, 'BOOL');
		props.globals.initNode(me.fbw_root~"protections/stall", 0, 'BOOL');
		props.globals.initNode(me.fbw_root~"protections/bank", 0, 'BOOL');
		props.globals.initNode(me.fbw_root~"protections/windshear", 0, 'BOOL');
		#props.globals.initNode(me.fbw_root~"autotrim/elevator", 0, 'BOOL');
		#props.globals.initNode(me.fbw_root~"autotrim/rudder", 0, 'BOOL');
		#props.globals.initNode(me.fbw_root~"autotrim/ailerons", 0, 'BOOL');

		setprop("/controls/flight/aileron-filtered", '0');
		setprop("/controls/flight/elevator-filtered", '0');

		# XML setting limits
		setprop("/limits/fbw/max-bank-angle-soft", '33' );
		setprop("/limits/fbw/max-bank-angle-hard", '67' );	
		setprop("/limits/fbw/max-roll-speed", '0.261799387'); # max 0.261799387 rad_sec, 15 deg_sec
		setprop("/limits/fbw/alpha-prot", '19');
		setprop("/limits/fbw/alpha-floor", '25');
		setprop("/limits/fbw/alpha-max", '30');
		setprop("/limits/fbw/alpha-min", '-15');
		setprop("/autopilot/internal/target-roll-deg", '0');
		setprop("/autopilot/internal/target-pitch-deg", '0');
		

		# Enter in loop
		me.UPDATE_INTERVAL = 0.01; 
		me.loopid = 0; 
		me.reset(); 
	},
	get_state : func{
		## Alpha Protection Limits
		me.alpha_prot = getprop("/limits/fbw/alpha-prot");
		me.alpha_floor = getprop("/limits/fbw/alpha-floor");
		me.alpha_max =  getprop("/limits/fbw/alpha-max");
		me.alpha_min = getprop("/limits/fbw/alpha-min");
		me.max_roll = getprop("/limits/fbw/max-roll-speed");

		## Bank Limit Setting

		me.banklimit_soft = getprop("/limits/fbw/max-bank-angle-soft");
		me.banklimit_hard = getprop("/limits/fbw/max-bank-angle-hard");

		## Position and Orientation

		me.altitudeagl = getprop("/position/altitude-agl-ft");

		me.altitudemsl = getprop("/position/altitude-ft");

		me.pitch = getprop("/orientation/pitch-deg");
		me.roll = getprop("/orientation/roll-deg");

		me.airspeedkt = getprop("/velocities/airspeed-kt");
		me.groundspeedkt = getprop("/velocities/groundspeed-kt");

		## Flight Control System Properties

		#me.elevtrim = getprop("/controls/flight/elevator-trim");
		#me.ailtrim = getprop("/controls/flight/aileron-trim");

		me.aileronin = getprop("/controls/flight/aileron-filtered");
		me.elevatorin =  getprop("/controls/flight/elevator-filtered");
		me.rudderin = getprop("/controls/flight/rudder");

		## FBW Output (actual surface positions)

		me.aileronout = getprop(me.fcs_root~"aileron-fbw-output");
		me.elevatorout =  getprop(me.fcs_root~"elevator-fbw-output");
		me.rudderout = getprop(me.fcs_root~"rudder-fbw-output");

		## Engine Throttle Positions

		me.throttle0 = getprop("controls/engines/engine[0]/throttle");
		me.throttle1 = getprop("controls/engines/engine[1]/throttle");
	},
	
	Airbus_law : func {
		# Flight mode
		#
		if (me.altitudeagl >= '100') {
			me.mode = 'Flight';
			me.active = 1;
		} else {
			if (getprop("/gear/gear/wow") and getprop("/gear/gear[1]/wow") and getprop("/gear/gear[2]/wow")) {
				me.mode = 'Ground';
				me.active = 0;
			} else {
				me.mode = 'Transition';
				me.active = 0;
			}
		}

		# Law mode - more to be aded
		# 
		if (me.pitch <= me.alpha_min or me.pitch >= me.alpha_prot){ 
			me.law = 'AOA';
		} else {
			var law = 'Normal';
		}
		# Direct law, alternate... for future


	},
	autostable : func {
		## AUTO-STABILIZATION

		### Get the aircraft to maintain pitch and roll when stick is at the center 
		### PID USED

		#### PITCH ####
		if ((me.elevatorin <= 0.1) and (me.elevatorin >= -0.1) ) {
			if (me.stabpitch == 0) {
				setprop("/autopilot/internal/target-pitch-deg", me.pitch);
				me.stabpitch = 1;
			}	
			setprop(me.fbw_root~"stabpitch", 1);
		} else { 
			setprop(me.fbw_root~"stabpitch", 0);
			me.stabpitch = 0;
		}


		#### ROLL ####
		if ((me.aileronin <= 0.1) and (me.aileronin >= -0.1)) {
			if (me.stabroll == 0) {
				setprop("/autopilot/internal/target-roll-deg", me.roll);
				me.stabroll = 1;
			}
			setprop(me.fbw_root~"stabroll", 1);
		} else { 
			setprop("/autopilot/internal/target-roll-deg", me.roll);
			setprop(me.fbw_root~"stabroll", 0);
			me.stabroll = 0;
		}

	},
	demand_pitch : func{
		# pitch rate w=a/v
		me.actual_G = getprop("/accelerations/pilot-gdamped") - 1;
		me.desired_G = me.elevatorin * -1.5;
		me.actual_pitch_rate = (me.actual_G * G_force) / (me.groundspeedkt * KT2MS);
		me.desired_pitch_rate = (me.desired_G * G_force) / (me.groundspeedkt * KT2MS);

		me.elevatorout = (me.desired_pitch_rate - me.actual_pitch_rate ) * -5 * me.fpsfix;

	},
	demand_roll : func{

		me.actual_roll_rate = getprop("/fdm/jsbsim/velocities/p-aero-rad_sec");
		me.desired_roll_rate = me.aileronin * me.max_roll;

		me.aileronout = (me.desired_roll_rate - me.actual_roll_rate) * 15 * me.fpsfix;
	},

	update : func{

		if (getprop("/sim/frame-rate") != nil) me.fpsfix = 25 / getprop("/sim/frame-rate");
		else me.fpsfix = 1;

		me.get_state(); # update variables
		me.Airbus_law(); # update engage mode
		me.autostable(); # if Joke neutral, Stabilize through PID

		#all protections

		if (me.active) { # FBW is in demand
			if (!me.stabroll) { #when not stable calculate roll
				me.demand_roll();
				setprop(me.fcs_root~"aileron-fbw-output", me.aileronout);
			}

		
			if (!me.stabpitch) { #when not stable calculate pitch
				
				me.demand_pitch();
				setprop(me.fcs_root~"elevator-fbw-output", me.elevatorout);
			}
			

			
			setprop(me.fcs_root~"rudder-fbw-output", me.rudderin);  #IN


		} else {
			setprop(me.fcs_root~"aileron-fbw-output", me.aileronin);
			setprop(me.fcs_root~"elevator-fbw-output", me.elevatorin);
			setprop(me.fcs_root~"rudder-fbw-output", me.rudderin);
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

fbw.init();
print("Fly-By-Wire ......... Initialized");
