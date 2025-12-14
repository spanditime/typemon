package utils

import "typemon/internal/config"

func AddVectors[T config.Rotation | config.Offset](a T, b T) T {
	var x, y, z float64
	switch s := any(b).(type) {
	case config.Offset:
		x = s.X
		y = s.Y
		z = s.Z
	case config.Rotation:
		x = s.X
		y = s.Y
		z = s.Z
	}
	switch f := any(a).(type) {
	case config.Offset:
		return T(config.Offset{X: f.X + x, Y: f.Y + y, Z: f.Z + z})
	case config.Rotation:

		return T(config.Rotation{X: f.X + x, Y: f.Y + y, Z: f.Z + z})
	default:
		return a
	}
}
