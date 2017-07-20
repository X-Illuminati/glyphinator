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
 * TODO
 *
 *****************************************************************************/

/*
 * 2dbitmap - Turn a 2D vector into a bitmap of cubes
 *
 * bitmap - 2D vector with z-height for each cube
 * center - center cubes around the origin
 * expansion - size of gap around each pixel (screendoor)
 */
module 2dbitmap(bitmap=[[1,0],[0,1]], center=false, expansion=0)
{
	ylen=len(bitmap)-1;

	for (y=[0:ylen]) {
		xlen=len(bitmap[y])-1;
		for (x=[0:xlen])
			translate([x-(center?xlen/2:0),
			           ylen-y-(center?ylen/2:0),
			           0])
				cube([1-expansion,
				      1-expansion,
				      bitmap[y][x]],
				     center=center);
	}
}

module 1dbitmap(bitmap=[1,0,1,0,1], center=false, expansion=0)
	2dbitmap([bitmap], center, expansion);

translate([0,10,0]) scale([1,10,1])
	1dbitmap(bitmap=[1,1,0,2,0,0,1], center=true, expansion=.1);

scale([2,2,1])
	2dbitmap(bitmap=[[1,0,2,1],[0,3,3,0],[1,1,0,1]],
		center=true);
