# Convert CloudFormation Templates to Terraform using GitHub Actions

This repository contains a **GitHub Actions workflow** that automatically converts **AWS CloudFormation templates (`.yaml` files)** into **Terraform configuration files (`.tf`)**. It ensures that Terraform files are always up to date with the latest CloudFormation changes and **automatically commits the converted files** back to the repository.

# Acknowledgement

The CF2TF tool was created by [DontShaveTheYak](https://github.com/DontShaveTheYak/cf2tf)

## 🔥 Workflow Overview

### What This Workflow Does:
1. **Triggers on push to `main`** to ensure Terraform templates are generated and stored correctly.
2. **Installs Python 3.10** using GitHub Actions.
3. **Finds all `.yaml` files** in the `cf_templates/` folder.
4. **Runs `cf2tf`** on each YAML file to generate the corresponding Terraform (`.tf`) file.
5. **Displays the conversion output in the GitHub Actions logs.**
6. **Uploads the Terraform files as artifacts for download.**
7. **Commits and pushes the generated Terraform files** back to the repository under the `tf_templates/` folder **while preventing infinite workflow loops**.

## 📜 Workflow File: `.github/workflows/cf2tf.yml`

This GitHub Actions workflow is responsible for **automating the conversion of CloudFormation YAML templates into Terraform configuration files**. It runs every time a push is made to the `main` branch.

```yaml
name: Convert CF Templates to Terraform

on:
  push:
    branches:
      - main

permissions:
  contents: write  # Grants permission to push changes

jobs:
  convert_cf_to_tf:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}  # Ensures authenticated checkout

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
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git add tf_templates/
          git diff --quiet && git diff --staged --quiet || (git commit -m "Add converted Terraform templates [skip ci]" && git push origin main)
```

---

## 📖 **Step-by-Step Explanation of the Workflow**

### **1️⃣ Trigger on Push to Main**
- The workflow **only runs when a commit is pushed to the `main` branch**.
- This ensures Terraform files are always in sync with CloudFormation templates.

### **2️⃣ Install Python and Dependencies**
- Sets up **Python 3.10** on the runner.
- Installs **`cf2tf`**, the tool that converts CloudFormation YAML templates into Terraform.

### **3️⃣ Convert YAML Files to Terraform (`.tf`)**
- Finds all `.yaml` files in the `cf_templates/` directory.
- Converts each one into a `.tf` file using `cf2tf`.
- The generated Terraform files are stored in `tf_templates/`.

### **4️⃣ Display Conversion Output in Logs**
- The workflow **logs each processed file** for debugging purposes.
- This allows users to **verify conversion results** directly in GitHub Actions logs.

### **5️⃣ Upload Terraform Files as Artifacts**
- The converted `.tf` files are **uploaded as artifacts**, making them available for download.

### **6️⃣ Commit and Push Terraform Files Back to Repository**
- The workflow **automatically commits the converted Terraform files**.
- Uses `GITHUB_TOKEN` with `write` permissions to **authenticate the commit**.
- Includes **`[skip ci]` in the commit message** to **prevent infinite loops**.
- Checks for changes before committing to **avoid unnecessary commits**.

---

## 🛠 **Fixing GitHub Actions Permission Issues (403 Error)**
If the workflow **fails with a `403 Permission Denied` error**, follow these steps:

1. **Enable "Read and Write Permissions" for GitHub Actions**:
   - Go to **Repository Settings → Actions → General → Workflow Permissions**.
   - Ensure **"Read and write permissions"** is enabled.

2. **Ensure the `GITHUB_TOKEN` is Passed Correctly**:
   - The workflow **must include `permissions: contents: write`**.
   - This allows the GitHub Actions bot to **push changes** back to the repository.

3. **Check if Branch Protection Rules are Blocking Pushes**:
   - If your repository has **branch protection rules**, ensure that:
     - "Require status checks to pass before merging" is **not blocking the bot**.
     - The GitHub Actions bot has **write access** to push changes.

---

## 🚀 **Why This Workflow is Useful**
- **Fully automates CloudFormation to Terraform conversion.**
- **Ensures Terraform files are always in sync** with CloudFormation templates.
- **Prevents infinite workflow loops** by using `[skip ci]` in commits.
- **Provides visibility into conversion results** via GitHub Actions logs.
- **Uploads Terraform files as artifacts** for easy review and validation.

---

## 📌 **Next Steps**
✅ **Run the workflow by pushing a change to `main`**.  
✅ **Verify the Terraform files in the `tf_templates/` directory**.  
✅ **Check the GitHub Actions logs to ensure everything runs smoothly**.  
