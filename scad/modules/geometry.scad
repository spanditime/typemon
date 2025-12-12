
module mirror_if_right() {
    if (LEFT)
        children();
    else
        mirror([0, 1, 0])
            children();
}

// Main keywell for the left half: 3 columns x 5 rows, projected onto a spherical surface.
// This module places individual switch placeholders.
module keywell_switches() {
    // Regular switches
    for (c = [0 : num_cols - 1]) {
        for (r = [0 : num_rows - 1]) {
            multmatrix(M_key_main(c, r))
                switch_placeholder(switch_size);
        }
    }
}

// final - do not change - this is the shape of the support for a given key corner
module key_corner_support_shape(key_corner_idx) {
    multmatrix(M_key_corner_local(key_corner_idx))
        support_shape();
}

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
                    switch_placeholder(switch_size);
                else if (thumb_keys[key][2] == "five_way")
                    five_way_placeholder(switch_size);
}

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

module main_body() {
    mirror_if_right() {
        multmatrix(M_base) {
            difference() {
                union() {
                    keywell_plane();
                    thumb_plane();
                }
                union() {
                    keywell_switches();
                    thumb_plane_switches();
                }
            }
            #if (DEBUG) {
                keywell_switches();
                thumb_plane_switches();
            }
        }
        base_plane();
    }
}