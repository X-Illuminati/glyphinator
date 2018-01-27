/*****************************************************************************
 * Dogtag
 * Example usage of the  Quick Response barcode generation library
 *****************************************************************************
 * Copyright 2018 Chris Baker
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *****************************************************************************
 * Usage:
 *  1. Set mark_space_select to appropriate value.
 *     The default value of 2 is useful for previewing the design.
 *     Change it to 0 before rendering and exporting an STL.
 *     A value of 1 may be useful for some purposes (like dualstruders).
 *  2. Fill out the dog name, owner name, and contact details.
 *  3. Printability can be greatly improved by reducing the content of the
 *     QR code or increasing the size of the tag.
 *       a. Try playing with the qr_code_data content and observe the
 *          results in the "QR Properties" output in the console log.
 *       b. Anything that can be encoded with qr_alphanum or qr_numeric rather
 *          than qr_bytes will provide substantial space savings.
 *       c. Try increasing tag_size to get individual QR modules larger than
 *          one mm^2, which should produce good results on any printer.
 *  4. Check the dog name on the back of the tag. If it is too long, you may
 *     need to reduce the font size or increase the tag size.
 *  5. After printing, fill in the holes with some sort of darkly-pigmented
 *     epoxy or adhesive. Then sand down the surface once it has dried.
 *
 * Library Dependencies:
 * - barcodes/quick_response.scad
 *   - util/stringlib.scad
 *   - util/bitlib.scad
 *   - util/bitmap.scad
 *   - util/quick_response-util.scad
 *     - util/bitlib.scad
 *     - util/reed-solomon-quick_response.scad
 *       - util/bitlib.scad
 * - util/stringlib.scad
 * - util/quick_response-util.scad
 *
 *****************************************************************************/
use <../../barcodes/quick_response.scad>
use <../../util/stringlib.scad>
use <../../util/quick_response-util.scad>

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
name_font="Liberation Sans:style=Bold"; //font to use for dog name
tag_size=37; //edge length of the tag in mm
hole_diameter=5; //diameter (mm) of the hole for clipping onto a collar
round_radius=3; //radius (mm) for the determining the "round-rectangle" shape
thickness=2.6; //thickness of the tag in mm
layer_height=.2; //layer height of the printer in mm
impression_depth=4; //number of layers of depth for the black parts
dogtag_ecc=0; //0=low, 1=mid, 2=qual, 3=high

/* derived values (don't modify) */
qr_props=qr_get_props_by_data_size(len(qr_code_data), dogtag_ecc);
qr_dimension=qr_prop_dimension(qr_props);
dim=qr_dimension+8;
xy_scale=tag_size/dim;
scaled_round_radius=round_radius/xy_scale;
scaled_hole_radius=(hole_diameter/2)/xy_scale;
tl=thickness/layer_height; //normalized to "# of layers"
depth=impression_depth;
middle_thickness=tl-2*depth;

echo(str("QR Properties:",
"\n  Version=",qr_prop_version(qr_props),
"\n  Dimensions=",qr_dimension,"x",qr_dimension,
"\n  Utilization = [", len(qr_code_data),"/", qr_prop_data_size(qr_props, dogtag_ecc),"]"
));

/*
 * helper operator to round the corners of our squares
 * for some reason it is necessary to round them all separately
 * or else they don't show up properly in the preview
 */
module round_corners(color=undef)
{
	/* helper module for creating the corner rounding tools */
	module round_tool(r, h, rotation=0, x=0, y=0, z=0)
	{
		translate([x,y,z])
			rotate(rotation)
				difference()
				{
					translate([0,-r,0])
						rotate(45)
							cube([r*sqrt(2),r*sqrt(2),h]);
					translate([r,r,-1])
						cylinder(h=h+2,r=r);
				}
	}

	difference()
	{
		children();
		//corner rounding tools to trim the square rectangle
		color(color) {
			round_tool(r=scaled_round_radius,h=tl+2,z=-1);
			round_tool(r=scaled_round_radius,h=tl+2,z=-1,
				rotation=-90,y=dim);
			round_tool(r=scaled_round_radius,h=tl+2,z=-1,
				rotation=-180,x=dim,y=dim);
			round_tool(r=scaled_round_radius,h=tl+2,z=-1,
				rotation=90,x=dim);
		}
	}
}

/* helper module for creating the name plate */
module name_plate() {
	module name_text(height=depth, offset=0)
	{
		translate([dim/2,dim/2,offset])
			rotate(45+180)
				mirror([1,0,0])
					linear_extrude(height=height,convexity=30)
						text(dog_name, font=name_font,
							halign="center", valign="center");
	}

	if (mark_space_select!=1)
		color("white") difference() {
			//base square
			round_corners()
				cube([dim,dim,depth]);
			//dog name cut out
			name_text(height=depth+2,offset=-1);
		}

	//dog name black fill
	if (mark_space_select!=0)
		color("black")
			name_text();
}

/* generate dog tag */
scale([xy_scale,xy_scale,layer_height])
{ //all z-values within here are "layer number" rather than mm
	difference() //subtract a hole for collar attachment
	{
		union() //3-layer sandwich: qr-code top, middle, bottom base with name
		{
			//cube middle
			if (mark_space_select!=1)
				color("white")
					translate([0,0,depth])
						round_corners()
							cube([dim,dim,middle_thickness]);

			//the qr-code creates the top _depth_ layers and is stacked on the rectangular base form
			translate([0,0,middle_thickness+depth])
				scale([1,1,depth])
					round_corners(color="white")
						quick_response(
							qr_code_data,
							ecc_level=dogtag_ecc,
							mark=(mark_space_select!=0)?"black":0,
							space=(mark_space_select!=1)?"white":0,
							quiet_zone=(mark_space_select!=1)?"white":0
						);

			//the name-plate creates the bottom _depth_ layers
			name_plate();
		}

		//hole for attachment to collar
		color("white")
			translate([dim-3-scaled_hole_radius,3+scaled_hole_radius,-1])
				cylinder(h=tl+2,r=scaled_hole_radius);
	}
}
