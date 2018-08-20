// Author: Arnaud Grignard (forked from dataarts/radiohead) implemented on GAMA 1.8
model r_adiohead_10kandOK

global{
  bool wandering parameter: 'wandering (w)' category: "Visualization" <- false;
  bool goto parameter: 'goto (g)' category: "Visualization" <- false;
  bool drawEnv parameter: 'drawEnv (e)' category: "Visualization" <- false;
  bool variableSize parameter: 'variableSize (b)' category: "Visualization" <- false;
  float pointSize parameter: 'point size ' category: "Visualization" min: 0.1 max:2.0 <- 1.0;
  point angleAxes <-{0,0,1}; 
  point offset <-{0,0,0};
  matrix data;
  init {
    do initModel();
  }
  
  action initModel{
    do coreInit();
    do customInit();
  }
  
  action coreInit{
  	data <- matrix(csv_file("../includes/not_ok.csv",""));
    offset<-{float(min(column_at (data , 0))),float(min(column_at (data , 1))),float(min(column_at (data , 2)))};
    shape<- box(float(max(column_at (data , 0)))-float(min(column_at (data , 0))),float(max(column_at (data , 1)))-float(min(column_at (data , 1))),float(max(column_at (data , 2)))-float(min(column_at (data , 2)))) 
    at_location {(float(max(column_at (data , 0)))-float(min(column_at (data , 0))))/2,(float(max(column_at (data , 1)))-float(min(column_at (data , 1))))/2,float(min(column_at (data , 2)))};
	loop i from: 1 to: data.rows -1{
	  create pointCloud{		
	    source<-{-offset.x+float(data[0,i]),-offset.y+float(data[1,i]),(float(data[2,i]))-offset.z};
		target<-{-offset.x+float(data[0,i]),-offset.y+float(data[1,i]),1000+float(data[2,i])-offset.z};	
		location<-source;		
		intensity<-float(data[3,i]);
      }	  
	}	
  }
  action customInit;
}

species pointCloud skills:[moving]{
	float intensity;
	point source;
	point target;

	reflex move{
		if(wandering){
		  do wander speed:intensity/1000;	
		}
		if(goto){
		do goto target:target speed:intensity/100000;	
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
	float minimum_cycle_duration <- 0.0333;
	output{
		display pointcloud type:opengl background:rgb(0,0,15)  draw_env:false synchronized:true fullscreen:false toolbar:false{
    	graphics "env"{
    		if(drawEnv){
    		  draw shape color: rgb(50*1.1,50*1.6,200,255) empty:true;	
    		}  
        }
	    species pointCloud aspect:base;
			event["e"] action: {drawEnv<-!drawEnv;};
			event["b"] action: {variableSize<-!variableSize;};
			event["w"] action: {wandering<-!wandering;};
			event["g"] action: {goto<-!goto;};
			event["x"] action: {angleAxes<-{1,0,0};};
			event["y"] action: {angleAxes<-{0,1,0};};
			event["z"] action: {angleAxes<-{0,0,1};};
			event["t"] action: {angleAxes<-{1,1,1};};
			event["i"] action: {ask pointCloud{location<-source;}};	
		}	
	}
}