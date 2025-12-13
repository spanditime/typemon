module generic_square_dip_switch_cutout(plane_thickness, key_size, 
    switch_size=[5,5,2], 
    hole_extra_depth=0.5,
    dip_leg_hole_diameter=1.5,
    dip_leg_holes_placements=[
        [-2.5,-2.5], [2.5,-2.5], [-2.5,2.5], [2.5,2.5]
        ]
    ) {
    main_cutout_size = switch_size + [0,0,hole_extra_depth];
    
    union(){
        // main cutout
        difference(){
            translate([0, 0, -main_cutout_size[2]/2])
            cube(main_cutout_size, center = true);
            union() {
                for (i = [-1 :2: 1]) {
                    radius = 0.5;
                    pos_z = radius-hole_extra_depth;
                    translate([0, i*main_cutout_size[1]/2, pos_z])
                    rotate([0, 90, 0])
                    cylinder(h = main_cutout_size[0], r = radius, center = true);
                }
            }
        }
        // cutout for keycap
        translate([0, 0, key_size[2]/2])
        cube(key_size, center = true);
        // cutout for dip leg holes
        for (i = [0 : len(dip_leg_holes_placements) - 1]) {
            depth = max(plane_thickness, main_cutout_size[2]);
            translate([dip_leg_holes_placements[i][0], dip_leg_holes_placements[i][1],-depth/2])
            cube([dip_leg_hole_diameter, dip_leg_hole_diameter, depth], center = true);
        }
    }
}