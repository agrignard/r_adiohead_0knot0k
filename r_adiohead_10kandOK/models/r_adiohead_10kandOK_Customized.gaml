// Author: Arnaud Grignard (forked from dataarts/radiohead) implemented on GAMA 1.8
model r_adiohead_10kandOK

global{
  bool wandering parameter: 'wandering (w)' category: "Visualization" <- false;
  bool goto parameter: 'goto (g)' category: "Visualization" <- false;
  bool drawEnv parameter: 'drawEnv (e)' category: "Visualization" <- false;
  bool variableSize parameter: 'variableSize (b)' category: "Visualization" <- false;
  bool drawDust parameter: 'dust (d)' category: "Visualization" <- false;
  bool spirals parameter: 'spirales (s)' category: "Visualization" <- false;
  float noiseAmpMax parameter: 'Noise amplitude ' category: "Visualization" min: 0.0 max: 20.0 <- 5.0;
  float noisePower  parameter: 'Noise irregularity ' category: "Visualization" min: 1.0 max: 20.0 <- 14.0;
  float pointSize parameter: 'point size ' category: "Visualization" min: 0.1 max:2.0 <- 1.0;
  point angleAxes <-{0,0,1}; 
  point offset <-{0,0,0};
  list<point> targetOffsetList <- [{0,0,0},{200,200,100},{-100,150,-20},{-125,-20,30}];
  int currentTarget <- 1;

  float noiseAmp;
  
  float maxIntensity;
  float minIntensity;
  bool waveExists <- false;
  float velocity <- 1.0;
  float caracDist <- 20.0;
  float waveLength <- 10.0;
  float mitigationDist <-60.0;
  float waveOffset <- 50.0;
  float waveRotationAngle <- 140.0;

  
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

////---> INITIALISATION DES VOISINS POUR LES VAGUES. COMMENTE POUR GAGNER DU TEMPS A L'INITIALISATION, NE PAS ENLEVER
//	loop i from:0 to: length(pointCloud)-2 {// écrit à la main car distance_at déconne
//		loop j from: i+1 to: length(pointCloud)-1{
//			if (pointCloud[i] distance_to pointCloud[j] < 4){
//				pointCloud[i].neighbours <- pointCloud[i].neighbours + [pointCloud[j]]; 
//				pointCloud[j].neighbours <- pointCloud[j].neighbours + [pointCloud[i]]; 
//			}
//		}
//	}
////-------------------------------------------------------------------------------------------------------------------

	ask pointCloud[4310]{
		self.a <- 1.0;
		self.b <- 1.0;
	}
	maxIntensity <- max(column_at(data,3)) as float;
	minIntensity <- min(column_at(data,3)) as float;
  }
  
  reflex noizify{
  	noiseAmp <- noiseAmpMax*(rnd(100)/100)^noisePower;
  }
  
	reflex changeTarget when: goto {
		if (pointCloud count(each.location = each.target)/length(pointCloud) > 0.4){
			currentTarget <- mod(currentTarget+1, length(targetOffsetList));
			ask pointCloud {target <- source + targetOffsetList[currentTarget];}
		}
  	}
}

species pointCloud skills:[moving3D]{
	float intensity;
	point source;
	point target;
	float mag;
	list<pointCloud> neighbours <- [];
	
	float a <- 0.0;
	float b <- 0.0;
	float oldA <- 0.0;
	float oldB <- 0.0;
	float spiralCoeff <- 1.0;

	reflex move{
		if(wandering){
		  do wander speed:intensity/1000;	
		}
		if(goto){
			do goto target:target speed:intensity/30;		
		}	
	}
	
	reflex updateSpiral when: spirals{
		oldA <- a;
		a <- 2 * a * exp(-b);
		b <- oldA * (1 - exp(-b));
		oldA <- a;
		oldB <- b;
		a <- 0.2 * a + 0.8 * sum(neighbours collect(each.oldA/length(each.neighbours)));
		b <- 0.2 * b + 0.8 * sum(neighbours collect(each.oldB/length(each.neighbours)));
	}
	
		
	reflex update_color{
		spiralCoeff <- spirals?(1-min([1,a / 10]))^2:1;
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

	
	
	reflex computeMagnitude when: waveExists{
		mag <-  first(wave).magnitude(self.location);
		//write wave accumulate each.magnitude(self.location);
		//mag <-  mul(wave accumulate each.magnitude(self.location));
	}

	
	aspect base { 
		if waveExists{
			draw rotated_by(square(pointSize* (variableSize ? intensity/100: 1)),mag*waveRotationAngle,{1,0,0}) color:rgb(intensity*1.1*(0.5+spiralCoeff)/1.5*(1-mag),intensity*1.6*(0.5+spiralCoeff)/1.5*(1-mag),200,50) rotate: cycle*intensity/10::angleAxes at: location + {0,0,mag*waveOffset} + {0,0,noiseAmp*sqrt(-2*ln(0.01+rnd(99)/100))*cos(360*rnd(100)/100)};	
//			draw rotated_by(square(pointSize*intensity/100),mag*waveRotationAngle,{1,0,0}) color:rgb(intensity*1.1*(1-mag),intensity*1.6*(1-mag),200,50) rotate: cycle*intensity/10::angleAxes at: location + {0,0,mag*waveOffset};	
		}else{
		draw rotated_by(square(pointSize* (variableSize ? intensity/100:1)),(1-spiralCoeff)*30,{0,1,0}) color:rgb(intensity*1.1*(0.5+spiralCoeff)/1.5,intensity*1.6*(0.5+spiralCoeff)/1.5,200,50) rotate: cycle*intensity/10::angleAxes at: location + {0,0,noiseAmp*sqrt(-2*ln(0.01+rnd(99)/100))*cos(360*rnd(100)/100)};
//			draw square(pointSize*intensity/100) color:rgb(intensity*1.1,intensity*1.6,200,50) rotate: cycle*intensity/10::angleAxes;	
		}
	}
}

species wave{
	int startCycle;
	int endCycle; 
	
	init{
		waveExists <- true;
		bool chooseLocation <- true;
		pointCloud tmp;
		loop while: chooseLocation {
			tmp <- one_of(pointCloud);
			if flip((tmp.intensity-minIntensity)/(maxIntensity-minIntensity)){chooseLocation <- false;}
		}
		self.location <- {tmp.location.x,tmp.location.y,0};//epicenter; 
		startCycle <- cycle+30;
		endCycle <- startCycle+ max([world.shape.width-self.location.x,world.shape.height-self.location.y,self.location.x,self.location.y])/velocity as int;
		write "Wave starts at cycle ";
	}
	
	
	
	float magnitude(point p){
		float dist <- self.location distance_to({p.x,p.y,0});
		float tmp <- dist/caracDist - velocity/caracDist*(cycle-first(wave).startCycle);
		return 0.5*exp(-abs(tmp))*(1+cos(360*min([0,tmp])*caracDist/waveLength))/(1+dist/mitigationDist)^2;
	}
	
	reflex dispose when: (cycle = endCycle) or !waveExists {
		waveExists <- false;
		write "killed";
		do die;
	}
}

species dust skills: [moving]{
	point rotationAxe;
	float intensity;
	float zSpeed <- 1.0;
	float z;
	float zMin;
	
	reflex move{
		zSpeed <- zSpeed * 1.01;
		z <- z - zSpeed;
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
			event["b"] action: {variableSize<-!variableSize;};
			event["w"] action: {wandering<-!wandering;};
			event["g"] action: {goto<-!goto;};
			event["x"] action: {angleAxes<-{1,0,0};};
			event["y"] action: {angleAxes<-{0,1,0};};
			event["z"] action: {angleAxes<-{0,0,1};};
			event["t"] action: {angleAxes<-{1,1,1};};
			event["i"] action: {ask pointCloud{location<-source;}};	
			event["p"] action: {waveExists <- !waveExists;if waveExists {create wave;}};
			event["o"] action: {waveExists <- !waveExists;if waveExists {create wave {location <- #user_location;}}};
			//event["o"] action: {waveExists <- true;create wave {location <- #user_location;}};
			event["d"] action: {drawDust<-!drawDust;};	
			event["s"] action: {spirals<-!spirals;};	
		}	
	}
}

