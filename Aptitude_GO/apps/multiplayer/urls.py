from django.urls import path
from . import views

app_name = 'multiplayer'

urlpatterns = [
    path('', views.topic_select, name='topic_select'),
    path('matchmaking/<str:topic>/', views.matchmaking, name='matchmaking'),
    path('game/<int:match_id>/', views.game_room, name='game_room'),
    path('results/<int:match_id>/', views.results, name='results'),
]
