/*
 *  Image.cpp
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "Image.h"

Image::Image(ImageData* pData) : // take ownership of pData
	m_pImageData(pData),
	m_colorSpace(NULL)
{
}

Image::Image(const string& strFilename) :
	m_pImageData(NULL),
	m_colorSpace(NULL)
{
	CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(strFilename.c_str());
	
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