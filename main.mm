#import "Image.h"

#import "Dot3Extend.h"
#import "Dot3Light.h"
#import "FileProperties.h"

#define VERBOSE(x) { if (verbose) { cout << x ; } }

namespace {
	bool bError = false;
	namespace po = boost::program_options;
	Dot3Extend* pDot3Extend = NULL;
	Dot3Light* pDot3Light = NULL;
	int verbose;
	
	bool StringEndsWith(const string& strInput, const string& strSuffix) {
		return ( strInput.length() > strSuffix.length() &&
				 strInput.substr(strInput.length() - strSuffix.length()) == strSuffix
				);
	}
	
	void DoStep(const string& strInFile, const string& strOutFile, const ImageProcessor* pProcessor) {
		FileProperties oInFileProps(strInFile);
		FileProperties oOutFileProps(strOutFile);
		if (!oInFileProps.Exists()) {
			cout << "Error: Input file \"" << strInFile << "\" does not exist.  Why?" << endl;
			bError = true;
			return;
		}
			
		if (oOutFileProps.Exists() && oInFileProps.OlderThan(oOutFileProps)) {
			VERBOSE(" -- Skipping step of creating \"" << strOutFile << "\" from \"" << strInFile << "\"\n\tsource not modified since last processed." << endl;)
		} else {
			// Create the image object (or throw...)
			Image oImg(strInFile);
			
			// Process the file and write the output
			VERBOSE(" -- extending colours into transparent area...";)
			Image oOutput(pProcessor->Process(oImg));
			VERBOSE(" done." << endl;)
				
			VERBOSE(" -- saving colour-extended version \"" << strOutFile << "\"...";)
			oOutput.Save(strOutFile);
			VERBOSE(" done." << endl;)
		}
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

		// || z = 0.75 ES1, 0.65 ES2
		pDot3Light = new Dot3Light(-0.7f, -0.4f, 0.65f);
		for (vector<string>::const_iterator it(aInFiles.begin());
			 it != aInFiles.end(); ++it) {
				// Generate the output filename
			const string strInFile(*it);
			if (strInFile.length() < 5) {
				cerr << "Input file name \"" << strInFile << "\" is too short - not even long enough to end with \".png\" - skipping." << endl;
				bError = true;
				continue;
			}
			
			if (!StringEndsWith(strInFile, ".png")) {
			}
			const string strExtension(strInFile.substr(strInFile.length() - 4));
			if (strExtension != ".png") {
				cerr << "Input file \"" << strInFile << "\" does not end with .png - skipping." << endl;
				bError = true;
				continue;
			}
			
			if (StringEndsWith(strInFile, "-extended.png") ||
				StringEndsWith(strInFile, "-lit.png")) {
				VERBOSE("Skipping \"" << strInFile << "\", as is probably an output from a previous run." << endl);
				continue;
			}
			
			const string strBaseName = strInFile.substr(0, strInFile.length() - 4);
			
			const string strExtendedFile = strBaseName + "-extended.png";		
			const string strLitFile = strBaseName + "-lit.png";		
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
				if (StringEndsWith(strBaseName, " Dot3")) {
					DoStep(strInFile, strLitFile, pDot3Light);
					DoStep(strInFile, strExtendedFile, pDot3Extend);
					DoPVRCompress(strExtendedFile, strPVRFile);
				} else {
					DoPVRCompress(strInFile, strPVRFile);
				}
			} catch (ImageOpenFailure& oEx) {
				cout << "Error: could not read image file \"" << strInFile << "\" - continuing with next file (if any)." << endl;
				bError = true;
				continue;
			} catch (ImageSaveFailure& oEx) {
				cout << "Error saving output of file \"" << strInFile << "\" - continuing with next file (if any)." << endl;
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
