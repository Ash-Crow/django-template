# Django template

Django template, allowing to create a new site based on my favourite Django initial configuration, using the [twelve-factor methodology](https://en.wikipedia.org/wiki/Twelve-Factor_App_methodology).

A few details:

- The project is always called `config`. This helps locating the settings file when navigating between various Django websites, see [this article](https://dev.to/alansomathew/django-project-structure-best-practices-a-production-ready-guide-3io3) for the reasoning ;
- Dependencies are managed through [uv](https://docs.astral.sh/uv/) ;
- Commands are managed through [just](https://just.systems/man/en/).
- Config settings are defined through environment variables.
