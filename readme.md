# Convert CloudFormation Templates to Terraform using GitHub Actions

This repository contains a GitHub Actions workflow that automatically converts CloudFormation templates (`.yaml` files) into Terraform configuration files (`.tf`).

## Workflow Overview

### What It Does:

1. **Runs on push to main** to ensure Terraform templates are generated and stored correctly.
2. **Installs Python 3.10** using GitHub Actions.
3. **Finds all `.yaml` files** in the `cf_templates/` folder.
4. **Runs `cf2tf`** on each YAML file to generate the corresponding Terraform (`.tf`) file.
5. **Displays the output of the conversion in the action logs.**
6. **Uploads the Terraform files** as artifacts for download.
7. **Commits and pushes the generated Terraform files** back to the repository under the `tf_templates/` folder while preventing infinite workflow loops.

## Workflow File: `.github/workflows/cf2tf.yml`

```yaml
name: Convert CF Templates to Terraform

on:
  push:
    branches:
      - main

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

      - name: Convert YAML files to Terraform and Display Output
        run: |
          mkdir -p tf_templates
          for file in cf_templates/*.yaml; do
            [ -f "$file" ] || continue
            filename=$(basename -- "$file")
            filename_no_ext="${filename%.*}"
            echo "Processing: $file"
            cf2tf "$file" | tee "tf_templates/${filename_no_ext}.tf"
          done

      - name: Upload Terraform Files as Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: converted-terraform-files
          path: tf_templates/

      - name: Commit and Push Converted Templates
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git add tf_templates/
          git diff --quiet && git diff --staged --quiet || (git commit -m "Add converted Terraform templates [skip ci]" && git push)
```

## Explanation of Workflow Steps

### 1. Trigger on Push to Main

- This workflow runs when **code is pushed to the `main` branch**.
- Ensures Terraform files are generated and stored properly.

### 2. Install Dependencies

- Uses **Python 3.10**.
- Installs **cf2tf**, a tool to convert CloudFormation YAML files to Terraform.

### 3. Convert YAML Files to Terraform and Display Output

- It finds all `.yaml` files in the `cf_templates/` folder.
- Converts them to `.tf` files and stores them in `tf_templates/`.
- Displays the conversion output in the GitHub Actions logs for visibility.

### 4. Upload Terraform Files as Artifacts

- Stores generated `.tf` files as GitHub artifacts, allowing easy download.

### 5. Commit and Push Terraform Files with a Skip CI Flag

- Automatically commits the generated `.tf` files to the repository under `tf_templates/`.
- The commit message includes `[skip ci]` to prevent GitHub Actions from retriggering the workflow indefinitely.
- The step checks for changes before committing to avoid unnecessary commits.

## Summary

- **Runs on push to main** to maintain Terraform files.
- **Converts CloudFormation YAML to Terraform**.
- **Displays conversion output in logs** for easier debugging.
- **Uploads artifacts** for review.
- **Commits Terraform templates** back to the repository while preventing infinite workflow loops.

Would you like any modifications? 🚀
