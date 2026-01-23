# Security Policy

## 🔒 Secret Scanning

This repository uses automated secret scanning to detect accidentally committed credentials and sensitive information.

### Automated Scans

We use three complementary tools to scan for secrets:

1. **[Gitleaks](https://github.com/gitleaks/gitleaks)** - Fast and comprehensive secret scanner
   - Scans all commits in the repository history
   - Uses custom rules defined in `.gitleaks.toml`
   - Runs on every push and pull request

2. **[TruffleHog](https://github.com/trufflesecurity/trufflehog)** - High-entropy secret detector
   - Detects high-entropy strings that may be secrets
   - Verifies secrets against live APIs when possible
   - Scans commit history and file contents

3. **[detect-secrets](https://github.com/Yelp/detect-secrets)** - Baseline-based secret detection
   - Uses multiple detection plugins
   - Excludes Terraform state files and Git metadata
   - Provides detailed findings

### When Scans Run

- ✅ On every push to `main`, `master`, or `develop` branches
- ✅ On every pull request
- ✅ Weekly scheduled scan (Mondays at 9:00 AM UTC)
- ✅ Manual trigger via GitHub Actions UI

### Local Scanning

You can run secret scans locally before committing:

#### Install Gitleaks

```bash
# macOS
brew install gitleaks

# Linux
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.1/gitleaks_8.18.1_linux_x64.tar.gz
tar -xzf gitleaks_8.18.1_linux_x64.tar.gz
sudo mv gitleaks /usr/local/bin/
```

#### Scan Your Changes

```bash
# Scan uncommitted changes
gitleaks detect --no-git

# Scan all files
gitleaks detect --source . -v

# Scan specific commit range
gitleaks detect --log-opts="origin/main..HEAD"
```

#### Install Pre-commit Hook

```bash
# Create pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "🔍 Scanning for secrets..."
gitleaks protect --staged --verbose
if [ $? -eq 1 ]; then
    echo "❌ Secret detected! Commit blocked."
    echo "If this is a false positive, add it to .gitleaks.toml allowlist"
    exit 1
fi
echo "✅ No secrets detected"
EOF

chmod +x .git/hooks/pre-commit
```

### False Positives

If the scanner detects a false positive, you can:

1. **Add to allowlist** in `.gitleaks.toml`:
   ```toml
   [allowlist]
   regexes = [
     '''your-false-positive-pattern''',
   ]
   ```

2. **Add inline comment** to ignore specific line:
   ```python
   secret = "not-a-real-secret"  # gitleaks:allow
   ```

3. **Exclude file paths** in `.gitleaks.toml`:
   ```toml
   [allowlist]
   paths = [
     '''path/to/safe/file\.txt''',
   ]
   ```

### What to Do If Secrets Are Found

If secrets are detected in your commits:

1. **DO NOT** just remove the secret in a new commit - it's still in Git history
2. **Immediately rotate** the exposed credentials
3. **Remove from Git history** using one of these methods:

   ```bash
   # Option 1: Use BFG Repo-Cleaner (recommended)
   java -jar bfg.jar --delete-files secret-file.txt
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive

   # Option 2: Use git filter-branch
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch path/to/secret-file" \
     --prune-empty --tag-name-filter cat -- --all
   ```

4. **Force push** to update remote (⚠️ coordinate with team):
   ```bash
   git push origin --force --all
   git push origin --force --tags
   ```

5. **Notify security team** if credentials were exposed

### Best Practices

- ✅ Use environment variables for secrets
- ✅ Use AWS Secrets Manager, HashiCorp Vault, or similar
- ✅ Use Terraform variables with `sensitive = true`
- ✅ Never commit `.tfvars` files with real values
- ✅ Use `.gitignore` to exclude sensitive files
- ✅ Review changes before committing
- ✅ Enable branch protection rules

### Reporting Security Issues

If you discover a security vulnerability, please email: **security@example.com**

Do not create public GitHub issues for security vulnerabilities.

---

**Last Updated**: 2026-01-23

