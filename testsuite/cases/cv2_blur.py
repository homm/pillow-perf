from math import ceil

from .base import rpartial
from .cv2 import cv2, Cv2TestCase


class BlurCase(Cv2TestCase):
    def handle_args(self, radius):
        self.radius = radius

    def runner(self, im):
        window = 1 + int(ceil(self.radius * 2.5)) * 2
        cv2.GaussianBlur(im, (window, window), self.radius)

    def readable_args(self):
        return ["{}px".format(self.radius)]


cases = [
    rpartial(BlurCase, radius)
    for radius in [
        1,
        10,
        30,
    ]
]
