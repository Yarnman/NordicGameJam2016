Shader "Hidden/CoarseFX/Upscale" {
Properties {
	_MainTex ("", any) = "" {}
}
SubShader {
	ZTest Always
	Cull Off
	ZWrite Off
Pass {
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore
	#pragma multi_compile _ _MAGNIFY_ON

	#include "UnityCG.cginc"
	#include "CoarseFX.cginc"

	float4 _Scale;
	float4 _MainTex_TexelSize;

	#ifdef _MAGNIFY_ON
		sampler2D _MainTex;
	#else
		texture2D _MainTex;
	#endif
	
	struct v2f
	{
						float4 pos	: SV_POSITION;
		noperspective	float2 uv	: TEXCOORD0;
	};

	v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
	{
		v2f OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = uv * _Scale.xy + _Scale.zw;
		#ifdef _MAGNIFY_ON
			OUT.uv += 0.5f / _ScreenParams.xy * _Scale.xy;
		#endif

		return OUT;
	}
	
	fixed4 frag(v2f IN) : SV_TARGET
	{
		if (any(0.0f > IN.uv || IN.uv > _MainTex_TexelSize.zw))
			return 0.0;
		#ifdef _MAGNIFY_ON
			float2 scale = _ScreenParams.xy / _Scale.xy;
			float2 uv; uv += saturate(modf(IN.uv, uv) * scale) - 0.5f;
			return tex2Dlod(_MainTex, float4(uv * _MainTex_TexelSize.xy, 0.0f, 0.0f));
		#else
			return _MainTex.Load(uint3(IN.uv, 0));
		#endif
	}
	ENDCG
}//Pass
}//SubShader
}//Shader