// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"log"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

// Use existing resource group
const resourceGroup = "geretain-test-resources"
const completeExampleDir = "examples/complete"
const basicExampleDir = "examples/basic"
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

// TestMain runs before any parallel tests, loading shared permanent resources from YAML.
func TestMain(m *testing.M) {
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}
	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, dir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  dir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
	})
	return options
}

func TestRunCompleteExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  completeExampleDir,
		Prefix:        "vsi-auto-c",
		ResourceGroup: resourceGroup,
		TerraformVars: map[string]interface{}{
			"access_tags":                 permanentResources["accessTags"],
			"existing_sm_instance_guid":   permanentResources["secretsManagerGuid"],
			"existing_sm_instance_region": permanentResources["secretsManagerRegion"],
			"existing_sm_cert_template":   permanentResources["privateCertTemplateName"],
		},
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

	// Verify that the ALB reports mTLS as supported.
	// Terraform outputs are available on options.LastTestTerraformOutputs after the apply.
	if assert.Contains(t, options.LastTestTerraformOutputs, "lb_mtls_supported", "Expected lb_mtls_supported in Terraform outputs") {
		mtlsMap, ok := options.LastTestTerraformOutputs["lb_mtls_supported"].(map[string]interface{})
		if assert.True(t, ok, "lb_mtls_supported should be a map") {
			for lbName, supported := range mtlsMap {
				assert.True(t, supported.(bool), "Expected ALB %q to report mtls_supported = true", lbName)
			}
		}
	}
}

func TestRunBasicUpgradeExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "vsi-auto-upg", basicExampleDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
