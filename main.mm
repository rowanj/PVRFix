#import "Image.h"

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
		return 1;
	}
	
	cout << "Processing file: \"" << argv[1] << "\"" << endl;
	Image oImg(argv[1]);

    return 0;
}
