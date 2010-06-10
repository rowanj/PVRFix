/*
 *  Image.cpp
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "Image.h"

Image::Image(const string& strFilename) :
	m_strFilename(strFilename),
	m_refSourceImage(NULL),
	m_width(0),
	m_height(0),
	m_pImageData(NULL),
	m_colorSpace(NULL)
{
	CGDataProviderRef dataProvider = CGDataProviderCreateWithFilename(strFilename.c_str());
	
	m_refSourceImage = CGImageCreateWithPNGDataProvider(dataProvider, NULL, NO, kCGRenderingIntentDefault);

	CGDataProviderRelease(dataProvider);
	
	m_width = CGImageGetWidth(m_refSourceImage);
	m_height = CGImageGetHeight(m_refSourceImage);
	cout << "Image is " << m_width << "px wide and " << m_height << "px high" << endl;
	
	m_pImageData = new ImageData(m_width, m_height);
	
	m_colorSpace = CGImageGetColorSpace(m_refSourceImage);
	
	CGContextRef imageContext = CGBitmapContextCreate(m_pImageData->GetBufferPtr(), m_width, m_height, 8, m_width * 4, m_colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);

	CGContextDrawImage(imageContext, CGRectMake(0, 0, m_width, m_height), m_refSourceImage);
	
	CGContextRelease(imageContext);
}

Image::~Image()
{
	CGImageRelease(m_refSourceImage);
	CGColorSpaceRelease(m_colorSpace);
	delete m_pImageData;
}

void Image::Process() const
{
	ImageData output(m_width, m_height);
	
	for (int y(0); y < m_height; ++y) {
		for (int x(0); x < m_width; ++x) {
			output.Pixel(x, y) = CalculateOutput(x, y);
		}
	}
	
	CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, output.GetBufferPtr(), output.GetBufferSize(), NULL);
	CGImageRef image = CGImageCreate(m_width, m_height, 8, 32, m_width * 4, m_colorSpace, kCGImageAlphaPremultipliedLast, dataProvider, NULL, true, kCGRenderingIntentDefault);
	CGDataProviderRelease(dataProvider);
	
	FSRef usersDesktop;
	FSFindFolder(kUserDomain, kDesktopFolderType, false, &usersDesktop);
	CFURLRef desktopURL = CFURLCreateFromFSRef(NULL, &usersDesktop);
	CFURLRef destinationURL = CFURLCreateWithFileSystemPathRelativeToBase(NULL, CFSTR("fixed.png"), kCFURLPOSIXPathStyle, false, desktopURL);
	CFRelease(desktopURL);
	
	CGImageDestinationRef exportDestination = CGImageDestinationCreateWithURL(destinationURL, kUTTypePNG, 1, NULL);
	CGImageDestinationAddImage(exportDestination, image, NULL);
	CGImageDestinationFinalize(exportDestination);

	CFRelease(destinationURL);
	CGImageRelease(image);
}	

ImagePixel Image::CalculateOutput(const int x, const int y) const
{
	ImagePixel output(m_pImageData->Pixel(x, y));
	if (output.a == 0) {
		output.a = 255;
			// find all neighboring non-transparent pixels
		list<pair<ImagePixel, float> > blendWith = FindClosest(x, y);
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
	return output;
}

list<pair<ImagePixel, float> > Image::FindClosest(const int x, const int y) const
{
	const byte AlphaThreshold = 250;
	const int MaxCount = 3000;
	const float DiagFactor = sqrt(2.0);
	
	list<pair<ImagePixel, float> > oReturn;

		// left
	for (int tx(x-1); tx >= max(0, x - MaxCount); --tx) {
		ImagePixel& tPixel(m_pImageData->Pixel(tx, y));
		if (tPixel.a > AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, abs(x - tx) ));
			break;
		}
	}
		// right
	for (int tx(x+1); tx < min(m_width, x + MaxCount); ++tx) {
		ImagePixel& tPixel(m_pImageData->Pixel(tx, y));
		if (tPixel.a > AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, abs(x - tx) ));
			break;
		}
	}
	
		// up
	for (int ty(y-1); ty >= max(0, y - MaxCount); --ty) {
		ImagePixel& tPixel(m_pImageData->Pixel(x, ty));
		if (tPixel.a > AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, abs(y - ty) ));
			break;
		}
	}
	
		// down
	for (int ty(y+1); ty < min(m_height, y + MaxCount); ++ty) {
		ImagePixel& tPixel(m_pImageData->Pixel(x, ty));
		if (tPixel.a > AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, abs(y - ty) ));
			break;
		}
	}
	
	int iCount;
	int MaxDiag = MaxCount / DiagFactor;
		// SE
	iCount = min(min(m_width - x, m_height - y), MaxDiag);
	for (int i(1); i < iCount; ++i) {
		ImagePixel& tPixel(m_pImageData->Pixel(x + i, y + i));
		if (tPixel.a > AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, i * DiagFactor));
			break;
		}
	}
		// SW
	iCount = min(min(x, m_height - y), MaxDiag);
	for (int i(1); i < iCount; ++i) {
		ImagePixel& tPixel(m_pImageData->Pixel(x - i, y + i));
		if (tPixel.a > AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, i * DiagFactor));
			break;
		}
	}
		// NE
	iCount = min(min(m_width - x, y), MaxDiag);
	for (int i(1); i < iCount; ++i) {
		ImagePixel& tPixel(m_pImageData->Pixel(x + i, y - i));
		if (tPixel.a > AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, i * DiagFactor));
			break;
		}
	}
		// NW
	iCount = min(min(x, y), MaxDiag);
	for (int i(1); i < iCount; ++i) {
		ImagePixel& tPixel(m_pImageData->Pixel(x - i, y - i));
		if (tPixel.a > AlphaThreshold) {
			oReturn.push_back(pair<ImagePixel, float>(tPixel, i * DiagFactor));
			break;
		}
	}
	
	return oReturn;
}
