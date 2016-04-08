Shader "Hidden/CoarseFX/Upscale Analoge" {
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

	float4 _Scale;
	float4 _NTSCParams;
	float4 _CRTParams;
	float _FrameOddEven;

	static const float3 kernel[4] =
	{
		float3(0.0f, 0.015625f, 0.015625f),
		float3(0.0f, 0.09375f, 0.09375f), 
		float3(0.0f, 0.234375f, 0.234375f),
		float3(1.0f, 0.3125f, 0.3125f),
	};

	float3 rgb2yiq(float3 rgb)
	{
	    return mul(float3x3(0.299,0.587,0.114,0.596,-0.274,-0.322,0.211,-0.523,0.312), rgb);
	}

	float3 yiq2rgb(float3 yiq)
	{
	    return mul(float3x3(1.0,0.956,0.621,1.0,-0.272,-0.647,1.0,-1.106,1.703), yiq);
	}

	float Gaus(float pos, float scale)
	{
		return exp2(-scale * pos * pos * abs(pos));
	}
	
	struct v2f
	{
						float4 pos	: SV_POSITION;
		noperspective	float2 uv	: TEXCOORD0;
	};

	ENDCG
Pass {
	CGPROGRAM

	float3 hash32(float2 p)
	{
		float3 p3 = frac(float3(p.xyx) * 443.8975);
	    p3 += dot(p3, p3.yxz+19.19);
	    return frac(float3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
	}

	v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
	{
		v2f OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = uv;

		return OUT;
	}

	fixed3 frag(v2f IN) : SV_TARGET
	{ 
		float ofs = frac((IN.pos.x + IN.pos.y + _FrameOddEven) * 0.5) > 0.25 ? _MainTex_TexelSize.x : -_MainTex_TexelSize.x;
		fixed3 curr = rgb2yiq(tex2D(_MainTex, IN.uv));
		fixed3 lumaSrc = rgb2yiq(tex2D(_MainTex, IN.uv + float2(ofs, 0.0)));
		fixed3 chromaSrc = rgb2yiq(tex2D(_MainTex, IN.uv + float2(-ofs, 0.0)));
		fixed3 res = yiq2rgb(lerp(curr, float3(lumaSrc.x, chromaSrc.yz), float3(distance(curr.yz, lumaSrc.yz), abs(curr.x - chromaSrc.x).xx) * _NTSCParams.xyy));
		return res + (hash32(IN.uv + _NTSCParams.w) - 0.5) * _NTSCParams.z;
	}
	ENDCG
}//Pass
Pass {
	CGPROGRAM
	v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
	{
		v2f OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = uv;

		return OUT;
	}

	fixed3 frag(v2f IN) : SV_TARGET
	{
		float3 res = rgb2yiq(tex2D(_MainTex, IN.uv + float2(-3.0f * _MainTex_TexelSize.x, 0.0f))) * kernel[0];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2(-2.0f * _MainTex_TexelSize.x, 0.0f))) * kernel[1];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2(-1.0f * _MainTex_TexelSize.x, 0.0f))) * kernel[2];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv)) * kernel[3];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2( 1.0f * _MainTex_TexelSize.x, 0.0f))) * kernel[2];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2( 2.0f * _MainTex_TexelSize.x, 0.0f))) * kernel[1];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2( 3.0f * _MainTex_TexelSize.x, 0.0f))) * kernel[0];
		return yiq2rgb(res);
	}
	ENDCG
}//Pass
Pass {
	CGPROGRAM
	v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
	{
		v2f OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = uv;

		return OUT;
	}

	fixed3 frag(v2f IN) : SV_TARGET
	{
		float3 res = rgb2yiq(tex2D(_MainTex, IN.uv + float2(0.0f, -3.0f * _MainTex_TexelSize.y))) * kernel[0];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2(0.0f, -2.0f * _MainTex_TexelSize.y))) * kernel[1];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2(0.0f, -1.0f * _MainTex_TexelSize.y))) * kernel[2];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv)) * kernel[3];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2(0.0f,  1.0f * _MainTex_TexelSize.y))) * kernel[2];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2(0.0f,  2.0f * _MainTex_TexelSize.y))) * kernel[1];
			  res += rgb2yiq(tex2D(_MainTex, IN.uv + float2(0.0f,  3.0f * _MainTex_TexelSize.y))) * kernel[0];
		return yiq2rgb(res);
	}
	ENDCG
}//Pass
Pass {
	CGPROGRAM
	float3 Fetch(float2 pos, float off)
	{
		pos.x += off * _MainTex_TexelSize.x;
		return all(0.0f < pos && pos < 1.0f) ? tex2D(_MainTex, pos).rgb : 0.0;
	}

	v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
	{
		v2f OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = uv * _Scale.xy + _Scale.zw;

		return OUT;
	}

	fixed3 frag(v2f IN) : SV_TARGET
	{
		float dst = frac(IN.uv.x * -_MainTex_TexelSize.z) - 0.5;

		float wa = Gaus(dst - 3.0, _CRTParams.y);
		float wb = Gaus(dst - 2.0, _CRTParams.y);
		float wc = Gaus(dst - 1.0, _CRTParams.y);
		float wd = Gaus(dst,       _CRTParams.y);
		float we = Gaus(dst + 1.0, _CRTParams.y);
		float wf = Gaus(dst + 2.0, _CRTParams.y);
		float wg = Gaus(dst + 3.0, _CRTParams.y);

		float3 res = Fetch(IN.uv, -3.0) * wa;
			  res += Fetch(IN.uv, -2.0) * wb;
			  res += Fetch(IN.uv, -1.0) * wc;
			  res += Fetch(IN.uv,  0.0) * wd;
			  res += Fetch(IN.uv,  1.0) * we;
			  res += Fetch(IN.uv,  2.0) * wf;
			  res += Fetch(IN.uv,  3.0) * wg;
		res /= wa + wb + wc + wd + we + wf + wg;

		return res;
	}
	ENDCG
}//Pass
Pass {
	CGPROGRAM
	float3 Fetch(float2 pos, float off)
	{
		pos.y += off * _MainTex_TexelSize.y;
		return all(0.0f < pos && pos < 1.0f) ? tex2D(_MainTex, pos).rgb : 0.0;
	}

	v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
	{
		v2f OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = uv;

		return OUT;
	}

	fixed3 frag(v2f IN) : SV_TARGET
	{
		float dst = frac(IN.uv.y * -_MainTex_TexelSize.w) - 0.5;

		float3 res = Fetch(IN.uv, -2.0) * Gaus(dst - 2.0, _CRTParams.x);
			  res += Fetch(IN.uv, -1.0) * Gaus(dst - 1.0, _CRTParams.x);
			  res += Fetch(IN.uv,  0.0) * Gaus(dst,       _CRTParams.x);
			  res += Fetch(IN.uv,  1.0) * Gaus(dst + 1.0, _CRTParams.x);
			  res += Fetch(IN.uv,  2.0) * Gaus(dst + 2.0, _CRTParams.x);
		float maskPos = frac(IN.pos.x / 3.0);
		res *= maskPos < 0.333 ? _CRTParams.wzz : maskPos < 0.666 ? _CRTParams.zwz : _CRTParams.zzw;

		return res;
	}
	ENDCG
}//Pass
}//SubShader
}//Shader