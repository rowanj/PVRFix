/*
 *  Image.cpp
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "Image.h"

#import <stdexcept>

Image::Image(ImageData* pData, CGColorSpaceRef colorSpace) : // take ownership of pData
	m_pImageData(pData),
	m_colorSpace(colorSpace)
{
	CGColorSpaceRetain(colorSpace);
}

Image::Image(const string& strFilename) throw (ImageOpenFailure) :
	m_pImageData(NULL),
	m_colorSpace(NULL)
{
	CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(strFilename.c_str());
	if (dataProvider == NULL) {
		throw ImageOpenFailure();
	}
	
	CGImageRef refSourceImage = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);

	CGDataProviderRelease(dataProvider);
	
	int width = CGImageGetWidth(refSourceImage);
	int height = CGImageGetHeight(refSourceImage);
	cout << "Image is " << width << "px wide and " << height << "px high" << endl;
	
	m_pImageData = new ImageData(width, height);
	
	m_colorSpace = CGImageGetColorSpace(refSourceImage);
	
	CGContextRef imageContext = CGBitmapContextCreate(m_pImageData->GetBufferPtr(), width, height, 8, width * 4, m_colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

	CGContextDrawImage(imageContext, CGRectMake(0, 0, width, height), refSourceImage);
	CGImageRelease(refSourceImage);
	
	CGContextRelease(imageContext);
}

Image::~Image()
{
	CGColorSpaceRelease(m_colorSpace);
	delete m_pImageData;
}

ImageData& Image::Data()
{
	return *m_pImageData;
}

const ImageData& Image::Data() const
{
	return *m_pImageData;
}

const CGColorSpaceRef Image::ColorSpace() const
{
	return m_colorSpace;
}

void Image::Save(const string& strFilename) const throw (ImageSaveFailure)
{
		// Create the CGImage to save
	CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, m_pImageData->GetBufferPtr(), m_pImageData->GetBufferSize(), NULL);
	CGImageRef image = CGImageCreate(m_pImageData->Width(), m_pImageData->Height(), 8, 32, m_pImageData->Width() * 4, ColorSpace(), kCGImageAlphaPremultipliedLast, dataProvider, NULL, true, kCGRenderingIntentDefault);
	CGDataProviderRelease(dataProvider);
	
		// Find the appropriate URL to export to
	NSString* nstrFilename = [[NSString alloc] initWithCString:strFilename.c_str()];
	NSURL* pURL = [[NSURL alloc] initFileURLWithPath:nstrFilename];
	[nstrFilename release];
	
		// Export the CGImage
	CGImageDestinationRef exportDestination = CGImageDestinationCreateWithURL((CFURLRef)pURL, kUTTypePNG, 1, NULL);
	CGImageDestinationAddImage(exportDestination, image, NULL);
	CGImageDestinationFinalize(exportDestination);
	
	[pURL release];
	CGImageRelease(image);
}
