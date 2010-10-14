/*
 *  AlphaBitMap.h
 *  PVRFix
 *
 *  Created by Rowan James on 13/10/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

class Image;
class AlphaBitMap
{
public:
	AlphaBitMap(size_t iSize, const Image& oImg);
	~AlphaBitMap();
	
	void Save(const string& strFileName) const;

private:
	const size_t m_iSize;
	float* m_pData;
};
