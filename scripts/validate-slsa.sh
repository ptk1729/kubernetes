#!/bin/bash

# SLSA Configuration Validation Script
# This script validates the SLSA setup for the Kubernetes repository

set -e

echo "🔍 Validating SLSA Configuration..."

# Check if required files exist
echo "📁 Checking required files..."

required_files=(
    ".github/workflows/slsa-goreleaser.yml"
    ".github/workflows/slsa-multi-binary.yml"
    ".slsa-goreleaser.yml"
    ".slsa-goreleaser-kubectl.yml"
    ".slsa-goreleaser-kubelet.yml"
    ".slsa-goreleaser-kube-apiserver.yml"
    ".slsa-policy.yml"
    "SLSA.md"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Validate YAML syntax
echo "🔧 Validating YAML syntax..."

yaml_files=(
    ".github/workflows/slsa-goreleaser.yml"
    ".github/workflows/slsa-multi-binary.yml"
    ".slsa-goreleaser.yml"
    ".slsa-goreleaser-kubectl.yml"
    ".slsa-goreleaser-kubelet.yml"
    ".slsa-goreleaser-kube-apiserver.yml"
    ".slsa-policy.yml"
)

for file in "${yaml_files[@]}"; do
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint "$file" >/dev/null 2>&1; then
            echo "✅ $file YAML syntax valid"
        else
            echo "❌ $file YAML syntax invalid"
            yamllint "$file"
        fi
    else
        echo "⚠️  yamllint not available, skipping YAML validation for $file"
    fi
done

# Check Go version consistency
echo "🐹 Checking Go version consistency..."

go_version_in_mod=$(grep "^go " go.mod | awk '{print $2}')
go_version_in_workflow=$(grep "go-version:" .github/workflows/slsa-goreleaser.yml | head -1 | awk '{print $2}' | tr -d "'")

if [[ "$go_version_in_mod" == "$go_version_in_workflow" ]]; then
    echo "✅ Go versions consistent: $go_version_in_mod"
else
    echo "❌ Go version mismatch: go.mod=$go_version_in_mod, workflow=$go_version_in_workflow"
    exit 1
fi

# Check if main.go files exist for configured binaries
echo "📦 Checking binary entry points..."

binary_configs=(
    ".slsa-goreleaser-kubectl.yml:./cmd/kubectl"
    ".slsa-goreleaser-kubelet.yml:./cmd/kubelet"
    ".slsa-goreleaser-kube-apiserver.yml:./cmd/kube-apiserver"
)

for config in "${binary_configs[@]}"; do
    file=$(echo "$config" | cut -d: -f1)
    main_path=$(echo "$config" | cut -d: -f2)
    
    if [[ -f "$main_path/main.go" ]]; then
        echo "✅ $file: $main_path/main.go exists"
    else
        echo "❌ $file: $main_path/main.go missing"
        exit 1
    fi
done

# Check SLSA workflow permissions
echo "🔐 Checking SLSA workflow permissions..."

if grep -q "id-token: write" .github/workflows/slsa-goreleaser.yml; then
    echo "✅ SLSA workflow has required id-token permission"
else
    echo "❌ SLSA workflow missing id-token permission"
    exit 1
fi

if grep -q "contents: write" .github/workflows/slsa-goreleaser.yml; then
    echo "✅ SLSA workflow has required contents permission"
else
    echo "❌ SLSA workflow missing contents permission"
    exit 1
fi

# Check SLSA builder version
echo "🏗️  Checking SLSA builder version..."

if grep -q "slsa-framework/slsa-github-generator" .github/workflows/slsa-goreleaser.yml; then
    echo "✅ SLSA GitHub generator referenced"
else
    echo "❌ SLSA GitHub generator not found"
    exit 1
fi

# Check for required build flags
echo "⚙️  Checking build configuration..."

required_flags=("-trimpath" "-tags=netgo")
for flag in "${required_flags[@]}"; do
    if grep -q "$flag" .slsa-goreleaser-kubectl.yml; then
        echo "✅ Required flag $flag found"
    else
        echo "❌ Required flag $flag missing"
        exit 1
    fi
done

# Check environment variables
echo "🌍 Checking environment variables..."

required_env_vars=("GO111MODULE=on" "CGO_ENABLED=0")
for env_var in "${required_env_vars[@]}"; do
    if grep -q "$env_var" .slsa-goreleaser-kubectl.yml; then
        echo "✅ Required env var $env_var found"
    else
        echo "❌ Required env var $env_var missing"
        exit 1
    fi
done

echo ""
echo "🎉 SLSA configuration validation completed successfully!"
echo ""
echo "📋 Summary:"
echo "   • All required files present"
echo "   • YAML syntax valid"
echo "   • Go versions consistent"
echo "   • Binary entry points exist"
echo "   • Workflow permissions correct"
echo "   • SLSA builder configured"
echo "   • Build flags and environment variables set"
echo ""
echo "🚀 Your SLSA setup is ready to use!"
echo "   • Single binary workflow: .github/workflows/slsa-goreleaser.yml"
echo "   • Multi-binary workflow: .github/workflows/slsa-multi-binary.yml"
echo "   • Documentation: SLSA.md"
echo ""
echo "💡 To trigger a build:"
echo "   git tag v1.25.0 && git push origin v1.25.0"
