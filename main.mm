#import "Image.h"

#import "Dot3Extend.h"

int main (int argc, const char * argv[]) {
	
	if (argc != 2) {
		cout << "Usage:" << endl;
		cout << "\t" << argv[0] << " \"filename\"" << endl;
		return 1;
	}
	
	cout << "Processing file: \"" << argv[1] << "\"" << endl;
	Image oImg(argv[1]);
	
	Dot3Extend oExtender(500, 250);
	oExtender.Process(oImg);


    return 0;
}
