Shader "Hidden/CoarseFX/Cubemap" {
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
		OUT.uv = (uv - 0.5) * float2(6.28318530718, -1.41421356237);
		OUT.uv.y *= _ScreenParams.y / _ScreenParams.x * 4.0;

		return OUT;
	}
	
	fixed4 frag(v2f IN) : SV_TARGET
	{
		if (abs(IN.uv.y) > 1.0)
			return 0;
		float3 coord; sincos(IN.uv.x, coord.x, coord.z); coord.y = IN.uv.y;
		return texCUBE(_MainTex, coord);
	}
	ENDCG
}//Pass
}//SubShader
}//Shader