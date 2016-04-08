Shader "Hidden/CoarseFX/Polygon" {
SubShader { 
	Tags { "RenderType"="Opaque" }
	Cull [_CullMode]
	ZTest [_ZTest]
	ZWrite [_ZWrite]
	Blend [_BlendSrc] [_BlendDst]
	BlendOp [_BlendOp] 
	
	CGINCLUDE
	#pragma target gl4.1
	#pragma only_renderers d3d11 glcore
	#pragma multi_compile_fog
	#pragma multi_compile QUEUE_GEOMETRY QUEUE_ALPHATEST QUEUE_TRANSPARENT QUEUE_OVERLAY
	#pragma multi_compile _ _GOURAUD_ON
	#pragma multi_compile _ _TEXTURED_ON

	#include "UnityCG.cginc"
	#include "Assets/CoarseFX/Shaders/CoarseFX.cginc"

	sampler2D _MainTex;
	fixed4 _MainTex_ST;
	float4 _MainTex_Scroll;
	float4 _MainTex_Strength;

	float _Blend;
	float4 _Lighting;
	fixed4 _ColorBack;
	fixed _FogIntns;

	ENDCG
Pass {
	Name "FORWARDBASE"
	Tags { "LightMode"="ForwardBase" }
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma multi_compile_fwdbase
	#pragma target gl4.1

	#define UNITY_PASS_FORWARDBASE

	struct vData
	{
						float4 pos	: SV_POSITION;
	#ifdef _TEXTURED_ON
		noperspective	fixed2 uv	: TEXCOORD0;
	#endif
	#if QUEUE_ALPHATEST || QUEUE_TRANSPARENT
		FACETEDINTERP fixed4 amb	: TEXCOORD1;
	#else
		FACETEDINTERP fixed3 amb	: TEXCOORD1;
	#endif
		COARSEFX_FOG_COORD(2)
		COARSEFX_LIGHTMAP_COORD(3)
	#ifndef LIGHTMAP_ON
		FACETEDINTERP fixed3 dir	: TEXCOORD4;
		COARSEFX_LIGHTING_COORDS(5,6)
	#endif
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		float2 uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
		#ifdef _TEXTURED_ON
			OUT.uv = uv;
		#endif

		fixed4 color = _Color * v.color * DepthBoundFade(v.vertex);
		#ifndef _TEXTURED_ON
			color *= tex2Dlod(_MainTex, float4(uv, 0.0f, 0.0f));
		#endif
		OUT.amb.rgb = color.rgb;
		#ifdef QUEUE_ALPHATEST
			OUT.amb.a = 1.0f - color.a;
		#elif QUEUE_TRANSPARENT
			OUT.amb.a = color.a;
		#endif

		fixed3 wNorm = UnityObjectToWorldNormal(v.normal);
		COARSEFX_TRANSFER_LIGHTMAP(OUT, v.texcoord1.xy, v.texcoord2.xy)
		OUT.amb.rgb *= AmbientLight(wNorm);

		#ifndef LIGHTMAP_ON
			OUT.dir = dot(_WorldSpaceLightPos0.xyz, wNorm) * _LightColor0.rgb * color.rgb;
			COARSEFX_TRANSFER_LIGHTING(OUT, mul(_Object2World, v.vertex).xyz)
		#endif

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);

		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		OUT.pos = VertexQuantize(OUT.pos);
		#ifdef _TEXTURED_ON
		InterpTri(uv)
		#endif
		FacetedTri(amb)
		COARSEFX_INTERP_FOG
		COARSEFX_INTERP_LIGHTMAP
		#ifndef LIGHTMAP_ON
			FacetedTri(dir)
			COARSEFX_INTERP_LIGHTING
		#endif
		return OUT;
	}
	
	fixed4 frag(vData IN, bool face : SV_IsFrontFace) : SV_TARGET
	{	
		float4 dither = Dither(IN.pos.xy);
		#ifdef _TEXTURED_ON
		fixed4 tex = tex2D(_MainTex, IN.uv);
		#else
		fixed4 tex = fixed4(1.0, 1.0, 1.0, 1.0);
		#endif
		#ifdef QUEUE_ALPHATEST
			clip(tex.a - IN.amb.a - dither.a * _Blend);
		#endif 
		#ifndef LIGHTMAP_ON
			fixed3 light = face ? IN.dir : -IN.dir;
			light *= light.x < 0.0 ? -_ColorBack.rgb : fixed3(1.0, 1.0, 1.0);
			light *= COARSEFX_LIGHT_ATTENUATION(IN);
			light += COARSEFX_SAMPLE_LIGHTMAP(IN) * IN.amb.rgb;
		#else
			fixed3 light = COARSEFX_SAMPLE_LIGHTMAP(IN) * IN.amb.rgb;
		#endif
		#ifdef QUEUE_TRANSPARENT
			fixed4 outcol = fixed4(tex.rgb * light, tex.a * IN.amb.a);
			outcol.rgb *= outcol.a;
			outcol.a *= _Blend;
		#else
			fixed4 outcol = fixed4(tex.rgb * light, 1.0);
		#endif
		COARSEFX_APPLY_FOG(IN, outcol);
		return Output(outcol, dither);
	}
	ENDCG
}//Pass ForwardBase  
Pass {
	Name "FORWARDADD"
	Tags { "LightMode"="ForwardAdd" }
	Blend One One

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma multi_compile_fwdadd_fullshadows
	#pragma target gl4.1

	#define UNITY_PASS_FORWARDADD

	struct vData
	{
						float4 pos		: SV_POSITION;
	#ifdef _TEXTURED_ON
		noperspective	fixed2 uv		: TEXCOORD0;
	#endif
	#if SPOT || POINT || POINT_COOKIE
		FACETEDINTERP	fixed2  atten	: TEXCOORD1; //TODO GLCORE BUG
	#endif
	#if QUEUE_ALPHATEST || QUEUE_TRANSPARENT
		FACETEDINTERP	fixed4 dir		: TEXCOORD2;
	#else
		FACETEDINTERP	fixed3 dir		: TEXCOORD2;
	#endif
		COARSEFX_LIGHTING_COORDS(3,4)
		COARSEFX_FOG_COORD(5)
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		float2 uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
		#ifdef _TEXTURED_ON
			OUT.uv = uv;
		#endif

		float3 wPos = mul(_Object2World, v.vertex).xyz;
		COARSEFX_TRANSFER_LIGHTING(OUT, wPos);

		fixed3 wNorm = UnityObjectToWorldNormal(v.normal);
		fixed4 color = _Color * v.color * DepthBoundFade(v.vertex);
		#ifndef _TEXTURED_ON
			color *= tex2Dlod(_MainTex, float4(uv, 0.0f, 0.0f));
		#endif
		OUT.dir.rgb = color.rgb;
		OUT.dir.rgb *= dot(normalize(UnityWorldSpaceLightDir(wPos)), wNorm) * _LightColor0.rgb;
		#ifdef QUEUE_ALPHATEST
			OUT.dir.a = 1.0f - color.a;
		#elif QUEUE_TRANSPARENT
			OUT.dir.a = color.a;
		#endif
		#if POINT_COOKIE || POINT || SPOT
			OUT.atten = COARSEFX_LIGHT_ATTEN_VERTEX(OUT, wPos);
		#endif

		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		OUT.pos = VertexQuantize(OUT.pos);
		#ifdef _TEXTURED_ON
			InterpTri(uv)
		#endif

		FacetedTri(dir)
		#if SPOT || POINT || POINT_COOKIE
			FacetedTri(atten)
		#endif
		COARSEFX_INTERP_FOG
		COARSEFX_INTERP_LIGHTING
		return OUT;
	}
	
	fixed4 frag(vData IN, bool face : SV_IsFrontFace) : SV_TARGET
	{
		float4 dither = Dither(IN.pos.xy);
		#ifdef _TEXTURED_ON
		fixed4 tex = tex2D(_MainTex, IN.uv);
		#else
		fixed4 tex = fixed4(1.0, 1.0, 1.0, 1.0);
		#endif
		#ifdef QUEUE_ALPHATEST
			clip(tex.a - IN.dir.a - dither.a * _Blend);
		#endif
		fixed3 light = face ? IN.dir.rgb : -IN.dir.rgb;
		light *= light.x < 0.0 ? -_ColorBack.rgb : fixed3(1.0, 1.0, 1.0);
		light *= COARSEFX_LIGHT_ATTENUATION(IN);
		#if SPOT || POINT || POINT_COOKIE
			light *= saturate(IN.atten.x);
		#endif
		#ifdef QUEUE_TRANSPARENT
			fixed4 outcol = fixed4(tex.rgb * light * tex.a * IN.dir.a, 1.0);
		#else
			fixed4 outcol = fixed4(tex.rgb * light, 1.0);
		#endif
		COARSEFX_APPLY_FOG_COLOR(IN, outcol.rgb, fixed3(0.0, 0.0, 0.0));
		return Output(outcol, dither);
	}
	ENDCG
}//Pass ForwardAdd
Pass {
	Name "VERTEX"
	Tags { "LightMode"="Vertex" }
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma target gl4.1

	struct vData
	{
						float4 pos	: SV_POSITION;
	#ifdef _TEXTURED_ON
		noperspective	fixed2 uv	: TEXCOORD0;
	#endif
	#if QUEUE_ALPHATEST || QUEUE_TRANSPARENT
		FACETEDINTERP	fixed4 dir	: TEXCOORD1;
	#else
		FACETEDINTERP	fixed3 dir	: TEXCOORD1;
	#endif
		COARSEFX_FOG_COORD(2)
	};

	vData vert(appdata_full v)
	{
		vData OUT;

		OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);

		float2 uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex) + _MainTex_Scroll.xy * _Time.x;
		#ifdef _TEXTURED_ON
			OUT.uv = uv;
		#endif

		fixed4 color = _Color * v.color * DepthBoundFade(v.vertex);
		#ifndef _TEXTURED_ON
			color *= tex2Dlod(_MainTex, float4(uv, 0.0f, 0.0f));
		#endif

		OUT.dir.rgb = color.rgb * VertexLightOpaqueMixed(mul(UNITY_MATRIX_MV, v.vertex), mul((float3x3)UNITY_MATRIX_IT_MV, v.normal), UnityObjectToWorldNormal(v.normal).y, _Lighting.xyz);
		#ifdef QUEUE_ALPHATEST
			OUT.dir.a = 1.0 - color.a;
		#elif QUEUE_TRANSPARENT
			OUT.dir.a = color.a;
		#endif
		COARSEFX_TRANSFER_FOG(OUT, OUT.pos);
		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		OUT.pos = VertexQuantize(OUT.pos);
		#ifdef _TEXTURED_ON
			InterpTri(uv)
		#endif
		FacetedTri(dir)
		COARSEFX_INTERP_FOG
		return OUT;
	}
	
	float4 frag(vData IN) : SV_TARGET
	{	
		float4 dither = Dither(IN.pos);
		#ifdef _TEXTURED_ON
		fixed4 tex = tex2D(_MainTex, IN.uv);
		#else
		fixed4 tex = 1.0;
		#endif		
		#ifdef QUEUE_ALPHATEST
			clip(tex.a - IN.dir.a - dither.a * _Blend);
			float4 outcol = fixed4(tex.rgb * IN.dir.rgb, 1.0);
		#elif QUEUE_TRANSPARENT
			float4 outcol = tex * IN.dir;
			outcol.rgb *= outcol.a;
		#else
			float4 outcol = fixed4(tex.rgb * IN.dir.rgb, 1.0);
		#endif
		COARSEFX_APPLY_FOG(IN, outcol);
		return Output(outcol, dither);
	}
	ENDCG
}//Pass Vertex
Pass {
	Name "SHADOWCASTER"
	Tags { "LightMode"="ShadowCaster" }
	Offset 1, 1

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#pragma hull hull
	#pragma domain dom
	#pragma multi_compile_shadowcaster
	#pragma target gl4.1

	struct vData
	{
		V2F_SHADOW_CASTER;
		noperspective	fixed2 uv	: TEXCOORD1;
		FACETEDINTERP	fixed2 alpha	: TEXCOORD2;
	};

	vData vert(appdata_full v)
	{
		vData OUT;
		TRANSFER_SHADOW_CASTER_NORMALOFFSET(OUT)
		OUT.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
		OUT.alpha = 1.0 - _Color.a * v.color.a;
		return OUT;
	}

	HULL_PERSPECTIVE_CORRECT

	vData dom(tDataTri hData, OutputPatch<vData, 3> IN, float3 domPos : SV_DomainLocation)
	{
		vData OUT;
		InterpTri(pos)
		if (abs(UNITY_MATRIX_P._m00) != abs(UNITY_MATRIX_P._m11))
			OUT.pos = VertexQuantize(OUT.pos);
		#ifdef SHADOWS_CUBE
			InterpTri(vec)
		#elif UNITY_MIGHT_NOT_HAVE_DEPTH_TEXTURE
			InterpTri(hpos)
		#endif
		InterpTri(uv)
		InterpTri(alpha)
		return OUT;
	}


	float4 frag(vData IN) : SV_TARGET
	{
		#ifdef QUEUE_ALPHATEST
			clip(tex2D(_MainTex, IN.uv).a - IN.alpha.x - Dither(IN.pos).a * _Blend);
		#endif
		SHADOW_CASTER_FRAGMENT(IN)
	}
	ENDCG
}//Pass ShadowCaster
}//SubShader
}//Shader