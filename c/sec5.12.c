
void foo() {
	char (*a[]);
	char *b[];
	char (*c)[];
	char (*e[])();
}

int main() {
	int *p, i;
	char v();
	char* p();
    char **argv; 			//ptr(ptr(char))
	int (*daytab1)[3]; 		//ptr(array(int))
	int *daytab2[3]; 		//array(ptr(int))
	void *comb();			//ptr(void)()
	void (*comp)(); 		//ptr(void())
	char (*pfa[3])();		//array(ptr(char()))
	char (*(*x())[3])(); 	//ptr(array(ptr(char())))()
	char (*(*y[3])())[5];	//array(ptr(ptr(array(char))()))
	//int i = (*daytab1)[2];
	//int i = *daytab2[2];
}