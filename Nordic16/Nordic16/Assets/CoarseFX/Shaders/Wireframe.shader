Shader "CoarseFX/Wireframe" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
	[Toggle] _LongEdge ("Triangle Mode", Float) = 0
}
SubShader {
	Tags { "Queue"="Transparent" "RenderType"="Transparent" }
Pass {
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
	CGPROGRAM
	#pragma vertex vert
	#pragma geometry geom
	#pragma fragment frag
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore
	#pragma multi_compile_fog
	#pragma shader_feature _ _LONGEDGE_ON

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	float _Tesselation;

	struct vData
	{
						float4 pos	: SV_POSITION;
		noperspective	fixed4 col	: COLOR;
		COARSEFX_FOG_COORD(0)

	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = v.vertex;
		OUT.col = v.color * _Color;

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}
		
	#ifdef _LONGEDGE_ON
		static const int count = 4;
	#else
		static const int count = 3;
	#endif
	[maxvertexcount(count)]
	void geom(triangle vData IN[3], inout LineStream<vData> stream)
	{
		#ifdef _LONGEDGE_ON
			uint start = 0;
		#else
			float maxDist = 0.0f;
			uint h0 = 0;
			for(uint i = 0; i < 3; i++)
			{
				float dist = distance(IN[i].pos.xyz, IN[(i + 1) % 3].pos.xyz);
				if (dist > maxDist)
				{
					h0 = i;
					maxDist = dist;
				}
			}
			uint start = (h0 + 1) % 3;
		#endif
		vData OUT;
		for (uint j = start; j < (start + count); j++)
		{
			OUT.pos = mul(UNITY_MATRIX_MVP, IN[j % 3].pos);
			OUT.pos = VertexQuantize(OUT.pos);
			OUT.col = IN[j % 3].col;
			COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
			stream.Append(OUT);
		}
	}

	fixed4 frag(vData IN) : COLOR
	{
		fixed4 outcol = IN.col;
		COARSEFX_APPLY_FOG(IN, outcol);
		return OutputDither(outcol, IN.pos);
	}
	ENDCG
}//Pass ForwardBase
}//SubShader
}//Shader