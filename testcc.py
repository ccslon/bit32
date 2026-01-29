# -*- coding: utf-8 -*-
"""
Created on Fri Sep  8 14:37:22 2023

@author: ccslon
"""
from unittest import TestCase, main, expectedFailure

from ccompiler import cpreprocessor2, cparser


class TestCompiler(TestCase):

    @classmethod
    def setUpClass(cls):
        cls.tests = []
        cls.preproc = cpreprocessor2.CPreProcessor()

    @classmethod
    def tearDownClass(cls):
        print(cls.tests)

    def code_eq_asm(self, name):
        self.preproc.process(f'tests/{name}.c')
        ast = cparser.parse(self.preproc.output())
        out = ast.generate()
        with open(f'tests/{name}.s') as file:
            asm = file.read()
        self.tests.append(name)
        self.assertEqual(out, asm)

    @expectedFailure
    def test_bad_const(self):
        self.preproc.process('tests/bad_const.c')
        ast = cparser.parse(self.preproc.stream())
        ast.generate()

    def test_init(self):
        self.code_eq_asm('init')

    def test_main(self):
        self.code_eq_asm('main')

    def test_const(self):
        self.code_eq_asm('const')

    def test_rconst(self):
        self.code_eq_asm('rconst')

    def test_params(self):
        self.code_eq_asm('params')

    def test_fact(self):
        self.code_eq_asm('fact')

    def test_fib(self):
        self.code_eq_asm('fib')

    def test_loop(self):
        self.code_eq_asm('loops')

    def test_sum(self):
        self.code_eq_asm('sum')

    def test_getset(self):
        self.code_eq_asm('getset')

    def test_getset2(self):
        self.code_eq_asm('getset2')

    def test_calls(self):
        self.code_eq_asm('calls')

    def test_hello(self):
        self.code_eq_asm('hello')

    def test_structs(self):
        self.code_eq_asm('structs')

    def test_array(self):
        self.code_eq_asm('arrays')

    def test_glob_struct(self):
        self.code_eq_asm('globs')

    def test_goto(self):
        self.code_eq_asm('goto')

    def test_return_struct(self):
        self.code_eq_asm('returns')

    def test_pointers(self):
        self.code_eq_asm('pointers')

    def test_defines(self):
        self.code_eq_asm('defines')

    def test_includes(self):
        self.code_eq_asm('includes')

    def test_enums(self):
        self.code_eq_asm('enums')

    def test_unions(self):
        self.code_eq_asm('unions')

    def test_func_ptrs(self):
        self.code_eq_asm('func_ptrs')

    def test_neg_nums(self):
        self.code_eq_asm('neg_nums')

    def test_unsigned(self):
        self.code_eq_asm('unsigned')

    def test_logic(self):
        self.code_eq_asm('logic')

    def test_cstrings(self):
        self.code_eq_asm('cstrings')

    def test_ifs(self):
        self.code_eq_asm('ifs')

    def test_sizeof(self):
        self.code_eq_asm('sizeof')

    def test_vardefns(self):
        self.code_eq_asm('vardefns')

    def test_ops(self):
        self.code_eq_asm('ops')

    def test_floats(self):
        self.code_eq_asm('floats')

    def test_eval(self):
        self.code_eq_asm('eval')

    def test_macro(self):
        self.preproc.process('tests/macros.c')
        with open('tests/macros.i') as file:
            expected = file.read()
        self.assertEqual(str(self.preproc), expected)

    def test_macro_ifs(self):
        self.preproc.process('tests/macro_ifs.c')
        with open('tests/macro_ifs.i') as file:
            expected = file.read()
        self.assertEqual(str(self.preproc), expected)


if __name__ == '__main__':
    main()
