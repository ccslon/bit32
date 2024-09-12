
void foo() {
	char i[5];
	char *j;
	char *k[5];
	char (*a[3]);
	char *b[3];
	char (*c)[3];
	char (*e[3])();
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