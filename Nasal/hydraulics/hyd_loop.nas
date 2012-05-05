var hydraulics_loop = {
       init : func {
            me.UPDATE_INTERVAL = 2;
            me.loopid = 0;
            
            me.reset();
    },
    	update : func {
    	
    	
		
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
 hydraulics_loop.init();
 print("Airbus Hydraulics System Initialized");
 });
