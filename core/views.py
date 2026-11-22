from datetime import timedelta
from urllib.parse import quote

from django.conf import settings
from django.contrib.staticfiles.storage import staticfiles_storage
from django.http import Http404
from django.utils import timezone
from django.views.generic.base import RedirectView, TemplateView


class FaviconView(RedirectView):
    """
    Redirects /favicon.ico to the hashed static file. The URL is resolved on each
    request: resolving it when the URLconf is imported breaks every management
    command (including the `migrate` and `collectstatic` of a deployment) as soon
    as the staticfiles manifest is missing or stale.
    """

    def get_redirect_url(self, *args, **kwargs):
        return staticfiles_storage.url("favicon/favicon.ico")


class SecurityTxtView(TemplateView):
    """
    RFC 9116 security.txt file. The Expires field is computed on each request
    so that it never goes stale. Without CONTACT_EMAIL the file would be invalid
    (Contact is mandatory), so the view returns a 404 instead.
    """

    template_name = "security.txt"
    content_type = "text/plain"

    def get(self, request, *args, **kwargs):
        if not settings.CONTACT_EMAIL:
            raise Http404
        return super().get(request, *args, **kwargs)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        expires = timezone.now().replace(microsecond=0) + timedelta(days=180)
        # Percent-encode for the mailto URI (RFC 6068), keeping allowed delimiters.
        context["contact_email"] = quote(settings.CONTACT_EMAIL, safe="!$'()*+,;:@")
        context["expires"] = expires.strftime("%Y-%m-%dT%H:%M:%SZ")
        return context
