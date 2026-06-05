from django.contrib import admin
from apps.multiplayer.models import Match, MatchPlayer

class MatchPlayerInline(admin.TabularInline):
    model = MatchPlayer
    extra = 0

@admin.register(Match)
class MatchAdmin(admin.ModelAdmin):
    list_display = ('id', 'topic', 'status', 'start_time', 'end_time', 'winner')
    list_filter = ('status', 'topic')
    inlines = [MatchPlayerInline]

@admin.register(MatchPlayer)
class MatchPlayerAdmin(admin.ModelAdmin):
    list_display = ('id', 'match', 'user', 'score', 'status', 'is_winner')
    list_filter = ('status', 'is_winner')
