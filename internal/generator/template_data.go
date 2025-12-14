package generator

import (
	"errors"
	"typemon/internal/config"
	"typemon/internal/generator/utils"
)

type templateKeywell struct {
	TiltAngle              float64
	VerticalRadius         float64
	HorizontalRadius       float64
	CenterOffset           config.Offset
	InnerLipSize           float64
	OuterLipSize           float64
	indexFingerStartColumn int
	Matrix                 [][]keyModifier
}

type keyModifier struct {
	Offset   config.Offset
	Rotation config.Rotation
	Type     string
}

func MatrixModifier(modifiers config.KeywellModifiers, numRows int, numCols int, indexFingerStartColumn int) [][]keyModifier {
	matrix := make([][]keyModifier, numCols)
	for col := range numCols {
		matrix[col] = make([]keyModifier, numRows)

		// get finger modifier
		currFingerIdx := 0

		if col >= indexFingerStartColumn {
			currFingerIdx = indexFingerStartColumn - col
		}
		if currFingerIdx > 3 {
			currFingerIdx = 3
		}

		var fingerModifier config.FingerModifier
		switch currFingerIdx {
		case 0:
			fingerModifier = modifiers.Finger.Index
		case 1:
			fingerModifier = modifiers.Finger.Middle
		case 2:
			fingerModifier = modifiers.Finger.Ring
		case 3:
			fingerModifier = modifiers.Finger.Pinky
		}

		var currColumnModifier *config.RowColumnModifier
		if colModifiers, ok := modifiers.Columns[col]; ok {
			currColumnModifier = &colModifiers
		}

		colModifier := &keyModifier{
			Offset:   fingerModifier.Offset,
			Rotation: config.Rotation{X: fingerModifier.Tilt, Y: 0, Z: 0},
			Type:     "regular",
		}

		if currColumnModifier != nil {
			colModifier.Offset = utils.AddVectors(colModifier.Offset, currColumnModifier.Offset)
			colModifier.Rotation = utils.AddVectors(colModifier.Rotation, config.Rotation{X: currColumnModifier.Tilt, Y: 0, Z: 0})
		}
		for row := range numRows {
			var currRowModifier *config.RowColumnModifier
			if rowModifiers, ok := modifiers.Rows[row]; ok {
				currRowModifier = &rowModifiers
			}
			keyModifier := keyModifier{
				Offset:   colModifier.Offset,
				Rotation: colModifier.Rotation,
				Type:     colModifier.Type,
			}

			if currRowModifier != nil {
				keyModifier.Offset = utils.AddVectors(keyModifier.Offset, currRowModifier.Offset)
				keyModifier.Rotation = utils.AddVectors(keyModifier.Rotation, config.Rotation{X: 0, Y: currRowModifier.Tilt, Z: 0})
			}
			matrix[col][row] = keyModifier
		}
	}
	return matrix
}

func newTemplateKeywell(keywell config.Keywell, numRows int, numCols int) templateKeywell {
	return templateKeywell{
		TiltAngle:              keywell.TiltAngle,
		VerticalRadius:         keywell.VerticalRadius,
		HorizontalRadius:       keywell.HorizontalRadius,
		CenterOffset:           keywell.CenterOffset,
		InnerLipSize:           keywell.InnerLipSize,
		OuterLipSize:           keywell.OuterLipSize,
		indexFingerStartColumn: keywell.IndexFingerStartColumn,
		Matrix:                 MatrixModifier(keywell.Modifiers, numRows, numCols, keywell.IndexFingerStartColumn),
	}
}

type templateThumbCluster struct {
	OriginColumnIndex int
	Offset            config.Offset
	Rotation          config.Rotation
	keys              map[int]config.ThumbKey
}

func (t *templateThumbCluster) Keys() []*config.ThumbKey {
	keys := make([]*config.ThumbKey, 0, len(t.keys))
	for i := range 3 {
		if key, ok := t.keys[i]; ok {
			keys = append(keys, &key)
		} else {
			keys = append(keys, &config.ThumbKey{
				Offset:   config.Offset{X: 0, Y: 0, Z: 0},
				Rotation: config.Rotation{X: 0, Y: 0, Z: 0},
				Type:     "regular",
			})
		}
	}
	return keys
}

func newTemplateThumbCluster(thumbCluster config.ThumbCluster) templateThumbCluster {
	return templateThumbCluster{
		OriginColumnIndex: thumbCluster.OriginColumnIndex,
		Offset:            thumbCluster.Offset,
		Rotation:          thumbCluster.Rotation,
		keys:              thumbCluster.Keys,
	}
}

type templateData struct {
	units        config.Units
	Layout       config.Layout
	switches     *switchRepository
	Geometry     config.GeometryConfig
	Keywell      templateKeywell
	Render       config.Render
	ThumbCluster templateThumbCluster
}

func (t *templateData) AllSwitchTypes() []string {
	types := make([]string, 0, len(t.switches.modules))
	for name := range t.switches.modules {
		types = append(types, name)
	}
	return types
}

func (t *templateData) AllSwitchIncludes() []string {
	includes := make([]string, 0, len(t.switches.modules))
	for name := range t.switches.modules {
		includes = append(includes, t.switches.modules[name].Filename)
	}
	return includes
}

func validateUnits(units config.Units) error {
	if units.Length != "mm" {
		return errors.New("only \"mm\" units are supported")
	}
	if units.Angle != "deg" {
		return errors.New("only \"deg\" units are supported")
	}
	return nil
}

func validateLayout(layout config.Layout) error {
	if layout.Rows <= 1 {
		return errors.New("rows must be greater than 1")
	}
	if layout.Cols <= 4 {
		return errors.New("cols must be greater than 4")
	}
	return nil
}

func validateSwitchTypes(switchTypes map[string]config.SwitchTypeConfig, repo *switchRepository) (*switchRepository, error) {
	newRepo := &switchRepository{modules: make(map[string]*config.SwitchModuleDefinition)}
	for name, switchType := range switchTypes {
		if switchType.Definition == "" {
			return nil, errors.New("switch type definition is required for switch type: " + name)
		}
		module, err := repo.GetModule(switchType.Definition)
		if err != nil {
			return nil, errors.Join(errors.New("failed to get switch module for switch type: "+name), err)
		}
		if module == nil {
			return nil, errors.New("switch module not found for switch type: " + name)
		}
		newModule, err := OverrideModule(module, switchType.ExtraArgs)
		if err != nil {
			return nil, errors.Join(errors.New("failed to override switch module for switch type: "+name), err)
		}
		err = newRepo.AddModule(name, newModule)
		if err != nil {
			return nil, errors.Join(errors.New("failed to add switch module for switch type: "+name), err)
		}
	}
	return newRepo, nil
}

func newTemplateData(config *config.Config, repo *switchRepository) (*templateData, error) {
	err := validateUnits(config.Units)
	if err != nil {
		return nil, errors.Join(errors.New("failed to validate units"), err)
	}
	err = validateLayout(config.Layout)
	if err != nil {
		return nil, errors.Join(errors.New("failed to validate layout"), err)
	}
	switchRepo, err := validateSwitchTypes(config.SwitchTypes, repo)
	if err != nil {
		return nil, errors.Join(errors.New("failed to validate switch types"), err)
	}

	return &templateData{
		units:        config.Units,
		Layout:       config.Layout,
		switches:     switchRepo,
		Geometry:     config.Geometry,
		Keywell:      newTemplateKeywell(config.Keywell, config.Layout.Rows, config.Layout.Cols),
		Render:       config.Render,
		ThumbCluster: newTemplateThumbCluster(config.ThumbCluster),
	}, nil
}
