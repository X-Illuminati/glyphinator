use <../../barcodes/quick_response.scad>
use <../../util/stringlib.scad>

$fn=20*4;

/* Modify these parameters: */

// Geometry Selection:
// 0 - white base
// 1 - black QR code
// 2 - both (preview-only)
mark_space_select=2;

// Name your dog!
dog_name="Spot";

// Name yourself
owner_name="Jane Doe";
phone_number=[6,3,6,5,5,5,0,1,2,3];
email="asdf@asdf.com";
// address is a little more complicated ...
qr_address_data=concat(
	qr_alphanum("123 F"),
	qr_bytes(
		ascii_to_vec("ake St\nSpringfield,")
	),
	qr_alphanum(" NT 12345")
);

/*
 * QR code content
 * (probably don't need to modify)
 */
qr_code_data = concat(
	qr_bytes(
		ascii_to_vec(
			str(
				"Hello, my name is ",
				dog_name,
				".\nMy owner is ",
				owner_name,
				".\nPH: "
			)
		)
	),
	qr_numeric(phone_number),
	qr_bytes(
		ascii_to_vec(str("\nEMail: ", email, "\nAddr:\n"))
	),
	qr_address_data
);

/*
 * dog tag size/scale parameters
 * (probably don't need to modify these)
 */
name_font="Liberation Sans:style=Regular"; //font to use for dog name
tag_size=40; //edge length of the tag in mm
qr_dimension=41; //depends on version determined from qr_code_data
hole_diameter=5; //diameter (mm) of the hole for clipping onto a collar
round_radius=3; //radius (mm) for the determining the "round-rectangle" shape
thickness=2.6; //thickness of the tag in mm
layer_height=.2; //layer height of the printer in mm
impression_depth=3; //number of layers of depth for the black parts

/* derived values (don't modify) */
dim=qr_dimension+8;
xy_scale=tag_size/dim;
rr=round_radius/xy_scale;
hr=(hole_diameter/2)/xy_scale;
tl=thickness/layer_height; //normalized to "# of layers"
depth=impression_depth;
el=tl-depth;

/* helper module for writing text */
module name_text(height=depth, offset=0)
{
	translate([dim/2,dim/2,offset])
		rotate(-90)
			mirror([1,0,0])
				linear_extrude(height=height)
					text(dog_name, font=name_font,
						halign="center", valign="center");
}

/* generate dog tag */
scale([xy_scale,xy_scale,layer_height])
{ //all z-values within here are "layer number" rather than mm
	difference() //cut corners to make rounded-rectangle
	{
		union() { //square rectangle form of dogtag
			difference() { //subtract hole for collar and name from obverse
				union() //cube with QR code on top
				{
					if (mark_space_select!=1)
						color("white")
							cube([dim,dim,el]);
					translate([0,0,el])
						scale([1,1,depth])
							quick_response(
								qr_code_data,
								ecc_level=0,
								mark=(mark_space_select!=0)?"black":0,
								space=(mark_space_select!=1)?"white":0,
								quiet_zone=(mark_space_select!=1)?"white":0
							);
				}

				//hole for attachment to collar
				color("white")
					translate([dim-hr-rr/2,dim/2,-1])
						cylinder(h=tl+2,r=hr);

				//dog name cut out from obverse
				name_text(height=depth+1,offset=-1);
			}
			//dog name printed on obverse in black
			if (mark_space_select!=0)
				color("black")
					name_text(height=depth+1,offset=-1);
		}

		//create a corner rounding tool to trim square rectangle
		color ("white")
			difference()
			{
				translate([-2,-2,-2])
					cube([dim+4,dim+4,tl+4]);
				union() { //create a rounded rectangle
					translate([rr,-1,-2])
						cube([dim-rr-rr,dim+2,tl+4]);
					translate([-1,rr,-2])
						cube([dim+2,dim-rr-rr,tl+4]);
					translate([dim-rr,rr,-2])
						cylinder(h=tl+4,r=rr);
					translate([dim-rr,dim-rr,-2])
						cylinder(h=tl+4,r=rr);
					translate([rr,dim-rr,-2])
						cylinder(h=tl+4,r=rr);
					translate([rr,rr,-2])
						cylinder(h=tl+45,r=rr);
				}
			}
	}
}
