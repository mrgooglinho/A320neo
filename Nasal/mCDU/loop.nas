# This loop Updates every 10 seconds

var mCDU_loop_10 = {
       init : func {
            me.UPDATE_INTERVAL = 10;
            me.loopid = 0;
            
            setprop("/instrumentation/mcdu/f-pln/disp/first", 0);
            
            me.reset();
    },
       update : func {

    	# Position String
    	
    	setprop("/instrumentation/mcdu/pos-string", getprop("/position/latitude-string") ~ "/" ~ getprop("/position/longitude-string"));
    	
    	# Always start at the 'start' page and have f-pln start at beginning
    	
    	if (getprop("/instrumentation/mcdu/brt") == 0) {
    		setprop("/instrumentation/mcdu/page", "start");
    		setprop("/instrumentation/mcdu/f-pln/disp/first", 0);
    	}
    	
    	var rte_dist = getprop(rm_route~ "wp-last/dist");
    	
    	if (rte_dist != nil)
			setprop(f_pln_disp~ "dist", int(rte_dist));
		else
			setprop(f_pln_disp~ "dist", "----");

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
 mCDU_loop_10.init();
 });
