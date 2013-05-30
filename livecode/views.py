# Create your views here.

from django.http import HttpResponse, HttpResponseRedirect
from django.template import Context, loader
from livecode.models import Sketch
from django.shortcuts import render_to_response
from django.template import RequestContext
from django.views.generic.edit import UpdateView

def index(request):
    sketches = Sketch.objects.order_by('?')
    return render_to_response("livecode/index.html",
                              {'sketches': sketches},
                              context_instance=RequestContext(request))

#def sketch(request,sketch_id):
#    sketch = Sketch.objects.get(pk=sketch_id)
#    return render_to_response("livecode/sketch.html",
#                              {'sketch': sketch},
#                              context_instance=RequestContext(request))

def new_sketch(request):
    s = Sketch(code="")
    r = s.save()
    return HttpResponseRedirect("/sketch/"+str(s.pk));

def fork_sketch(request,pk):
    sketch = Sketch.objects.get(pk=pk)
    s = Sketch(code=sketch.code)
    r = s.save()
    return HttpResponseRedirect("/sketch/"+str(s.pk));



class SketchUpdate(UpdateView):
    model = Sketch
