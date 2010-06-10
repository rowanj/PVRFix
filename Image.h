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

class ImageException : public std::runtime_error
{
protected:
	ImageException(const string& strDescription) : std::runtime_error(strDescription) {}	
};

class ImageOpenFailure : public ImageException
{
public:
	ImageOpenFailure() : ImageException("Could not open the image file.") {}
};

class ImageSaveFailure : public ImageException
{
public:
	ImageSaveFailure() : ImageException("Could not save the image file.") {}
};

class Image
{
public:
	Image(ImageData* pData, CGColorSpaceRef colorSpace); // takes ownership of pData
	Image(const string& strFilename) throw (ImageOpenFailure);
	virtual ~Image();
	
	ImageData& Data();
	const ImageData& Data() const;
	
	const CGColorSpaceRef ColorSpace() const;
	
	void Save(const string& strFilename) const throw (ImageSaveFailure);

private:
	CGColorSpaceRef m_colorSpace;
	ImageData* m_pImageData;
};
