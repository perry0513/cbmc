int main()
{
  int *p;
  int z;
  z=*p;
  *p=123;
  
  __CPROVER_assert(z==0, "hello");
}
