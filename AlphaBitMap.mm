/*
 *  AlphaBitMap.mm
 *  PVRFix
 *
 *  Created by Rowan James on 13/10/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "AlphaBitMap.h"

#import "Image.h"

#import <cmath>
#import <fstream>

#pragma pack(1)
struct AlphaBitMapHeader
{
	char magic[8];
	char text[12];
	unsigned int version;
	unsigned int header_size;
	unsigned int width;
	unsigned int height;
};

AlphaBitMap::AlphaBitMap(size_t iSize, const Image& oImg) :
	m_iSize(iSize),
	m_pData(NULL)
{
	m_pData = new float[m_iSize * m_iSize];
	
	const ImageData& oData(oImg.Data());
	const float fX_rate = (float)oData.Width() / (float)m_iSize;
	const float fY_rate = (float)oData.Height() / (float)m_iSize;
	
	const float f_rate = fX_rate * fY_rate;
	
	// for each pixel in the output data
	for (size_t Y_o(0); Y_o < m_iSize; ++Y_o) {
		for (size_t X_o(0); X_o < m_iSize; ++X_o) {
			// sum up the alpha of each pixel in the input block for that pixel
			float alpha_sum(0.0f);
			const size_t X_min = max(0.0f, floor(fX_rate * X_o));
			const size_t X_max = min(oData.Width() - 1.0f, ceil(fX_rate * (X_o + 1)));
			const size_t Y_min = max(0.0f, floor(fY_rate * Y_o));
			const size_t Y_max = min(oData.Height() - 1.0f, ceil(fY_rate * (Y_o + 1)));
			
			for (size_t Y_i(Y_min); Y_i <= Y_max; ++Y_i) {
				for (size_t X_i(X_min); X_i <= X_max; ++X_i) {
					alpha_sum += oData.Pixel(X_i, Y_i).a;
				}
			}
			
			size_t index_o = Y_o * m_iSize + X_o;
			assert(index_o >= 0);
			assert(index_o < m_iSize * m_iSize);
			
			m_pData[index_o] = alpha_sum / f_rate;
		}
	}
}

AlphaBitMap::~AlphaBitMap()
{
	delete[] m_pData;
}


void AlphaBitMap::Save(const string& strFileName) const
{
	ofstream file(strFileName.c_str());
	
	AlphaBitMapHeader oHeader;
	memset(&oHeader, 0, sizeof(AlphaBitMapHeader));
	memcpy(oHeader.magic, "RawAlpha", 8);
	memcpy(oHeader.text, "1bpp alpha", 10); 
	oHeader.version = CFSwapInt32HostToLittle(1);
	oHeader.header_size = CFSwapInt32HostToLittle(sizeof(AlphaBitMapHeader));
	oHeader.width = CFSwapInt32HostToLittle(m_iSize);
	oHeader.height = CFSwapInt32HostToLittle(m_iSize);
	
	file.write(reinterpret_cast<const char*>(&oHeader), sizeof(AlphaBitMapHeader));

	int iBit(0);
	unsigned char iByte;
	for (size_t pixel(0); pixel < m_iSize * m_iSize; ++pixel) {
		if (m_pData[pixel] > 10.0f) {
			unsigned char iThisBit = 1 << (7 - iBit);
			iByte |= iThisBit;
		}

		if (++iBit == 8) {
			file << iByte;
			iBit = 0;
			iByte = 0;
		}
	}
	if (iByte != 0) {
		file << iByte;
	}
}
