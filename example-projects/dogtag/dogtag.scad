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
qr_dimension=49; //depends on version determined from qr_code_data
round_radius=3;
hole_radius=2.5;
thickness=2;
layer_height=.1;
xy_scale=.5;
name_font="Liberation Sans:style=Regular";

/* derived values (don't modify) */
rr=round_radius/xy_scale;
hr=hole_radius/xy_scale;
tl=thickness/layer_height;
el=tl-1;
dim=qr_dimension;

/* generate dog tag */
scale([xy_scale,xy_scale,layer_height])
{
	intersection()
	{
		color ([0,0,0,0])
			union()
			{
				translate([rr,0])
					cube([dim-rr-rr,dim,tl]);
				translate([0,rr])
					cube([dim,dim-rr-rr,tl]);
				translate([dim-rr,rr])
					cylinder(h=tl,r=rr);
				translate([dim-rr,dim-rr])
					cylinder(h=tl,r=rr);
				translate([rr,dim-rr])
					cylinder(h=tl,r=rr);
				translate([rr,rr])
					cylinder(h=tl,r=rr);
			}
		union() {
			difference() {
				union()
				{
					if (mark_space_select!=1)
						color("white")
							cube([dim,dim,el]);
					translate([0,0,el])
						quick_response(
							qr_code_data,
							ecc_level=0,
							mark=(mark_space_select!=0)?"black":0,
							space=(mark_space_select!=1)?"white":0,
							quiet_zone=(mark_space_select!=1)?"white":0
						);
				}
				color("white")
					translate([dim-hr-rr/2,dim/2,-1])
						cylinder(h=tl+2,r=hr);
				translate([dim/2,dim/2,0])
					rotate(-90)
						mirror([1,0,0])
							linear_extrude(height=1)
								text(dog_name, font=name_font,
									halign="center", valign="center");
			}
			if (mark_space_select!=0) color("black")
				translate([dim/2,dim/2,0])
					rotate(-90)
						mirror([1,0,0])
							linear_extrude(height=1)
								text(dog_name, font=name_font,
									halign="center", valign="center");
		}
	}
}
