from django.db import models
from django.core.urlresolvers import reverse

class Sketch(models.Model):
    name = models.CharField(max_length=256)
    code = models.TextField()
    image = models.ImageField(upload_to="images")

    def __unicode__(self):
        return self.name

    def get_absolute_url(self):
        return reverse('sketch_update', kwargs={'pk': self.pk})
