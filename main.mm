#import "Image.h"

#import "Dot3Extend.h"

namespace po = boost::program_options;


int main (int argc, char * argv[]) {
	po::options_description desc("Allowed options");
	po::positional_options_description p;
	p.add("input", -1);
	
	desc.add_options()
	("help", "produce help message")
	("range", po::value<int>()->default_value(500), "how many pixels to extend the borders by")
	("threshold", po::value<int>()->default_value(250), "alpha threshold to determine visible boundary")
	("output,o", po::value<string>(), "output file")
	("input,i", po::value< vector<string> >(), "input file");	
	
	po::variables_map vm;
	po::store(po::command_line_parser(argc, argv).options(desc).positional(p).run(), vm);
	po::notify(vm);
	
	
	bool bError(false);
	if (vm.count("help")) {
		bError = true;
	}
	
	vector<string> aInFiles;
	if (!vm.count("input")) {
		cout << "Error: No input file specified." << endl;
		bError = true;
	} else {
		aInFiles = vm["input"].as< vector<string> >();
	}
	
	if (aInFiles.size() > 1) {
		cout << "Error: Too many input files specified; one at a time, please." << endl;
		bError = true;
	}
	
	if (!vm.count("output")) {
		cout << "Error: No output file specified." << endl;
		bError = true;
	}
	
	int range = vm["range"].as<int>();
	if (range < 1) {
		cout << "Error: Range must be 1 or greater." << endl;
		bError = true;
	}
	
	int threshold = vm["threshold"].as<int>();
	if (threshold < 1 || threshold > 255) {
		cout << "Error: Threshold must be between 1 and 255, inclusive." << endl;
		bError = true;
	}
	
	if (bError) {
		cout << endl << "Usage: " << argv[0] << "<input file> -o <output file>" << endl;
		cout << desc << endl;
		return 1;
	}
	

	string strInFile = aInFiles.at(0);
	string strOutFile = vm["output"].as<string>();
	
	Dot3Extend oExtender(range, threshold);
	
	try {
		Image oImg(strInFile);
		oExtender.Process(oImg).Save(strOutFile);
	} catch (ImageOpenFailure& oEx) {
		cout << "Error opening file \"" << strInFile << "\" - exiting." << endl;
		return 1;
	} catch (ImageSaveFailure& oEx) {
		cout << "Error saving file \"" << strOutFile << "\" - exiting." << endl;
		return 1;
	}

    return 0;
}
