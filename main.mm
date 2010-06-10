#import <iostream>
#import <ApplicationServices/ApplicationServices.h>
#import "Image.h"

using namespace std;

int main (int argc, const char * argv[]) {

	/**
	cout << "Called with args:" << endl;
	for (int i(0); i < argc; ++i) {
		cout << "(" << i << ") " << argv[i] << endl;
	}
	/**/
	
	if (argc != 2) {
		cout << "Usage:" << endl;
		cout << "\t" << argv[0] << " \"filename\"" << endl;
	}
	
	Image oImg(argv[1]);

    return 0;
}
