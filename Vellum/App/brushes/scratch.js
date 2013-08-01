function scratch(){
	this.init();
}

scratch.prototype = {
	context: null,
	target : { x:0, y:0 },
	prev : { x:0, y:0, nib:0, angle:0 },
	interpolation_multiplier : 0.5,
    distance_multiplier : 2.5,
    nib_multiplier : 0.25,
	step : 1.5,

	init : function(){
		this.context = VLM.state.context;
	    if ( window.devicePixelRatio == 1 ){
	        this.interpolation_multiplier = 0.333;
	        this.distance_multiplier = 1.25;
			this.nib_multiplier = 0.25;
			this.step = 1.5;
	    }

	},
	
	begin : function(x,y){
        var prev = this.prev,
            target = this.target;
		prev.x = x;
		prev.y = y;
		prev.angle = 0;
		prev.nib = 0;
		target.x = x;
		target.y = y;
	},
	
	continue : function(x,y){
        var prev = this.prev,
            target = this.target;
		target.x = x;
		target.y = y;
	},
    
	end : function(x,y){
	    var prev = this.prev,
	        target = this.target;
	    target.x = x;
	    target.y = y;
	},
	
	tick : function(){
        var prev = this.prev,
            target = this.target,
            interpolation_multiplier = this.interpolation_multiplier,
            distance_multiplier = this.distance_multiplier,
            nib_multiplier = this.nib_multiplier;

		var x = prev.x + (target.x - prev.x) * interpolation_multiplier,
	        y = prev.y + (target.y - prev.y) * interpolation_multiplier,
	        //dx = x - prev.x,
	        //dy = y - prev.y,
            dx = target.x-x,
            dy = target.y-y,
	        dist = Math.sqrt(dx * dx + dy * dy),
	        state = VLM.state,
	        zoomlevel = state.zoomlevel,
	        threshold = 0.001 / (zoomlevel * 1000),
			fgcolor = 'rgba(242,242,232,0.666)';
			
        // overwrite fgcolor with whatever is in state
        var col = state.color,
        rgba = col.rgba,
        alpha = rgba[3]*0.666;
        fgcolor = 'rgba(' + rgba[0] + ',' + rgba[1] + ',' + rgba[2] + ',' + alpha + ')';
        

	    if (dist >= threshold) {
			var angle = Math.atan2(dy, dx) - Math.PI / 2,
            curnib = (prev.nib + dist * distance_multiplier) * nib_multiplier,
            multiplier = 0.25,
            count = 0,
            cosangle = Math.cos(angle),
            sinangle = Math.sin(angle),
            cospangle = Math.cos(prev.angle),
            sinpangle = Math.sin(prev.angle),
            vertexCount = 0,
            ctx = this.context;

            
            var currange = curnib * multiplier,
                prevrange = prev.nib * multiplier;

            if (zoomlevel < 10) {
                ctx.lineWidth = 0.5; // solid lines MOIRE
                ctx.beginPath();
                ctx.strokeStyle = fgcolor;

                var step = this.step;
                for (var i = -currange; i <= currange; i += step) {
                    var pct = i / currange,
                    localx = x + cosangle * pct * currange,
                    localy = y + sinangle * pct * currange,
                    localpx = prev.x + cospangle * pct * prevrange,
                    localpy = prev.y + sinpangle * pct * prevrange;
					ctx.moveTo(localpx, localpy);
	                ctx.lineTo(localx, localy);
                }
				
                ctx.stroke();
                ctx.closePath();
            } else {
                ctx.beginPath();
                ctx.lineWidth = 0.45;
                ctx.strokeStyle = fgcolor;
                ctx.moveTo(x, y);
                ctx.lineTo(prev.x, prev.y);
                ctx.stroke();
                ctx.closePath();
            }
            
			prev.angle = angle;
			prev.nib = curnib;
		}
	    prev.x = x;
	    prev.y = y;
	},
	
	destroy : function(){
		this.target = null;
		this.prev = null;	
		this.context = null;
		this.interpolation_multiplier = null;
	    this.distance_multiplier = null;
	    this.nib_multiplier = null;
		this.grr_fg = null;
	}
};
