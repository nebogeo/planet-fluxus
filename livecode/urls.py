from django.conf.urls.defaults import patterns, include, url

from livecode import views

urlpatterns = patterns('',
    url(r'^$', views.index, name='index'),
#    url(r'^sketch/(?P<sketch_id>\d+)', forms.modify, name='sketch'),
    url(r'^sketch/(?P<pk>\d+)/$', views.SketchUpdate.as_view(), name='sketch_update'),
    url(r'^fork_sketch/(?P<pk>\d+)/$', views.fork_sketch, name='fork_sketch'),
)
