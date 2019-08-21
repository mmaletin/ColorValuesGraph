Shader "Hidden/Custom/ColorValuesGraph"
{
	HLSLINCLUDE

		#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

		TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
		float4 _MainTex_TexelSize;

		float _LineScale, _SamplingHeight, _IsColor, _SignalScale;

		float4 _SamplingHeightColor, _UnitLinesColor;

		// Copied from UnityCG.cginc
		// Including UnityCG.cginc causes conflicts
		inline half3 LinearToGammaSpace(half3 linRGB)
		{
			linRGB = max(linRGB, half3(0.h, 0.h, 0.h));
			// An almost-perfect approximation from http://chilliant.blogspot.com.au/2012/08/srgb-approximations-for-hlsl.html?m=1
			return max(1.055h * pow(linRGB, 0.416666667h) - 0.055h, 0.h);
		}

		float getLine(float2 uv, float value)
		{
			float width = _MainTex_TexelSize.y;
			return smoothstep(value - width, value, uv.y) - smoothstep(value, value + width, uv.y);
		}

		// This function draws smooth graph lines.
		//
		// On picture below (*) represents opaque pixels. Without smoothing only those will be drawn
		// (.) represents transparent line segments. Cells are graph texture pixels.
		//
		// For each point texture is sampled 3 times, for central point vp; left and right points vl and vr with 1 pixel displacement
		// Then delta between values is calculated, and that delta defines length of transparent lines
		//
		//     vl vp vr     <--- Sampling positions for points
		// +--+--+--+--+--+
		// |  | .|**|. |  | <--- vp point value
		// +--+--+--+--+--+
		// |  | .|..|. |  |
		// +--+--+--+--+--+
		// |  | .|..|. |  |
		// +--+--+--+--+--+
		// |  |**|..|. |  | <--- vl point value
		// +--+--+--+--+--+
		// |  |  | .|. |  |
		// +--+--+--+--+--+
		// |  |  | .|**|  | <--- vr point value
		// +--+--+--+--+--+
		//         ^
		//         o --- This line of pixels has alpha of 1 at the top and 0 at the bottom. 
		//               Its height is defined by right point, because among vl and vr lowest negative is vr
		//               So in this case transparent line will go 5 pixels down and 0 pixels up
		//
		// If in a picture above vl was highter then vp, it would create another transparent line that would go up
		//
		float3 getGraphLines(float2 uv)
		{
			float width = _MainTex_TexelSize.y;

			// Reading pixel in required position and pixels to the right and left
			float3 pointSample = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x, _SamplingHeight)).rgb * _SignalScale;
			float3 pointSampleLeft = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x - _MainTex_TexelSize.x, _SamplingHeight)).rgb * _SignalScale;
			float3 pointSampleRight = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x + _MainTex_TexelSize.x, _SamplingHeight)).rgb * _SignalScale;

			// Conversion to gamma if it's a color
			pointSample = _IsColor ? LinearToGammaSpace(pointSample) : pointSample;
			pointSampleLeft = _IsColor ? LinearToGammaSpace(pointSampleLeft) : pointSampleLeft;
			pointSampleRight = _IsColor ? LinearToGammaSpace(pointSampleRight) : pointSampleRight;

			// Values of point, left and right after rescaling
			float3 vp = pointSample * _LineScale + (1 - _LineScale) * .5;
			float3 vl = pointSampleLeft * _LineScale + (1 - _LineScale) * .5;
			float3 vr = pointSampleRight * _LineScale + (1 - _LineScale) * .5;

			// Difference in values between center and left, center and right
			float3 dl = vp - vl;
			float3 dr = vp - vr;

			// Highest positive and lowest negative
			float3 pos = max(max(dl, 0), max(dr, 0));
			float3 neg = min(min(dl, 0), min(dr, 0));

			// Outputing values for smooth lines
			float3 smooth = smoothstep(vp + width - neg, vp, uv.y) - smoothstep(vp, vp - width - pos, uv.y);

			return smooth;
		}

		float4 Frag(VaryingsDefault i) : SV_Target
		{
			float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);

			float samplingHeightLine = getLine(i.texcoord, _SamplingHeight);

			float lineZero = getLine(i.texcoord, (1 - _LineScale) * .5);
			float lineOne = getLine(i.texcoord, 1 * _LineScale + (1 - _LineScale) * .5);

			float3 graphLines = getGraphLines(i.texcoord);

			color = lerp(color, float4(_UnitLinesColor.rgb, color.a), (lineZero + lineOne) * _UnitLinesColor.a);
			color = lerp(color, float4(_SamplingHeightColor.rgb, color.a), samplingHeightLine * _SamplingHeightColor.a);

			color = lerp(color, float4(1, 0, 0, color.a), graphLines.r);
			color = lerp(color, float4(0, 1, 0, color.a), graphLines.g);
			color = lerp(color, float4(0, 0, 1, color.a), graphLines.b);

			return color;
		}

	ENDHLSL

	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			HLSLPROGRAM

				#pragma vertex VertDefault
				#pragma fragment Frag

			ENDHLSL
		}
	}
}