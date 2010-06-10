/*
 *  Image.h
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#import <ApplicationServices/ApplicationServices.h>

class Image
{
public:
	typedef unsigned char byte;
	
	Image(const string& strFilename);
	virtual ~Image();
	
	void Process();

private:
	string m_strFilename;
	CGImageRef m_refSourceImage;

	int m_width;
	int m_height;

	byte* m_pImageData;
};
