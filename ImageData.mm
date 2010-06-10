/*
 *  ImageData.mm
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "ImageData.h"



ImageData::ImageData(int width, int height) :
	m_width(width),
	m_height(height),
	m_pixels(NULL)
{
	m_pixels = new ImagePixel[width * height];
}

ImageData::~ImageData()
{
	delete[] m_pixels;
}

void* ImageData::GetBufferPtr()
{
	return m_pixels;
}

int ImageData::GetBufferSize() const
{
	return Width() * Height() * 4;
}

int ImageData::Width() const
{
	if (m_pixels == NULL) {
		return 0;
	}
	return m_width;
}

int ImageData::Height() const
{
	if (m_pixels == NULL) {
		return 0;
	}
	return m_height;
}