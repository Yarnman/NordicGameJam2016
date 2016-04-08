Shader "Hidden/CoarseFX/Clear" {
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

	#ifdef _INTERLACE_ON
		float _OddEvenFrame;
	#endif

	float4 vert(float4 pos : POSITION) : SV_POSITION
	{
		return mul(UNITY_MATRIX_MVP, pos);
	}
	
	fixed4 frag(float4 pos : SV_POSITION) : SV_TARGET
	{
		#ifdef _INTERLACE_ON
			clip(frac(pos.y * 0.5f + _OddEvenFrame) - 0.5f);
		#endif
		return 0.0;
	} 
	ENDCG
}//Pass
}//SubShader
}//Shader