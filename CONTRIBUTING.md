# Contributing to Mongez

Thank you for taking the time to contribute. Please read this guide before opening issues or submitting pull requests.

---

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/Mongez.git
   cd Mongez
   ```
3. Follow the setup steps in [README.md](README.md) to get the backend and mobile app running locally.

---

## Branching

Always branch off `main`:

```bash
git checkout main
git pull origin main
git checkout -b feat/your-feature-name
```

Branch naming conventions:

| Prefix | Use for |
|---|---|
| `feat/` | New feature |
| `fix/` | Bug fix |
| `refactor/` | Code restructure, no new feature |
| `docs/` | Documentation only |
| `chore/` | Build, config, tooling changes |

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short description
```

| Type | When to use |
|---|---|
| `feat` | Adding new functionality |
| `fix` | Fixing a bug |
| `refactor` | Restructuring without changing behaviour |
| `docs` | README, comments, documentation |
| `chore` | Config, dependencies, tooling |
| `test` | Adding or fixing tests |
| `ci` | GitHub Actions, CI pipeline |

**Examples:**

```
feat(orders): add order cancellation endpoint
fix(mobile/auth): handle 401 on token refresh failure
docs(readme): add Android emulator setup instructions
chore(docker): reduce image size with multi-stage build
```

---

## Backend (Django)

### Code style
- Follow PEP 8
- Use Django REST Framework conventions (ModelSerializer, APIView / ViewSet)
- Keep views thin — business logic belongs in models or services

### Adding a new app

```bash
# Create the app inside core/apps/
docker compose exec web python manage.py startapp <name> core/apps/<name>
```

Register it in `core/settings.py` under `INSTALLED_APPS`:
```python
'apps.<name>',
```

### Migrations

Always create and include migrations with your changes:

```bash
docker compose exec web python manage.py makemigrations
docker compose exec web python manage.py migrate
```

Never edit existing migration files — create new ones instead.

### Running checks locally

```bash
docker compose exec web python manage.py check
docker compose exec web python manage.py test
```

---

## Mobile (Flutter)

### Code style
- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` — zero warnings before submitting
- Each feature lives in `lib/features/<feature_name>/`

### State management
- Use BLoC / Cubit for all state that crosses widget boundaries
- Keep UI widgets stateless where possible
- Place cubits under `lib/core/bloc/` if shared, or inside the feature folder if local

### Adding a new screen

1. Create the screen under `lib/features/<feature>/screens/`
2. If it needs data from the API, add a service method in `lib/core/services/`
3. Add a cubit + state if needed in `lib/core/bloc/<feature>/`
4. Wire it into the relevant navigation path

### Before submitting

```bash
flutter analyze        # must show 0 issues
flutter test           # all tests must pass
flutter build linux    # verify it compiles
```

---

## Pull Requests

1. Make sure your branch is up to date with `main`:
   ```bash
   git fetch origin
   git rebase origin/main
   ```
2. Open a pull request against `main`
3. Fill in the PR description:
   - What does this change do?
   - How was it tested?
   - Any screenshots for UI changes?
4. A reviewer will be assigned — address all comments before merge

### PR checklist

- [ ] Code follows the style guidelines above
- [ ] `flutter analyze` returns zero issues (mobile changes)
- [ ] `python manage.py check` passes (backend changes)
- [ ] Migrations are included (if models changed)
- [ ] Existing tests still pass
- [ ] New behaviour is covered by tests where appropriate

---

## Reporting Bugs

Open an issue and include:

- Steps to reproduce
- Expected behaviour
- Actual behaviour
- Environment (OS, Flutter version, Docker version)
- Relevant logs or screenshots

---

## Questions

Open a GitHub Discussion or reach out via the repository's issue tracker.
