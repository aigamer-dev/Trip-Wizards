# 🛠 How to Contribute to the AI Trip Planner Repo

As a **collaborator** in this private repository, follow the steps below to safely make changes and contribute code.

---

## 1️⃣ Clone the Repository

If you haven’t cloned the repository yet:

```bash
git clone https://github.com/<owner>/<repo>.git
cd <repo>
```

This creates a local copy on your machine.

---

## 2️⃣ Create a Feature Branch

Always branch off the `develop` branch:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/<your-feature-name>
```

**Example:**

```bash
git checkout -b feature/chat-ui
```

> **Branch naming convention:** `feature/<task>` or `bugfix/<issue>`.

---

## 3️⃣ Make Changes Locally

* Edit files, add features, or fix bugs.
* Keep commits **small, logical, and descriptive**.
* Follow the **commit message guidelines**:

```
<type>(scope): short description
```

**Example:**

```bash
git add .
git commit -m "feat(chat): add real-time messaging feature"
```

---

## 4️⃣ Push Your Branch to GitHub

```bash
git push origin feature/<your-feature-name>
```

This creates a **remote branch** for your feature.

---

## 5️⃣ Open a Pull Request (PR)

1. Go to **GitHub → Pull Requests → New Pull Request**
2. **Base branch:** `develop`
3. **Compare branch:** your feature branch
4. Add a **clear title & description**
5. Link to related issues (`Closes #<issue-number>`)
6. Submit PR for review

---

## 6️⃣ Code Review & Merge

* **1 or 2 team members** review your code
* Make requested changes via commits in the same branch
* After approval, merge using **Squash & Merge** or **Rebase & Merge**

> ⚠️ Do not push directly to `develop` or `main` unless explicitly allowed.

---

## 7️⃣ Keep Your Branch Updated

If `develop` has new commits:

```bash
git checkout develop
git pull origin develop
git checkout feature/<your-feature-name>
git merge develop
```

Resolve conflicts if any, then push again.

---

## 8️⃣ Delete Branch After Merge

Once your feature is merged:

```bash
git branch -d feature/<your-feature-name>         # delete local branch
git push origin --delete feature/<your-feature-name>  # delete remote branch
```

---

## ✅ Summary Workflow

```
develop ← feature/<task> → PR → code review → merge → develop
main ← release from develop
```

---

> Following this workflow ensures that the repository remains **organized, stable, and easy for collaboration**.
