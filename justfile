set dotenv-load
set shell := ["bash", "-uc"]

## Variables initialized from env
host_url := env("HOST_URL", "django.localhost")
host_port := env("HOST_PORT", "8000")
# Exported so the Docker web container runs as the host user (see compose.yaml)
export HOST_UID := env("HOST_UID", `id -u`)
export HOST_GID := env("HOST_GID", `id -g`)

## Recipes

[private]
default:
    @just --list

# Pass a django command
[group('Django')]
[positional-arguments]
django +command:
    uv run python manage.py "$@"

# Collect static files
[group('Django')]
collectstatic:
    just django collectstatic --noinput

# Create a superuser
[group('Django')]
createsuperuser:
    just django createsuperuser

alias mm:= makemigrations
# Create missing migrations
[group('Django')]
makemigrations app="":
    just django makemigrations {{app}}

alias mi := migrate
# Run existing migrations
[group('Django')]
migrate app="" version="":
    just django migrate {{app}} {{version}}

# Create and run migrations
[group('Django')]
mmi:
    just makemigrations
    just migrate

alias run := runserver
# Run the development server
[group('Django')]
runserver host_url=host_url host_port=host_port:
    just django runserver {{host_url}}:{{host_port}}

# Open a Django shell
[group('Django')]
shell:
    just django shell

# Build and start the Docker dev stack
[group('Docker')]
docker-up:
    docker compose up --build -d --wait
    @echo "Docker development server ready at http://{{host_url}}:{{host_port}}"

# Stop the Docker dev stack
[group('Docker')]
docker-down:
    docker compose down

# Follow the logs of a Docker service
[group('Docker')]
docker-logs service="web":
    docker compose logs -f {{service}}

alias ddj := docker-django
# Pass a django command inside the web container
[group('Docker')]
[positional-arguments]
docker-django +command:
    docker compose exec web python manage.py "$@"

# Open a bash shell inside the web container
[group('Docker')]
docker-shell:
    docker compose exec web bash

# Open a psql shell on the Docker database
[group('Docker')]
docker-dbshell:
    docker compose exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'

# Compile internationalization messages
[group('Internationalization')]
compilemessages:
    uv run python manage.py compilemessages --ignore=.venv

# Update internationalization strings
[group('Internationalization')]
makemessages:
    uv run python manage.py makemessages -l fr --no-location --ignore=manage.py

# Check test coverage
[group('Tests')]
coverage app="":
    uv run coverage run --source='.' manage.py test {{app}}
    uv run coverage html
    firefox htmlcov/index.html

# Run the unit tests
[group('Tests')]
test app="":
    just django test {{app}}

# Run the Django system check framework
[group('Code audit')]
check +apps="":
    just django check {{apps}}

# Run all git pre-commit hooks on every file
[group('Code audit')]
quality:
    uv run prek run --all-files

# Check that all imported packages are declared as dependencies (and vice versa)
[group('Code audit')]
deps-check:
    uv run deptry .

# Check dependency licenses for disallowed (e.g. GPL) licenses
[group('Code audit')]
licenses-check:
    uv run pip-licenses

# Generate a secret key
[group('Utils')]
generate_secret_key:
    uv run python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# Upgrade versions of dependencies
[group('Utils')]
upgrade:
    uv lock --upgrade
    uv run prek update --cooldown-days 7
