# 🧳 AI Trip Planner – Contribution Guide

Welcome to the **AI Trip Planner Project**!
This repository hosts both the **Web Application** and the **Android Application**. To maintain consistency and smooth collaboration, please follow the contribution rules below.

---

## 📂 Repository Structure

```
root/
│── web/         # Web application code
│── android/     # Android application code
│── docs/        # Documentation
│── .github/     # CI/CD workflows, issue templates, PR templates
│── README.md    # This file
```

---

## 🌿 Branching Strategy

We follow a **3-level branching model**:

* **`main` (production branch)**

  * Always stable.
  * Contains only production-ready, tested code.
  * Protected branch (no direct pushes, PR only).

* **`develop` (integration branch)**

  * Contains latest merged features that are ready for QA/testing.
  * Developers branch off from here.
  * Merges into `main` only after release approval.

* **Feature branches (`feature/<name>`)**

  * For individual tasks/features/bug fixes.
  * Always branch off from `develop`.
  * Naming:

    * `feature/login-system`
    * `feature/payment-api`
    * `bugfix/ui-alignment`

> Example workflow:
> `develop` → `feature/search-api` → commit work → push → PR → merge back into `develop` → release → merge into `main`

---

## 📝 Commit Message Guidelines

We follow the **Conventional Commits** format:

```
<type>(scope): short description
```

### Types:

* `feat` → new feature
* `fix` → bug fix
* `docs` → documentation changes
* `style` → code formatting (no logic change)
* `refactor` → code restructuring
* `test` → adding/updating tests
* `chore` → maintenance tasks

### Examples:

```
feat(auth): add Google login integration
fix(api): handle null response in trip planner API
docs(readme): update contribution guidelines
```

---

## 🔀 Pull Request (PR) Rules

* PRs must be created **against `develop`** (unless hotfix).

* Each PR must:

  * Have a **clear title & description**
  * Link to the issue/task (`Closes #12`)
  * Pass **CI/CD checks**
  * Be reviewed by at least **1 other developer**

* No direct commits to `main` or `develop`.

---

## 🧩 Contribution Workflow

1. **Create a branch**

   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/<task-name>
   ```

2. **Work on changes**

   * Keep commits small & logical.
   * Follow commit rules.

3. **Push to remote**

   ```bash
   git push origin feature/<task-name>
   ```

4. **Open Pull Request**

   * Merge request into `develop`.

5. **Code Review & Merge**

   * Squash or rebase before merging if needed.

---

## ✅ Code Quality & Reviews

* Follow **coding standards** (set by team: ESLint, Prettier, Checkstyle, etc.)
* All code must pass **tests** before PR approval.
* **Do not commit credentials or secrets** – use `.env` files (ignored in `.gitignore`).

---

## 📌 Branch Protection Rules

* `main`:

  * No direct commits
  * Requires PR + 1 approval + CI pass

* `develop`:

  * No direct commits
  * Requires PR + CI pass

* `feature/*`:

  * Free for developer work

---

## 👨‍💻 Developer Roles (for now, 3 devs)

* **Dev A (Lead)**: Reviews PRs, merges into `main`
* **Dev B & Dev C**: Feature development, bug fixes

---

## 🚀 Release Workflow

1. Merge `develop` → `main` only when stable.
2. Tag release version:

   ```bash
   git tag -a v1.0.0 -m "First stable release"
   git push origin v1.0.0
   ```
3. CI/CD will auto-deploy based on tags.

---

## 🧾 Example GitHub Workflow

```
main (stable)  ← release from develop
develop        ← integrates all features
feature/*      ← per feature/task
```

---

## 📋 Summary of Rules

* Branches: `main`, `develop`, `feature/*`
* Commit format: Conventional Commits
* PRs: Always → `develop`
* No direct pushes to `main` or `develop`
* 1 review required before merge
* Secrets → never in repo

---

👉 This keeps the project **organized, scalable, and easy for new devs to onboard**.

---

Would you like me to also create a **`.github/CONTRIBUTING.md`** and **PR template** along with this README so your team can directly use it in GitHub?
