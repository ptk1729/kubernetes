# SLSA (Supply-chain Levels for Software Artifacts) Setup

This document describes the SLSA provenance setup for the Kubernetes repository.

## Overview

SLSA (Supply-chain Levels for Software Artifacts) is a security framework that provides a way to secure the software supply chain. This repository implements SLSA Level 3 provenance generation and verification for Kubernetes binaries.

## Files

### Workflow Files

- `.github/workflows/slsa-goreleaser.yml` - Original single binary workflow
- `.github/workflows/slsa-multi-binary.yml` - Multi-binary workflow for multiple Kubernetes components

### Configuration Files

- `.slsa-goreleaser.yml` - Configuration for kubectl binary
- `.slsa-goreleaser-kubectl.yml` - Specific configuration for kubectl
- `.slsa-goreleaser-kubelet.yml` - Specific configuration for kubelet
- `.slsa-goreleaser-kube-apiserver.yml` - Specific configuration for kube-apiserver
- `.slsa-policy.yml` - SLSA policy configuration for validation

## Workflows

### Single Binary Workflow

The `slsa-goreleaser.yml` workflow builds a single binary (kubectl) with SLSA provenance:

1. **Args Job**: Gathers git information (commit, version, tree state)
2. **Build Job**: Uses SLSA GitHub generator to build and sign the binary
3. **Verify Job**: Downloads and verifies the provenance

### Multi-Binary Workflow

The `slsa-multi-binary.yml` workflow builds multiple Kubernetes binaries:

1. **Args Job**: Gathers git information
2. **Build Jobs**: Parallel builds for kubectl, kubelet, and kube-apiserver
3. **Verify Job**: Verifies all binaries using the official SLSA verifier

## Configuration

### Binary Configuration

Each binary has its own configuration file with:

- **Entry Point**: The main.go file to compile
- **Output Name**: The binary output name with OS/arch template
- **Build Flags**: Compiler flags for reproducible builds
- **LDFlags**: Version information embedded in the binary

### Build Flags

All binaries are built with:
- `-trimpath`: Removes file system paths for reproducibility
- `-tags=netgo`: Uses pure Go network stack
- `CGO_ENABLED=0`: Disables CGO for static binaries

### Version Information

Version information is embedded using LDFlags:
- `gitVersion`: Git tag/version
- `gitCommit`: Git commit hash
- `gitTreeState`: Clean/dirty state
- `buildDate`: Build timestamp

## Verification

### SLSA Verifier

The verification process uses the official SLSA verifier to:

1. Verify provenance signatures
2. Validate build environment
3. Check source repository
4. Validate binary properties

### Policy Validation

The `.slsa-policy.yml` file defines security policies:

- **Source Validation**: Allowed repositories and tags
- **Build Environment**: Required OS, architecture, and tools
- **Binary Properties**: Required binary characteristics
- **Security Requirements**: SLSA level and attestation requirements

## Usage

### Triggering Builds

Workflows are triggered by:
- **Tag Push**: `git tag v1.25.0 && git push origin v1.25.0`
- **Manual Dispatch**: GitHub Actions UI

### Verifying Binaries

To verify a binary locally:

```bash
# Download the binary and provenance
wget https://github.com/kubernetes/kubernetes/releases/download/v1.25.0/kubectl-linux-amd64
wget https://github.com/kubernetes/kubernetes/releases/download/v1.25.0/kubectl-linux-amd64.intoto.jsonl

# Verify using SLSA verifier
slsa-verifier verify-artifact \
  --provenance-path kubectl-linux-amd64.intoto.jsonl \
  --source-uri github.com/kubernetes/kubernetes \
  --source-tag v1.25.0 \
  kubectl-linux-amd64
```

## Security Benefits

### SLSA Level 3 Compliance

This setup provides:

1. **Provenance**: Cryptographic proof of build process
2. **Reproducible Builds**: Deterministic build process
3. **Source Verification**: Proof of source code origin
4. **Build Environment**: Verified build environment
5. **Transparency**: Public transparency log

### Supply Chain Security

- **Tamper Evidence**: Any tampering with build process is detectable
- **Source Integrity**: Proof that binaries come from verified source
- **Build Integrity**: Proof of build environment and process
- **Verification**: Anyone can verify binary authenticity

## Troubleshooting

### Common Issues

1. **Go Version Mismatch**: Ensure go.mod and workflow use same Go version
2. **Binary Not Found**: Check that main.go path is correct in config
3. **Verification Fails**: Ensure source URI and tag match exactly
4. **Build Fails**: Check that all required dependencies are available

### Debugging

Enable debug logging in workflows:
```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## References

- [SLSA Framework](https://slsa.dev/)
- [SLSA GitHub Generator](https://github.com/slsa-framework/slsa-github-generator)
- [SLSA Verifier](https://github.com/slsa-framework/slsa-verifier)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)
