/////////////////////////////////////////////
/// transformation matrices
/////////////////////////////////////////////

function Mx(angle) = [
    [1, 0, 0, 0],
    [0, cos(angle), -sin(angle), 0],
    [0, sin(angle), cos(angle), 0],
    [0, 0, 0, 1]
];

function My(angle) = [
    [cos(angle), 0, sin(angle), 0],
    [0, 1, 0, 0],
    [-sin(angle), 0, cos(angle), 0],
    [0, 0, 0, 1]
];

function Mz(angle) = [
    [cos(angle), -sin(angle), 0, 0],
    [sin(angle), cos(angle), 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
];

function Mrotate(r) = Mx(r[0]) * My(r[1]) * Mz(r[2]);

function Mtranslate(p) = [
    [1, 0, 0, p[0]],
    [0, 1, 0, p[1]],
    [0, 0, 1, p[2]],
    [0, 0, 0, 1]
];

function Mscale(s) = [
    [s[0], 0, 0, 0],
    [0, s[1], 0, 0],
    [0, 0, s[2], 0],
    [0, 0, 0, 1]
];

function M_TRS(T,R,S) = Mtranslate(T) * Mrotate(R) * Mscale(S);

function M_translation(M)= [for (i = [0 : 3]) M[i][3]];
function M_rotation(M)= [for (i = [0 : 2]) atan2(M[1][i], M[0][i])];
function M_scale(M)= [for (i = [0 : 2]) sqrt(M[i][0]*M[i][0] + M[i][1]*M[i][1] + M[i][2]*M[i][2])];

/////////////////////////////////////////////
/// points
/////////////////////////////////////////////

function vec3(p) = [p[0], p[1], p[2]];
function normalize(v) = let(vec = vec3(v)) vec / sqrt(vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2]);
function vec3_len(v) = sqrt(v[0]*v[0] + v[1]*v[1] + v[2]*v[2]);
function transform_point(M, p) = M * [each vec3(p), 1];
function _x(v) = v[0];
function _y(v) = v[1];
function _z(v) = v[2];

/////////////////////////////////////////////
/// planes
/////////////////////////////////////////////

// creation
function plane_from_normal_and_displacement(norm_dir, displacement) = [each normalize(norm_dir), displacement];
function plane(p) = plane_from_normal_and_displacement(p, p[3]);

plane_xy = plane_from_normal_and_displacement([0,0,1], 0);
plane_yz = plane_from_normal_and_displacement([1,0,0], 0);
plane_xz = plane_from_normal_and_displacement([0,1,0], 0);

// accessors
// _u is for unsafe accessors that do not check the plane format
function _u_plane_normal(p) = vec3(p);
function plane_normal(p) = _u_plane_normal(plane(p));

function _u_plane_displacement(p) = p[3];
function plane_displacement(p) = _u_plane_displacement(plane(p));



/////////////////////////////////////////////
/// projections
/////////////////////////////////////////////

function _u_project_point_onto_plane(p, pl) = let(
    norm = _u_plane_normal(pl),
    disp = _u_plane_displacement(pl)
    ) p - norm * (p * norm + disp);
function project_point_onto_plane(p, pl) = vec3(_u_project_point_onto_plane(vec3(p), plane(pl)));