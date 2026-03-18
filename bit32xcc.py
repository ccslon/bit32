# -*- coding: utf-8 -*-
"""
Created on Fri Mar 13 23:04:03 2026

@author: Colin
"""

if __name__ == '__main__':
    import argparse
    from ccompiler import comp
    parser = argparse.ArgumentParser()
    parser.add_argument('files', nargs='+')
    parser.add_argument('-o', '--output', default='out')
    parser.add_argument('-S', '--assemble', action='store_true')
    parser.add_argument('-E', '--preprocess', action='store_true')
    args = parser.parse_args()
    comp(args.files, args.output, args.preprocess, args.assemble, True)
