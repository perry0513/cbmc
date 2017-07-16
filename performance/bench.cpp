#include <fstream>
#include <iostream>
#include <string>

int main()
{
  for(unsigned i=10; i<300; i+=1)
  {
    std::string cmd="cbmc array_write1.c -D N="+std::to_string(i);
    cmd+=" | grep \"Runtime decision procedure\" > /tmp/t";
    system(cmd.c_str());
    std::ifstream in("/tmp/t");
    std::string s;
    std::getline(in, s);
    std::size_t p1=s.find(": ");
    std::size_t p2=s.rfind("s");
    if(p1!=std::string::npos && p2!=std::string::npos)
    {
      std::string time=s.substr(p1+2, p2-p1-2);
      std::cout << i << " " << time << "\n";
    }
  }
}
