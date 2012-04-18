var fmgc = "/flight-management/control/";
var settings = "/flight-management/settings/";
var fcu = "/flight-management/fcu-values/";
var fmgc_val = "/flight-management/fmgc-values/";
var servo = "/servo-control/";

var fmgc_loop = {
       init : func {
            me.UPDATE_INTERVAL = 0.1;
            me.loopid = 0;
            
            # AUTO-THROTTLE
            
            setprop(fmgc~ "spd-mode", "ias"); # AVAIL MODES : ias mach
            setprop(fmgc~ "spd-ctrl", "off"); # AVAIL MODES : off fmgc man-set
            
            setprop(fmgc~ "a-thr/ias", 0);
            setprop(fmgc~ "a-thr/mach", 0);
            
            setprop(fmgc~ "fmgc/ias", 0);
            setprop(fmgc~ "fmgc/mach", 0);
            
            # AUTOPILOT (LATERAL)
            
            setprop(fmgc~ "lat-mode", "hdg"); # AVAIL MODES : hdg nav1
            setprop(fmgc~ "lat-ctrl", "off"); # AVAIL MODES : off fmgc man-set
            
            # AUTOPILOT (VERTICAL)
            
            setprop(fmgc~ "ver-mode", "alt"); # AVAIL MODES : alt vs ils fpa
            setprop(fmgc~ "ver-ctrl", "off"); # AVAIL MODES : off fmgc man-set
            
            # Rate/Load Factor Configuration
            
            setprop(settings~ "pitch-norm", 0.1);
            setprop(settings~ "roll-norm", 0.2);
            
            # Terminal Procedure
            
            setprop(fmgc~ "procedure/active", "off"); # AVAIL MODES : off sid star iap
            
            # Set Flight Control Unit Initial Values
            
            setprop(fcu~ "ias", 250);
            setprop(fcu~ "mach", 0.78);
            
            setprop(fcu~ "alt", 10000);
            setprop(fcu~ "ias", 250);
            setprop(fcu~ "ias", 250);
            
            setprop(fcu~ "hdg", 0);
            
            setprop(fmgc_val~ "ias", 250);
            setprop(fmgc_val~ "mach", 0.78);
            
            # Servo Control Settings
            
            setprop(servo~ "aileron", 0);
            setprop(servo~ "target-bank", 0);
            
            setprop(servo~ "elevator", 0);
            setprop(servo~ "target-pitch", 0);
            
            me.reset();
    },
    	update : func {
    	
    	me.get_settings();
    	
    	# SET OFF IF NOT USED
    	
    	if (me.spd_ctrl == off) {
    	
    		setprop(fmgc~ "a-thr/ias", 0);
            setprop(fmgc~ "a-thr/mach", 0);
            
            setprop(fmgc~ "fmgc/ias", 0);
            setprop(fmgc~ "fmgc/mach", 0);
    	
    	}
    	
    	if (me.lat_ctrl == off) {
    	
    		setprop(servo~ "aileron", 0);
            setprop(servo~ "target-bank", 0);
    	
    	}
    	
    	if (me.ver_ctrl == off) {
    	
    		setprop(servo~ "elevator", 0);
            setprop(servo~ "target-pitch", 0);
    	
    	}
    	
    	# MANUAL SELECT MODE ===================================================

		## AUTO-THROTTLE -------------------------------------------------------
    	
    	if (me.spd_ctrl == "man-set") {
    	
    		if (me.spd_mode == "ias") {
    		
    			setprop(fmgc~ "a-thr/ias", 1);
    			setprop(fmgc~ "a-thr/mach", 0);
    		
    		} else {
    		
    			setprop(fmgc~ "a-thr/ias", 0);
    			setprop(fmgc~ "a-thr/mach", 1);
    		
    		}
    	
    	}
    	
    	## LATERAL CONTROL -----------------------------------------------------
    	
    	if (me.lat_ctrl == "man-set") {
    	
    		if (me.lat_mode == "hdg") {
    		
    			# Find Heading Deflection
    			
    			var bug = getprop(fcu~ "hdg");
    			
    			var deflection = defl(bug, 180);
    			
    			var bank = defl(bug, 20);
    			
    			setprop(servo~  "aileron", 1);
    			
    			if (math.abs(defl) <= 1)
    				setprop(servo~ "target-bank", 0);
    			else
    				setprop(servo~ "target-bank", bank);
    		
    		} elsif (me.lat_mode == "nav1") {
    		
    			var nav1_error = getprop("/autopilot/internal/nav1-track-error-deg");
    			
    			var bank = limit(nav1_error, 25);
    			
    			setprop(servo~ "aileron", 1);
    			
    			if (math.abs(defl) <= 1)
    				setprop(servo~ "target-bank", 0);
    			else
    				setprop(servo~ "target-bank", bank);    			
    		
    		} # else, this is handed over from fcu to fmgc
    	
    	}
    	
    	## VERTICAL CONTROL ----------------------------------------------------
    	
    	
    	
    	# FMGC CONTROL MODE ====================================================
    	
    	## AUTO-THROTTLE -------------------------------------------------------
    	
    	## LATERAL CONTROL -----------------------------------------------------
    	
    	
    	
    	## VERTICAL CONTROL ----------------------------------------------------

		

	},
		get_settings : func {
		
		me.spd_mode = getprop(fmgc~ "spd-mode");
		me.spd_ctrl = getprop(fmgc~ "spd-ctrl");
		
		me.lat_mode = getprop(fmgc~ "lat-mode");
		me.lat_ctrl = getprop(fmgc~ "lat-ctrl");
		
		me.ver_mode = getprop(fmgc~ "ver-mode");
		me.ver_ctrl = getprop(fmgc~ "ver-ctrl");
		
		
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

setlistener("sim/signals/fdm-initialized", func
 {
 fmgc_loop.init();
 print("Flight Management and Guidance Computer Initialized");
 });
