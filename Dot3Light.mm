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

Dot3Light::Dot3Light(float fLightX, float fLightY, float fLightZ) :
	m_fLightX(fLightX),
	m_fLightY(fLightY),
	m_fLightZ(fLightZ)
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

	

	/*
	if (output.a == 0) {
		
		// find all neighboring non-transparent pixels
		list<pair<ImagePixel, float> > blendWith = FindClosest(oSource, x, y);
		float fCount = blendWith.size();
		
		float fTotalDistance(0.0);
		float fMaximumDistance(0.0);
		for (list<pair<ImagePixel, float> >::iterator it(blendWith.begin());
			 it != blendWith.end(); ++it) {
			fTotalDistance += it->second;
			fMaximumDistance = max(fMaximumDistance, it->second);
		}
		float fAverageDistance(fTotalDistance/fCount);
		
		
		double dR(0.0);
		double dG(0.0);
		double dB(0.0);
		float fTotalWeight(0.0);
		for (list<pair<ImagePixel, float> >::iterator it(blendWith.begin());
			 it != blendWith.end(); ++it) {
			float fDistance(it->second);
			float fWeight = fAverageDistance / fDistance;
			//			fWeight = 1.0;
			// accumulate as though range was -1 to 1, * weight
			fTotalWeight += fWeight;
			dR += (((it->first.r / 255.0) * 2.0) - 1.0) * fWeight;
			dG += (((it->first.g / 255.0) * 2.0) - 1.0) * fWeight;
			dB += (((it->first.b / 255.0) * 2.0) - 1.0) * fWeight;
		}
		
		if (fCount > 0.0) {
			output.r = max(min(255.0, 128 + (dR * 128.0) / fTotalWeight), 0.0);
			output.g = max(min(255.0, 128 + (dG * 128.0) / fTotalWeight), 0.0);
			output.b = max(min(255.0, 128 + (dB * 128.0) / fTotalWeight), 0.0);
		} else {
			output.r = 128;
			output.g = 128;
			output.b = 255;
		}
	}
	output.a = 255; */
	return output;
}