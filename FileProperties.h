/*
 *  FileProperties.h
 *  PVRFix
 *
 *  Created by Rowan James on 2/07/10.
 *  Copyright 2010 Rowan James. All rights reserved.
 *
 */

class FileProperties
{
public:
	FileProperties(const string& strPath);
	virtual ~FileProperties();
	
	bool Exists() const;
	NSDate* GetModTime() const;
	
	bool OlderThan(const FileProperties& other) const;

private:
	NSString* m_strPath;
};