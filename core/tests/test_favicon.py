from django.contrib.staticfiles import finders
from django.test import TestCase


class FaviconTests(TestCase):
    def test_favicon_static_file_is_found(self):
        self.assertIsNotNone(finders.find("favicon/favicon.ico"))

    def test_favicon_redirects_to_static_file(self):
        response = self.client.get("/favicon.ico")
        self.assertRedirects(
            response,
            "/static/favicon/favicon.ico",
            status_code=302,
            fetch_redirect_response=False,
        )
