/*
 *  ImagePixel.h
 *  PVRFix
 *
 *  Created by Rowan James on 10/06/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

typedef unsigned char byte;
#pragma pack(push,1)
class ImagePixel
{
public:
	ImagePixel();
	
	byte r;
	byte g;
	byte b;
	byte a;
};
#pragma pack(pop)
