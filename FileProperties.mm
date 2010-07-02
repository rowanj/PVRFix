/*
 *  FileProperties.mm
 *  PVRFix
 *
 *  Created by Rowan James on 2/07/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

#include "FileProperties.h"

FileProperties::FileProperties(const string& strPath) :
	m_strPath(nil)
{
	m_strPath = [[NSString alloc] initWithCString:strPath.c_str()];
}

FileProperties::~FileProperties()
{
	[m_strPath release];
}

bool FileProperties::Exists() const
{
	bool bResult = [[NSFileManager defaultManager] fileExistsAtPath:m_strPath];
	return bResult;
}

NSDate* FileProperties::GetModTime() const
{
	assert(Exists());
	NSError* errorReturn(nil);
	NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:m_strPath error:&errorReturn];
	NSDate* pDate = [attributes objectForKey:@"NSFileModificationDate"];
	
	return pDate;
}

bool FileProperties::OlderThan(const FileProperties& other) const
{
	NSComparisonResult result = [GetModTime() compare:other.GetModTime()];
	return result == NSOrderedAscending;
}