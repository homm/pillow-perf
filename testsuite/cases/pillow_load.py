from io import BytesIO

from .base import rpartial, root, BaseLoadCase, BaseSaveCase
from .pillow import Image


class LoadCase(BaseLoadCase):
    def runner(self):
        im = Image.open(root('resources', self.filename))
        im.load()


class SaveCase(BaseSaveCase):
    def create_test_data(self):
        im = Image.open(root('resources', self.filename))
        im.load()
        return [im]

    def runner(self, im):
        im.save(BytesIO(), format=self.filetype, quality=85)


cases = [
    rpartial(LoadCase, 'JPEG', 'pineapple.jpeg'),
    rpartial(SaveCase, 'JPEG', 'pineapple.jpeg'),
]
