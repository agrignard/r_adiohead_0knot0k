// Author: Arnaud Grignard (forked from dataarts/radiohead) implemented on GAMA 1.8
model r_adiohead_10kandOK

global{
  point zRange<-{0,-200};
  point offset<-{0,0,0};
  float scale<-1.0;
  point angleAxes<-{0,0,1};
  bool updateCloudFile<-false;
  bool static<-true;
  bool wandering<-true;
  bool drawEnv<-true;
  float pointSize parameter: 'point size ' category: "Visualization" min: 0.1 max:5.0 <- 1.0;
  init {
  	matrix data <- matrix(csv_file("../includes/not_ok.csv",""));
    shape <- computeBoundingBox(data);
	loop i from: 1 to: data.rows -1{
		  create pointCloud{		
		    source<-{-offset.x+float(data[0,i])*scale,-offset.y+float(data[1,i])*scale,(float(data[2,i])*scale)-offset.z};
			target<-{-offset.x+float(data[0,i])*scale,-offset.y+float(data[1,i])*scale,offset.z+float(data[2,i])*scale};	
			location<-source;
			depth<-float(data[3,i]);		
			intensity<-float(data[3,i]);
	      }	  
	  }
  }
    
  action reInitModel{
  	ask pointCloud{
  		location<-source;
  	}
  }
  
  action filter(float xMin, float xMax,float yMin, float yMax, float zMin, float zMax){
  	ask pointCloud{
  		if(location.x<xMax and location.x>xMin and location.y<yMax and location.y>yMin and location.z<zMax and location.z>zMin){
  			save [location.x,location.y, location.z,depth,intensity] to: "../includes/filter.csv" type:"csv" rewrite: false;
  		}
  	}
  }
  
  
  geometry computeBoundingBox(matrix data){
  	float max<-10000.0;
  	float xMin<-max;
  	float xMax<--max;
  	float yMin<-max;
  	float yMax<--max;
  	float zMin<-max;
  	float zMax<--max;
  	loop i from: 1 to: data.rows -1{
		if (float(data[0,i])<xMin){
			xMin<-float(data[0,i]);
		}
		if (float(data[0,i])>xMax){
			xMax<-float(data[0,i]);
		}
		if (float(data[1,i])<yMin){
			yMin<-float(data[1,i]);
		}
		if (float(data[1,i])>yMax){
			yMax<-float(data[1,i]);
		}
		if (float(data[2,i])<zMin){
			zMin<-float(data[2,i]);
		}
		if (float(data[2,i])>zMax){
			zMax<-float(data[2,i]);
		}
  	}
  	offset<-{xMin,yMin,zMin};
  	return box(xMax-xMin,yMax-yMin,zMax-zMin) at_location {(xMax-xMin)/2,(yMax-yMin)/2,zMin};
  	
  }
}

species pointCloud skills:[moving]{
	float intensity;
	point source;
	point target;
	float depth;

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
		display pointcloud type:opengl background:#black  draw_env:true synchronized:true fullscreen:false{
    	graphics "env"{
    		if(drawEnv){
    		  draw shape color: rgb(50*1.1,50*1.6,200,255) empty:true;	
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