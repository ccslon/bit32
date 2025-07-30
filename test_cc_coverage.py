# -*- coding: utf-8 -*-
"""
Created on Fri Sep  8 14:37:22 2023

@author: ccslon
"""

import os
import coverage
import unittest
if __name__ == '__main__':    
    cov = coverage.Coverage()
    cov.start()
    cov.exclude(r'\.error')
    
    import testcc
    unittest.main(module=testcc)
    
    cov.stop()
    cov.save()
    cov.html_report(directory=os.sep.join([os.getcwd(), 'coverage']))