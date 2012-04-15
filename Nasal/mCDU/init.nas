var co_tree = "/database/co_routes/";
var active_rte = "/flight-management/active-rte/";
var altn_rte = "/flight-management/alternate/route/";

var mCDU_init = {

	co_rte : func (mcdu, id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
		
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
		
			if (rte_id == id) {
			
				var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
				var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
				var flt_num = getprop(co_tree~ "route[" ~ index ~ "]/flight-num");
			
				me.rte_sel(id, dep, arr, flt_num);
			
			} else
				setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/msg", "NOT IN DATABASE");
		
		}
	
	},
	
	rte_sel : func (id, dep, arr, flt_num) {
	
		# The Route Select function is the get the selected route and put those stuff into the active route
		
		setprop(active_rte~ "id", id);
		setprop(active_rte~ "depicao", dep);
		setprop(active_rte~ "arricao", arr);
		setprop(active_rte~ "flight-num", flt_num);
		
		me.set_active_rte(id);
	
	},
	
	set_active_rte : func (id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
	
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
	
			if (rte_id == id) {
			
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
					setprop(active_rte~ "route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
					
					if (getprop(route~ "wp[" ~ wp ~ "]/altitude-ft") != nil)
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop(route~ "wp[" ~ wp ~ "]/altitude-ft"));
					else
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", 0);
					
					if (getprop(route~ "wp[" ~ wp ~ "]/ias-mach") != nil)
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(route~ "wp[" ~ wp ~ "]/ias-mach"));
					else
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", 0);
						
					# While using the FMGS to fly, if altitude or ias-mach is 0, then the FMGS predicts appropriate values between the previous and next values. If none of the values are entered, the FMGS leaves out that specific control to ALT HOLD or IAS/MACH HOLD
				
				} # End of WP-Copy For Loop
			
			} # End of Route ID Check
	
		} # End of Route-ID For Loop
	
	},
	
	flt_num : func (mcdu, flight_num) {
	
		var flt_num_rte = 0;
		
		var results = "/instrumentation/mcdu[" mcdu "]/flt-num-results/";
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/flight-num") != nil; index += 1) {
		
			var flight_num_chk = getprop(co_tree~ "route[" ~ index ~ "]/flight-num");
			
			if (flight_num_chk == flight_num) {
			
				setprop(results~ "result[" ~ flt_num_rte ~ "]/rte_id", getprop(co_tree~ "route[" ~ index ~ "]/rte_id"));
				
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
					setprop(results~ "result[" ~ flt_num_rte ~ "]/route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
				
				} # End of Waypoints Copy Loop

			} # End of Flight Number Check
			
			flt_num_rte += 1;
		
		} # End of Flight Number Loop
		
		setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/page", "FLT-NUM_RESULTS");
	
	},
	
	from_to : func (mcdu, from, to) {
	
		var from-to_rte = 0;
		
		var results = "/instrumentation/mcdu[" mcdu "]/from-to-results/";
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/depicao") != nil; index += 1) {
		
			var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
			
			var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
			
			if ((from == dep) and (to == arr)) {
			
				setprop(results~ "result[" ~ from-to_rte ~ "]/rte_id", getprop(co_tree~ "route[" ~ index ~ "]/rte_id"));
				
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
					setprop(results~ "result[" ~ from-to_rte ~ "]/route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
				
				} # End of Waypoints Copy Loop

			} # End of From-To Check
			
			from-to_rte += 1;
		
		} # End of From-To Loop
		
		setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/page", "FROM-TO_RESULTS");
	
	},
	
	altn_co_rte : func (mcdu, icao, id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
		
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
		
			if (rte_id == id) {
			
				var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
				var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
				var flt_num = getprop(co_tree~ "route[" ~ index ~ "]/flight-num");
			
				me.altn_rte_sel(id, dep, arr, flt_num);
			
			} else
				setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/msg", "NOT IN DATABASE");
		
		}
		
		setprop("flight-management/alternate/icao", icao);
	
	},
	
	altn_rte_sel : func (id, dep, arr, flt_num) {
	
		# The Route Select function is the get the selected route and put those stuff into the alternate route
		
		setprop(altn_rte~ "id", id);
		setprop(altn_rte~ "depicao", dep);
		setprop(altn_rte~ "arricao", arr);
		setprop(altn_rte~ "flight-num", flt_num);
		
		me.set_altn_rte(id);
	
	},
	
	set_altn_rte : func (id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
	
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
	
			if (rte_id == id) {
			
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
					setprop(altn_rte~ "route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
					
					if (getprop(route~ "wp[" ~ wp ~ "]/altitude-ft") != nil)
						setprop(altn_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop(route~ "wp[" ~ wp ~ "]/altitude-ft"));
					else
						setprop(altn_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", 0);
					
					if (getprop(route~ "wp[" ~ wp ~ "]/ias-mach") != nil)
						setprop(altn_rte~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(route~ "wp[" ~ wp ~ "]/ias-mach"));
					else
						setprop(altn_rte~ "route/wp[" ~ wp ~ "]/ias-mach", 0);
				
				} # End of WP-Copy For Loop
			
			} # End of Route ID Check
	
		} # End of Route-ID For Loop
	
	}	

};
