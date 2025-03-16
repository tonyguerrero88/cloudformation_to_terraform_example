# Convert CloudFormation Templates to Terraform using GitHub Actions

This repository contains a GitHub Actions workflow that automatically converts CloudFormation templates (`.yaml` files) into Terraform configuration files (`.tf`).

## Acknowledgement 
### CF2TF is a tool created by [DontShaveTheYak](https://github.com/DontShaveTheYak/cf2tf)

## Workflow Overview

### What It Does:

1. **Installs Python 3.10** using GitHub Actions.
2. **Finds all `.yaml` files** in the `cf_templates/` folder.
3. **Runs `cf2tf`** on each YAML file to generate the corresponding Terraform (`.tf`) file.
4. **Uploads the Terraform files** as artifacts for download.

## Workflow File: `.github/workflows/cf2tf.yml`

```yaml
name: Convert CF Templates to Terraform

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  convert_cf_to_tf:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Python 3.10
        uses: actions/setup-python@v4
        with:
          python-version: "3.10"

      - name: Install cf2tf
        run: |
          pip install cf2tf  # Modify this if cf2tf requires a different install method

      - name: Convert YAML files to Terraform
        run: |
          mkdir -p converted_tf
          for file in cf_templates/*.yaml; do
            [ -f "$file" ] || continue
            filename=$(basename -- "$file")
            filename_no_ext="${filename%.*}"
            cf2tf "$file" > "converted_tf/${filename_no_ext}.tf"
          done

      - name: Upload Terraform Files as Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: converted-terraform-files
          path: converted_tf/
```

## Fixing `Missing download info for actions/upload-artifact@v3`

If you encounter this error, try one of the following solutions:

### 1. Use the Latest Version

Change the artifact upload step to use `v4`:

```yaml
      - name: Upload Terraform Files as Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: converted-terraform-files
          path: converted_tf/
```

### 2. Use the Full Version Number

Specify the full version of `upload-artifact`:

```yaml
      - name: Upload Terraform Files as Artifacts
        uses: actions/upload-artifact@v4.3.1
        with:
          name: converted-terraform-files
          path: converted_tf/
```

### 3. Ensure Network Connectivity

If using a self-hosted runner, verify it has internet access:

```bash
curl -L https://api.github.com/repos/actions/upload-artifact/releases/latest
```

### 4. Manually Specify the Repository

Try explicitly defining the repository reference:

```yaml
      - name: Upload Terraform Files as Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: converted-terraform-files
          path: converted_tf/
```

### 5. Clear GitHub Actions Cache

Delete existing workflow runs and restart a fresh run.

### 6. Commit and Push Generated Files Instead

If you prefer to commit the `.tf` files to the repository instead of uploading them as artifacts, add this step:

```yaml
      - name: Commit and Push Changes
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git add converted_tf/
          git commit -m "Add converted Terraform files"
          git push
```

## Summary

- This workflow automates CloudFormation to Terraform conversion.
- Fixes for `upload-artifact` errors are provided.
- Files can either be uploaded as artifacts or committed directly to the repository.

Would you like additional customizations? 🚀
