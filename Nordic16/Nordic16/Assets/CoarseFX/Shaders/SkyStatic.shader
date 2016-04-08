Shader "CoarseFX/Sky Static" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
	_Rotation ("Rotation", Range(0, 1)) = 0
	[NoScaleOffset] _SkyCube ("Cubemap", Cube) = "grey" {}
}
SubShader {
	Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
Pass {
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag 
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	struct v2f
	{
		float4 pos		: SV_POSITION;
		noperspective float3 texcoord : TEXCOORD0;
	};

	v2f vert (float4 pos : POSITION)
	{
		v2f OUT;
		OUT.texcoord = pos.xyz;

		float2 sc; sincos(_Rotation * UNITY_PI * 2.0f, sc.x, sc.y);
		pos.xz = mul(float2x2(sc.y, -sc.x, sc), pos.xz);
		OUT.pos = mul(UNITY_MATRIX_MVP, pos);
		OUT.pos = VertexQuantize(OUT.pos);
		return OUT;
	}

	fixed4 frag(v2f IN) : SV_Target
	{
		fixed4 outcol = texCUBE(_SkyCube, IN.texcoord) * _Color;
		return OutputDither(outcol, IN.pos);
	}
	ENDCG 
}
}
}