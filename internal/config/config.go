package config

import (
	"errors"
	"os"

	"gopkg.in/yaml.v3"
)

// Config описывает корневую структуру конфигурации клавиатуры.
type Config struct {
	Units        Units                       `yaml:"units"`
	Layout       Layout                      `yaml:"layout"`
	Geometry     GeometryConfig              `yaml:"geometry"`
	SwitchTypes  map[string]SwitchTypeConfig `yaml:"switch_types"`
	Keywell      Keywell                     `yaml:"keywell"`
	ThumbCluster ThumbCluster                `yaml:"thumb_cluster"`
	Render       Render                      `yaml:"render"`
	// Trackpoint    *Trackpoint                 `yaml:"trackpoint,omitempty"`
}

type GeometryConfig struct {
	PlaneThickness          float64 `yaml:"plane_thickness"`
	SupportRadius           float64 `yaml:"support_radius"`
	KeywellElevation        float64 `yaml:"keywell_elevation"`
	WallBaseThickness       float64 `yaml:"wall_base_thickness"`
	WallCenterOffsetPercent float64 `yaml:"wall_center_offset_percent"`
}

type Units struct {
	Length string `yaml:"length"`
	Angle  string `yaml:"angle"`
}

type Layout struct {
	Rows int `yaml:"rows"`
	Cols int `yaml:"cols"`
}

type SwitchTypeConfig struct {
	Definition string                 `yaml:"definition"`
	ExtraArgs  map[string]interface{} `yaml:"extra_args,omitempty"`
}

type Keywell struct {
	TiltAngle              float64          `yaml:"tilt_angle"`
	HorizontalRadius       float64          `yaml:"horizontal_radius"`
	VerticalRadius         float64          `yaml:"vertical_radius"`
	CenterOffset           Offset           `yaml:"center_offset"`
	InnerLipSize           float64          `yaml:"inner_lip_size"`
	OuterLipSize           float64          `yaml:"outer_lip_size"`
	IndexFingerStartColumn int              `yaml:"index_finger_start_column"`
	Modifiers              KeywellModifiers `yaml:"modifiers"`
}

type Offset struct {
	X float64 `yaml:"x"`
	Y float64 `yaml:"y"`
	Z float64 `yaml:"z"`
}

type Rotation struct {
	X float64 `yaml:"x"`
	Y float64 `yaml:"y"`
	Z float64 `yaml:"z"`
}

type KeywellModifiers struct {
	Finger  FingerModifiers           `yaml:"finger"`
	Rows    map[int]RowColumnModifier `yaml:"rows"`
	Columns map[int]RowColumnModifier `yaml:"columns"`
	Matrix  []MatrixModifier          `yaml:"matrix"`
}

type FingerModifiers struct {
	Index  FingerModifier `yaml:"index"`
	Middle FingerModifier `yaml:"middle"`
	Ring   FingerModifier `yaml:"ring"`
	Pinky  FingerModifier `yaml:"pinky"`
}

type FingerModifier struct {
	Offset Offset  `yaml:"offset"`
	Tilt   float64 `yaml:"tilt,omitempty"`
}

type RowColumnModifier struct {
	Offset Offset  `yaml:"offset"`
	Tilt   float64 `yaml:"tilt"`
}

type MatrixModifier struct {
	Column                int      `yaml:"column"`
	Row                   int      `yaml:"row"`
	Offset                Offset   `yaml:"offset"`
	Rotation              Rotation `yaml:"rotation"`
	IgnoreFingerModifiers bool     `yaml:"ignore_finger_modifiers"`
	IgnoreColumnModifiers bool     `yaml:"ignore_column_modifiers"`
	IgnoreRowModifiers    bool     `yaml:"ignore_row_modifiers"`
	SwitchType            string   `yaml:"switch_type"`
}

type ThumbCluster struct {
	OriginColumnIndex int              `yaml:"origin_column_index"`
	Offset            Offset           `yaml:"offset"`
	Rotation          Rotation         `yaml:"rotation"`
	Keys              map[int]ThumbKey `yaml:"keys"`
}

type ThumbKey struct {
	Offset   Offset   `yaml:"offset"`
	Rotation Rotation `yaml:"rotation"`
	Type     string   `yaml:"type"`
}

// type Trackpoint struct {
// 	LeftSide  TrackpointSide `yaml:"left_side"`
// 	RightSide TrackpointSide `yaml:"right_side"`
// }

// type TrackpointSide struct {
// 	ColumnIndex     int     `yaml:"column_index"`
// 	RowIndex        int     `yaml:"row_index"`
// 	Enabled         bool    `yaml:"enabled"`
// 	OffsetX         float64 `yaml:"offset_x"`
// 	OffsetY         float64 `yaml:"offset_y"`
// 	OffsetZ         float64 `yaml:"offset_z"`
// 	HoleDiameterMM  float64 `yaml:"hole_diameter_mm"`
// 	MountDiameterMM float64 `yaml:"mount_diameter_mm"`
// 	MountDepthMM    float64 `yaml:"mount_depth_mm"`
// }

type Render struct {
	Fn    int  `yaml:"$fn"`
	Debug bool `yaml:"debug,omitempty"`
}

// Load загружает YAML-конфиг из файла по указанному пути.
func Load(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, errors.Join(errors.New("failed to read config file"), err)
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, errors.Join(errors.New("failed to unmarshal yaml"), err)
	}

	return &cfg, nil
}
