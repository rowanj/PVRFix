#import "Image.h"

#import "Dot3Extend.h"
#import "Dot3Light.h"
#import "FileProperties.h"
#import "AlphaBitMap.h"


#import <unistd.h> // fork
#import <sys/wait.h>

#define VERBOSE(x) { if (verbose) { cout << x ; } }

namespace {
	bool bError = false;
	namespace po = boost::program_options;
	Dot3Extend* pDot3Extend = NULL;
	Dot3Light* pDot3Light = NULL;
	int verbose;
	int iChildren = 0;
	
	
	bool StringEndsWith(const string& strInput, const string& strSuffix) {
		return ( strInput.length() > strSuffix.length() &&
				 strInput.substr(strInput.length() - strSuffix.length()) == strSuffix
				);
	}
	
	// 'Make' type check about if input file exists and is newer than output file
	bool CheckShouldProcess(const string& strInFile, const string& strOutFile) {
		FileProperties oInFileProps(strInFile);
		FileProperties oOutFileProps(strOutFile);
		if (!oInFileProps.Exists()) {
			cout << "Error: Input file \"" << strInFile << "\" does not exist.  Why?" << endl;
			bError = true;
			return false;
		}
		if (oOutFileProps.Exists() && oInFileProps.OlderThan(oOutFileProps)) {
			VERBOSE(" -- Skipping step of creating \n\t\"" << strOutFile << "\" from\n\t\"" << strInFile << "\"\n\tsource not modified since last processed." << endl;)
			return false;
		}
		return true;
	}
	
	// Generic ImageProcessor operation into file
	void DoStep(const string& strInFile, const string& strOutFile, const ImageProcessor* pProcessor) {
		if (!CheckShouldProcess(strInFile, strOutFile)) {
			return;
		}
			
		// Create the image object (or throw...)
		Image oImg(strInFile);
			
		// Process the file and write the output
		VERBOSE(" -- Creating data for \"" << strOutFile << "\"...";)
		Image oOutput(pProcessor->Process(oImg));
		VERBOSE(" done." << endl;)
				
		VERBOSE(" -- Saving \"" << strOutFile << "\"...";)
		oOutput.Save(strOutFile);
		VERBOSE(" done." << endl;)
	}

	void DoPVRCompress(const string& strInFile, const string& strOutFile) {
		if (!CheckShouldProcess(strInFile, strOutFile)) {
			return;
		}
		
		VERBOSE(" -- compressing into PVR format; about to launch 'texturetool'" << endl;)
		
		
		string strCommand = "./texturetool -f PVR -e PVRTC -m -o \"";
		strCommand += strOutFile + "\" \"" + strInFile + "\"";
		
		iChildren++;
		while (iChildren > 2) {
			int _tmp(0);
			wait(&_tmp);
			--iChildren;
		}
		if (!fork()) {
			int iError = system(strCommand.c_str());
			if (iError == 0) {						
				VERBOSE(" -- successfully compressed \"" << strOutFile << "\"." << endl;)
			} else {
				cout << "Error: System did not successfully run \"" << strCommand << "\"" << endl;
				bError = true;
				return;
			}
			
			// texturetool has a nasty bug - the PPC (universal) binary shipped by Apple
			// around the time of the iPhone OS 3.2 SDK is not endian-aware, and writes
			// byte-swapped headers.  Newer versions removed the PPC version of the binary, probably for this reason
			//			if (CFByteOrderGetCurrent() == CFByteOrderBigEndian) {
				//			cout << "Host is big endian, trying to fix PVR " << strOutFile << endl;
				NSData* pFile = [[NSData alloc] initWithContentsOfFile:[NSString stringWithUTF8String:strOutFile.c_str()]];
				NSMutableData* pNewFile = [pFile mutableCopy];
				[pFile release];
				
				uint32_t iHeaderSize;
				[pNewFile getBytes:&iHeaderSize length:4];
				if (iHeaderSize == 0x34) {
					void* newData = [pNewFile mutableBytes];
					uint32_t* newInts = static_cast<uint32_t*>(newData);
					
					const int iInts = iHeaderSize / sizeof(uint32_t);
					if (newInts[11] == *reinterpret_cast<const uint32_t*>("PVR!")) {
						cout << "- " << strOutFile << " is not byte swapped" <<endl;
					} else if (newInts[11] == *reinterpret_cast<const uint32_t*>("!RVP")) {
						cout << "+ " << strOutFile << " is byte swapped" <<endl;
						for (int i(0); i < iInts; ++i) {
							newInts[i] = CFSwapInt32(newInts[i]);
						}
						[pNewFile writeToFile:[NSString stringWithUTF8String:strOutFile.c_str()] atomically: NO];
					} else {
						cout << "! " << strOutFile << " has unknown magic bytes" << endl;
					}
					
				} else {
					cout << "Error: no idea what to do about endianness of \"" << strOutFile << "\" - header length not recognised" << endl;
					bError = true;
				}
			//}
			exit(0);
		}
	} 
			
	void DoMakeAlpha(const string& strInFile, const string& strOutFile) {
		if (!CheckShouldProcess(strInFile, strOutFile)) {
			return;
		}
		
		Image oImg(strInFile);
		AlphaBitMap oAlphaBitMap(32, oImg);
		oAlphaBitMap.Save(strOutFile);
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
		pDot3Light = new Dot3Light(-0.7f, -0.4f, 0.65f, 1.0f, 1.0f);
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
			
			if ( StringEndsWith(strInFile, "-extended.png") ||
				 StringEndsWith(strInFile, "-lit.png") ||
				 StringEndsWith(strInFile, ".hitmap") ) {
				VERBOSE("Skipping \"" << strInFile << "\", as is probably an output from a previous run." << endl);
				continue;
			}
			
			const string strBaseName = strInFile.substr(0, strInFile.length() - 4);
			
			const string strExtendedFile = strBaseName + "-extended.png";		
			const string strLitFile = strBaseName + "-lit.png";		
			const string strPVRFile = strBaseName + ".pvr";
			const string strAlphaFile = strBaseName + ".hitmap"; 
			
			try {
				FileProperties oInFileProps(strInFile);
				if (!oInFileProps.Exists()) {
					cout << "Error: input file \"" << strInFile << "\" does not exist.  Probably." << endl;
					bError = true;
					continue;
				}
				
				VERBOSE("Processing file \"" << strInFile << "\"" << endl;)
					// Phase 1 - extend colours into transparencies to avoid blocking artifacts
				if (StringEndsWith(strBaseName, " Dot3")) {
					DoStep(strInFile, strLitFile, pDot3Light);
					DoStep(strInFile, strExtendedFile, pDot3Extend);
					DoPVRCompress(strExtendedFile, strPVRFile);
				} else {
					DoPVRCompress(strInFile, strPVRFile);
					DoMakeAlpha(strInFile, strAlphaFile);
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
	
	while (iChildren > 0) {
		int _tmp(0);
		wait(&_tmp);
		--iChildren;
	}
	
	return bError;
}
