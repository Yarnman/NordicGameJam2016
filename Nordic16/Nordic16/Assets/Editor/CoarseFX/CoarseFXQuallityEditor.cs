using UnityEngine;
using UnityEditor;
using System.Collections.Generic;

public class CoarseFXQualityEditor : EditorWindow
{
    [MenuItem("Window/CoarseFX/Scene Settings")]
    static void Init()
    {
        CoarseFXQualityEditor window = GetWindow<CoarseFXQualityEditor>("CoarseFX");
        window.titleContent.image = EditorGUIUtility.IconContent("LightmapEditor.WindowTitle").image;
        window.Show();
        window.minSize = new Vector2(300, 400);
        window.wantsMouseMove = true;
    }

    [MenuItem("Edit/Project Settings/CoarseFX")]
    static void Init2()
    {

    }

    Rect rect;

    void OnGUI()
    {
        if (Event.current.type == EventType.Layout)
            return;

        Texture2D ditherPattern = CoarseFXQuality.ditherTex;
        Vector4 colorPrecision = CoarseFXQuality.colQuant;
        Vector2 vertexPrecision = CoarseFXQuality.vertQuant;
        Vector2 perspCorr = CoarseFXQuality.perspCorr;
        CoarseFXQuality.Resolution resolution = CoarseFXQuality.resolution;

        bool posterize = CoarseFXQuality.posterize;
        bool dither = CoarseFXQuality.dither;
        bool wobble = CoarseFXQuality.wobble;
        bool perspectiveCorrection = CoarseFXQuality.perspectiveCorrection;
        bool limitFrameRate = CoarseFXQuality.limitFrameRate;

        float width = EditorGUIUtility.currentViewWidth - 10f, height = EditorGUIUtility.singleLineHeight, marginLeft = 4f, marginTop = 5f;
        float space = EditorGUIUtility.singleLineHeight + EditorGUIUtility.standardVerticalSpacing;
        rect = new Rect(marginLeft, marginTop, width, height);
        EditorGUIUtility.labelWidth = 90;

        if (BeginModule("Color Posterize", ref posterize))
        {
            colorPrecision.x = EditorGUI.Slider(rect, "Red", colorPrecision.x, 1f, 255f);
            rect.y += space;
            colorPrecision.y = EditorGUI.Slider(rect, "Green", colorPrecision.y, 1f, 255f);
            rect.y += space;
            colorPrecision.z = EditorGUI.Slider(rect, "Blue", colorPrecision.z, 1f, 255f);
            rect.y += space;
            colorPrecision.w = EditorGUI.Slider(rect, "Alpha", colorPrecision.w, 1f, 255f);
            rect.y += space;
        }
        EndModule();
        if (BeginModule("Color Dither", ref dither))
        {
            ditherPattern = (Texture2D)EditorGUI.ObjectField(rect, "Pattern", ditherPattern, typeof(Texture2D), false);
            rect.y += space;
            EditorGUI.Slider(rect, "Amount", 0.5f, 0f, 1f);
            rect.y += space;
        }
        EndModule();
        if (BeginModule("Vertex Wobble", ref wobble))
        {
            vertexPrecision.x = EditorGUI.Slider(rect, "Horizontal", vertexPrecision.x, 1f, 256f);
            rect.y += space;
            vertexPrecision.y = EditorGUI.Slider(rect, "Vertical", vertexPrecision.y, 1f, 256f);
            rect.y += space;
        }
        EndModule();
        if (BeginModule("Perspective Correction", ref perspectiveCorrection))
        {
            perspCorr.x = EditorGUI.Slider(rect, "Slope", perspCorr.x, 0f, 1f);
            rect.y += space;
            perspCorr.y = EditorGUI.Slider(rect, "Bias", perspCorr.y, 0f, 1f);
            rect.y += space;
        }
        EndModule();
        if (BeginModule("Force Resolution", ref resolution.force))
        {
            float smallWidth = rect.width = width / 2f - 12f, hSpace = smallWidth + 4f;
            EditorGUI.BeginDisabledGroup(resolution.lockPixelAspect);
            if (resolution.lockPixelAspect)
                EditorGUI.IntField(rect, "Width", resolution.width);
            else
                resolution.widthLocked = EditorGUI.IntField(rect, "Width", resolution.widthLocked);
            EditorGUI.EndDisabledGroup();
            rect.x += hSpace;
            EditorGUI.BeginDisabledGroup(!resolution.lockImageAspect);
            if (resolution.lockImageAspect)
                resolution.imageAspectLocked = Mathf.Max(0.1f, EditorGUI.FloatField(rect, "Image Aspect", resolution.imageAspectLocked));
            else
                EditorGUI.FloatField(rect, "Image Aspect", resolution.imageAspect);
            EditorGUI.EndDisabledGroup();
            rect.x += hSpace;
            resolution.lockImageAspect = Lock(resolution.lockImageAspect);

            rect = new Rect(marginLeft, rect.y + space, smallWidth, height);
            resolution.heightLocked = EditorGUI.IntField(rect, "Height", resolution.heightLocked);
            rect.x += hSpace;
            EditorGUI.BeginDisabledGroup(!resolution.lockPixelAspect);
            if (resolution.lockPixelAspect)
                resolution.pixelAspectLocked = Mathf.Max(0.1f, EditorGUI.FloatField(rect, "Pixel Aspect", resolution.pixelAspectLocked));
            else
                EditorGUI.FloatField(rect, "Pixel Aspect", resolution.pixelAspect);
            EditorGUI.EndDisabledGroup();
            rect.x += hSpace;
            resolution.lockPixelAspect = Lock(resolution.lockPixelAspect);

            rect = new Rect(marginLeft, rect.y + space, smallWidth, height);
            resolution.progressive = EditorGUI.Toggle(rect, "Progressive", resolution.progressive);
            rect.x += hSpace;
            rect.width = width - smallWidth - 4f;
            resolution.antialias = EditorGUI.Toggle(rect, "Antialias", resolution.antialias);
            rect = new Rect(marginLeft, rect.y + space, width, height);
            resolution.cubemap = EditorGUI.Toggle(new Rect(marginLeft, rect.y, smallWidth, height), "Cubemap", resolution.cubemap);
            resolution.cuberes = EditorGUI.IntField(new Rect(marginLeft + hSpace, rect.y, smallWidth, height), new GUIContent("Resolution"), resolution.cuberes);
            rect.y += space;
        }
        if (BeginModule("Low Frame Rate", ref limitFrameRate))
            CoarseFXQuality.targetFrameRate = EditorGUI.IntField(rect, "FPS", CoarseFXQuality.targetFrameRate);

        if (GUI.changed)
        {
            CoarseFXQuality.ditherTex = ditherPattern;
            CoarseFXQuality.colQuant = colorPrecision;
            CoarseFXQuality.vertQuant = vertexPrecision;
            CoarseFXQuality.perspCorr = perspCorr;
            CoarseFXQuality.resolution = resolution;

            CoarseFXQuality.posterize = posterize;
            CoarseFXQuality.dither = dither;
            CoarseFXQuality.wobble = wobble;
            CoarseFXQuality.perspectiveCorrection = perspectiveCorrection;
            CoarseFXQuality.limitFrameRate = limitFrameRate;

            CoarseFXQuality.UpdateProperties();
            foreach (CoarseFXFrontBuffer buf in FindObjectsOfType<CoarseFXFrontBuffer>())
                buf.Reinitialize();

            CoarseFXQuality.SetDirty();
        }
        if (Event.current.isMouse)
            Repaint();
    }

    Dictionary<string, bool> showDictionary = new Dictionary<string, bool>();

    bool BeginModule(string label, ref bool enabled)
    {
        if (!showDictionary.ContainsKey(label))
            showDictionary.Add(label, true);

        GUIStyle styleFoldout = "ShurikenModuleTitle", styleToggle = "ShurikenCheckMark";
        Rect rectFoldout = new Rect(rect.x + 16, rect.y, rect.width - 16, 16), rectToggle = new Rect(rect.x + 2, rect.y + 1, 14, 15);
        int idFoldout = GUIUtility.GetControlID(FocusType.Passive), idToggle = GUIUtility.GetControlID(FocusType.Passive);

        switch (Event.current.GetTypeForControl(idFoldout))
        {
            case EventType.MouseDown:
                if (!rectFoldout.Contains(Event.current.mousePosition) || Event.current.button != 0)
                    break;
                GUIUtility.hotControl = idFoldout;
                Event.current.Use();
                break;
            case EventType.MouseUp:
                if (GUIUtility.hotControl != idFoldout)
                    break;
                if (rect.Contains(Event.current.mousePosition))
                    showDictionary[label] = !showDictionary[label];
                GUIUtility.hotControl = 0;
                Event.current.Use();
                break;
            case EventType.Repaint:
                styleFoldout.Draw(rect, label, rect.Contains(Event.current.mousePosition), GUIUtility.hotControl == idFoldout, enabled, false);
                break;
        }
        switch (Event.current.GetTypeForControl(idToggle))
        {
            case EventType.MouseDown:
                if (!rectToggle.Contains(Event.current.mousePosition) || Event.current.button != 0)
                    break;
                GUIUtility.hotControl = idToggle;
                Event.current.Use();
                break;
            case EventType.MouseUp:
                if (GUIUtility.hotControl != idToggle)
                    break;
                if (rectToggle.Contains(Event.current.mousePosition))
                {
                    enabled = !enabled;
                    GUI.changed = true;
                }
                GUIUtility.hotControl = 0;
                Event.current.Use();
                break;
            case EventType.Repaint:
                styleToggle.Draw(rectToggle, false, false, enabled, false);
                break;
        }

        rect.y += showDictionary[label] ? 18f : 16f;
        EditorGUI.BeginDisabledGroup(!enabled);
        return showDictionary[label];
    }

    void EndModule()
    {
        EditorGUI.EndDisabledGroup();
    }

    bool Lock(bool locked)
    {
        GUIStyle style = "IN LockButton";

        rect.width = 15f;
        int id = GUIUtility.GetControlID(FocusType.Passive);

        switch (Event.current.GetTypeForControl(id))
        {
            case EventType.MouseDown:
                if (!rect.Contains(Event.current.mousePosition) || Event.current.button != 0)
                    break;
                GUIUtility.hotControl = id;
                Event.current.Use();
                break;
            case EventType.MouseUp:
                if (GUIUtility.hotControl != id)
                    break;
                if (rect.Contains(Event.current.mousePosition))
                {
                    locked = !locked;
                    GUI.changed = true;
                }
                GUIUtility.hotControl = 0;
                Event.current.Use();
                break;
            case EventType.Repaint:
                style.Draw(new Rect(rect.x, rect.y + 1f, rect.width, rect.height), rect.Contains(Event.current.mousePosition), GUIUtility.hotControl == id, locked, false);
                break;
        }
        return locked;
    }
}