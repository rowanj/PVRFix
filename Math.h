/*
 *  Math.h
 *  Anathema
 *
 *  Created by Dafydd Williams & Rowan James on 21/05/10.
 *  Copyright 2010 Phere Development. All rights reserved.
 *
 */


namespace Math
{
		// Returns the point fPhase through the range [first:second]
		// 0.0 = origin, 0.5 = half way, 1.0 = second, etc.
	template <typename T>
	static T Lerp(const T& first, const T& second, const CGFloat& fPhase) {
		return T(first + (fPhase * (second - first)));
	}
	
	
		//! Answers the question: how far through the range [first:second] is value?
	template <typename T>
	static CGFloat InverseLerp(const T& first, const T& second, const T& value) {
		return CGFloat(value - first) / CGFloat(second - first);
	}
	
		// If you have a value in the range [inFirst:inSecond], and wish to map it
		// to the corresponding point in the range [outFirst:outSecond]
		// i.e. (-1.0, 1.0, 0.0, 400.0, 0.5) = 300.0
		//   ... the given input value 0.5 is 75% of the way from -1 to 1;
		// so return the value 75% of the way from 0 to 400.
	template <typename T>
	static T MapRange(const T& inFirst, const T& inSecond,
					  const T& outFirst, const T& outSecond,
					  const T& input) {
		return Lerp<T>(outFirst, outSecond, InverseLerp(inFirst, inSecond, input));
	}
	
		// Return value, unless it would be less than minValue or more than maxValue
		// in which case, return the nearest boundary.
	template <typename T>
	static T ClampToRange(const T& minValue, const T& maxValue, const T& value) {
		ASSERT(minValue <= maxValue);
		return max(minValue, min(maxValue, value));
	}
	
		// Return value as though it had been wrapped into the range minValue:maxValue
		// i.e. WrapToRange(1, 32, 34) = 2
	template <typename T>
	static T WrapToRange(const T& minValue, const T& maxValue, const T& value);
	
	template <>
	float WrapToRange<float>(const float& minValue, const float& maxValue, const float& value);
	
	template <typename T>
	T WrapToRange(const T& minValue, const T& maxValue, const T& value)
	{
		ASSERT(minValue <= maxValue);
		return minValue + (value % (maxValue - minValue + 1));
	}

		// Unit conversion constants
	static const CGFloat DEGREES_TO_RADIANS =  static_cast<CGFloat>(M_PI / 180.0);
	static const CGFloat DEGREES_TO_RADIANS_NEG = static_cast<CGFloat>(M_PI / -180.0);
	static const CGFloat RADIANS_TO_DEGREES = static_cast<CGFloat>(180.0 / M_PI);
} // namespace Math
