from django.urls import path
from . import views

urlpatterns = [
    # Auth & Onboarding
    path('login/', views.login_api, name='api_login'),
    path('register/', views.register_api, name='api_register'),
    path('logout/', views.logout_api, name='api_logout'),
    path('auth-status/', views.auth_status_api, name='api_auth_status'),
    path('resend-verification/', views.resend_verification_api, name='api_resend_verification'),

    # Profile & settings
    path('profile/', views.profile_api, name='api_profile'),
    path('profile/edit/', views.edit_profile_api, name='api_edit_profile'),
    path('profile/upload-certificate/', views.upload_certificate_api, name='api_upload_certificate'),
    path('profile/delete-certificate/<int:certificate_id>/', views.delete_certificate_api, name='api_delete_certificate'),
    path('profile/delete-account/', views.delete_account_api, name='api_delete_account'),
    path('profile/<str:username>/', views.profile_api, name='api_user_profile'),

    # Practice Arena & solo test
    path('tests/practice/', views.practice_dashboard_api, name='api_practice_dashboard'),
    path('tests/practice/<slug:category_slug>/', views.start_test_api, name='api_start_test'),
    path('tests/submit/', views.submit_test_api, name='api_submit_test'),
    path('tests/attempt-history/', views.attempt_history_api, name='api_attempt_history'),
    path('tests/arena/practice/', views.practice_arena_pdfs_api, name='api_practice_arena_pdfs'),
    path('tests/arena/practice/pdf/<str:filename>', views.serve_pdf_api, name='api_serve_pdf'),

    # Gamification
    path('gamification/store/', views.store_items_api, name='api_store_items'),
    path('gamification/buy/<int:item_id>/', views.buy_item_api, name='api_buy_item'),
    path('gamification/reward-wheel/status/', views.spin_wheel_status_api, name='api_spin_wheel_status'),
    path('gamification/process-spin/', views.process_spin_api, name='api_process_spin'),

    # Events (Student & Recruiter)
    path('events/dashboard/', views.events_dashboard_api, name='api_events_dashboard'),
    path('events/create/', views.create_event_api, name='api_create_event'),
    path('events/<int:event_id>/', views.event_detail_api, name='api_event_detail'),
    path('events/<int:event_id>/register/', views.register_event_api, name='api_register_event'),
    path('events/<int:event_id>/submit/', views.submit_event_test_api, name='api_submit_event_test'),
    path('events/<int:event_id>/results/', views.event_results_api, name='api_event_results'),

    # Chat Inbox & messaging
    path('inbox/', views.inbox_api, name='api_inbox'),
    path('chat/<int:conversation_id>/', views.chat_detail_api, name='api_chat_detail'),
    path('chat/<int:conversation_id>/send/', views.send_message_api, name='api_send_message'),

    # Custom Admin stats & controls
    path('admin/stats/', views.admin_dashboard_stats_api, name='api_admin_stats'),
    path('admin/toggle-malpractice/', views.admin_toggle_malpractice_api, name='api_admin_toggle_malpractice'),
    path('admin/delete-user/<int:user_id>/', views.admin_delete_user_api, name='api_admin_delete_user'),
]
