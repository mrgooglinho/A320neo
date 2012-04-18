var co_tree = "/database/co_routes/";
var active_rte = "/flight-management/active-rte/";
var altn_rte = "/flight-management/alternate/route/";

setprop("/instrumentation/mcdu/input", "");

# Initialize with 0 Brightness

setprop("/instrumentation/mcdu/brt", 0);

# Set Default Tropo to 36090 (airbus default)

setprop("/flight-management/tropo", "36090");

# Empty Field Symbols are used when values are "empty" for strings and 0 for numbers, you set values with the functions when programming the FMGC

setprop(active_rte~ "id", "empty");
setprop(active_rte~ "depicao", "empty");
setprop(active_rte~ "arricao", "empty");
setprop(active_rte~ "flight-num", "empty");

setprop("/flight-management/alternate/icao", "empty");
setprop(altn_rte~ "depicao", "empty");
setprop(altn_rte~ "arricao", "empty");

setprop("/flight-management/cost-index", 0);
setprop("/flight-management/crz_fl", 0);

var mCDU_init = {

	co_rte : func (mcdu, id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
		
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
		
			if (rte_id == id) {
			
				var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
				var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
			
				me.rte_sel(id, dep, arr);
			
			} else
				setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/input", "ERROR: NOT IN DATABASE");
		
		}
		
		f_pln.init_f_pln();
	
	},
	
	rte_sel : func (id, dep, arr) {
	
		# The Route Select function is the get the selected route and put those stuff into the active route
		
		setprop(active_rte~ "id", id);
		setprop(active_rte~ "depicao", dep);
		setprop(active_rte~ "arricao", arr);
		
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
					else {
					
						# Use CRZ FL
						
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop("/flight-management/crz_fl") * 100);
					
					}
					
					if (getprop(route~ "wp[" ~ wp ~ "]/ias-mach") != nil)
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(route~ "wp[" ~ wp ~ "]/ias-mach"));
					else {
					
						var spd = 0;
			
						# Use 250 kts if under FL100 and 0.78 mach if over FL100
				
						if (alt <= 10000)
							spd = 250;
						else
							spd = 0.78;
							
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", spd);
			
					}
						
					# While using the FMGS to fly, if altitude or ias-mach is 0, then the FMGS predicts appropriate values between the previous and next values. If none of the values are entered, the FMGS leaves out that specific control to ALT HOLD or IAS/MACH HOLD
				
				} # End of WP-Copy For Loop
			
			} # End of Route ID Check
	
		} # End of Route-ID For Loop
	
	},
	
	flt_num : func (mcdu, flight_num) {
	
		var flt_num_rte = 0;
		
		var results = "/instrumentation/mcdu[" ~ mcdu ~ "]/flt-num-results/";
	
################################################################################	
	
		# Come back later
		
################################################################################
		
		setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/page", "FLT-NUM_RESULTS");
	
	},
	
	from_to : func (mcdu, from, to) {
	
		var from_to_rte = 0;
		
		var results = "/instrumentation/mcdu[" ~mcdu~ "]/from-to-results/";
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/depicao") != nil; index += 1) {
		
			var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
			
			var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
			
			if ((from == dep) and (to == arr)) {
			
				setprop(results~ "result[" ~ from_to_rte ~ "]/rte_id", getprop(co_tree~ "route[" ~ index ~ "]/rte_id"));
				
				var route = co_tree~ "route[" ~ index ~ "]/route/";
				
				for (var wp = 0; getprop(route~ "wp[" ~ wp ~ "]/wp-id") != nil; wp += 1) {
				
					setprop(results~ "result[" ~ from_to_rte ~ "]/route/wp[" ~ wp ~ "]/wp-id", getprop(route~ "wp[" ~ wp ~ "]/wp-id"));
				
				} # End of Waypoints Copy Loop

			} # End of From-To Check
			
			from_to_rte += 1;
		
		} # End of From-To Loop
		
		setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/page", "FROM-TO_RESULTS");
	
	},
	
	altn_co_rte : func (mcdu, icao, id) {
	
		for (var index = 0; getprop(co_tree~ "route[" ~ index ~ "]/rte_id") != nil; index += 1) {
		
			var rte_id = getprop(co_tree~ "route[" ~ index ~ "]/rte_id");
		
			if (rte_id == id) {
			
				var dep = getprop(co_tree~ "route[" ~ index ~ "]/depicao");
				var arr = getprop(co_tree~ "route[" ~ index ~ "]/arricao");
			
				me.altn_rte_sel(id, dep, arr);
			
			} else
				setprop("/instrumentation/mcdu[" ~ mcdu ~ "]/input", "ERROR: NOT IN DATABASE");
		
		}
		
		setprop("flight-management/alternate/icao", icao);
	
	},
	
	altn_rte_sel : func (id, dep, arr) {
	
		# The Route Select function is the get the selected route and put those stuff into the alternate route
		
		setprop(altn_rte~ "id", id);
		setprop(altn_rte~ "depicao", dep);
		setprop(altn_rte~ "arricao", arr);
		
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
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop(route~ "wp[" ~ wp ~ "]/altitude-ft"));
					else {
					
						# Use CRZ FL
						
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/altitude-ft", getprop("/flight-management/crz_fl") * 100);
					
					}
					
					if (getprop(route~ "wp[" ~ wp ~ "]/ias-mach") != nil)
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", getprop(route~ "wp[" ~ wp ~ "]/ias-mach"));
					else {
					
						var spd = 0;
			
						# Use 250 kts if under FL100 and 0.78 mach if over FL100
				
						if (alt <= 10000)
							spd = 250;
						else
							spd = 0.78;
							
						setprop(active_rte~ "route/wp[" ~ wp ~ "]/ias-mach", spd);
			
					}
				
				} # End of WP-Copy For Loop
			
			} # End of Route ID Check
	
		} # End of Route-ID For Loop
	
	}

};
