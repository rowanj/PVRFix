/*
 *  Dot3Extend.h
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#import "ImageProcessor.h"
#import "ImagePixel.h"

class Dot3Extend : public ImageProcessor
{
public:
	Dot3Extend(int iRadius, byte AlphaThreshold);
	~Dot3Extend();
	
	Image Process(const Image& oSource) const;
			   
protected:
	ImagePixel CalculateOutput(const Image& oSource, const int x, const int y) const;
	list<pair<ImagePixel, float> > FindClosest(const Image& oSource, const int x, const int y) const;
	
	const int m_iRadius;
	const byte m_AlphaThreshold;
};

