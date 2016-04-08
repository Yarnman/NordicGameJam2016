Shader "Hidden/CoarseFX/Composite" {
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
	#pragma multi_compile _ _INTERLACE_ON

	#include "UnityCG.cginc"
	#include "CoarseFX.cginc"

	sampler2D _MainTex;
	float4 _Scale;
	#ifdef _INTERLACE_ON
		float _OddEvenFrame;
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
		OUT.pos.xy = OUT.pos.xy * _Scale.xy + _Scale.zw;
		OUT.uv = uv;

		return OUT;
	}
	
	fixed4 frag(v2f IN) : SV_TARGET
	{
		#ifdef _INTERLACE_ON
			clip(frac(IN.pos.y * 0.5f + _OddEvenFrame) * -2.0f + 1.0f);
		#endif
		return tex2D(_MainTex, IN.uv);
	} 
	ENDCG
}//Pass
}//SubShader
}//Shader