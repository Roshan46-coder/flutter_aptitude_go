from django.urls import path
from . import views

urlpatterns = [
    # Recruiter URLs
    path('dashboard/', views.recruiter_dashboard, name='recruiter_events'),
    path('create/', views.create_event, name='create_event'),
    path('<int:event_id>/questions/', views.add_questions, name='add_questions'),
    path('<int:event_id>/cancel/', views.cancel_event, name='cancel_event'),
    path('<int:event_id>/results/', views.event_results, name='event_results'),
    
    # Student URLs
    path('', views.event_list, name='event_list'),
    path('<int:event_id>/', views.event_detail, name='event_detail'),
    path('<int:event_id>/take/', views.take_event, name='take_event'),
]
