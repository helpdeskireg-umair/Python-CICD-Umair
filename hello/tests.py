from django.test import SimpleTestCase
from django.urls import reverse


class HomePageTests(SimpleTestCase):
    def test_home_page_returns_200(self):
        response = self.client.get(reverse("home"))
        self.assertEqual(response.status_code, 200)

    def test_home_page_contains_greeting(self):
        response = self.client.get(reverse("home"))
        self.assertContains(response, "Hello, Zachi Zoo!")
