#include <iostream>
#include <iterator>
#include <string>
#include <vector>
#include <algorithm>
int main(int argc,char **argv){
    std::vector<char*> code1(argv,argv + argc);
    std::vector<std::string> code2;
    for(auto c: code1){
        std::string d = c;
        auto f = std::distance(code2.begin(), std::find(code2.begin(),code2.end(),d));
        if(f == argc){
            code2.push_back("0");
            code2.push_back(d);
        }else{
            code2.push_back(std::to_string(f + 1));
        }
    }
    std::cout << "int[] l={";
    for(auto d: code2)std::cout << d << ",";
    std::cout << "-1}";
    std::cout << "std::vector<int> m;int i = 0;int r(){auto n = l[i++];if(n == 0){auto o = l[i++];m.push_back(n);m.push_back(o);return 0;};m.push_back(n);return m[n - 1];};";
    std::cout << "int main(){while(1){*((int*)(*r()) + r()) = *((int*)(*r()) + r());__asm__(\"jmp %1\":r():));}}";
}