/*
 *  ImageProcessor.h
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

class Image;

class ImageProcessor
{
public:
	virtual ~ImageProcessor() {}
	
	virtual Image Process(const Image& oSource) const = 0;
};