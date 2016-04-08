Shader "Hidden/CoarseFX/Video" {
Properties {
	_MainTex ("", any) = "" {}
}
SubShader {
	ZTest Always
	Cull Off
	ZWrite Off
	CGINCLUDE
	#pragma vertex vert
	#pragma fragment frag
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore

	#include "UnityCG.cginc"
	#include "CoarseFX.cginc"

	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	float _FrameOddEven;

	float3 rgb2yuv(float3 rgb)
	{
	    return mul(float3x3(0.25,0.5,0.25,0.0,-0.5,0.5,0.50,-0.5,0.0), srgb(rgb));
	}

	float3 yuv2rgb(float3 yuv)
	{
	    return lin(mul(float3x3(1.0,-0.5,1.5,1.0,-0.5,-0.5,1.0,1.5,-0.5), yuv));
	}

	struct v2f
	{
						float4 pos	: SV_POSITION;
		noperspective	float2 uv	: TEXCOORD0;
	};

	v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
	{
		v2f OUT;
		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = uv;
		return OUT;
	}

	ENDCG
Pass {
	CGPROGRAM
	fixed3 frag(v2f IN) : SV_TARGET
	{
		fixed3 prev = rgb2yuv(tex2D(_MainTex, IN.uv + float2(int(IN.pos.y + _FrameOddEven) % 2 > 0.5 ? _MainTex_TexelSize.x : -_MainTex_TexelSize.x, 0.0)));
		fixed3 curr = rgb2yuv(tex2D(_MainTex, IN.uv));
		return yuv2rgb(lerp(curr, prev, float3(distance(curr.yz, prev.yz) * 2, abs(curr.x - prev.x).xx * 8)));
	}
	ENDCG
}//Pass
Pass {
	CGPROGRAM
	fixed3 frag(v2f IN) : SV_TARGET
	{
		float3 cen = rgb2yuv(tex2D(_MainTex, IN.uv));
		float3 res = rgb2yuv(tex2D(_MainTex, IN.uv + float2(-3.0f * _MainTex_TexelSize.x, 0.0f)));
			  res += rgb2yuv(tex2D(_MainTex, IN.uv + float2(-2.0f * _MainTex_TexelSize.x, 0.0f))) * 6.0f;
			  res += rgb2yuv(tex2D(_MainTex, IN.uv + float2(-1.0f * _MainTex_TexelSize.x, 0.0f))) * 15.0f;
			  res += cen * 20.0f;
			  res += rgb2yuv(tex2D(_MainTex, IN.uv + float2( 1.0f * _MainTex_TexelSize.x, 0.0f))) * 15.0f;
			  res += rgb2yuv(tex2D(_MainTex, IN.uv + float2( 2.0f * _MainTex_TexelSize.x, 0.0f))) * 6.0f;
			  res += rgb2yuv(tex2D(_MainTex, IN.uv + float2( 3.0f * _MainTex_TexelSize.x, 0.0f)));
		res /= 64.0f;
		return yuv2rgb(float3(cen.x, res.yz));
	}
	ENDCG
}//Pass
}//SubShader
}//Shader