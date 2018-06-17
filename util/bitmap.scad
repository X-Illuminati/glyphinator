/*****************************************************************************
 * Module Bitmap Library
 * Modules to create bitmaps of unit squares from 1 or 2 dimensional vectors.
 *****************************************************************************
 * Copyright 2017 Chris Baker
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
 * Include this file with the "use" tag.
 *
 * API:
 *   1dbitmap(bitmap, center, expansion, vector_mode)
 *   2dbitmap(bitmap, center, expansion, vector_mode)
 *     Generate a 1 or 2-Dimensional field of modules based on the provided
 *     bitmap vector. See Bitmap Vectors below.
 *     The center flag determines whether to center the bitmap on the origin.
 *     The expansion value actually shrinks each cube in the x and y
 *     dimension by the specified amount.
 *     The vector_mode flag determines whether to create 3D solid geometry
 *     (unit cubes) or 2D vector geometry (squares).
 *
 * Bitmap Vectors:
 *   The bitmap vectors primarily provide boolean information.
 *   A module will be placed where these vectors have a postive value and
 *   skipped where they have a negative value. I.E. 0, -1, false, and undef
 *   are all equivalent and result in a skip. 1 and true are equivalent and
 *   result in a placed 1-unit module.
 *   Further, if the value is an integer it will be treated as a height for
 *   the module, allowing z-maps to be created.
 *   If the value is not an integer or boolean, it will be treated as a color
 *   reference. This can be a string or RGBA vector that will be used to
 *   color the module in the OpenSCAD preview window.
 *   In current versions of OpenSCAD, the color has no effect in the rendered
 *   view or STL output.
 *
 * Vector Mode:
 *   Although OpenSCAD supports generating 2D geometry, there are several
 *   caveats:
 *   - 2D and 3D geometry cannot be mixed
 *   - Extruding 2D geometry causes color information to be lost
 *   - All 2D geometry is projected onto the XY plane when rendering
 *   - Rendering also results in loss of color (same as 3D)
 *   - The SVG exporter is somewhat limited:
 *     - The pixel size of the image is hard-coded in the file
 *     - The title of the image is a generic string
 *     - The color selection for stroke and fill is fixed
 *     - The stroke-width is set to a large value that will cause overlap
 *     - The background is transparent
 *     - Only one path element is created with all of the geometry; there is
 *       no easy way to split up the geometry into multiple logical units.
 *     - These issues can mostly be resolved by hand-editing the file:
 *       - Remove or modify the width and height parameters from the svg
 *         element at the top of the file to provide better scaling.
 *       - Edit the title element at the top of the file to change the title.
 *       - Edit the stroke and fill parameters of the path element (these will
 *         probably be at the end of the file).
 *       - Set the stroke-width parameter for the path element to 0.
 *****************************************************************************/

/*
 * 2dbitmap - Turn a 2D vector into a bitmap of cubes
 *
 * bitmap - 2D vector representing where to place each cube
 *          Value can either be boolean, z-height, or color
 * center - center cubes around the origin
 * expansion - size of gap around each pixel (screendoor)
 * vector_mode - create a 2D vector drawing instead of 3D extrusion
 */
module 2dbitmap(bitmap=[[1,0],[0,1]], center=false, expansion=0, vector_mode=false)
{
	ylen=len(bitmap)-1;

	for (y=[0:ylen]) {
		xlen=len(bitmap[y])-1;
		for (x=[0:xlen])
			translate([x-(center?xlen/2:0),ylen-y-(center?ylen/2:0),0])
				if (len(bitmap[y][x]))
					color(bitmap[y][x])
						if (vector_mode)
							square([1-expansion,1-expansion], center=center);
						else
							cube([1-expansion,1-expansion,1], center=center);
				else
					if (bitmap[y][x])
						if (vector_mode)
							square([1-expansion,1-expansion], center=center);
						else
							cube([1-expansion,1-expansion,bitmap[y][x]], center=center);
	}
}

module 1dbitmap(bitmap=[1,0,1,0,1], center=false, expansion=0, vector_mode=false)
	2dbitmap([bitmap], center, expansion, vector_mode);

/*
 * Examples
 */

// 1D with z-height
translate([0,10,0]) scale([1,10,1])
	1dbitmap(bitmap=[1,1,0,2,0,0,3], center=true, expansion=.1);

// 1D with boolean
translate([-20,0,0]) scale([1,10,1])
	1dbitmap(bitmap=[true,false,true,false,true,true]);

// 2D with z-height
scale([2,2,1])
	2dbitmap(bitmap=[[1,0,2,1],[0,3,3,0],[1,1,0,1]],
		center=true);

// 1D with color
translate([0,-10,0]) scale([1,3,1])
	1dbitmap(bitmap=["red","white","blue",[0,0.3,0,0.5]]);

// 1D with color using 2D-vector-mode
translate([-7,-8,0]) scale([1,2])
	1dbitmap(bitmap=["red",0,"blue",0,"green"], vector_mode=true);
translate([-4.5,-10,0]) scale([1,2])
	1dbitmap(bitmap=["red",0,"blue",0,"green"], vector_mode=true, center=true);
