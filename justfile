set dotenv-load
set shell := ["bash", "-uc"]

## Variables initialized from env
host_url := env("HOST_URL", "localhost")
local_port := env("LOCAL_PORT", "8000")

## Recipes

# List the available recipes
default:
    @just --list

# Pass a django command
[group('Django')]
django +command:
    uv run python manage.py {{command}}

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
runserver host_url=host_url local_port=local_port:
    just django runserver {{host_url}}:{{local_port}}

# Open a Django shell
[group('Django')]
shell:
    just django shell

# Check test coverage
[group('Tests')]
coverage app="":
    uv run coverage run --source='.' manage.py test {{app}}
    uv run coverage html
    firefox htmlcov/index.html

# Run the unit tests
[group('Tests')]
test app="":
    uv run python manage.py test {{app}}

# Make quality checks on the whole project
[group('Utils')]
quality:
    uv run pre-commit run --all-files

# Generate a secret key
[group('Utils')]
generate_secret_key:
    uv_run python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'

# Upgrate dependencies
[group('Utils')]
upgrade:
    uv lock --upgrade
    uv run pre-commit autoupdate
