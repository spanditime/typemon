include <lib/linear_algebra.scad>;

/////////////////////////////////////////////
/// CONFIGURATION
/////////////////////////////////////////////

// Prototype of a generated SCAD file for the left half.
// For now it only contains the main key plane (no thumb cluster, no trackpoint).

// Layout parameters (mirroring configs/default.yml)
// rows: number of rows (Y direction, away from user)
// cols: number of columns (X direction, left to right)

DEBUG = true;

/// TODO: tolerances should be added to the config
/// this will allow to generate the model with different tolerances
/// for different materials and printing techniques
/// switch tolerance
/// case tolerance

rows = 5;
cols = 4;

// Internal counts used for generation
num_rows = rows; // logical rows (Y direction)
num_cols = cols; // physical columns (X direction)

// Row heights relative to the base plane (mm), from farthest row to nearest.
// todo: fix - this represents coulumn heights, not row heights - rename to column_heights_mm
row_heights_mm = [3.0, 3.0, 0.0, 4.0, 8.0];

// Simple spherical keywell parameters (should match geometry section).
keywell_radius_mm = 160.0;
keywell_depth_mm  = 0;

// Base tilt angle of the main surface relative to the table (degrees).
// Positive angle tilts the keyboard away from the user (backward).
base_tilt_angle_deg = 55.0;

// Thickness of the continuous keywell plane (approximate shell under switches).
plane_thickness_mm = 5.0;

// Choc switch dimensions (mm).
switch_size_x = 17.0;
switch_size_y = 18.0;
switch_size_z = 3.0;

support_radius_mm = 1;
col_spacing_x = switch_size_x + support_radius_mm + 0.5;
row_spacing_y = switch_size_y + support_radius_mm + 0.5;
base_height_mm = 5.0;
base_plane_thickness_mm = 2.0;
wall_base_thickness_mm = 4.0;
wall_center_offset_percent = 0.05;

// Per-finger offsets relative to the origin column (index finger), in mm.
// Order: [pinky, ring, middle, index]
// todo: fix - this represents row offsets, not finger offsets
finger_offsets = [
    [0.0,  0.0,  0.0],  // pinky
    [0.0,  0.0,  0.0],  // ring
    [0.0,  0.0,  0.0],  // middle (origin)
    [0.0,  0.0,  0.0]   // index
];

// Thumb cluster parameters (mirroring configs/default.yml)
thumb_plane_angle_x_deg = -120.0;  // Angle of thumb plane relative to main surface
thumb_plane_angle_y_deg = 0.0;  // Angle of thumb plane relative to main surface
thumb_plane_angle_z_deg = -10.0;  // Angle of thumb plane relative to main surface
thumb_origin_row_index = 1; // Row index to use as origin for thumb cluster
thumb_offset_x = 5.0;          // X offset from origin column
thumb_offset_y = 10.0;        // Y offset from origin column
thumb_offset_z = 0.0;         // Z offset from origin column

// Thumb keys positions (relative to thumb plane origin)
thumb_keys = [
    [  [0.0,  0.0,  0], [0.0, 0.0, 0.0], "regular"],
    [ [1.0,  0.0,  -2], [-10.0, 0.0, -5.0], "regular"],
    [ [3.0,  0.0,  -6], [-15.0, 0.0, -7.0], "five_way"]
];

inner_lip_size = 10;
outer_lip_size = 10;

/////////////////////////////////////////////
/// MODULES
/////////////////////////////////////////////

function sum_array(arr, index) = 
  (index < 0) ? 0 : arr[index] + sum_array(arr, index - 1);

// Wrapper function for convenience
function total_sum(arr) = sum_array(arr, len(arr) - 1);


// Simple placeholder for a Choc switch position (can be replaced by real cutout later).
module choc_switch_placeholder(size = [18, 18, 3]) {
    color("lightgray")
        cube(size, center = true);
}

module five_way_placeholder(size = [18, 18, 3]) {
    color("green")
        cylinder(h = size[2], r = size[0]/2, center = true);
}

// Compute key position [x, y, z] and rotation [tilt_x, tilt_y] on the spherical keywell
// for a given column/row index pair (c, r).
// Returns [x, y, z, tilt_x, tilt_y].
function __get_key_pos_and_rot(c, r) =
    let(
        finger = c,
        x_off = finger_offsets[finger][0],
        y_off = finger_offsets[finger][1],
        z_off = finger_offsets[finger][2],

        // Center columns around X=0.
        x_flat = (c - (num_cols - 1) / 2) * col_spacing_x + x_off,
        // Rows go away from the user for increasing r.
        y_flat = -(r * row_spacing_y) + y_off,

        // Base height for the given row + per-finger Z offset.
        base_z = row_heights_mm[r] + z_off,

        // Spherical keywell: project (x_flat, y_flat) onto a sphere segment.
        r2 = keywell_radius_mm * keywell_radius_mm,
        d2 = x_flat * x_flat + y_flat * y_flat,
        sphere_center_z = keywell_radius_mm - keywell_depth_mm,
        z_sphere = sphere_center_z - sqrt(max(0, r2 - d2)),

        // Approximate local surface orientation.
        tilt_x = atan2(y_flat, keywell_radius_mm),
        tilt_y = -atan2(x_flat, keywell_radius_mm)
    )
    [x_flat, y_flat, z_sphere + base_z, tilt_x, tilt_y];

// todo: remove 
function M_key_main(c, r) = 
    let (p = __get_key_pos_and_rot(c, r)) 
    Mtranslate(p) * Mx(p[3]) * My(p[4]);

// Main keywell for the left half: 3 columns x 5 rows, projected onto a spherical surface.
// This module places individual switch placeholders.
module keywell_switches() {
    // Regular switches
    for (c = [0 : num_cols - 1]) {
        for (r = [0 : num_rows - 1]) {
            multmatrix(M_key_main(c, r))
                choc_switch_placeholder([switch_size_x, switch_size_y, switch_size_z]);
        }
    }
}

function M_key_corner_local(corner_idx) =
    let(
        corner_offsets_xy = [
            [-switch_size_x/2,  switch_size_y/2],  // 0: top-left
            [ switch_size_x/2,  switch_size_y/2],  // 1: top-right
            [-switch_size_x/2, -switch_size_y/2],  // 2: bottom-left
            [ switch_size_x/2, -switch_size_y/2]   // 3: bottom-right
        ]
    ) Mtranslate([each corner_offsets_xy[corner_idx], -plane_thickness_mm]);

module support_shape() {
    cylinder(h = plane_thickness_mm, r = support_radius_mm, center = false);
}

// final - do not change - this is the shape of the support for a given key corner
module key_corner_support_shape(key_corner_idx) {
    multmatrix(M_key_corner_local(key_corner_idx))
        support_shape();
}


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

module keywell_plane_inner_lip() {
    for (part_idx = [0 : inner_lip_parts_num - 2]) {
        hull() {
            for (window_idx = [0 : 1]) {
                curr_part_idx = part_idx + window_idx;
                col = floor(curr_part_idx/2);
                corner_idx = curr_part_idx%2;
                multmatrix(M_key_main(col, 0))
                    key_corner_support_shape(corner_idx);
                multmatrix(M_keywell_plane_inner_lip_part(curr_part_idx))
                    support_shape();
            }
        }
    }
}

module keywell_plane_outer_lip() {
    for (part_idx = [0 : outer_lip_parts_num - 2]) {
        hull() {
            for (window_idx = [0 : 1]) {
                curr_part_idx = part_idx + window_idx;
                col = floor(curr_part_idx/2);
                corner_idx = 2+ curr_part_idx%2;
                multmatrix(M_key_main(col, num_rows-1))
                    key_corner_support_shape(corner_idx);
                multmatrix(M_keywell_plane_outer_lip_part(curr_part_idx))
                    support_shape();
            }
        }
    }
}

module keywell_plane() {
    // Matrix of corner supports: (num_cols * 2) x (num_rows * 2) = 6 x 10
    support_cols = num_cols * 2;
    support_rows = num_rows * 2;

    union() {
        keywell_plane_inner_lip();
        keywell_plane_outer_lip();
        // Iterate over 2x2 windows in the support matrix.
        for (sc = [0 : support_cols - 2]) {
            for (sr = [0 : support_rows - 2]) {
                hull() {
                    // Four corners of the 2x2 window.
                    for (dc = [0 : 1]) {
                        for (dr = [0 : 1]) {
                            sc_idx = sc + dc;
                            sr_idx = sr + dr;

                            // Map support matrix index to switch (c, r) and corner (0..3).
                            switch_c = floor(sc_idx / 2);
                            switch_r = floor(sr_idx / 2);
                            corner_c = sc_idx % 2;
                            corner_r = sr_idx % 2;
                            corner_idx = corner_r * 2 + corner_c;  // 0=TL, 1=TR, 2=BL, 3=BR

                            // Only generate support if switch exists.
                            if (switch_c >= 0 && switch_c < num_cols && switch_r >= 0 && switch_r < num_rows) {
                                multmatrix(M_key_main(switch_c, switch_r))
                                    key_corner_support_shape(corner_idx);
                            }
                        }
                    }
                }
            }
        }
    }
}

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

module thumb_plane_support() {
    union() {
        support_cols = 2;
        support_rows = len(thumb_keys) * 2;

        for (sc = [0 : support_cols - 2]) {
            for (sr = [0 : support_rows - 2]) {
                hull() {
                    for (dc = [0 : 1]) {
                        for (dr = [0 : 1]) {
                            sc_idx = sc + dc;
                            sr_idx = sr + dr;

                            // Map support matrix index to switch (c, r) and corner (0..3).
                            switch_r = floor(sr_idx / 2);
                            corner_c = sc_idx % 2;
                            corner_r = sr_idx % 2;
                            corner_idx = corner_r * 2 + corner_c;  // 0=TL, 1=TR, 2=BL, 3=BR

                            // Only generate support if switch exists.
                            multmatrix(M_thumb_key(switch_r))
                                key_corner_support_shape(3-corner_idx);
                        }
                    }
                }
            }
        }
    }
}

module thumb_plane() {
    union() {
        // thumb plane main
        thumb_plane_support();
        // thumb plane and main plane connector
        for (key = [0 : len(thumb_keys) - 1]) {
            hull(){ 
                multmatrix(M_thumb_origin_on_main_plane){
                    if (key == 0)
                        key_corner_support_shape(1);
                    key_corner_support_shape(3);
                }
                multmatrix(M_thumb_key(key)){
                    key_corner_support_shape(0);
                    key_corner_support_shape(2);
                }
            }
        }
        for (key = [1 : len(thumb_keys) - 1]) {
            hull(){ 
                multmatrix(M_thumb_origin_on_main_plane){
                    key_corner_support_shape(3);
                }
                multmatrix(M_thumb_key(key)){
                    key_corner_support_shape(2);
                }
                multmatrix(M_thumb_key(key-1)){
                    key_corner_support_shape(0);
                }
            }
        }
    }
}
module thumb_plane_switches(){
        for (key = [0 : len(thumb_keys) - 1])
            multmatrix(M_thumb_key(key))
                if (thumb_keys[key][2] == "regular")
                    choc_switch_placeholder([switch_size_x, switch_size_y, switch_size_z]);
                else if (thumb_keys[key][2] == "five_way")
                    five_way_placeholder([switch_size_x, switch_size_y, switch_size_z]);
}


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
/// RENDER ENTRY POINT
/////////////////////////////////////////////

module base_plane_support_shape() {
    translate([0, 0, base_plane_thickness_mm/2])
        cylinder(h = base_plane_thickness_mm, r = wall_base_thickness_mm/2, center = true);
}

module base_plane() {
    // inner lip projections
    main_transforms = [
        // inner lip parts
        for (part_idx = [inner_lip_parts_num - 1 : -1 : 0]) 
            M_base * M_keywell_plane_inner_lip_part(part_idx),
        // back wall parts
        for (row = [0 : num_rows - 1]) 
            for (cor = [0 : 2 : 2]) 
                M_base * M_key_main(0, row) * M_key_corner_local(cor),
        // outer lip parts
        for (part_idx = [0 : outer_lip_parts_num - 1]) 
            M_base * M_keywell_plane_outer_lip_part(part_idx)
    ];
    main_plane_points = [
        for (i = [0:len(main_transforms)-1])
            project_point_onto_plane(transform_point(main_transforms[i], [0, 0, 0]), plane_xy)
    ];

    thumb_transforms = [
        for (corner = [0 : 1])
            M_base *M_thumb_key(len(thumb_keys)-1) * M_key_corner_local(corner)
    ];

    thumb_plane_points = [
        for (i = [0:len(thumb_transforms)-1])
            project_point_onto_plane(transform_point(thumb_transforms[i], [0, 0, 0]), plane_xy)
    ];

    transforms = [each main_transforms, each thumb_transforms];
    _all_points = [each main_plane_points, each thumb_plane_points];
    echo(_all_points);
    // move points from the center
    center_point = [
        total_sum([for (point = _all_points) point[0]]) / len(_all_points),
        total_sum([for (point = _all_points) point[1]]) / len(_all_points),
        total_sum([for (point = _all_points) point[2]]) / len(_all_points)
    ];
    echo(center_point);
    points = [
        for (point = _all_points) let(
            vect = point - center_point
        ) center_point + vect * (1+wall_center_offset_percent)
    ];
    echo(points);


    for (i = [0:len(main_plane_points)-2]) {
        hull() {
            for (j = [0:1]) {
                translate(points[i+j])
                    base_plane_support_shape();
                multmatrix(transforms[i+j])
                    support_shape();
            }
        }
    }
    for (i = [len(main_plane_points):len(points)-2]) {
        hull() {
            for (j = [0:1]) {
                translate(points[i+j])
                    base_plane_support_shape();
                multmatrix(transforms[i+j])
                    support_shape();
            }
        }
    }


    // hull()
    // for (i = [0:len(points)-1]) {
    //     translate(points[i])
    //         base_plane_support_shape();
    // }
}

// Apply base tilt angle to the entire keyboard surface.

multmatrix(M_base) {
    union() {
        union() {
            keywell_plane();
            thumb_plane();
        }
        union() {
            keywell_switches();
            thumb_plane_switches();
        }
    }
}
base_plane();
