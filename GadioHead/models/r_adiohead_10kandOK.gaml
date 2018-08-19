// Author: Arnaud Grignard (forked from dataarts/radiohead) implemented on GAMA 1.8
model r_adiohead_10kandOK

global{
  bool static parameter: 'static (s)' category: "Visualization" <- true;
  bool wandering parameter: 'wandering (w)' category: "Visualization" <- true;
  bool variableSize parameter: 'variableSize (b)' category: "Visualization" <- false;
  bool drawEnv parameter: 'drawEnv (e)' category: "Visualization" <- false;
  float pointSize parameter: 'point size ' category: "Visualization" min: 0.1 max:5.0 <- 1.0;
  point angleAxes parameter:'angle (x,y,z)' category: 'Visualization' <-{0,0,1};
  
  point offset <-{0,0,0};
  
  init {
  	matrix data <- matrix(csv_file("../includes/not_ok.csv",""));
    offset<-{float(min(column_at (data , 0))),float(min(column_at (data , 1))),float(min(column_at (data , 2)))};
    shape<- box(float(max(column_at (data , 0)))-float(min(column_at (data , 0))),float(max(column_at (data , 1)))-float(min(column_at (data , 1))),float(max(column_at (data , 2)))-float(min(column_at (data , 2)))) 
    at_location {(float(max(column_at (data , 0)))-float(min(column_at (data , 0))))/2,(float(max(column_at (data , 1)))-float(min(column_at (data , 1))))/2,float(min(column_at (data , 2)))};
	loop i from: 1 to: data.rows -1{
		  create pointCloud{		
		    source<-{-offset.x+float(data[0,i]),-offset.y+float(data[1,i]),(float(data[2,i]))-offset.z};
			target<-{-offset.x+float(data[0,i]),-offset.y+float(data[1,i]),offset.z+float(data[2,i])};	
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
			do goto target:target speed:intensity/100000;	
			}	
		}
	}
	aspect base{
		if(variableSize){
		  draw square(pointSize*intensity/100) color:rgb(intensity*1.1,intensity*1.6,200,50) rotate: cycle*intensity/10::angleAxes;	
		}else{
		  draw square(pointSize) color:rgb(intensity*1.1,intensity*1.6,200,50) rotate: cycle*intensity/10::angleAxes;	
		}
      
	}
}

experiment OK type:gui {
	float minimum_cycle_duration <- 0.0333; //(fps 30)
	output{
		display pointcloud type:opengl background:#black  draw_env:false synchronized:true fullscreen:false{
    	graphics "env"{
    		if(drawEnv){
    		  draw shape color: rgb(50*1.1,50*1.6,200,255) empty:true;	
    		}  
        }
	    species pointCloud aspect:base;
			event["b"] action: {variableSize<-!variableSize;};
			event["e"] action: {drawEnv<-!drawEnv;};
			event["s"] action: {static<-!static;};
			event["w"] action: {wandering<-!wandering;};
			event["x"] action: {angleAxes<-{1,0,0};};
			event["y"] action: {angleAxes<-{0,1,0};};
			event["z"] action: {angleAxes<-{0,0,1};};
			event["t"] action: {angleAxes<-{1,1,1};};
			event["i"] action: reInitModel;	
		}	
	}
}



