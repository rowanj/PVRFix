/*
 *  ImageData.h
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#import "ImagePixel.h"

class ImageData
{
public:
	ImageData(int iWidth, int iHeight);
	virtual ~ImageData();
	
	ImagePixel& Pixel(int x, int y);
	const ImagePixel& Pixel(int x, int y) const;
	
	void* GetBufferPtr();
	int GetBufferSize() const;
	
protected:
	int m_width;
	int m_height;
	
	ImagePixel* m_pixels;
};
