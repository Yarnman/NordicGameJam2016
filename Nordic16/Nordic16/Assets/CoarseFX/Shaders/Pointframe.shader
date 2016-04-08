Shader "CoarseFX/Pointframe" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
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

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	struct vData
	{
		float4 pos	: SV_POSITION;
		fixed4 col	: COLOR;
		COARSEFX_FOG_COORD(0)
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		OUT.pos = VertexQuantize(OUT.pos);
		OUT.col = v.color * _Color;
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}

	[maxvertexcount(3)]
	void geom(triangle vData IN[3], inout PointStream<vData> stream)
	{
		for (uint i = 0; i < 3; i++)
			stream.Append(IN[i]);
	}

	fixed4 frag(vData IN) : COLOR
	{
		fixed4 outcol = IN.col;
		COARSEFX_APPLY_FOG(IN, outcol.rgb);
		return OutputDither(outcol, IN.pos);
	}
	ENDCG
}//Pass ForwardBase
}//SubShader
}//Shader