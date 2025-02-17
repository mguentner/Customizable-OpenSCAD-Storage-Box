$fn=20;

/*[Part]*/
// Select part to render
PART = "container"; //[container, lid, latch]

/*[Dimensions]*/
// Add a top rim
RIM = true;

// Internal or External Lock
INTERNAL_LOCK = false;

// Container Length in mm
BOX_L_OUTER = 165; //[50:5:300]

// Container Width in mm
BOX_W_OUTER = 120; //[50:5:300]

// Container Height in mm
BOX_H_OUTER =  22; //[20:5:300]

// Lid Thickness in mm
LID_H = 3; //[3:1:10]

// Corner Radius in mm
CORNER_RADIUS = 3; //[1:1:10]

// Top Rim in mm 
RIM_W = 3; //[3:1:10]

// Outer Wall Thickness
WALL_THICKNESS = 1.5; //[1:0.5:10]

// Inner Wall Thickness
DIVIDER_THICKNESS = 1; //[1:1:10]

// Floor Thickness
FLOOR_THICKNESS = 1; //[1:1:10]

// Number of Divisions on the Long Edge
DIVISIONS_L =1; //[0:1:20]

// Number of Divisions on the Short Edge
DIVISIONS_W =3; //[0:1:20]


// Width of Lock Fixtures
FIXTURE_W = 5; //[3:1:10]

// Thickness of Lock Fixtures
FIXTURE_THICKNESS = 4; //[3:1:10]

// Width of Interlocking Mechanism
LOCK_W = 35; //[20:2.5:50]

// Depth of Internal Lock
INTERNAL_LOCK_DEPTH = 15; //[10:1:20]

// Diamenter of Lock Bolts
LOCK_BOLT_D = 1.3; //[1:0.1:4]

/*[Hidden]*/
module __customizer_limit__ () {};
//above 2 lines make sure customizer does not show parameters below

BOX_L = BOX_L_OUTER-2*CORNER_RADIUS; // Box Width
BOX_W = BOX_W_OUTER-2*CORNER_RADIUS; // Box Length
BOX_H = BOX_H_OUTER; // Box Height

POST_OFFSET=10;

// Offset between snapping parts
PART_OFFSET = 0.3;

///////////////////////////////////////////////////////////////////////////////
// Modules
///////////////////////////////////////////////////////////////////////////////

module base_plate(length, width, thickness){
	corner_coordinates = [ [0,0],[0,length],[width,length],[width,0] ];

	translate ( [-width/2, -length/2] ) {
		hull(){
			for (i = corner_coordinates) {
				translate(i) cylinder(r=CORNER_RADIUS,h=thickness);
			};
		};
	};
};

module container_hull() {
  ext_h = RIM ? BOX_H-RIM_W : BOX_H;
  linear_extrude( ext_h )
		difference(){
			offset(r=CORNER_RADIUS) 
				square( [BOX_W , BOX_L ], center=true );

			offset( r = CORNER_RADIUS - WALL_THICKNESS )
				square([BOX_W - WALL_THICKNESS, BOX_L - WALL_THICKNESS], center=true );
		}
	base_plate(BOX_L, BOX_W, FLOOR_THICKNESS);
};

module box_rim () {
	difference(){
		hull(){
			//upper face
			translate([0,0,-RIM_W/2]){
				linear_extrude(RIM_W/2){
					offset(r=CORNER_RADIUS)
					  square( [BOX_W+RIM_W, BOX_L+RIM_W], center=true );
				};
			};
			//lower face
			translate([0,0,-2*RIM_W]){
				linear_extrude(RIM_W/2){
					offset(r=CORNER_RADIUS) 
						square( [BOX_W, BOX_L], center=true );
				};
			};
		};
		//cutout
		union(){
		  //upper
			translate ([0,0,-2]) {
				linear_extrude(5){
					offset(r=CORNER_RADIUS+.3)
						square([BOX_W-RIM_W/4+PART_OFFSET,BOX_L-RIM_W/4+PART_OFFSET],
						center=true);
				};
			};
			//lower
			translate([0,0,-BOX_H/2])
				linear_extrude(BOX_H){
					offset( r= CORNER_RADIUS - WALL_THICKNESS )
						square( [BOX_W-WALL_THICKNESS, BOX_L-WALL_THICKNESS], center=true );
				};
		};
	};
};

module fixture_holes(offset_bottom) {
		union() {

			hole_offset=INTERNAL_LOCK ? -INTERNAL_LOCK_DEPTH/4 : FIXTURE_THICKNESS/2;
			cut=LOCK_W+WALL_THICKNESS*4;
			//upper
			translate([-cut/2,hole_offset,BOX_H-5])
				rotate (90,[0,1,0])
		  		cylinder(cut,LOCK_BOLT_D,LOCK_BOLT_D);
			//lower
			translate([-cut/2,hole_offset,offset_bottom])
				rotate (90,[0,1,0])
			  	cylinder(cut,LOCK_BOLT_D,LOCK_BOLT_D);
		};
};

module lock_fixture() {
  offset_bottom=FIXTURE_THICKNESS;
	difference () {
		translate([0,0,offset_bottom])
			union() {
			  translate([0,0,-FIXTURE_THICKNESS])
					cube([FIXTURE_W,0.3,BOX_H-2]);
				translate([0,0.3,0])
					cube([FIXTURE_W,FIXTURE_THICKNESS,BOX_H-offset_bottom]);
				translate([0,0.3,0])
				  //rounded bottom
					intersection() {
						rotate(90, [0,1,0])
						  cylinder (r=FIXTURE_THICKNESS,h=FIXTURE_W);
						translate([0,0,-FIXTURE_THICKNESS])
						  cube([FIXTURE_W,FIXTURE_THICKNESS,FIXTURE_THICKNESS]);
					};
			};
		//fixture holes
		fixture_holes(offset_bottom);
	};
};

module lock_internal() {
		width=LOCK_W;
		depth=INTERNAL_LOCK_DEPTH;
		translate ([0,BOX_L_OUTER/2,1])
		difference () {
			linear_extrude(BOX_H-RIM_W)
				difference () {
				  offset(3) square([width, depth], center=true);
				  square([width, depth], center=true);
				};
				translate([-width,0,0]) cube([width*2,INTERNAL_LOCK_DEPTH,BOX_H]);
				fixture_holes(FIXTURE_THICKNESS+2);
		};
};

module lock_cutout(offset) {
  cut_depth = INTERNAL_LOCK ? INTERNAL_LOCK_DEPTH : RIM_W+FIXTURE_THICKNESS;
	cut_offset = INTERNAL_LOCK ? offset-cut_depth/2 : offset;
	translate ([-LOCK_W/2,cut_offset,-3])
		linear_extrude(BOX_H*2)
  //		offset(r=CORNER_RADIUS)
    		square([LOCK_W,cut_depth]);
};

module division(count, length, width) {
  step_x=width/(count+1) ;
	for (i=[1:count]) {
	translate ([-width/2+i*step_x,0,BOX_H/2-0.5])
		cube([DIVIDER_THICKNESS,length+RIM_W,BOX_H-RIM_W],center=true);
		};
	};

module hinge() {
	difference () {
		union () {
		  //hinge lever
			translate ([0,0,6])
				cube([FIXTURE_W, FIXTURE_THICKNESS,LID_H-3]);
			rotate(90, [0,1,0]) {
				translate([-3-LID_H,FIXTURE_THICKNESS/2,0])
					cylinder (r=FIXTURE_THICKNESS/2, h=FIXTURE_W);
			};
			//upper rounding
			translate ([0,0,FIXTURE_THICKNESS])
				rotate(90, [0,1,0]) {
					intersection () {
						cylinder (r=FIXTURE_THICKNESS, h=FIXTURE_W);
						cube([FIXTURE_W*2,FIXTURE_THICKNESS*2,FIXTURE_W]);
					};
				};
		};
		  //add holes for bolt
	    translate([-1,FIXTURE_THICKNESS/2,LID_H+3])	
				rotate(90, [0,1,0]) 
						cylinder (r=LOCK_BOLT_D, h=FIXTURE_W*2);
	};
};

module lid_phase(){
  translate ([BOX_L/2-FIXTURE_W,BOX_W/2+0.5,LID_H-2])
  rotate (45,[1,0,0]) cube([BOX_L,LID_H,LID_H]);
};

///////////////////////////////////////////////////////////////////////////////
// Derived Variables
///////////////////////////////////////////////////////////////////////////////

fixture_offset = BOX_L/2 + CORNER_RADIUS;

fixture_coordinates = [ [LOCK_W/2,fixture_offset],
                        [-LOCK_W/2-FIXTURE_W,fixture_offset]];

hinge_offset = BOX_L/2 + CORNER_RADIUS;
hinge_coordinates = [	[LOCK_W/2-FIXTURE_W, hinge_offset, 0],
                      [-LOCK_W/2, hinge_offset, 0]];

///////////////////////////////////////////////////////////////////////////////
// Parts
///////////////////////////////////////////////////////////////////////////////

// container
////////////

if (PART == "container"){
	union() {
		difference (){
			union () {
				//create base shape
				container_hull();

				//add top rim
				if (RIM){
					translate([0,0,BOX_H]) {
						box_rim();
					};
				};
      
				//add division
				if (DIVISIONS_W > 0) {
				division(DIVISIONS_W, BOX_L, BOX_W);
				};
				if (DIVISIONS_L > 0) {
				rotate (90,[0,0,1])
				division(DIVISIONS_L, BOX_W, BOX_L);
				};
			};

			//make space for locking mechanism
			lock_cutout(fixture_offset);
			mirror ([0,1,0]){
				lock_cutout(fixture_offset);
			};
		};

		//add lock fixtures
		if (INTERNAL_LOCK) {
			lock_internal();
			mirror([0,1,0]) {
				lock_internal();
			};
		}
		else {
			for (i = fixture_coordinates) {
				translate (i) lock_fixture();
			}
			mirror ([0,1,0]){
				for (i = fixture_coordinates) {
					translate (i) lock_fixture();
				};
			};
		};
	};
};

// lid
//////

if (PART == "lid"){
	union() {
		difference() {
		  //lid with interlocking ledge
			union(){
				base_plate(BOX_L, BOX_W, LID_H);
				if (RIM) {
					base_plate(BOX_L + RIM_W, BOX_W + RIM_W, LID_H-2);
				};
			};
			//make space for latch / hinge
			lock_cutout(fixture_offset);
			lid_phase();
			mirror ([0,1,0])
				lock_cutout(fixture_offset);
			mirror ([1,0,0])
   			lid_phase();
		};
		//add hinges
			for (i = hinge_coordinates) {
				translate (i) hinge();
			}
	};
};

// latch
if (PART == "latch"){
	union () {
		cylinder(r=100,h=1);
		linear_extrude (3)
			text("Sry, not designed yet. :(",halign="center",valign="center");
	};
};
