from django.contrib import admin
from .models import Category, Question, Option, TestAttempt

class OptionInline(admin.TabularInline):
    model = Option
    extra = 4

class QuestionAdmin(admin.ModelAdmin):
    inlines = [OptionInline]
    list_filter = ('category', 'difficulty')
    search_fields = ('text',)

admin.site.register(Category)
admin.site.register(Question, QuestionAdmin)
admin.site.register(TestAttempt)
