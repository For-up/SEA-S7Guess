#include <iostream>
#include <fstream>
#include <cassert>
#include <string>

using namespace std;

void readTxt(string file_rd,string file_wr)
{
	ifstream infile;
	infile.open(file_rd.data());   //���ļ����������ļ��������� 
	assert(infile.is_open());   //��ʧ��,�����������Ϣ,����ֹ�������� 

	string str;
	int i = 0;

	getline(infile, str);
	cout << str << endl;
	getline(infile, str);
	cout << str << endl;

	ofstream outfile;
	outfile.open(file_wr.data());
	for(i=0;i<88;i++){
		getline(infile, str);
		if(i%5==4)outfile << "rom["<<i<<"]<=24'h"<<str[0] << str[1] << str[2] << str[3] << str[4] << str[5] <<";"<< endl;
		else outfile << "rom[" << i << "]<=24'h" << str[0] << str[1] << str[2] << str[3] << str[4] << str[5] << ";";
	}
	infile.close();             //�ر��ļ������� 
	outfile.close();
}

void main() {
	readTxt("./OV5647.coe","./OV5647.txt");
}