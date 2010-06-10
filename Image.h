/*
 *  Image.h
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#import <ApplicationServices/ApplicationServices.h>

#import "ImageData.h"

class Image
{
public:
	
	Image(const string& strFilename);
	virtual ~Image();
	
	void Process() const;

private:
	ImagePixel CalculateOutput(const int x, const int y) const;
	list<pair<ImagePixel, float> > FindClosest(const int x, const int y) const;
	
	string m_strFilename;
	CGImageRef m_refSourceImage;
	CGColorSpaceRef m_colorSpace;

	int m_width;
	int m_height;

	ImageData* m_pImageData;
};
