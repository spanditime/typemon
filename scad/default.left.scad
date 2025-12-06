// Prototype of a generated SCAD file for the left half.
// For now it only contains the main key plane (no thumb cluster, no trackpoint).

// Layout parameters (mirroring configs/default.yml)
// rows: number of rows (Y direction, away from user)
// cols: number of columns (X direction, left to right)
rows = 5;
cols = 4;

// Internal counts used for generation
num_rows = rows; // logical rows (Y direction)
num_cols = cols; // physical columns (X direction)

col_spacing_x = 18.5;
row_spacing_y = 18.0;

// Row heights relative to the base plane (mm), from farthest row to nearest.
row_heights_mm = [3.0, 3.0, 0.0, 4.0, 8.0];

// Simple spherical keywell parameters (should match geometry section).
keywell_radius_mm = 140.0;
keywell_depth_mm  = 0;

// Base tilt angle of the main surface relative to the table (degrees).
// Positive angle tilts the keyboard away from the user (backward).
base_tilt_angle_deg = 55.0;

// Thickness of the continuous keywell plane (approximate shell under switches).
plane_thickness_mm = 5.0;

// Choc switch dimensions (mm).
switch_size_x = 18.0;
switch_size_y = 18.0;
switch_size_z = 3.0;

// Per-finger offsets relative to the origin column (index finger), in mm.
// Order: [pinky, ring, middle, index]
finger_offsets = [
    [-5.0,  2.0,  3.0],  // pinky
    [-2.0,  1.0,  2.0],  // ring
    [ 0.0,  0.0,  0.0],  // middle (origin)
    [ 3.0, -1.0, -1.0]   // index
];

// Simple placeholder for a Choc switch position (can be replaced by real cutout later).
module choc_switch_placeholder(size = [18, 18, 3]) {
    color("lightgray")
        cube(size, center = true);
}

// Compute key position [x, y, z] and rotation [tilt_x, tilt_y] on the spherical keywell
// for a given column/row index pair (c, r).
// Returns [x, y, z, tilt_x, tilt_y].
function key_pos_and_rot(c, r) =
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

// Compute key position [x, y, z] on the spherical keywell for a given
// column/row index pair (c, r).
function key_pos(c, r) =
    let(p = key_pos_and_rot(c, r))
    [p[0], p[1], p[2]];

// Compute position of a switch corner in world coordinates.
// c, r: column/row indices of the switch
// corner: 0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right (in switch's local space)
function switch_corner_pos(c, r, corner) =
    let(
        // Get switch center position and rotation.
        p = key_pos_and_rot(c, r),
        cx = p[0],
        cy = p[1],
        cz = p[2],
        tilt_x = p[3],
        tilt_y = p[4],

        // Local corner offsets relative to switch center (before rotation).
        corner_offsets = [
            [-switch_size_x/2,  switch_size_y/2, 0],  // 0: top-left
            [ switch_size_x/2,  switch_size_y/2, 0],  // 1: top-right
            [-switch_size_x/2, -switch_size_y/2, 0],  // 2: bottom-left
            [ switch_size_x/2, -switch_size_y/2, 0]   // 3: bottom-right
        ],
        local_offset = corner_offsets[corner],

        // Apply rotation around X axis (tilt_x).
        cos_x = cos(tilt_x),
        sin_x = sin(tilt_x),
        after_x = [
            local_offset[0],
            local_offset[1] * cos_x - local_offset[2] * sin_x,
            local_offset[1] * sin_x + local_offset[2] * cos_x
        ],

        // Apply rotation around Y axis (tilt_y).
        cos_y = cos(tilt_y),
        sin_y = sin(tilt_y),
        after_y = [
            after_x[0] * cos_y + after_x[2] * sin_y,
            after_x[1],
            -after_x[0] * sin_y + after_x[2] * cos_y
        ]
    )
    [cx + after_y[0], cy + after_y[1], cz + after_y[2]];

// Main keywell for the left half: 3 columns x 5 rows, projected onto a spherical surface.
// This module places individual switch placeholders.
module main_plane_left() {
    // Regular switches
    for (c = [0 : num_cols - 1]) {
        for (r = [0 : num_rows - 1]) {
            p = key_pos_and_rot(c, r);
            x = p[0];
            y = p[1];
            z = p[2];
            tilt_x = p[3];
            tilt_y = p[4];

            translate([x, y, z])
                rotate([tilt_x, tilt_y, 0])
                    choc_switch_placeholder([switch_size_x, switch_size_y, switch_size_z]);
        }
    }
}

// Continuous keywell plane formed from support shapes at switch corners.
// For a 3x5 switch matrix, we get a 6x10 matrix of corner supports.
// We then apply hull() over 2x2 windows of these supports.
module keywell_plane_left() {
    // Matrix of corner supports: (num_cols * 2) x (num_rows * 2) = 6 x 10
    support_cols = num_cols * 2;
    support_rows = num_rows * 2;

    union() {
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
                                p = switch_corner_pos(switch_c, switch_r, corner_idx);
                                x = p[0];
                                y = p[1];
                                z = p[2];

                                translate([x, y, z - plane_thickness_mm])
                                    cylinder(h = plane_thickness_mm, r = 1.5, center = false);
                            }
                        }
                    }
                }
            }
        }
    }
}

// Render entry point.
// Apply base tilt angle to the entire keyboard surface.
rotate([base_tilt_angle_deg, 0, 0]) {
    union() {
        keywell_plane_left();
        main_plane_left();
    }
}


