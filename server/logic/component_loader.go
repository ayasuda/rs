package logic

import (
  _ "embed"
  "fmt"
  "gopkg.in/yaml.v3"
)

//go:embed components.yaml
var componentYAML []byte

type ComponentSpec struct {
  ID           string               `yaml:"id"`
  Type         string               `yaml:"type"`
  Label        string               `yaml:"label"`
  Contribution map[MetricKey]uint16 `yaml:"contribution"`
}

var ComponentMaster = map[string]ComponentSpec{}

// LoadComponentSpecs は埋め込まれたYAMLをパースして ComponentMaster に格納します
func LoadComponentSpecs() error {
  var list []ComponentSpec
  if err := yaml.Unmarshal(componentYAML, &list); err != nil {
    return fmt.Errorf("YAMLパース失敗: %w", err)
  }
  for _, spec := range list {
    ComponentMaster[spec.ID] = spec
  }
  return nil
}
