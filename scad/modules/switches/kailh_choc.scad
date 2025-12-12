

kailh_choc_switch_hole_side = 13.8;
kailh_choc_switch_support_width = 4.7*2;
kailh_choc_switch_support_height = 1.3;
kailh_choc_switch_hole_size = [14.5, 13.8, 2.2+3.0]; // todo: change to actual depth
kailh_choc_above_lip_size = [15,15,0.8+2]; // with lip, switch upper body and the keycap


module kailh_choc_switch_cutout(key_size) {
    union() {
        difference() {
            translate([0, 0, -kailh_choc_switch_hole_size[2]/2])
                cube(kailh_choc_switch_hole_size, center = true);
            union() {
                for (i = [-1 :2: 1]) {
                    support_size = kailh_choc_switch_hole_size[0]-kailh_choc_switch_hole_side;
                    translate([i*kailh_choc_switch_hole_size[0]/2,0,-kailh_choc_switch_support_height/2])
                    cube([support_size,kailh_choc_switch_support_width,kailh_choc_switch_support_height],center=true);
                }
            }
        }
        translate([0, 0, kailh_choc_above_lip_size[2]/2])
            cube(kailh_choc_above_lip_size, center = true);
        translate([0, 0, kailh_choc_above_lip_size[2] + key_size[2]/2])
            cube(key_size, center = true);
    }
}

