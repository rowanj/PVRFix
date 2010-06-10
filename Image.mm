/*
 *  Image.cpp
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "Image.h"

Image::Image(const string& strFilename) :
	m_strFilename(strFilename),
	m_refSourceImage(NULL),
	m_width(0),
	m_height(0),
	m_pImageData(NULL)
{
	CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(strFilename.c_str());
	
	m_refSourceImage = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);

	CGDataProviderRelease(dataProvider);
	
	m_width = CGImageGetWidth(m_refSourceImage);
	m_height = CGImageGetHeight(m_refSourceImage);
	cout << "Image is " << m_width << "px wide and " << m_height << "px high" << endl;
	
	m_pImageData = new byte[m_width * m_height * 4];
	
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(m_refSourceImage);
	
	CGContextRef imageContext = CGBitmapContextCreate(m_pImageData, m_width, m_height, 8, m_width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);

	CGContextDrawImage(imageContext, CGRectMake(0, 0, m_width, m_height), m_refSourceImage);
	CGContextRelease(imageContext);
}

Image::~Image()
{
	CGImageRelease(m_refSourceImage);
	delete[] m_pImageData;
}

void Image::Process()
{
}
