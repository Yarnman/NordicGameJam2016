Shader "CoarseFX/Sprite/Forward" {
Properties {
	_Color ("Color", Color) = (1,1,1,1)
	[TextureFade] _MainTex("Sprite Texture", 2D) = "white" {}
	_FogIntns("Foginess", Range(0,1)) = 1
	[Blending] _Blend ("Blending", Vector) = (1,1,1,1) 
	[LightModeDrawer] _Lighting ("Lighting" , Vector) = (1,1,0,0)

	[HideInInspector] _MainTex_Strength("Sprite Texture Strength", Vector) = (1,0,0,0)
	[HideInInspector] [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("Depth Test", Float) = 4
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc ("Blend Source", Float) = 1 
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst ("Blend Destination", Float) = 0
	[HideInInspector] [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Operator", Float) = 0
	[HideInInspector] [Toggle] _ZWrite ("Depth Write", Float) = 0
}
SubShader { 
	Tags { "Queue"="Transparent" "RenderType"="Transparent" "PreviewType"="Plane" }
UsePass "Hidden/CoarseFX/Sprite/FORWARDBASE"
UsePass "Hidden/CoarseFX/Sprite/FORWARDADD"
UsePass "Hidden/CoarseFX/Sprite/VERTEX"
UsePass "Hidden/CoarseFX/Sprite/SHADOWCASTER"
}//SubShader
}//Shader