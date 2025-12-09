package config

import (
	"errors"
	"os"

	"gopkg.in/yaml.v3"
)

// Config описывает корневую структуру конфигурации клавиатуры.
type Config struct {
	Units      string          `yaml:"units"`
	Layout     Layout          `yaml:"layout"`
	Geometry   Geometry        `yaml:"geometry"`
	Columns    ColumnsGeometry `yaml:"columns_geometry"`
	Thumbs     ThumbClusters   `yaml:"thumb_clusters"`
	Trackpoint Trackpoint      `yaml:"trackpoint"`
	PCBs       PCBs            `yaml:"pcbs"`
	Render     Render          `yaml:"render"`
}

type Layout struct {
	Rows           int  `yaml:"rows"`
	Cols           int  `yaml:"cols"`
	PinkyExtraHome bool `yaml:"pinky_extra_home"`
}

type Geometry struct {
	BaseTiltAngleDeg float64 `yaml:"base_tilt_angle_deg"`
	TentAngleDeg     float64 `yaml:"tent_angle_deg"`

	KeywellRadiusMM float64 `yaml:"keywell_radius_mm"`
	KeywellDepthMM  float64 `yaml:"keywell_depth_mm"`
}

type ColumnsGeometry struct {
	ColSpacingX       float64       `yaml:"col_spacing_x"`
	RowSpacingY       float64       `yaml:"row_spacing_y"`
	RowHeights        []float64     `yaml:"row_heights_mm"`
	OriginColumnIndex int           `yaml:"origin_column_index"`
	PerFinger         PerFingerSpec `yaml:"per_finger"`
}

type PerFingerSpec struct {
	Pinky  FingerConfig `yaml:"pinky"`
	Ring   FingerConfig `yaml:"ring"`
	Middle FingerConfig `yaml:"middle"`
	Index  FingerConfig `yaml:"index"`
}

type FingerConfig struct {
	OffsetX  float64 `yaml:"offset_x"`
	OffsetY  float64 `yaml:"offset_y"`
	OffsetZ  float64 `yaml:"offset_z"`
	TiltXDeg float64 `yaml:"tilt_x_deg"`
	TiltYDeg float64 `yaml:"tilt_y_deg"`
	SplayDeg float64 `yaml:"splay_deg"`
}

type ThumbClusters struct {
	ThumbPlaneAngleDeg float64      `yaml:"thumb_plane_angle_deg"`
	ThumbPlaneTiltDeg  float64      `yaml:"thumb_plane_tilt_deg"`
	OriginColumnIndex  int          `yaml:"origin_column_index"`
	OffsetX            float64      `yaml:"offset_x"`
	OffsetY            float64      `yaml:"offset_y"`
	OffsetZ            float64      `yaml:"offset_z"`
	Keys               []ThumbKey   `yaml:"keys"`
	LeftSide           ThumbSideCfg `yaml:"left_side"`
}

type ThumbKey struct {
	ID   string  `yaml:"id"`
	PosX float64 `yaml:"pos_x"`
	PosY float64 `yaml:"pos_y"`
	PosZ float64 `yaml:"pos_z"`
}

type ThumbSideCfg struct {
	FiveWayReplaces   string  `yaml:"five_way_replaces"`
	FiveWayDiameterMM float64 `yaml:"five_way_diameter_mm"`
	FiveWayHeightMM   float64 `yaml:"five_way_height_mm"`
}

type Trackpoint struct {
	LeftSide  TrackpointSide `yaml:"left_side"`
	RightSide TrackpointSide `yaml:"right_side"`
}

type TrackpointSide struct {
	ColumnIndex     int     `yaml:"column_index"`
	RowIndex        int     `yaml:"row_index"`
	Enabled         bool    `yaml:"enabled"`
	OffsetX         float64 `yaml:"offset_x"`
	OffsetY         float64 `yaml:"offset_y"`
	OffsetZ         float64 `yaml:"offset_z"`
	HoleDiameterMM  float64 `yaml:"hole_diameter_mm"`
	MountDiameterMM float64 `yaml:"mount_diameter_mm"`
	MountDepthMM    float64 `yaml:"mount_depth_mm"`
}

type PCBs struct {
	SwitchType string `yaml:"switch_type"`
}

type Render struct {
	Fn            int  `yaml:"$fn"`
	KeycapOutline bool `yaml:"keycap_outline"`
	GenerateLeft  bool `yaml:"generate_left"`
	GenerateRight bool `yaml:"generate_right"`
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
