/*
 *  Dot3Light.mm
 *  PVRFix
 *
 *  Created by Rowan James on 8/10/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "Dot3Light.h"

#import "Image.h"
#import "Math.h"

Dot3Light::Dot3Light(float fLightX, float fLightY, float fLightZ, float fDiffuse, float fSpecular) :
	m_fLightX(fLightX),
	m_fLightY(fLightY),
	m_fLightZ(fLightZ),
	m_fDiffuse(fDiffuse),
	m_fSpecular(fSpecular)
{
}

Dot3Light::~Dot3Light()
{
}

Image Dot3Light::Process(const Image& oSource) const
{
	ImageData* output = new ImageData(oSource.Data().Width(), oSource.Data().Height());
	
	// We like our CPUs utilized, thanks
#pragma omp parallel for
	for (int y = 0; y < output->Height(); ++y) {
		for (int x(0); x < output->Width(); ++x) {
			// For each out pixel, CalculateSource
			output->Pixel(x, y) = CalculateOutput(oSource, x, y);
		}
	}
	
	return Image(output, oSource.ColorSpace());
}	

ImagePixel Dot3Light::CalculateOutput(const Image& oSource, const int x, const int y) const
{
	ImagePixel output(oSource.Data().Pixel(x, y));
	
	const ImagePixel& input = oSource.Data().Pixel(x, y);
	float ir = Math::MapRange(0.0f, 255.0f, -1.0f, 1.0f, (float)input.r);
	float ig = Math::MapRange(0.0f, 255.0f, -1.0f, 1.0f, (float)input.g);
	float ib = Math::MapRange(0.0f, 255.0f, -1.0f, 1.0f, (float)input.b);
	
	float fDot =
		ir * m_fLightX +
		ig * m_fLightY +
		ib * m_fLightZ;
	
	fDot = Math::ClampToRange(0.0f, 1.0f, fDot);

	float fLit = Math::MapRange(0.0f, 1.0f, 0.0f, 255.0f, fDot);
	output.r = output.g = output.b = fLit;

	return output;
}