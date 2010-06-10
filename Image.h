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
	Image(ImageData* pData); // takes ownership of pData
	Image(const string& strFilename);
	virtual ~Image();
	
	ImageData& Data();
	const ImageData& Data() const;
	
	const CGColorSpaceRef ColorSpace() const;
	

private:
	CGColorSpaceRef m_colorSpace;
	ImageData* m_pImageData;
};
