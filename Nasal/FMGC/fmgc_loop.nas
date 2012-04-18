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
            
            setprop(fmgc~ "ver-mode", "alt"); # AVAIL MODES : alt (vs/fpa) ils
            setprop(fmgc~ "ver-sub", "vs"); # AVAIL MODES : vs fpa
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
            setprop(fcu~ "vs", 1800);
            setprop(fcu~ "fpa", 5);
            
            setprop(fcu~ "hdg", 0);
            
            setprop(fmgc_val~ "ias", 250);
            setprop(fmgc_val~ "mach", 0.78);
            
            # Servo Control Settings
            
            setprop(servo~ "aileron", 0);
            setprop(servo~ "target-bank", 0);
            
            setprop(servo~ "elevator-vs", 0);
            setprop(servo~ "elevator", 0);
            setprop(servo~ "target-pitch", 0);
            
            me.reset();
    },
    	update : func {
    	
    	me.get_settings();
    	
    	# SET OFF IF NOT USED
    	
    	if (me.spd_ctrl == "off") {
    	
    		setprop(fmgc~ "a-thr/ias", 0);
            setprop(fmgc~ "a-thr/mach", 0);
            
            setprop(fmgc~ "fmgc/ias", 0);
            setprop(fmgc~ "fmgc/mach", 0);
    	
    	}
    	
    	if (me.lat_ctrl == "off") {
    	
    		setprop(servo~ "aileron", 0);
            setprop(servo~ "target-bank", 0);
    	
    	}
    	
    	if (me.ver_ctrl == "off") {
    	
    		setprop(servo~ "elevator-vs", 0);
    		setprop(servo~ "elevator-gs", 0);
    		setprop(servo~ "elevator", 0);
            setprop(servo~ "target-pitch", 0);
    	
    	}
    	
    	# MANUAL SELECT MODE ===================================================

		## AUTO-THROTTLE -------------------------------------------------------
    	
    	if (me.spd_ctrl == "man-set") {
    	
    		if (me.spd_mode == "ias") {
    		
    			setprop(fmgc~ "a-thr/ias", 1);
    			setprop(fmgc~ "a-thr/mach", 0);
    			
    			setprop(fmgc~ "fmgc/ias", 0);
            	setprop(fmgc~ "fmgc/mach", 0);
    		
    		} else {
    		
    			setprop(fmgc~ "a-thr/ias", 0);
    			setprop(fmgc~ "a-thr/mach", 1);
    			
    			setprop(fmgc~ "fmgc/ias", 0);
        	    setprop(fmgc~ "fmgc/mach", 0);
    		
    		}
    	
    	}
    	
    	## LATERAL CONTROL -----------------------------------------------------
    	
    	if (me.lat_ctrl == "man-set") {
    	
    		if (me.lat_mode == "hdg") {
    		
    			# Find Heading Deflection
    			
    			var bug = getprop(fcu~ "hdg");
    			
    			var deflection = defl(bug, 180);
    			
    			var bank = -1 * defl(bug, 20);
    			
    			setprop(servo~  "aileron", 1);
    			
    			if (math.abs(deflection) <= 1)
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
    	
    	var altitude = getprop("/position/altitude-ft");
    	
    	var vs_setting = getprop(fcu~ "vs");
    	
    	var fpa_setting = getprop(fcu~ "fpa");
    	
    	if (me.ver_ctrl == "man-set") {
    	
    		if (me.ver_mode == "alt") {
    		
    			if (me.ver_sub == "vs") {
    		
    				var target = getprop(fcu~ "alt");
    			
    				var trgt_vs = limit2((target - altitude) * 2, vs_setting);
    				
    				setprop(servo~ "target-vs", trgt_vs / 60);
    				
    				setprop(servo~ "elevator-vs", 1);
    				
    				setprop(servo~ "elevator", 0);
    				
    				setprop(servo~ "elevator-gs", 0);
    				
    			} else {
    			
    				var target_alt = getprop(fcu~ "alt");
    				
    				var trgt_fpa = limit2((target_alt - altitude) * 2, fpa_setting);
    				
    				setprop(servo~ "target-pitch", trgt_fpa);
    				
    				setprop(servo~ "elevator-vs", 0);
    				
    				setprop(servo~ "elevator", 1);
    				
    				setprop(servo~ "elevator-gs", 0);
    			
    			}
    		
    		} elsif (me.ver_mode == "ils") {
    		
    			# Main stuff are done on the PIDs
    			
    			setprop(servo~ "elevator-gs", 1);
    				
    			setprop(servo~ "elevator", 0);
    			
    			setprop(servo~ "elevator-vs", 0);
    		    		
    		}
    	
    	} # End of Manual Setting Check
    	
    	# FMGC CONTROL MODE ====================================================
    	
    	if (me.ver_ctrl == "fmgc") {
    	
    	var cur_wp = getprop("autopilot/route-manager/current-wp");
    	
    	## AUTO-THROTTLE -------------------------------------------------------
    	
    	var spd = getprop("/autopilot/route-manager/route/wp[" ~ cur_wp ~ "]/ias-mach");
    	
    	setprop(fmgc_val~ "target-spd", spd);
    	
    	setprop(fmgc~ "a-thr/ias", 0);
        setprop(fmgc~ "a-thr/mach", 0);
    	
    	if (spd < 1) {
    	
    		setprop(fmgc~ "fmgc/ias", 0);
            setprop(fmgc~ "fmgc/mach", 0);
    	
    	} else {
    	
    		setprop(fmgc~ "fmgc/ias", 1);
            setprop(fmgc~ "fmgc/mach", 0);
    	
    	}
    	
    	## LATERAL CONTROL -----------------------------------------------------
    	
    	
    	
    	## VERTICAL CONTROL ----------------------------------------------------

		

		} # End of FMGC Control Check
		

	},
		get_settings : func {
		
		me.spd_mode = getprop(fmgc~ "spd-mode");
		me.spd_ctrl = getprop(fmgc~ "spd-ctrl");
		
		me.lat_mode = getprop(fmgc~ "lat-mode");
		me.lat_ctrl = getprop(fmgc~ "lat-ctrl");
		
		me.ver_mode = getprop(fmgc~ "ver-mode");
		me.ver_ctrl = getprop(fmgc~ "ver-ctrl");
		
		me.ver_sub = getprop(fmgc~ "ver-sub");
		
		
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
