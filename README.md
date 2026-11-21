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
- [just](https://just.systems/man/en/) **1.29.0 or later** (needed for the
`[positional-arguments]` recipe attribute used in the `justfile`)
- [GNU gettext](https://www.gnu.org/software/gettext/) (provides `msgfmt` and `xgettext`, needed by `just makemessages` and `just compilemessages`): `sudo apt install gettext`

After cloning, install the dependencies and the git hooks:

```sh
uv sync
uv run prek install
```

## Local development

To run a development instance directly on your machine, copy `.env.example` to `.env`. In that file, set `DEBUG=True` and fill `SECRET_KEY` with the output of `just generate_secret_key`. If `DATABASE_URL` is not set, the site uses a local SQLite database (`db.sqlite3`), so no database server is needed. Then apply the migrations with `just migrate`, create an admin account with `just createsuperuser`, and start the development server with `just run`. The site is then available on <http://django.localhost:8000> (set by `HOST_URL` and `HOST_PORT`), with the Django debug toolbar enabled.

```sh
[ -f .env ] || cp .env.example .env  # then set DEBUG=True
just generate_secret_key
# Copy the generated SECRET_KEY to the .env file, bound by single quotes.
just migrate
just createsuperuser
just run
```

## Docker (development)

A `compose.yaml` allows to run the site through Docker with a PostgreSQL database.

The project directory is bind-mounted, so the development server reloads on code changes. Requires [Docker](https://docs.docker.com/get-docker/) with Compose **2.24 or later**.

```sh
[ -f .env ] || cp .env.example .env  # optional: compose provides dev defaults; if copied, set DEBUG=True
just docker-up                       # build and start; returns once migrations are applied and the server is up
just docker-django createsuperuser
```

The site is then available on <http://django.localhost:8000> (port set by `HOST_PORT`).

- `just docker-logs`, `just docker-shell`, `just docker-dbshell` follow the logs, open a shell in the web container, or open `psql`.
- `just docker-django <command>` (alias `ddj`) runs any `manage.py` command in the container.
- Change dependencies with `uv add` / `uv remove` so `uv.lock` stays in sync (after editing `pyproject.toml` by hand, run `uv lock`), then run `just docker-up` again to rebuild the image. The build uses `uv sync --locked` and fails if the lockfile is out of date.
- Database data persists in the `pgdata` volume; `docker compose down -v` resets it.
- Inside the container (`IN_DOCKER`, set by the `Dockerfile`), the debug toolbar also accepts requests from the Docker network gateway. Native runs show it to `INTERNAL_IPS` (127.0.0.1) only.
- The web container runs with your UID/GID (set by `just`, or `HOST_UID`/`HOST_GID` in `.env` when using `docker compose` directly), so files it creates stay editable.

## Dependency cooldown

To reduce exposure to supply-chain attacks, package versions published less than 7 days ago are ignored:

- uv: `exclude-newer = "7 days"` in the `[tool.uv]` section of `pyproject.toml`. This applies to every resolution (`uv lock`, `uv add`, `just upgrade`…).
- prek: `just upgrade` runs `prek update --cooldown-days 7`, so hook revisions are only bumped to tags at least 7 days old.

If you urgently need a newer version (e.g. a security fix), override the cutoff for that package only, for instance `uv lock --upgrade-package django --exclude-newer-package django=2026-10-07`.
