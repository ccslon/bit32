# -*- coding: utf-8 -*-
"""
Created on Fri Sep  8 14:37:22 2023

@author: ccslon
"""
from unittest import TestCase, main, expectedFailure

from ccompiler.cpreprocessor import CPreProcessor
from ccompiler import cparser
from ccompiler.emitter import Emitter


class TestCompiler(TestCase):

    @classmethod
    def setUpClass(cls):
        cls.tests = []

    @classmethod
    def tearDownClass(cls):
        print(cls.tests)

    def generated_equals_expected(self, name):
        preproc = CPreProcessor()
        preproc.process(f'tests/{name}.c')
        root = cparser.parse(preproc.output())
        emitter = Emitter()
        root.generate(emitter)
        with open(f'tests/{name}.s') as file:
            expected = file.read()
        self.tests.append(name)
        self.assertEqual(str(emitter), expected)

    @expectedFailure
    def test_bad_const(self):
        preproc = CPreProcessor()
        preproc.process('tests/bad_const.c')
        emitter = Emitter()
        root = cparser.parse(preproc.stream())
        root.generate(emitter)

    def test_init(self):
        self.generated_equals_expected('init')

    def test_main(self):
        self.generated_equals_expected('main')

    def test_const(self):
        self.generated_equals_expected('const')

    def test_rconst(self):
        self.generated_equals_expected('rconst')

    def test_params(self):
        self.generated_equals_expected('params')

    def test_fact(self):
        self.generated_equals_expected('fact')

    def test_fib(self):
        self.generated_equals_expected('fib')

    def test_loop(self):
        self.generated_equals_expected('loops')

    def test_sum(self):
        self.generated_equals_expected('sum')

    def test_getset(self):
        self.generated_equals_expected('getset')

    def test_getset2(self):
        self.generated_equals_expected('getset2')

    def test_calls(self):
        self.generated_equals_expected('calls')

    def test_hello(self):
        self.generated_equals_expected('hello')

    def test_structs(self):
        self.generated_equals_expected('structs')

    def test_array(self):
        self.generated_equals_expected('arrays')

    def test_glob_struct(self):
        self.generated_equals_expected('globs')

    def test_goto(self):
        self.generated_equals_expected('goto')

    def test_return_struct(self):
        self.generated_equals_expected('returns')

    def test_pointers(self):
        self.generated_equals_expected('pointers')

    def test_defines(self):
        self.generated_equals_expected('defines')

    def test_includes(self):
        self.generated_equals_expected('includes')

    def test_enums(self):
        self.generated_equals_expected('enums')

    def test_unions(self):
        self.generated_equals_expected('unions')

    def test_func_ptrs(self):
        self.generated_equals_expected('function_ptrs')

    def test_neg_nums(self):
        self.generated_equals_expected('neg_numbers')

    def test_unsigned(self):
        self.generated_equals_expected('unsigned')

    def test_logic(self):
        self.generated_equals_expected('logic')

    def test_cstrings(self):
        self.generated_equals_expected('cstrings')

    def test_ifs(self):
        self.generated_equals_expected('ifs')

    def test_sizeof(self):
        self.generated_equals_expected('sizeof')

    def test_vardefns(self):
        self.generated_equals_expected('variadics')

    def test_ops(self):
        self.generated_equals_expected('ops')

    def test_floats(self):
        self.generated_equals_expected('floats')

    def test_eval(self):
        self.generated_equals_expected('eval')

    def test_commas(self):
        self.generated_equals_expected('commas')

    def test_macro(self):
        preproc = CPreProcessor()
        preproc.process('tests/macros.c')
        with open('tests/macros.i') as file:
            expected = file.read()
        self.assertEqual(str(preproc), expected)

    def test_macro_ifs(self):
        preproc = CPreProcessor()
        preproc.process('tests/macro_ifs.c')
        with open('tests/macro_ifs.i') as file:
            expected = file.read()
        self.assertEqual(str(preproc), expected)


if __name__ == '__main__':
    main()
