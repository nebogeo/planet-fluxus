from django.db import models
from django.core.urlresolvers import reverse

class Sketch(models.Model):
    code = models.TextField()

    def __unicode__(self):
        return self.code

    def get_absolute_url(self):
        return reverse('sketch_update', kwargs={'pk': self.pk})
