from django.urls import path
from . import views

urlpatterns = [
    path('store/', views.store_view, name='store'),
    path('buy/<int:item_id>/', views.buy_item, name='buy_item'),
    path('reward-wheel/', views.reward_wheel_view, name='reward_wheel'),
    path('process-spin/', views.process_spin, name='process_spin'),
]
