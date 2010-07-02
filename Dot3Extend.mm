/*
 *  Dot3Extend.mm
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "Dot3Extend.h"

#import "Image.h"

Dot3Extend::Dot3Extend(int iRadius, byte AlphaThreshold) :
	m_iRadius(iRadius),
	m_AlphaThreshold(AlphaThreshold)
{
}

Dot3Extend::~Dot3Extend()
{
}

Image Dot3Extend::Process(const Image& oSource) const
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

ImagePixel Dot3Extend::CalculateOutput(const Image& oSource, const int x, const int y) const
{
	ImagePixel output(oSource.Data().Pixel(x, y));
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
	output.a = 255;
	return output;
}

list<pair<ImagePixel, float> > Dot3Extend::FindClosest(const Image& oSource, const int x, const int y) const
{
	const float DiagFactor = sqrt(2.0);
	
	const ImageData& oSourceData(oSource.Data());
	
	list<pair<ImagePixel, float> > oReturn;
	
		// left
	for (int tx(x-1); tx >= max(0, x - m_iRadius); --tx) {
		const ImagePixel& tPixel(oSourceData.Pixel(tx, y));
		if (tPixel.a > m_AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, abs(x - tx) ));
			break;
		}
	}
		// right
	for (int tx(x+1); tx < min(oSourceData.Width(), x + m_iRadius); ++tx) {
		const ImagePixel& tPixel(oSourceData.Pixel(tx, y));
		if (tPixel.a > m_AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, abs(x - tx) ));
			break;
		}
	}
	
		// up
	for (int ty(y-1); ty >= max(0, y - m_iRadius); --ty) {
		const ImagePixel& tPixel(oSourceData.Pixel(x, ty));
		if (tPixel.a > m_AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, abs(y - ty) ));
			break;
		}
	}
	
		// down
	for (int ty(y+1); ty < min(oSourceData.Height(), y + m_iRadius); ++ty) {
		const ImagePixel& tPixel(oSourceData.Pixel(x, ty));
		if (tPixel.a > m_AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, abs(y - ty) ));
			break;
		}
	}
	
	int iCount;
	int MaxDiag = m_iRadius / DiagFactor;
		// SE
	iCount = min(min(oSourceData.Width() - x, oSourceData.Height() - y), MaxDiag);
	for (int i(1); i < iCount; ++i) {
		const ImagePixel& tPixel(oSourceData.Pixel(x + i, y + i));
		if (tPixel.a > m_AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, i * DiagFactor));
			break;
		}
	}
		// SW
	iCount = min(min(x, oSourceData.Height() - y), MaxDiag);
	for (int i(1); i < iCount; ++i) {
		const ImagePixel& tPixel(oSourceData.Pixel(x - i, y + i));
		if (tPixel.a > m_AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, i * DiagFactor));
			break;
		}
	}
		// NE
	iCount = min(min(oSourceData.Width() - x, y), MaxDiag);
	for (int i(1); i < iCount; ++i) {
		const ImagePixel& tPixel(oSourceData.Pixel(x + i, y - i));
		if (tPixel.a > m_AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, i * DiagFactor));
			break;
		}
	}
		// NW
	iCount = min(min(x, y), MaxDiag);
	for (int i(1); i < iCount; ++i) {
		const ImagePixel& tPixel(oSourceData.Pixel(x - i, y - i));
		if (tPixel.a > m_AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, i * DiagFactor));
			break;
		}
	}
	
	return oReturn;
}
