// Author: Arnaud Grignard (forked from dataarts/radiohead) implemented on GAMA 1.8
model r_adiohead_10kandOK

global{
	init {
	  matrix data <- matrix(csv_file("../includes/ok.csv",""));
	  loop i from: 1 to: data.rows -1{
		  create pointCloud{		
		    target<-{rnd(100),rnd(100),rnd(100)};
			location<-{float(data[0,i]),float(data[1,i]),float(data[2,i])};
			intensity<-float(data[3,i]);
	      }		
	  }		
  }
}

species pointCloud skills:[moving]{
	float intensity;
	point target;

	reflex move{
		do goto target:target speed:intensity/1000;
	}
	aspect{
		draw square(1) color:rgb(intensity*1.1,intensity*1.6,200,255);
	}
}

experiment OK type:gui {
	output{
		display pointcloud type:opengl background:#black draw_env:false fullscreen:true camera_pos: {100,100,500} camera_look_pos: {100,100,0} camera_up_vector: {0,0,0}{
			species pointCloud;
		}
	}
}