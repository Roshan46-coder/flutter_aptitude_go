from django.urls import path
from . import views

urlpatterns = [
    path('arena/', views.arena_home, name='arena_home'),
    path('arena/practice/', views.practice_arena, name='practice_arena'),
    path('arena/practice/pdf/<str:filename>', views.serve_watermarked_pdf, name='serve_watermarked_pdf'),
    path('practice/', views.practice_dashboard, name='practice_dashboard'),
    path('practice/<slug:category_slug>/', views.start_test, name='start_test'),
    path('submit/', views.submit_test, name='submit_test'),
]
