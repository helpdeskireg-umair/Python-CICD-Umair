from django.http import HttpResponse


def home(request):
    return HttpResponse("<h1>Hello, Umair Rao!</h1><p>This app was deployed with a CI/CD pipeline.</p>")
