/*
 *  Dot3Light.h
 *  PVRFix
 *
 *  Created by Rowan James on 8/10/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#import "ImageProcessor.h"
#import "ImagePixel.h"

class Dot3Light : public ImageProcessor
{
public:
	Dot3Light(float fLightX, float fLightY, float fLightZ, float fDiffuse, float fSpecular);
	~Dot3Light();
	
	Image Process(const Image& oSource) const;
	
protected:
	ImagePixel CalculateOutput(const Image& oSource, const int x, const int y) const;

	const float m_fLightX;
	const float m_fLightY;
	const float m_fLightZ;
	
	const float m_fDiffuse;
	const float m_fSpecular;
};

