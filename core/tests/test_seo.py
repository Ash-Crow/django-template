from datetime import UTC, datetime

from django.test import TestCase, override_settings


class SeoFilesTests(TestCase):
    def test_sitemap(self):
        response = self.client.get("/sitemap.xml")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "application/xml")
        self.assertContains(response, "<urlset")

    def test_robots_txt(self):
        response = self.client.get("/robots.txt")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response["Content-Type"].startswith("text/plain"))
        self.assertContains(response, "Sitemap: http://testserver/sitemap.xml")

    @override_settings(CONTACT_EMAIL="security@example.com")
    def test_security_txt(self):
        response = self.client.get("/.well-known/security.txt", secure=True)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response["Content-Type"].startswith("text/plain"))
        self.assertContains(response, "Contact: mailto:security@example.com")
        self.assertContains(
            response, "Canonical: https://testserver/.well-known/security.txt"
        )
        expires_line = next(
            line
            for line in response.content.decode().splitlines()
            if line.startswith("Expires: ")
        )
        expires = datetime.strptime(
            expires_line.removeprefix("Expires: "), "%Y-%m-%dT%H:%M:%SZ"
        ).replace(tzinfo=UTC)
        self.assertGreater(expires, datetime.now(UTC))

    @override_settings(CONTACT_EMAIL="o'brien@example.com")
    def test_security_txt_contact_not_html_escaped(self):
        response = self.client.get("/.well-known/security.txt", secure=True)
        self.assertContains(response, "Contact: mailto:o'brien@example.com")
        self.assertNotContains(response, "&#x27;")

    @override_settings(CONTACT_EMAIL="a?b@example.com")
    def test_security_txt_contact_uri_encoded(self):
        response = self.client.get("/.well-known/security.txt", secure=True)
        self.assertContains(response, "Contact: mailto:a%3Fb@example.com")

    @override_settings(CONTACT_EMAIL='"not@me;"@example.org')
    def test_security_txt_contact_quoted_local_part(self):
        response = self.client.get("/.well-known/security.txt", secure=True)
        self.assertContains(response, "Contact: mailto:%22not%40me%3B%22@example.org")

    @override_settings(CONTACT_EMAIL="")
    def test_security_txt_without_contact(self):
        response = self.client.get("/.well-known/security.txt")
        self.assertEqual(response.status_code, 404)
