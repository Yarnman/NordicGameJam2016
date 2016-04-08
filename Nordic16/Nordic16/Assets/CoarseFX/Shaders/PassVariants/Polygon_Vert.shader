Shader "CoarseFX/Polygon/Vertex" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
	_ColorBack ("Back Color", Color) = (0,0,0,0)
	[TextureFadeScroll] _MainTex("Main Texture", 2D) = "white" {}
	_FogIntns("Fog Intensity", Range(0,1)) = 1
	[Space] [Toggle] _Gouraud("Gouraud Shading", Float) = 1
	[Toggle] _Textured("Textured", Float) = 1
	[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Face Cull Mode", Float) = 0
	[Blending] _Blend ("Blending", Float) = 1
	[LightModeDrawer] _Lighting ("Lighting" , Vector) = (1,1,0,0) 

	[HideInInspector] _MainTex_Strength("Sprite Texture Strength", Vector) = (1,0,0,0)
	[HideInInspector] _MainTex_Scroll("Sprite Texture Scroll", Vector) = (1,0,0,0)
	[HideInInspector] [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Depth Test", Float) = 4
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1 
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 0
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operator", Float) = 0
	[HideInInspector] [Toggle] _ZWrite ("Depth Write", Float) = 0
}
SubShader {  
	Tags { "RenderType"="Opaque" }
UsePass "Hidden/CoarseFX/Polygon/VERTEX"
UsePass "Hidden/CoarseFX/Polygon/SHADOWCASTER"
UsePass "Standard/META"
}//SubShader
}//Shader