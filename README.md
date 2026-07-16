# DevSecOps Pipeline for OWASP Juice Shop

An end-to-end DevSecOps CI/CD pipeline built from scratch using GitHub Actions, applying automated security scanning — SAST, SCA, secrets detection, container image scanning, and IaC scanning — against OWASP Juice Shop, an intentionally vulnerable web application.

This project was built as a hands-on learning exercise to understand how security scanning tools integrate into a real CI/CD pipeline, how to interpret their findings, and how to enforce security gates that actually block insecure code from passing.

---

## Objective

Rather than reading about DevSecOps, this project takes a real (deliberately vulnerable) application and wraps a full security-scanning pipeline around it — mirroring what a security engineer would set up around a real production codebase. Every tool in this pipeline was chosen, configured, debugged, and validated against real findings, not just copy-pasted from documentation.

---

## Architecture
Jobs run in parallel on every push. Two jobs (`sast-scan`, `image-scan`) are configured as **hard gates** — they fail the pipeline outright when high-severity findings are detected, rather than merely reporting them.

A full diagram is included in this repo: `architecture-diagram.drawio`.

---

## Tools Used

| Category | Tool | Purpose |
|---|---|---|
| CI/CD Engine | GitHub Actions | Pipeline orchestration and automation |
| Containerization | Docker / Docker Compose | Running Juice Shop locally, building scannable images |
| SAST | Semgrep | Static source code vulnerability scanning |
| SCA | Trivy (fs mode) | Dependency vulnerability scanning |
| Secrets Detection | Gitleaks | Hardcoded credentials / key detection |
| Container Scanning | Trivy (image mode) | OS + dependency vulnerabilities in built Docker image |
| IaC Scanning | Checkov | Terraform misconfiguration detection |
| IaC | Terraform | Infrastructure-as-Code definitions (AWS S3 + Security Group) |

---

## Key Findings

This pipeline surfaced real, exploitable vulnerabilities in Juice Shop's codebase and dependency tree:

- **SQL Injection** in `routes/login.ts` (confirmed exploitable manually via `' OR 1=1--`)
- **Hardcoded JWT secret and RSA private key** in `lib/insecurity.ts` — confirmed independently by both Semgrep and Trivy
- **Path traversal** and **open redirect** vulnerabilities in several route handlers
- **CRITICAL CVEs** in transitive dependencies shipped inside the built container image, including:
  - `crypto-js@3.3.0` — critically weak password hashing (CVE-2023-46233)
  - `decompress@4.2.1` — arbitrary file write via crafted archive (CVE-2026-53486)
  - `jsonwebtoken@0.1.0` — JWT algorithm confusion authentication bypass (CVE-2015-9235)
  - `marsdb@0.6.11` — command injection via unsanitized query clauses
- **Insecure Terraform configuration** — publicly-writable S3 bucket, SSH security group open to the entire internet (0.0.0.0/0), missing encryption/versioning/logging (14 Checkov findings)

---

## Pipeline Gating

Two jobs enforce hard security gates rather than just reporting:

- `sast-scan` fails the build on any Semgrep finding rated `ERROR` severity
- `image-scan` fails the build on any `CRITICAL` container vulnerability

This demonstrates the core DevSecOps principle of **shifting left**: catching and blocking security issues automatically, before they can reach a deployable branch — not relying on manual review after the fact.

---

## Known Limitations

Documented transparently rather than hidden:

- **SCA (`sca-scan`) fs-mode detection** — Trivy's filesystem-mode dependency scan intermittently fails to detect `package.json`/lockfiles depending on checkout path resolution; image-mode scanning (which does work reliably) is used as the primary dependency-vulnerability source instead.
- **Secrets scan working directory** — Gitleaks' GitHub Action does not support a `working-directory`/`path` input on `uses:` steps in the way initially expected; the job currently scans the default checkout context rather than Juice Shop's full git history. Marked `continue-on-error: true` pending a fix.

---

## What I Learned

- How SAST, SCA, secrets scanning, container scanning, and IaC scanning are conceptually different and where each catches issues the others can't
- How to debug real GitHub Actions YAML and permissions issues (least-privilege `permissions:` blocks, step-level `working-directory` constraints, checkout path resolution)
- How to interpret real CVE/CWE/OWASP-mapped findings and distinguish signal from noise
- The practical difference between a pipeline that *reports* problems and one that *enforces* a security bar via gating
- How static analysis (SAST) complements, rather than replaces, manual penetration testing — confirmed by manually exploiting a SQL injection finding that Semgrep flagged

---

## Running This Project Locally

```bash
git clone https://github.com/vivere1949/devsecops-juiceshop-lab.git
cd devsecops-juiceshop-lab
docker compose up -d
```

Juice Shop will be available at `http://localhost:3000`.

The full pipeline runs automatically on every push via GitHub Actions — no local setup required to see scan results; check the **Actions** tab of this repository.

---

## Roadmap / Possible Extensions

- DAST scanning with OWASP ZAP against a running instance
- AI-powered triage layer summarizing findings across all scanners into a single prioritized report
- Real cloud deployment (AWS EC2 + Nginx reverse proxy + Let's Encrypt) with a full CD stage gated on these security checks

---

## Author

Built by Omar Bouhriz as a hands-on DevSecOps learning project.
