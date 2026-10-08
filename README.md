# Django template

Django template, allowing to create a new site based on my favourite Django initial configuration, using the [twelve-factor methodology](https://en.wikipedia.org/wiki/Twelve-Factor_App_methodology).

A few details:

- The project is always called `config`. This helps locating the settings file when navigating between various Django websites, see [this article](https://dev.to/alansomathew/django-project-structure-best-practices-a-production-ready-guide-3io3) for the reasoning ;
- Dependencies are managed through [uv](https://docs.astral.sh/uv/) ;
- Commands are managed through [just](https://just.systems/man/en/).
- Git pre-commit hooks, managed through [prek](https://prek.j178.dev/), control various aspects of the quality of the code. In particular:
  - [black](https://pypi.org/project/black/) and [ruff](https://docs.astral.sh/ruff/) are used for linting Python code
  - [djLint](https://djlint.com/) is used for linting HTML code
  - [bandit](https://pypi.org/project/bandit/) is used to check for security issues
  - [deptry](https://deptry.com/) is used to check for dependency issues
- Config settings are defined through environment variables.

## Requirements

- [uv](https://docs.astral.sh/uv/) **0.9.17 or later** (needed for the relative `exclude-newer` value used for the cooldown below.)
- [just](https://just.systems/man/en/) **1.27.0 or later** (needed for the `[group()]` recipe attribute used in the `justfile`)

After cloning, install the dependencies and the git hooks:

```sh
uv sync
uv run prek install
```

## Dependency cooldown

To reduce exposure to supply-chain attacks, package versions published less than 7 days ago are ignored:

- uv: `exclude-newer = "7 days"` in the `[tool.uv]` section of `pyproject.toml`. This applies to every resolution (`uv lock`, `uv add`, `just upgrade`…).
- prek: `just upgrade` runs `prek update --cooldown-days 7`, so hook revisions are only bumped to tags at least 7 days old.

If you urgently need a newer version (e.g. a security fix), override the cutoff for that package only, for instance `uv lock --upgrade-package django --exclude-newer-package django=2026-10-07`.
