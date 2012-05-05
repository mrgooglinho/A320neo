var fmgc = "/flight-management/control/";
var settings = "/flight-management/settings/";
var fcu = "/flight-management/fcu-values/";
var fmgc_val = "/flight-management/fmgc-values/";
var servo = "/servo-control/";

setprop("/flight-management/text/qnh", "QNH");

setprop(settings~ "gps-accur", "LOW");

setprop("/flight-management/end-flight", 0);

var fmgc_loop = {
       init : func {
            me.UPDATE_INTERVAL = 0.1;
            me.loopid = 0;
            
            me.current_wp = 0;
            
            setprop("/flight-management/current-wp", me.current_wp);
            
            # ALT SELECT MODE
            
            setprop(fmgc~ "alt-sel-mode", "100"); # AVAIL MODES : 100 1000
            
            # AUTO-THROTTLE
            
            setprop(fmgc~ "spd-mode", "ias"); # AVAIL MODES : ias mach
            setprop(fmgc~ "spd-ctrl", "man-set"); # AVAIL MODES : --- fmgc man-set
            
            setprop(fmgc~ "a-thr/ias", 0);
            setprop(fmgc~ "a-thr/mach", 0);
            
            setprop(fmgc~ "fmgc/ias", 0);
            setprop(fmgc~ "fmgc/mach", 0);
            
            # AUTOPILOT (LATERAL)
            
            setprop(fmgc~ "lat-mode", "hdg"); # AVAIL MODES : hdg nav1
            setprop(fmgc~ "lat-ctrl", "man-set"); # AVAIL MODES : --- fmgc man-set
            
            # AUTOPILOT (VERTICAL)
            
            setprop(fmgc~ "ver-mode", "alt"); # AVAIL MODES : alt (vs/fpa) ils
            setprop(fmgc~ "ver-sub", "vs"); # AVAIL MODES : vs fpa
            setprop(fmgc~ "ver-ctrl", "man-set"); # AVAIL MODES : --- fmgc man-set
            
            # AUTOPILOT (MASTER)
            
            setprop(fmgc~ "ap1-master", "off");
            setprop(fmgc~ "ap2-master", "off");
            setprop(fmgc~ "a-thrust", "off");
            
            # Rate/Load Factor Configuration
            
            setprop(settings~ "pitch-norm", 0.1);
            setprop(settings~ "roll-norm", 0.2);
            
            # Terminal Procedure
            
            setprop("/flight-management/procedures/active", "off"); # AVAIL MODES : off sid star iap
            
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
            setprop(servo~ "aileron-nav1", 0);
            setprop(servo~ "target-bank", 0);
            
            setprop(servo~ "elevator-vs", 0);
            setprop(servo~ "elevator", 0);
            setprop(servo~ "target-pitch", 0);
            
            me.reset();
    },
    	update : func {
    	
    	var altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    	
    	me.get_settings();
    	
    	me.lvlch_check();
    	
    	me.knob_sum();
    	
    	me.hdg_disp();
    	
    	me.fcu_lights();
    	
    	setprop("flight-management/procedures/active", procedure.check());
    	
    	setprop(fcu~ "alt-100", me.alt_100());
    	
    	# SET OFF IF NOT USED
    	
    	if ((me.spd_ctrl == "off") or (me.a_thr == "off")) {
    	
    		setprop(fmgc~ "a-thr/ias", 0);
            setprop(fmgc~ "a-thr/mach", 0);
            
            setprop(fmgc~ "fmgc/ias", 0);
            setprop(fmgc~ "fmgc/mach", 0);
    	
    	}
    	
    	if ((me.lat_ctrl == "off") or ((me.ap1 == "off") and (me.ap2 == "off"))) {
    	
    		setprop(servo~ "aileron", 0);
    		setprop(servo~ "aileron-nav1", 0);
            setprop(servo~ "target-bank", 0);
    	
    	}
    	
    	if ((me.ver_ctrl == "off") or ((me.ap1 == "off") and (me.ap2 == "off"))) {
    	
    		setprop(servo~ "elevator-vs", 0);
    		setprop(servo~ "elevator-gs", 0);
    		setprop(servo~ "elevator", 0);
            setprop(servo~ "target-pitch", 0);
    	
    	}
    	
    	# MANUAL SELECT MODE ===================================================

		## AUTO-THROTTLE -------------------------------------------------------
    	
    	if ((me.spd_ctrl == "man-set") and (me.a_thr == "eng")) {
    	
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
    	
    	if ((me.ap1 == "eng") or (me.ap2 == "eng")) {
    	
    	## LATERAL CONTROL -----------------------------------------------------
    	
    	if (me.lat_ctrl == "man-set") {
    	
    		if (me.lat_mode == "hdg") {
    		
    			# Find Heading Deflection
    			
    			var bug = getprop(fcu~ "hdg");
    			
    			var bank = -1 * defl(bug, 20);
    			
    			var deflection = defl(bug, 180);
    			
    			
    			setprop(servo~  "aileron", 1);
    			setprop(servo~ "aileron-nav1", 0);
    			
    			if (math.abs(deflection) <= 1)
    				setprop(servo~ "target-bank", 0);
    			else
    				setprop(servo~ "target-bank", bank);
    		
    		} elsif (me.lat_mode == "nav1") {
    		
    			var nav1_error = getprop("/autopilot/internal/nav1-track-error-deg");
    			
    			var bank = limit(nav1_error, 30);
    			
    			setprop(servo~ "aileron", 0);
    			
    			setprop(servo~ "aileron-nav1", 1); 	
    			
    			setprop(servo~ "target-bank", bank);
    		
    		} # else, this is handed over from fcu to fmgc
    	
    	}
    	
    	## VERTICAL CONTROL ----------------------------------------------------
    	
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
    	
    	} # End of AP1 Master Check
    	
    	# FMGC CONTROL MODE ====================================================
    	
    	if ((me.spd_ctrl == "fmgc") and (me.a_thr == "eng")) {
    	
    	var cur_wp = getprop("autopilot/route-manager/current-wp");
    	
    	## AUTO-THROTTLE -------------------------------------------------------
    	
    	var spd = getprop("/autopilot/route-manager/route/wp[" ~ cur_wp ~ "]/ias-mach");
    	
    	if (spd == nil) {
			
			if (altitude <= 10000)
				spd = 250;
			else
				spd = 0.78;
    	
    	}
    	
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
    	
    	}
    	
    	if ((me.ap1 == "eng") or (me.ap2 == "eng")) {
    	
    	## LATERAL CONTROL -----------------------------------------------------
    	
    	if (me.lat_ctrl == "fmgc") {
    	
    		# If A procedure's NOT being flown, we'll fly the active F-PLN
    	
    		if (getprop("/flight-management/procedures/active") == "off") {
    	
    		var bug = getprop("/autopilot/internal/true-heading-error-deg");
			
			var accuracy = getprop(settings~ "gps-accur");

			var bank = 0; 
			
			if (accuracy == "HIGH")
				bank = limit(bug, 25);
			else
				bank = limit(bug, 15);
			
			setprop(servo~  "aileron", 1);
			
			setprop(servo~ "aileron-nav1", 0);
			
			setprop(servo~ "target-bank", bank);
			
			# Else, fly the respective procedures
			
			} else {
			
				if (getprop("/flight-management/procedures/active") == "sid") {
				
					procedure.fly_sid();
					
					var bug = getprop("/flight-management/procedures/sid/course");
					
					var bank = -1 * defl(bug, 25);					
					
					setprop(servo~  "aileron", 1);
					
					setprop(servo~ "aileron-nav1", 0);
					
					setprop(servo~ "target-bank", bank);
				
				} elsif (getprop("/flight-management/procedures/active") == "star") {
				
					procedure.fly_star();
					
					var bug = getprop("/flight-management/procedures/star/course");
					
					var bank = -1 * defl(bug, 25);					
					
					setprop(servo~  "aileron", 1);
					
					setprop(servo~ "aileron-nav1", 0);
					
					setprop(servo~ "target-bank", bank);
				
				} else {
				
					procedure.fly_iap();
					
					var bug = getprop("/flight-management/procedures/iap/course");
					
					var bank = -1 * defl(bug, 28);					
					
					setprop(servo~  "aileron", 1);
					
					setprop(servo~ "aileron-nav1", 0);
					
					setprop(servo~ "target-bank", bank);
				
				}
			
			}
    	
    	}
    	
    	## VERTICAL CONTROL ----------------------------------------------------

		if (me.ver_ctrl == "fmgc") {
		
			var current_wp = getprop("/autopilot/route-manager/current-wp");
			
			var target_alt = getprop("/autopilot/route-manager/route/wp[" ~ current_wp ~ "]/altitude-ft");

			if (target_alt == nil)
				target_alt = altitude;
			
			if (target_alt < 0)
				target_alt = altitude;
			
			var alt_diff = target_alt - altitude;
			
			var final_vs = 0;
			
			if (math.abs(alt_diff) >= 100) {
				
				var ground_speed_kt = getprop("/velocities/groundspeed-kt");
			
				var leg_dist_nm = getprop("/instrumentation/gps/wp/leg-distance-nm");
			
				var leg_time_hr = leg_dist_nm / ground_speed_kt;
			
				var leg_time_sec = leg_time_hr * 3600;
			
				var target_fps = (alt_diff / leg_time_sec) + 5;
			
				final_vs = limit(target_fps, 50);
			
			}
			
			setprop(servo~ "target-vs", final_vs);
    				
			setprop(servo~ "elevator-vs", 1);
			
			setprop(servo~ "elevator", 0);
			
			setprop(servo~ "elevator-gs", 0);
		
		}
		
		} # End of AP1 MASTER CHECK

	},
		get_settings : func {
		
		me.spd_mode = getprop(fmgc~ "spd-mode");
		me.spd_ctrl = getprop(fmgc~ "spd-ctrl");
		
		me.lat_mode = getprop(fmgc~ "lat-mode");
		me.lat_ctrl = getprop(fmgc~ "lat-ctrl");
		
		me.ver_mode = getprop(fmgc~ "ver-mode");
		me.ver_ctrl = getprop(fmgc~ "ver-ctrl");
		
		me.ver_sub = getprop(fmgc~ "ver-sub");
		
		me.ap1 = getprop(fmgc~ "ap1-master");
		me.ap2 = getprop(fmgc~ "ap2-master");
		me.a_thr = getprop(fmgc~ "a-thrust");
	
	},
	
		lvlch_check : func {
		
		if ((me.ap1 == "eng") or (me.ap2 == "eng")) {
		
			var vs_fps = getprop("/velocities/vertical-speed-fps");
		
			if (math.abs(vs_fps) > 8)
				setprop("/flight-management/fcu/level_ch", 1);
			else
				setprop("/flight-management/fcu/level_ch", 0);
		
		} else
			setprop("/flight-management/fcu/level_ch", 0);
		
	},
	
		knob_sum : func {

		var ias = getprop(fcu~ "ias");
		
		var mach = getprop(fcu~ "mach");
		
		setprop(fcu~ "spd-knob", ias + (100 * mach));
		
		var vs = getprop(fcu~ "vs");
		
		var fpa = getprop(fcu~ "fpa");
		
		setprop(fcu~ "vs-knob", fpa + (vs/100));
		
	},
		hdg_disp : func {
		
		var hdg = getprop(fcu~ "hdg");
		
		if (hdg < 10)
			setprop(fcu~ "hdg-disp", "00" ~ hdg);
		elsif (hdg < 100)
			setprop(fcu~ "hdg-disp", "0" ~ hdg);
		else
			setprop(fcu~ "hdg-disp", "" ~ hdg);
		
	},
	
		fcu_lights : func {
		
		if (me.lat_mode == "nav1")
			setprop(fmgc~ "fcu/nav1", 1);
		else
			setprop(fmgc~ "fcu/nav1", 0);
			
		if (me.ver_mode == "ils")
			setprop(fmgc~ "fcu/ils", 1);
		else
			setprop(fmgc~ "fcu/ils", 0);
			
		if (me.a_thr == "eng")
			setprop(fmgc~ "fcu/a-thrust", 1);
		else
			setprop(fmgc~ "fcu/a-thrust", 0);
			
		if (me.ap1 == "eng")
			setprop(fmgc~ "fcu/ap1", 1);
		else
			setprop(fmgc~ "fcu/ap1", 0);
			
		if (me.ap2 == "eng")
			setprop(fmgc~ "fcu/ap2", 1);
		else
			setprop(fmgc~ "fcu/ap2", 0);
		
	},
	
		alt_100 : func {
		
		var alt = getprop("/instrumentation/altimeter/indicated-altitude-ft");
		
		return int(alt/100);
		
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