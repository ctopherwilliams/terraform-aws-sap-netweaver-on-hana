// Package test contains Terratest-based integration tests for the
// terraform-aws-sap-netweaver-on-hana module.
//
// These tests provision real, billable AWS infrastructure. They run only when
// the required environment variables (and AWS credentials) are present, and
// they always destroy what they create. See test/README.md for how to run them.
package test

import (
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// requiredEnv returns the value of an environment variable, or skips the test
// if it is not set. This keeps the suite a no-op in environments (CI forks,
// local checkouts) that have not been wired up with a test AWS account.
func requiredEnv(t *testing.T, key string) string {
	t.Helper()
	v := os.Getenv(key)
	if v == "" {
		t.Skipf("skipping integration test: %s is not set", key)
	}
	return v
}

// TestBasicExampleAppliesAndDestroys applies the examples/basic configuration,
// asserts that the module returns the expected outputs, and tears everything
// down again.
func TestBasicExampleAppliesAndDestroys(t *testing.T) {
	t.Parallel()

	vpcID := requiredEnv(t, "SAP_TEST_VPC_ID")
	subnetIDs := requiredEnv(t, "SAP_TEST_SUBNET_IDS") // comma-separated
	amiID := requiredEnv(t, "SAP_TEST_AMI_ID")
	sid := requiredEnv(t, "SAP_TEST_SID")

	region := os.Getenv("AWS_REGION")
	if region == "" {
		region = "us-east-1"
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/basic",
		Vars: map[string]interface{}{
			"aws_region": region,
			"vpc_id":     vpcID,
			"subnet_ids": splitAndTrim(subnetIDs),
			"ami_id":     amiID,
			"sid":        sid,
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// The composed example exposes the whole module under the `sap` output.
	sap := terraform.OutputJson(t, terraformOptions, "sap")
	assert.NotEmpty(t, sap, "module should expose outputs")
	assert.Contains(t, sap, "hana_instance_ids", "outputs should include the HANA tier")
}

func splitAndTrim(csv string) []string {
	parts := strings.Split(csv, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if s := strings.TrimSpace(p); s != "" {
			out = append(out, s)
		}
	}
	return out
}
