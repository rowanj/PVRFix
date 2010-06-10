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

ImagePixel& ImageData::Pixel(int x, int y)
{
	return m_pixels[y * m_width + x];
}

const ImagePixel& ImageData::Pixel(int x, int y) const
{
	return m_pixels[y * m_width + x];
}

void* ImageData::GetBufferPtr()
{
	return m_pixels;
}

int ImageData::GetBufferSize() const
{
	if (m_pixels == NULL) {
		return 0;
	}
	return m_width * m_height * 4;
}