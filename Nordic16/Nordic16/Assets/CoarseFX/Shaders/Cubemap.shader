﻿Shader "Hidden/CoarseFX/Cubemap" {
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

	#include "UnityCG.cginc"
	#include "CoarseFX.cginc"

	float4 _Scale;
	float _Health;
	float _Reveal;
	fixed4 _HealthColor;

	samplerCUBE _MainTex;
	
	struct v2f
	{
						float4 pos	: SV_POSITION;
		noperspective	float2 uv	: TEXCOORD0;
	};

	v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
	{
		v2f OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.uv = uv * float2(6.28318530718, 3.14159265359) - float2(3.14159265359, 1.57079632679);
		//OUT.uv *= 420.0 / 360.0;
		OUT.uv.y = OUT.uv.y * _ScreenParams.y / _ScreenParams.x * 2.0 + 1.57079632679;

		return OUT;
	}
	
	fixed4 frag(v2f IN) : SV_TARGET
	{
		if (2.61799387799 < IN.uv.y || IN.uv.y < 0.52359877559)
			return 0;
		if (abs(IN.uv.x) > 3.14159265359 * _Reveal)
			return 0;
		float4 sc; sincos(IN.uv.xy, sc.xz, sc.yw);
		fixed4 color = texCUBE(_MainTex, float3(sc.x * sc.z, sc.w, sc.y * sc.z));
		if (IN.uv.y < 0.6)
			color.rgb = lerp(color, _HealthColor.rgb * (abs(IN.uv.x) / 3.14159265359 < _Health), 0.75);
		return color;
	}
	ENDCG
}//Pass
}//SubShader
}//Shader