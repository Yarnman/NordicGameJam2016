using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

public class QueueDrawer : MaterialPropertyDrawer
{
    public enum QueueEnum
    {
        Default = -1,
        Geometry = 2000,
        AlphaTest = 2450,
        Transparent = 3000,
        Overlay = 4000
    }

    public override void OnGUI(Rect rect, MaterialProperty prop, string label, MaterialEditor editor)
    {
        EditorGUI.BeginChangeCheck();
        Material material = editor.target as Material;
        EditorGUI.showMixedValue = prop.hasMixedValue;
        QueueEnum queueEnum = (QueueEnum)EditorGUI.EnumPopup(rect, label, (QueueEnum)material.renderQueue);
        if (!EditorGUI.EndChangeCheck())
            return;

        List<string> keywords = new List<string>(material.shaderKeywords);
        keywords.RemoveAll(key => key.StartsWith("QUEUE_"));
        keywords.Add("QUEUE_" + queueEnum.ToString().ToUpper());
        material.shaderKeywords = keywords.ToArray();

        material.renderQueue = (int)queueEnum;

        prop.floatValue = (float)queueEnum;

        EditorGUI.showMixedValue = false;
        EditorUtility.SetDirty(material);
    }
}

public class LightModeDrawer : MaterialPropertyDrawer
{
    public enum LightMode
    {
        Unlit = 0,
        Vertex = 1,
        Forward = 2
    }

    public override void OnGUI(Rect rect, MaterialProperty prop, string label, MaterialEditor editor)
    {
        EditorGUI.BeginChangeCheck();
        Material material = editor.target as Material;
        EditorGUI.showMixedValue = prop.hasMixedValue;
        EditorGUIUtility.labelWidth = Mathf.Max(EditorGUIUtility.labelWidth / 2.23f, 120f);

        Rect enumRect = new Rect(rect.x, rect.y, EditorGUIUtility.fieldWidth, rect.height);
        Rect labelRect = new Rect(enumRect.xMax + 5f, rect.y, EditorGUIUtility.labelWidth - enumRect.width - 5f, rect.height);
        Rect xFadeRect = new Rect(labelRect.xMax, rect.y, (rect.width - EditorGUIUtility.fieldWidth - EditorGUIUtility.labelWidth) * 0.5f - 5f, rect.height);
        Rect fadeRect = new Rect(xFadeRect.xMax + 5f, rect.y, xFadeRect.width, rect.height);
        Rect xFloatRect = new Rect(fadeRect.xMax + 5f, rect.y, EditorGUIUtility.fieldWidth * 0.5f - 2.5f, rect.height);
        Rect floatRect = new Rect(xFloatRect.xMax + 5f, rect.y, xFloatRect.width, rect.height);

        bool vertex = (LightMode)EditorGUI.EnumPopup(enumRect, material.shader.name.EndsWith("/Vertex") ? LightMode.Vertex : LightMode.Forward) == LightMode.Vertex;
        GUI.Label(labelRect, label);
        Vector4 vec = prop.vectorValue;
        vec.w = GUI.HorizontalSlider(xFadeRect, vec.w, -1f, 1f);
        vec.z = 1f - GUI.HorizontalSlider(fadeRect, 1f - vec.z, 0f, 1f);
        vec.w = Mathf.Clamp(EditorGUI.FloatField(xFloatRect, vec.w), -1f, 1f);
        vec.z = Mathf.Clamp01(1f - EditorGUI.FloatField(floatRect, 1f - vec.z));

        vec.x = Mathf.Clamp01(1f + vec.w) * (1f - vec.z);
        vec.y = Mathf.Clamp01(1f - vec.w) * (1f - vec.z);

        if (!EditorGUI.EndChangeCheck())
            return;

        prop.vectorValue = vec;
        if (material.shader.name.EndsWith("/Vertex") != vertex)
            material.shader = Shader.Find(material.shader.name.Remove(material.shader.name.Length - (vertex ? 7 : 6)) + (vertex ? "Vertex" : "Forward"));

        EditorGUI.showMixedValue = false;
        EditorUtility.SetDirty(material);
    }
}

public class Blending : MaterialPropertyDrawer
{
    public enum BlendingEnum
    {
        Opaque = 0,
        Cutout = 1,
        Blended = 2,

        Darken = 3,
        Multiply = 4,
        Burn = 5,

        Lighten = 6,
        Screen = 7,
        Dodge = 8,

        Invert = 9
    }

    public struct BlendState
    {
        public BlendMode src;
        public BlendMode dst;
        public BlendOp op;
        public bool zWrite;
        public int queue;

        public BlendState(BlendMode src, BlendMode dst, BlendOp op = BlendOp.Add, bool zWrite = false, int queue = 3000)
        {
            this.src = src;
            this.dst = dst;
            this.op = op;
            this.zWrite = zWrite;
            this.queue = queue;
        }
    }

    BlendState opaque = new BlendState(BlendMode.One, BlendMode.Zero, BlendOp.Add, true, 2000);
    BlendState cutout = new BlendState(BlendMode.One, BlendMode.Zero, BlendOp.Add, true, 2450);
    BlendState blended = new BlendState(BlendMode.One, BlendMode.OneMinusSrcAlpha);

    BlendState darken = new BlendState(BlendMode.One, BlendMode.One, BlendOp.Min);
    BlendState multiply = new BlendState(BlendMode.Zero, BlendMode.SrcColor);
    BlendState burn = new BlendState(BlendMode.One, BlendMode.One, BlendOp.ReverseSubtract);

    BlendState lighten = new BlendState(BlendMode.One, BlendMode.One, BlendOp.Max);
    BlendState screen = new BlendState(BlendMode.One, BlendMode.OneMinusSrcColor);
    BlendState dodge = new BlendState(BlendMode.One, BlendMode.One);

    BlendState invert = new BlendState(BlendMode.OneMinusDstColor, BlendMode.OneMinusSrcAlpha);
    
    BlendState Mode2State(BlendingEnum mode)
    {
        switch (mode)
        {
            case BlendingEnum.Opaque:
                return opaque;
            case BlendingEnum.Cutout:
                return cutout;
            case BlendingEnum.Blended:
                return blended;

            case BlendingEnum.Darken:
                return darken;
            case BlendingEnum.Multiply:
                return multiply;
            case BlendingEnum.Burn:
                return burn;

            case BlendingEnum.Lighten:
                return lighten;
            case BlendingEnum.Screen:
                return screen;
            case BlendingEnum.Dodge:
                return dodge;

            case BlendingEnum.Invert:
                return invert;

            default:
                return opaque;
        }
    }

    BlendingEnum State2Mode(BlendState state)
    {
        if (state.Equals(opaque))
            return BlendingEnum.Opaque;
        else if (state.Equals(cutout))
            return BlendingEnum.Cutout;
        else if (state.Equals(blended))
            return BlendingEnum.Blended;

        else if (state.Equals(darken))
            return BlendingEnum.Darken;
        else if (state.Equals(multiply))
            return BlendingEnum.Multiply;
        else if (state.Equals(burn))
            return BlendingEnum.Burn;

        else if (state.Equals(lighten))
            return BlendingEnum.Lighten;
        else if (state.Equals(screen))
            return BlendingEnum.Screen;
        else if (state.Equals(dodge))
            return BlendingEnum.Dodge;

        else if (state.Equals(invert))
            return BlendingEnum.Invert;

        EditorGUI.showMixedValue = true;
        return 0;
    }

    public override void OnGUI(Rect rect, MaterialProperty prop, string label, MaterialEditor editor)
    {
        EditorGUI.BeginChangeCheck();
        Material material = editor.target as Material;
        EditorGUIUtility.labelWidth = Mathf.Max(EditorGUIUtility.labelWidth / 2.23f, 120f);

        Rect enumRect = new Rect(rect.x, rect.y, EditorGUIUtility.fieldWidth, rect.height);
        Rect labelRect = new Rect(enumRect.xMax + 5f, rect.y, EditorGUIUtility.labelWidth - enumRect.width - 5f, rect.height);
        Rect sliderRect = MaterialEditor.GetFlexibleRectBetweenLabelAndField(rect);
        Rect floatRect = MaterialEditor.GetRightAlignedFieldRect(rect);

        BlendState state = new BlendState(
            (BlendMode)material.GetFloat("_BlendSrc"),
            (BlendMode)material.GetFloat("_BlendDst"),
            (BlendOp)material.GetFloat("_BlendOp"),
            material.GetFloat("_ZWrite") == 1f,
            material.renderQueue);

        BlendingEnum mode = State2Mode(state);
        BlendingEnum modeNew = (BlendingEnum)EditorGUI.EnumPopup(enumRect, mode);
        EditorGUI.showMixedValue = prop.hasMixedValue;
        EditorGUI.PrefixLabel(labelRect, new GUIContent(label));

        if (prop.type == MaterialProperty.PropType.Float)
        {
            prop.floatValue = GUI.HorizontalSlider(sliderRect, prop.floatValue, 0f, 1f);
            prop.floatValue = Mathf.Clamp01(EditorGUI.FloatField(floatRect, prop.floatValue));
        }
        else
        {
            Vector4 vec = prop.vectorValue;
            float fill = vec.x;
            fill = GUI.HorizontalSlider(sliderRect, fill, 0f, 1f);
            fill = Mathf.Clamp01(EditorGUI.FloatField(floatRect, fill));
            bool darkMul = modeNew == BlendingEnum.Darken || modeNew == BlendingEnum.Multiply;
            bool burn = modeNew == BlendingEnum.Burn;

            vec.x = fill;
            vec.y = burn ? -1f : darkMul ? -1f : 1f;
            vec.z = burn ? 0f : darkMul ? 1f : 0f;
            vec.w = burn ? 1f : darkMul ? -1 : 0f;
            prop.vectorValue = vec;
        }

        if (!EditorGUI.EndChangeCheck())
            return;

        if (mode != modeNew)
        {
            BlendState stateNew = Mode2State(modeNew);
            material.SetFloat("_BlendSrc", (float)stateNew.src);
            material.SetFloat("_BlendDst", (float)stateNew.dst);
            material.SetFloat("_BlendOp", (float)stateNew.op);
            material.SetFloat("_ZWrite", stateNew.zWrite ? 1f : 0f);
            material.renderQueue = stateNew.queue;

            List<string> keywords = new List<string>(material.shaderKeywords);
            keywords.RemoveAll(key => key.StartsWith("QUEUE_"));
            string queueKey = modeNew == BlendingEnum.Opaque ? "GEOMETRY" : modeNew == BlendingEnum.Cutout ? "ALPHATEST" : "TRANSPARENT";
            material.shaderKeywords = keywords.ToArray();
            material.EnableKeyword("QUEUE_" + queueKey);
        }

        EditorGUI.showMixedValue = false;
        EditorUtility.SetDirty(material);
    }
}

public class TextureFade : MaterialPropertyDrawer
{
     float range;

     public TextureFade()
     {
         range = 1f;
     }
     
     public TextureFade(float argument)
     {
         range = argument;
     }

    public override void OnGUI(Rect rect, MaterialProperty prop, string label, MaterialEditor editor)
    {
        EditorGUI.BeginChangeCheck();
        Material material = editor.target as Material;
        EditorGUI.showMixedValue = prop.hasMixedValue;
        EditorGUIUtility.labelWidth = Mathf.Max(EditorGUIUtility.labelWidth / 2.23f, 120f);
        editor.DefaultShaderProperty(rect, prop, label);
        Vector2 fadeVec = material.GetVector(prop.name + "_Strength");
        fadeVec.x = GUI.HorizontalSlider(MaterialEditor.GetFlexibleRectBetweenLabelAndField(rect), fadeVec.x, 0f, range);
        fadeVec.y = 1f - fadeVec.x;

        GUILayout.Space(54f);

        if (!EditorGUI.EndChangeCheck())
            return;

        material.SetVector(prop.name + "_Strength", fadeVec);

        EditorGUI.showMixedValue = false;
        EditorUtility.SetDirty(material);
    }
}

public class TextureScroll : MaterialPropertyDrawer
{
    public override void OnGUI(Rect rect, MaterialProperty prop, string label, MaterialEditor editor)
    {
        EditorGUI.BeginChangeCheck();
        Material material = editor.target as Material;
        EditorGUI.showMixedValue = prop.hasMixedValue;
        EditorGUIUtility.labelWidth = Mathf.Max(EditorGUIUtility.labelWidth / 2.23f, 120f);

        Rect scaleOffsetRect = editor.GetTexturePropertyCustomArea(rect);
        Rect scrollRect = new Rect(scaleOffsetRect.x + 65f, scaleOffsetRect.y, scaleOffsetRect.width - 65f, scaleOffsetRect.height);

        editor.DefaultShaderProperty(rect, prop, label);

        EditorGUI.PrefixLabel(scaleOffsetRect, new GUIContent("Scroll"));
        Vector2 scrollVec = material.GetVector(prop.name + "_Scroll");
        scrollVec = EditorGUI.Vector2Field(scrollRect, GUIContent.none, scrollVec);

        GUILayout.Space(54f);

        if (!EditorGUI.EndChangeCheck())
            return;

        material.SetVector(prop.name + "_Scroll", scrollVec);

        EditorGUI.showMixedValue = false;
        EditorUtility.SetDirty(material);
    }
}

public class TextureFadeScroll : MaterialPropertyDrawer
{
    float range;

    public TextureFadeScroll()
    {
        range = 1f;
    }

    public TextureFadeScroll(float argument)
    {
        range = argument;
    }

    public override void OnGUI(Rect rect, MaterialProperty prop, string label, MaterialEditor editor)
    {
        EditorGUI.BeginChangeCheck();
        Material material = editor.target as Material;
        EditorGUI.showMixedValue = prop.hasMixedValue;
        EditorGUIUtility.labelWidth = Mathf.Max(EditorGUIUtility.labelWidth / 2.23f, 120f);

        Rect scaleOffsetRect = editor.GetTexturePropertyCustomArea(rect);
        Rect scrollRect = new Rect(scaleOffsetRect.x + 65f, scaleOffsetRect.y, scaleOffsetRect.width - 65f, scaleOffsetRect.height);

        editor.DefaultShaderProperty(rect, prop, label);
        Vector2 fadeVec = material.GetVector(prop.name + "_Strength");
        fadeVec.x = GUI.HorizontalSlider(MaterialEditor.GetFlexibleRectBetweenLabelAndField(rect), fadeVec.x, 0f, range);
        fadeVec.y = 1f - fadeVec.x;

        EditorGUI.PrefixLabel(scaleOffsetRect, new GUIContent("Scroll"));
        Vector2 scrollVec = material.GetVector(prop.name + "_Scroll");
        scrollVec = EditorGUI.Vector2Field(scrollRect, GUIContent.none, scrollVec);

        GUILayout.Space(54f);

        if (!EditorGUI.EndChangeCheck())
            return;

        material.SetVector(prop.name + "_Strength", fadeVec);
        material.SetVector(prop.name + "_Scroll", scrollVec);

        EditorGUI.showMixedValue = false;
        EditorUtility.SetDirty(material);
    }
}

public class AdvancedTab : MaterialPropertyDrawer
{
    public override void OnGUI(Rect rect, MaterialProperty prop, string label, MaterialEditor editor)
    {
        EditorGUI.BeginChangeCheck();
        Material material = editor.target as Material;
        EditorGUI.showMixedValue = prop.hasMixedValue;
        EditorGUIUtility.labelWidth = Mathf.Max(EditorGUIUtility.labelWidth / 2.23f, 120f);
        
        bool show = EditorGUI.Foldout(rect, prop.floatValue > 0.5f, prop.displayName);

        if (EditorGUI.EndChangeCheck())
        {
            material.SetFloat(prop.name, show ? 1f : 0f);
            EditorGUI.showMixedValue = false;
            EditorUtility.SetDirty(material);
        }

        //if (!show)
        //    Event.current.Use();

    }
}