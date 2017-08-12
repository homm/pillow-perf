# coding: utf-8

from __future__ import print_function, unicode_literals, absolute_import

import cv2

from .base import rpartial, root, BaseLoadCase, BaseSaveCase


class LoadCase(BaseLoadCase):
    def runner(self):
        cv2.imread(root('resources', self.filename),
                   flags=cv2.IMREAD_UNCHANGED)


class SaveCase(BaseSaveCase):
    def create_test_data(self):
        im = cv2.imread(root('resources', self.filename),
                        flags=cv2.IMREAD_UNCHANGED)
        return [im]

    def runner(self, im):
        cv2.imencode("." + self.filetype, im,
                     [int(cv2.IMWRITE_JPEG_QUALITY), 85])


cases = [
    rpartial(LoadCase, 'JPEG', 'pineapple.jpeg'),
    rpartial(SaveCase, 'JPEG', 'pineapple.jpeg'),
]
