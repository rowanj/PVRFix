#import "Image.h"

#import "Dot3Extend.h"
#import "FileProperties.h"

#define VERBOSE(x) { if (verbose) { cout << x ; } }

namespace po = boost::program_options;
Dot3Extend* pDot3Extend = NULL;
int verbose;
bool bError = false;

void DoDot3Extend(const string& strInFile, const string& strOutFile) {
	FileProperties oInFileProps(strInFile);
	FileProperties oOutFileProps(strOutFile);
	if (!oInFileProps.Exists()) {
		cout << "Error: Input file \"" << strInFile << "\" does not exist.  Why?" << endl;
		bError = true;
		return;
	}
	
	if (oOutFileProps.Exists() && oInFileProps.OlderThan(oOutFileProps)) {
		VERBOSE(" -- Skipping extending of \"" << strInFile << "\" - source not modified since last processed." << endl;)
	} else {
			// Create the image object (or throw...)
		Image oImg(strInFile);
		
			// Process the file and write the output
		VERBOSE(" -- extending colours into transparent area...";)
		Image oExtended(pDot3Extend->Process(oImg));
		VERBOSE(" done." << endl;)
		
		VERBOSE(" -- saving colour-extended version \"" << strOutFile << "\"...";)
		oExtended.Save(strOutFile);
		VERBOSE(" done." << endl;)
	}
}

void DoPVRCompress(const string& strInFile, const string& strOutFile) {
	FileProperties oInFileProps(strInFile);
	FileProperties oOutFileProps(strOutFile);
	if (!oInFileProps.Exists()) {
		cout << "Error: Input file \"" << strInFile << "\" does not exist.  Why?" << endl;
		bError = true;
		return;
	}
	
	if (oOutFileProps.Exists() && oInFileProps.OlderThan(oOutFileProps)) {
		VERBOSE(" -- Skipping PVR compression of \"" << strInFile << "\" - source not modified since last compressed." << endl;)
	} else {
		VERBOSE(" -- compressing into PVR format; about to launch 'texturetool'" << endl;)
		string strCommand = "./texturetool -f PVR -e PVRTC -m -o \"";
		strCommand += strOutFile + "\" \"" + strInFile + "\"";
		int iError = system(strCommand.c_str());
		if (iError == 0) {						
			VERBOSE(" -- successfully compressed \"" << strOutFile << "\"." << endl;)
		} else {
			cout << "Error: System did not successfully run \"" << strCommand << "\"";
			bError = true;
			return;
		}
	}
}


int main (int argc, char * argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	try {
		po::options_description desc("Allowed options");
		po::positional_options_description p;
		p.add("input", -1);
		
		desc.add_options()
		("help", "produce help message")
		("range", po::value<int>()->default_value(500), "how many pixels to extend the borders by")
		("threshold", po::value<int>()->default_value(250), "alpha threshold to determine visible boundary")
		("input,i", po::value< vector<string> >(), "input file")
		("verbose,v", "show progress messages");
		
		
		po::variables_map vm;
		try {
			po::store(po::command_line_parser(argc, argv).options(desc).positional(p).run(), vm);
			po::notify(vm);
		} catch (boost::program_options::unknown_option& oEx) {
			cout << "Error: " << oEx.what() << endl;
			cout << desc << endl;
			return 1;
		}
		
		
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
			cout << endl << "Usage: " << argv[0] << " [options] <file> [<file>...]" << endl;
			cout << desc << endl;
			return 1;
		}
		
		verbose = vm.count("verbose");
		
		bError = false; // re-set the error flag..
		pDot3Extend = new Dot3Extend(range, threshold);
		for (vector<string>::const_iterator it(aInFiles.begin());
			 it != aInFiles.end(); ++it) {
				// Generate the output filename
			const string strInFile(*it);
			if (strInFile.length() < 5) {
				cerr << "Input file name \"" << strInFile << "\" is too short - not even long enough to end with \".png\" - skipping." << endl;
				bError = true;
				continue;
			}
			
			const string strExtension(strInFile.substr(strInFile.length() - 4));
			if (strExtension != ".png") {
				cerr << "Input file \"" << strInFile << "\" does not end with .png - skipping." << endl;
				bError = true;
				continue;
			}
			
			if (strInFile.length() > strlen("-extended.png") && strInFile.substr(strInFile.length() - strlen("-extended.png")) == "-extended.png") {
				VERBOSE("Skipping \"" << strInFile << "\", as is probably an output from a previous run." << endl);
				continue;
			}
			
			const string strBaseName = strInFile.substr(0, strInFile.length() - 4);
			
			const string strExtendedFile = strBaseName + "-extended.png";		
			const string strPVRFile = strBaseName + ".pvr";
			
			try {
				FileProperties oInFileProps(strInFile);
				if (!oInFileProps.Exists()) {
					cout << "Error: input file \"" << strInFile << "\" does not exist.  Probably." << endl;
					bError = true;
					continue;
				}
				
				cout << "Processing file \"" << strInFile << "\"" << endl;
					// Phase 1 - extend colours into transparencies to avoid blocking artifacts
				if (strBaseName.substr(strBaseName.length() - strlen(" Dot3")) == " Dot3") {
					DoDot3Extend(strInFile, strExtendedFile);
					DoPVRCompress(strExtendedFile, strPVRFile);
				} else {
					DoPVRCompress(strInFile, strPVRFile);
				}
			} catch (ImageOpenFailure& oEx) {
				cout << "Error: could not read image file \"" << strInFile << "\" - continuing with next file (if any)." << endl;
				bError = true;
				continue;
			} catch (ImageSaveFailure& oEx) {
				cout << "Error saving alpha-extend version of file \"" << strInFile << "\" - continuing with next file (if any)." << endl;
				bError = true;
				continue;
			}
		}
	} catch (std::exception& oEx) {
		cerr << "Unhandled exception - " << oEx.what() << endl;
		bError = true;
	} catch (...) {
		cerr << "Unrecognised exception - terminating." << endl;
		bError = true;
	}
	
	delete pDot3Extend;
	[pool drain];
	return bError;
}
