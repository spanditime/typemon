include <lib/linear_algebra.scad>;
include <lib/utils.scad>;
include <modules/geometry.scad>;

/////////////////////////////////////////////
/// GENERATED INCLUDES
/////////////////////////////////////////////
include <modules/switches/kailh_choc.scad>;
include <modules/switches/square_dip.scad>;

/////////////////////////////////////////////
/// GENERATED DEBUG VALUES
/////////////////////////////////////////////
DEBUG_all_switch_types = ["regular", "five_way"];

/////////////////////////////////////////////
/// GENERATED CONFIGURATION VALUES
/////////////////////////////////////////////

DEBUG = false;

// matrix size
num_rows = 5; // logical rows (Y direction)
num_cols = 4; // physical columns (X direction)

// keywell parameters
keywell_vertical_radius_mm = 100;
keywell_horizontal_radius_mm = 200.0;
keywell_center_offset_xy = [0, 0];
inner_lip_size = 10;
outer_lip_size = 10;


// base plane tilt angle
base_tilt_angle_deg = 40.0;

// keywell plane thickness
plane_thickness_mm = 2.2;


// switch keycap size
switch_size_x = 17.0;
switch_size_y = 18.0;
switch_size_z = 3.0;

// support shape radius
support_radius_mm = 1;

// base plane parameters
// base plane elevation
base_height_mm = 5.0;
base_plane_thickness_mm = 2.0;

// wall parameters
wall_base_thickness_mm = 4.0;
wall_center_offset_percent = 0.05;


// thumb cluster parameters
thumb_plane_angle_x_deg = -120.0;  // Angle of thumb plane relative to main surface
thumb_plane_angle_y_deg = 0.0;  // Angle of thumb plane relative to main surface
thumb_plane_angle_z_deg = -10.0;  // Angle of thumb plane relative to main surface
thumb_origin_row_index = 1; // Row index to use as origin for thumb cluster
thumb_offset_x = 5.0;          // X offset from origin column
thumb_offset_y = 10.0;        // Y offset from origin column
thumb_offset_z = 0.0;         // Z offset from origin column

// thumb keys positions (relative to thumb plane origin)
thumb_keys = [
    [  [0.0,  0.0,  0], [0.0, 0.0, 0.0], "regular"],
    [ [1.0,  0.0,  -2], [-10.0, 0.0, -5.0], "regular"],
    [ [3.0,  0.0,  -6], [-15.0, 0.0, -7.0], "five_way"]
];

matrix_keys = [
    [// col 0
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"]
    ],[// col 1
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"]
    ],[// col 2
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"]
    ],[// col 3
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"],
        [ [0.0,  0.0,  0], [0.0, 0.0], "regular"]
    ],
];


/////////////////////////////////////////////
/// Generated functions
/////////////////////////////////////////////

// todo: replace 0.5 with tolerance(configurable)
col_spacing_x = switch_size_x + support_radius_mm + 0.5;
row_spacing_y = switch_size_y + support_radius_mm + 0.5;

switch_size = [switch_size_x, switch_size_y, switch_size_z];

// Compute key position [x, y, z] and rotation [tilt_x, tilt_y] on the spherical keywell
// for a given column/row index pair (c, r).
// Returns [x, y, z, tilt_x, tilt_y].

function circle_elevation(x,radius) = radius *(1-sqrt(1-x*x/radius/radius));

function __get_base_key_pos(c,r) = 
    let( 
        x = (c - (num_cols - 1) / 2) * col_spacing_x,
        y = -(r - (num_rows - 1) / 2) * row_spacing_y
    )
    [x, y];

__base_key_center_pos = let(
    min_pos = __get_base_key_pos(0, 0),
        max_pos = __get_base_key_pos(num_cols-1, num_rows-1),
        center = min_pos + (max_pos - min_pos) / 2
)
    center+keywell_center_offset_xy;

function __get_key_pos_and_rot(c, r) =
    let(
        // Center columns around X=0.
        base_pos = __get_base_key_pos(c, r),
        center_pos = __base_key_center_pos,
        circ_x = _x(base_pos-center_pos),
        circ_y = _y(base_pos-center_pos),
        circ_vertical_elev = circle_elevation(circ_x, keywell_vertical_radius_mm),
        circ_horizontal_elev = circle_elevation(circ_y, keywell_horizontal_radius_mm),
        
        key_props = matrix_keys[c][r],
        key_type = key_props[2],
        key_pos = key_props[0],
        key_rot = key_props[1],

        rot_y = acos(1-circ_vertical_elev/keywell_vertical_radius_mm)*-sign(circ_x),
        rot_x = acos(1-circ_horizontal_elev/keywell_horizontal_radius_mm)*sign(circ_y),
        pos = [base_pos[0], base_pos[1], circ_vertical_elev+circ_horizontal_elev]+key_pos,
        rot = [rot_x, rot_y]+key_rot
    )
    [each pos, each rot];

// todo: remove 
function M_key_main(c, r) = 
    let (p = __get_key_pos_and_rot(c, r)) 
    Mtranslate(p) * Mrotate([p[3], p[4],0]);

function M_key_corner_local(corner_idx) =
    let(
        corner_offsets_xy = [
            [-switch_size_x/2,  switch_size_y/2],  // 0: top-left
            [ switch_size_x/2,  switch_size_y/2],  // 1: top-right
            [-switch_size_x/2, -switch_size_y/2],  // 2: bottom-left
            [ switch_size_x/2, -switch_size_y/2]   // 3: bottom-right
        ]
    ) Mtranslate([each corner_offsets_xy[corner_idx], -plane_thickness_mm]);

// Continuous keywell plane formed from support shapes at switch corners.
// For a 3x5 switch matrix, we get a 6x10 matrix of corner supports.
// We then apply hull() over 2x2 windows of these supports.

function M_keywell_plane_inner_lip_part(idx) = let(
    col = floor(idx/2),
    corner_idx = idx%2,
    M_key = M_key_main(col, 0) * M_key_corner_local(corner_idx),
    M_local = M_key*Mrotate([-base_tilt_angle_deg,0,0])
) M_local*Mtranslate([0,inner_lip_size,0]);

function M_keywell_plane_outer_lip_part(idx) = let(
    col = floor(idx/2),
    corner_idx = 2+idx%2,
    M_key = M_key_main(col, num_rows-1) * M_key_corner_local(corner_idx),
    M_local = Mtranslate(M_translation(M_key))*Mrotate([-base_tilt_angle_deg,0,0])
) M_local*Mtranslate([0,-outer_lip_size,0]);

inner_lip_parts_num = num_cols*2;
outer_lip_parts_num = num_cols*2;

M_thumb_origin_on_main_plane = M_key_main(num_cols-1, thumb_origin_row_index);

M_thumb_plane = (
    M_thumb_origin_on_main_plane
    * Mtranslate([thumb_offset_x+col_spacing_x, thumb_offset_y, thumb_offset_z])
    * Mrotate([thumb_plane_angle_x_deg, thumb_plane_angle_y_deg, thumb_plane_angle_z_deg])
);

function M_thumb_key(key_id) = (
    M_thumb_plane 
    * Mtranslate(thumb_keys[key_id][0])
    * Mtranslate([0, row_spacing_y*key_id, 0])
    * Mrotate(thumb_keys[key_id][1])
);

function get_min_key_height() = min(
    let(
        heights_main = [
            for (row = [0 : num_rows - 1]) 
                for (corner = [0 : 3])
                    let(p = transform_point(M_base_tilt * M_key_main(num_cols-1, row) * M_key_corner_local(corner), [0, 0, 0]))
                    p[2]
        ],
        heights_thumb = [
            for (key = [0 : len(thumb_keys) - 1])
                for (corner = [0 : 3])
                    let(p = transform_point(M_base_tilt * M_thumb_key(key) * M_key_corner_local(corner), [0, 0, 0]))
                    p[2]
        ],
        min_val = min([each heights_main, each heights_thumb])
    )
    min_val + support_radius_mm *sign(min_val)
);

M_base_tilt = Mrotate([base_tilt_angle_deg, 0, 0]);
M_base = let(
    min_key_height = get_min_key_height(),
    z_offset = abs(min_key_height+base_height_mm*sign(min_key_height))
) Mtranslate([0, 0, z_offset]) * M_base_tilt;


/////////////////////////////////////////////
/// configurable modules
/////////////////////////////////////////////

module support_shape() {
    cylinder(h = plane_thickness_mm, r = support_radius_mm, center = false);
}

module switch_placeholder(size, type) {
    color("lightgray")
        mirror_if_right()
            if (type == "regular")
                kailh_choc_switch_cutout(plane_thickness_mm, size);
            else if (type == "five_way")
                generic_square_dip_switch_cutout(plane_thickness_mm, size);
}
/////////////////////////////////////////////
/// RENDER ENTRY POINT
/////////////////////////////////////////////

// Apply base tilt angle to the entire keyboard surface.

LEFT = true;

main_body();