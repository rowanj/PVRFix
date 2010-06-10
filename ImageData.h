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
	
	
	inline ImagePixel& Pixel(int x, int y) {
		return m_pixels[y * m_width + x];
	}
	inline const ImagePixel& Pixel(int x, int y) const {
		return m_pixels[y * m_width + x];
	}
	
	int Width() const;
	int Height() const;
	
	void* GetBufferPtr();
	int GetBufferSize() const;
	
protected:
		// not implemented
	ImageData(const ImageData& other);
	ImageData& operator=(const ImageData& other);
	
	
	int m_width;
	int m_height;
	
	ImagePixel* m_pixels;
};
