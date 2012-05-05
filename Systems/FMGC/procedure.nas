var fmgc_root = "/systems/flight-management/";

var procedure = {

	check : func() {
	
		var rte_len = getprop("/autopilot/route-manager/route/num");
	
		if ((getprop(fmgc_root~"procedures/sid/active-sid/name") != "------") and (getprop(fmgc_root~"current-wp") == 1) and (getprop(fmgc_root~"procedures/sid-current") != getprop(fmgc_root~"procedures/sid-transit")) and (getprop(fmgc_root~"control/lat-ctrl") == "fmgc")) { # Standard Departure
		
			return "sid";
		
		} elsif ((getprop(fmgc_root~"procedures/sid/active-star/name") != "------") and (getprop(fmgc_root~"current-wp") == (rte_len - 1)) and (getprop(fmgc_root~"procedures/star-current") != getprop(fmgc_root~"procedures/star-transit")) and (getprop(fmgc_root~"control/lat-ctrl") == "fmgc")) {
		
			return "star";
		
		} elsif ((getprop(fmgc_root~"procedures/iap/active-iap/name") != "------") and (getprop(fmgc_root~"procedures/star-current") == getprop(fmgc_root~"procedures/star-transit")) and (getprop(fmgc_root~"procedures/iap-current") != getprop(fmgc_root~"procedures/iap-transit")) and (getprop(fmgc_root~"control/lat-ctrl") == "fmgc")) { 

			return "iap";
		
		} else {
		
			return "off";
		
		}
	
	},
	
	reset_tp : func() {
	
		setprop(fmgc_root~"procedures/active", "off");
		
		setprop(fmgc_root~"procedures/sid-current", 0);
		
		setprop(fmgc_root~"procedures/star-current", 0);
		
		setprop(fmgc_root~"procedures/iap-current", 0);
	
	},
	
	fly_sid : func() {
	
		var current_wp = getprop(fmgc_root~"procedures/sid-current");
		
		var target_lat = getprop(fmgc_root~"procedures/sid/active-sid/wp[" ~ current_wp ~ "]/latitude-deg");
		
		var target_lon = getprop(fmgc_root~"procedures/sid/active-sid/wp[" ~ current_wp ~ "]/longitude-deg");
		
		if ((target_lat == 0) or (target_lon == 0))
			setprop(fmgc_root~"procedures/sid-current", current_wp + 1);
			
		var current_wp = getprop(fmgc_root~"procedures/sid-current");
		
		setprop(fmgc_root~"procedures/sid/course", me.course_to(target_lat, target_lon));
		
		var pos_lat = getprop("/position/latitude-deg");
		
		var pos_lon = getprop("/position/longitude-deg");
		
		var accuracy = 0.02;
		
		if ((math.abs(pos_lat - target_lat) <= accuracy) and (math.abs(pos_lon - target_lon) <= accuracy)) {
		
			setprop(fmgc_root~"procedures/sid-current", current_wp + 1);
			
			var current_wp = getprop(fmgc_root~"procedures/sid-current");
			
			var transit_wp = getprop(fmgc_root~"procedures/sid-transit");
		
			if (current_wp < transit_wp) {
		
				print("--------------------------");
				print("[FMGC] SID: " ~ getprop(fmgc_root~"procedures/sid/active-sid/name") ~ " > WP" ~ (current_wp - 1) ~ " Reached...");
				print("[FMGC] SID: " ~ getprop(fmgc_root~"procedures/sid/active-sid/name") ~ " > TARGET SET: " ~ getprop(fmgc_root~"procedures/sid/active-sid/wp[" ~ current_wp ~ "]/name"));
			
			} else {
			
				print("--------------------------");
				print("[FMGC] TRANSITION TO F-PLN");
			
			}
			
		}
	
	},
	
	fly_star : func() {
	
		var current_wp = getprop(fmgc_root~"procedures/star-current");
		
		var target_lat = getprop(fmgc_root~"procedures/star/active-star/wp[" ~ current_wp ~ "]/latitude-deg");
		
		var target_lon = getprop(fmgc_root~"procedures/star/active-star/wp[" ~ current_wp ~ "]/longitude-deg");
		
		if ((target_lat == 0) or (target_lon == 0))
			setprop(fmgc_root~"procedures/star-current", current_wp + 1);
			
		var current_wp = getprop(fmgc_root~"procedures/star-current");
		
		setprop(fmgc_root~"procedures/star/course", me.course_to(target_lat, target_lon));
		
		var pos_lat = getprop("/position/latitude-deg");
		
		var pos_lon = getprop("/position/longitude-deg");
		
		var accuracy = 0.02;
		
		if ((math.abs(pos_lat - target_lat) <= accuracy) and (math.abs(pos_lon - target_lon) <= accuracy)) {
		
			setprop(fmgc_root~"procedures/star-current", current_wp + 1);
			
			var current_wp = getprop(fmgc_root~"procedures/star-current");
			
			var transit_wp = getprop(fmgc_root~"procedures/star-transit");
		
			if (current_wp < transit_wp) {
		
				print("--------------------------");
				print("[FMGC] STAR: " ~ getprop(fmgc_root~"procedures/star/active-star/name") ~ " > WP" ~ (current_wp - 1) ~ " Reached...");
				print("[FMGC] STAR: " ~ getprop(fmgc_root~"procedures/star/active-star/name") ~ " > TARGET SET: " ~ getprop(fmgc_root~"procedures/star/active-star/wp[" ~ current_wp ~ "]/name"));
			
			} else {
			
				print("--------------------------");
				print("[FMGC] TRANSITION TO APPROACH");
			
			}
			
		}
	
	},
	
	fly_iap : func() {
	
	var current_wp = getprop(fmgc_root~"procedures/iap-current");
		
		var target_lat = getprop(fmgc_root~"procedures/iap/active-iap/wp[" ~ current_wp ~ "]/latitude-deg");
		
		var target_lon = getprop(fmgc_root~"procedures/iap/active-iap/wp[" ~ current_wp ~ "]/longitude-deg");
		
		if ((target_lat == 0) or (target_lon == 0))
			setprop(fmgc_root~"procedures/iap-current", current_wp + 1);
			
		var current_wp = getprop(fmgc_root~"procedures/iap-current");
		
		setprop(fmgc_root~"procedures/iap/course", me.course_to(target_lat, target_lon));
		
		var pos_lat = getprop("/position/latitude-deg");
		
		var pos_lon = getprop("/position/longitude-deg");
		
		var accuracy = 0.02;
		
		if ((math.abs(pos_lat - target_lat) <= accuracy) and (math.abs(pos_lon - target_lon) <= accuracy)) {
		
			setprop(fmgc_root~"procedures/iap-current", current_wp + 1);
			
			var current_wp = getprop(fmgc_root~"procedures/iap-current");
			
			var transit_wp = getprop(fmgc_root~"procedures/iap-transit");
		
			if (current_wp < transit_wp) {
		
				print("--------------------------");
				print("[FMGC] IAP: " ~ getprop(fmgc_root~"procedures/iap/active-iap/name") ~ " > WP" ~ (current_wp - 1) ~ " Reached...");
				print("[FMGC] IAP: " ~ getprop(fmgc_root~"procedures/iap/active-iap/name") ~ " > TARGET SET: " ~ getprop(fmgc_root~"procedures/iap/active-iap/wp[" ~ current_wp ~ "]/name"));
			
			} else {
			
				print("--------------------------");
				print("[FMGC] ---------- END OF F-PLN ----------");
			
			}
			
		}
	
	},
	
	course_to : func(lat,lon) {
	
		var aircraft_pos = geo.aircraft_position();
	
		var wp_pos = geo.Coord.new();
		
		wp_pos.set_latlon(lat, lon);
		
		var course_to_wp = aircraft_pos.course_to(wp_pos);
		
		return course_to_wp;
	
	},

};
