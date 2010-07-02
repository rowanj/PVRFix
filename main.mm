#import "Image.h"

#import "Dot3Extend.h"
#import "FileProperties.h"

namespace po = boost::program_options;


int main (int argc, char * argv[]) {
	
	bool bError(false);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	try {
		po::options_description desc("Allowed options");
		po::positional_options_description p;
		p.add("input", -1);
		
		desc.add_options()
		("help", "produce help message")
		("range", po::value<int>()->default_value(500), "how many pixels to extend the borders by")
		("threshold", po::value<int>()->default_value(250), "alpha threshold to determine visible boundary")
		("input,i", po::value< vector<string> >(), "input file");	
		
		
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
		
		
		bError = false; // re-set the error flag..
		Dot3Extend oExtender(range, threshold);
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
			if (strExtension != ".png" && strExtension != ".PNG") {
				cerr << "Input file \"" << strInFile << "\" does not end with .png or .PNG - skipping." << endl;
				bError = true;
				continue;
			}
			
			string strBaseName = strInFile.substr(0, strInFile.length() - 4);
			
			string strExtendedFile = strBaseName + "-extended.png";			
			
			try {
					// Phase 1 - extend colours into transparencies to avoid blocking artifacts
				FileProperties oInFileProps(strInFile);
				if (!oInFileProps.Exists()) {
					cout << "Error: input file \"" << strInFile << "\" does not exist.  Probably." << endl;
					bError = true;
					continue;
				}
				
				FileProperties oExtendedFileProps(strExtendedFile);
				if (oExtendedFileProps.Exists() && oInFileProps.OlderThan(oExtendedFileProps)) {
					cout << "Skipping \"" << strInFile << "\" - not modified since last processed." << endl;
					continue;
				} else {
						// Create the image object (or throw...)
					Image oImg(strInFile);
				
						// Process the file and write the output
					cout << "Processing file \"" << strInFile << "\"" << endl;
					cout << " -- extending colours into transparent area...";
					oExtender.Process(oImg);
					cout << " done." << endl;
				
					cout << " -- saving colour-extended version \"" << strExtendedFile << "\"...";
					oImg.Save(strOutFile);
					cout << " done." << endl;
				}

					// Now, compress the output to PVR
				if (!oExtendedFileProps.Exists()) {
					cout << "Error: colour-extended file \"" << strExtendedFile << "\" does not exist.  Should have been created..." << endl;
					bError = true;
					continue;
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
			
			cout << strOutFile << endl;			
		}
	} catch (std::exception& oEx) {
		cerr << "Unhandled exception - " << oEx.what() << endl;
		bError = true;
	} catch (...) {
		cerr << "Unrecognised exception - terminating." << endl;
		bError = true;
	}
	
	[pool drain];
	return bError;
}
