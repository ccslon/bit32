char gloo();

void func() {
	char *p, c; 	//4, 1
	char a[5];		//5
	char *pa[5];	//20
	char (*pc)[5];	//4
	char foo();		//0
	char* bar();	//0
	char (*baz)();	//4
	c = a[3];
	a[4] = c;
	
	p = pa[3];
	pa[4] = p;
	
	c = (*pc)[3];
	(*pc)[4] = c;
	
	c = foo();
	c = gloo();
	p = bar();
	
	c = (*baz)();
	char (*fs[5])();
	*p = (*fs[0])();
}

int main() {
    char **argv; 			//ptr(ptr(char))
	int (*daytab1)[3]; 		//ptr(array(int))
	int *daytab2[3]; 		//array(ptr(int))
	void *comb();			//ptr(void)()
	void (*comp)(); 		//ptr(void())
	char (*pfa[3])();		//array(ptr(char()))
	char (*(*x())[3])(); 	//ptr(array(ptr(char())))()
	char (*(*y[3])())[5];	//array(ptr(ptr(array(char))()))
}