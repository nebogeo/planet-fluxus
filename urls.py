from django.conf.urls.defaults import patterns, include, url

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
    url(r'^', include('livecode.urls')),
    url(r'^sketch/', include('livecode.urls')),
    url(r'^admin/', include(admin.site.urls)),
)
