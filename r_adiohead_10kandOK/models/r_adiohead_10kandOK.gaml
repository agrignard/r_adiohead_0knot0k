// Author: Arnaud Grignard (forked from dataarts/radiohead) implemented on GAMA 1.8
model r_adiohead_10kandOK

global{
  bool wandering parameter: 'wandering (w)' category: "Visualization" <- false;
  bool goto parameter: 'goto (g)' category: "Visualization" <- false;
  bool drawEnv parameter: 'drawEnv (e)' category: "Visualization" <- false;
  bool drawDust parameter: 'dust d' category: "Visualization" <- false;
  float pointSize parameter: 'point size ' category: "Visualization" min: 0.1 max:2.0 <- 1.0;
  point angleAxes <-{0,0,1}; 
  point offset <-{0,0,0};
  list<point> targetOffsetList <- [{200,200,100},{-100,150,-20},{-125,-20,30},{0,0,0}];
  int currentTarget <- 1;
  int onTarget <- 0;
  
  bool waveExists <- false;
  point epicenter;
  float velocity <- 1.0;
  float caracDist <- 20.0;
  float waveLength <- 10;
  float mitigationDist <-100;
  float waveOffset <- 50;
  float waveRotation <- 140;

  

  
  init {
  	matrix data <- matrix(csv_file("../includes/not_ok.csv",""));
    offset<-{float(min(column_at (data , 0))),float(min(column_at (data , 1))),float(min(column_at (data , 2)))};
    shape<- box(float(max(column_at (data , 0)))-float(min(column_at (data , 0))),float(max(column_at (data , 1)))-float(min(column_at (data , 1))),float(max(column_at (data , 2)))-float(min(column_at (data , 2)))) 
    at_location {(float(max(column_at (data , 0)))-float(min(column_at (data , 0))))/2,(float(max(column_at (data , 1)))-float(min(column_at (data , 1))))/2,float(min(column_at (data , 2)))};
	loop i from: 1 to: data.rows -1{
	  create pointCloud{		
	    source<-{-offset.x+float(data[0,i]),-offset.y+float(data[1,i]),float(data[2,i])-offset.z};
		target<-{-offset.x+float(data[0,i]),-offset.y+float(data[1,i]),float(data[2,i])-offset.z}+targetOffsetList[currentTarget];	
		location<-source;
		intensity<-float(data[3,i]);
      }	  
	}
	epicenter <- {shape.width/2,shape.height/2,0};
  }
  
  
 
  
  reflex changeTarget when: (onTarget/length(pointCloud) > 0.5){
  	onTarget <- 0;
  	currentTarget <- mod(currentTarget+1, length(targetOffsetList));
  	ask pointCloud {
  		isOnTarget <- false;
  		target <- source + targetOffsetList[currentTarget];
  	}
  }
  

//   reflex changeTarget when: (pointCloud count(each.location = each.target)/length(pointCloud) > 0.5   //code plus lent
//   ){
//  	onTarget <- 0;
//  	currentTarget <- mod(currentTarget+1, length(targetOffsetList));
//  	ask pointCloud {
//  		//isOnTarget <- false;
//  		target <- source + targetOffsetList[currentTarget];
//  	}
//  }
  
  

}

species pointCloud skills:[moving]{
	float intensity;
	point source;
	point target;
	bool isOnTarget <- false;


	reflex move{
		if(wandering){
		  do wander speed:intensity/1000;	
		}
		if(goto){
			do goto target:target speed:intensity/30;			
			if !isOnTarget and (location = target) {isOnTarget <- true; onTarget <- onTarget + 1;}// c'est un peu crade, mais c'est pour que ça tourne plus vite
																					// l'autre solution c'est de compter tous ceux qui sont sur la cible à chaque cycle, 
		}	
	}
	
	reflex createDust when: drawDust and flip(0.01) {
		create dust{
			self.location <- myself.location;
			self.intensity <- myself.intensity;
			z <- self.location.z;
			zMin <- z - 150;
			int theta <- rnd(-180,180);
			int phi <- rnd(-90,90);
			rotationAxe <-{ cos(phi) * cos(theta), cos(phi) * sin(theta),sin(phi)};
		}
	}
	
	aspect base { 
		if waveExists{
			float mag <-  first(wave).magnitude(self.location);
			draw rotated_by(square(pointSize*intensity/100),mag*waveRotation,{1,0,0}) color:rgb(intensity*1.1*(1-mag),intensity*1.6*(1-mag),200,50) rotate: cycle*intensity/10::angleAxes at: location + {0,0,mag*waveOffset};	
		}else{
			draw square(pointSize*intensity/100) color:rgb(intensity*1.1,intensity*1.6,200,50) rotate: cycle*intensity/10::angleAxes;	
		}	
	}
}

species wave{
	int startCycle;
	int endCycle; 
	
	init{
		waveExists <- true;
		point tmp <- one_of(pointCloud).location;
		self.location <- {tmp.x,tmp.y,0};//epicenter;
		startCycle <- cycle+30;
		endCycle <- startCycle+0.5*max([world.shape.width,world.shape.height])/velocity as int;
		write "Wave starts at cycle "+startCycle;
	}
	
	float magnitude(point p){
		float dist <- self.location distance_to({p.x,p.y,0});
		float tmp <- dist/caracDist - velocity/caracDist*(cycle-first(wave).startCycle);
		return 0.5*exp(-abs(tmp))*(1+cos(360*min([0,tmp])*caracDist/waveLength))/(1+dist/mitigationDist)^2;
	}
	
	reflex dispose when: (cycle = endCycle) or !waveExists {
		waveExists <- false;
		do die;
	}
}

species dust skills: [moving]{
	point rotationAxe;
	float intensity;
	float speed <- 1.0;
	float z;
	float zMin;
	
	reflex move{
		speed <- speed * 1.01;
		z <- z - speed;
		do wander speed:50/(1+intensity);
		location <- {location.x, location.y, z};
		if (z < zMin) or !drawDust {do die;}
	}
	
	aspect base { 
			draw square(pointSize*intensity/100) color:rgb(intensity*1.1,intensity*1.6,200,50) rotate: cycle*10::rotationAxe;		
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
        species dust aspect:base;
	    species pointCloud aspect:base;
			event["e"] action: {drawEnv<-!drawEnv;};
			event["w"] action: {wandering<-!wandering;};
			event["g"] action: {goto<-!goto;};
			event["x"] action: {angleAxes<-{1,0,0};};
			event["y"] action: {angleAxes<-{0,1,0};};
			event["z"] action: {angleAxes<-{0,0,1};};
			event["t"] action: {angleAxes<-{1,1,1};};
			event["i"] action: {ask pointCloud{location<-source;}};	
			event["p"] action: {waveExists <- !waveExists;if waveExists {create wave;}};
			event["d"] action: {drawDust<-!drawDust;};	
		}	
	}
}

