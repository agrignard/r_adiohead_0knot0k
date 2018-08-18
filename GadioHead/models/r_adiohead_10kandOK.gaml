// Author: Arnaud Grignard (forked from dataarts/radiohead) implemented on GAMA 1.8
model r_adiohead_10kandOK

global{
  point zRange<-{0,-200};
  point offset<-{25,25,100};
  float scale<-0.25;
  point angleAxes<-{0,0,1};
  bool updateCloudFile<-false;
  bool static<-true;
  bool wandering<-true;
  bool drawEnv<-true;
  init {
  	matrix data <- matrix(csv_file("../includes/ok.csv",""));
	loop i from: 1 to: data.rows -1{
	   	if(float(data[2,i])<zRange.x and float(data[2,i])>(zRange.y)){
		  create pointCloud{		
		    source<-{offset.x+float(data[0,i])*scale,offset.y+float(data[1,i])*scale,offset.z+float(data[2,i])*scale};
			target<-{-offset.x+float(data[0,i])*scale,-offset.y+float(data[1,i])*scale,offset.z+float(data[2,i])*scale};	
			location<-source;		
			intensity<-float(data[3,i]);
	      }	  
	    }	
	  }
  }
    
  action reInitModel{
  	ask pointCloud{
  		location<-source;
  	}
  }
}

species pointCloud skills:[moving]{
	float intensity;
	point source;
	point target;

	reflex move{
		if(!static){
			if(wandering){
			  do wander speed:intensity/1000;	
			}
			else{
			do goto target:target speed:intensity/100;	
			}	
		}
		
	}
	aspect base{
      draw square(scale) color:rgb(intensity*1.1,intensity*1.6,200,255) rotate: cycle::angleAxes;
	}
}

experiment OK type:gui {
	float minimum_cycle_duration <- 0.0333; //(fps 30)
	output{
		display pointcloud type:opengl background:#black  draw_env:false synchronized:true fullscreen:true{
    	graphics "env"{
    		if(drawEnv){
    		  draw cube(100) color: rgb(50*1.1,50*1.6,200,255) empty:true;	
    		}  
        }
	    species pointCloud aspect:base;
			event["e"] action: {drawEnv<-!drawEnv;};
			event["s"] action: {static<-!static;};
			event["w"] action: {wandering<-!wandering;};
			event["x"] action: {angleAxes<-{1,0,0};};
			event["y"] action: {angleAxes<-{0,1,0};};
			event["z"] action: {angleAxes<-{0,0,1};};
			event["i"] action: reInitModel;	
		}	
	}
}