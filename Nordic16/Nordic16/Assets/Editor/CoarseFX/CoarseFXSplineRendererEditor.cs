using UnityEngine;
using UnityEditor;
using UnityEditorInternal;
using System.Collections.Generic;

[CustomEditor(typeof(CoarseFXSplineRenderer))]
public class CoarseFXSplineRendererEditor : Editor
{
    CoarseFXSplineRenderer spline;
    List<CoarseFXSplineRenderer.Point> points;
    MaterialEditor matEditor;
    List<Quaternion> rots = new List<Quaternion>(), rotsInv = new List<Quaternion>();
    Tool tool, toolOld;
    PivotMode pMode, pModeOld;
    PivotRotation pRot, pRotOld;
    bool altMode = false;
    bool showList = true;

    ReorderableList list;

    void OnEnable()
    {
        spline = (CoarseFXSplineRenderer)target;
        points = spline.points;
        UpdateWorldRotation();
        if (spline.material)
            matEditor = (MaterialEditor)CreateEditor(spline.material);

        list = new ReorderableList(points, typeof(CoarseFXSplineRenderer.Point), true, true, true, true);
        list.showDefaultBackground = false;
        list.headerHeight = 0f;
        list.elementHeight = 24f;
        list.drawElementBackgroundCallback = (Rect rect, int i, bool active, bool focus) => 
            ReorderableList.defaultBehaviours.DrawElementBackground(new Rect(rect.x, rect.y, rect.width + 6f, rect.height), i, active, focus, true);
        list.drawElementCallback = (Rect rect, int i, bool active, bool focus) =>
        {
            CoarseFXSplineRenderer.Point point = points[i];

            rect.y += 3f;
            rect.height = EditorGUIUtility.singleLineHeight;
            if (points.Count == 0)
                return;

            GUIStyle popopStyle = new GUIStyle(EditorStyles.label);
            popopStyle.font = EditorStyles.miniLabel.font;
            point.type = (CoarseFXSplineRenderer.PointType)EditorGUI.EnumPopup(new Rect(rect.x - 2f, rect.y - 4f, 78f, 12f), point.type, popopStyle);
            point.color = EditorGUI.ColorField(new Rect(rect.x, rect.y + 8f, 80f, 9f), GUIContent.none, point.color, false, true, false, new ColorPickerHDRConfig(0f, 1f, 0f, 1f));

            rect.x = EditorGUIUtility.labelWidth + 14f;
            rect.width = (rect.width - EditorGUIUtility.labelWidth + 16f) * 0.5f;
            point.transform = (Transform)EditorGUI.ObjectField(rect, point.transform, typeof(Transform), true);

            rect.x += rect.width + 5f;
            rect.width *= 0.5f;
            EditorGUI.BeginDisabledGroup(point.type != CoarseFXSplineRenderer.PointType.BezierCorner && point.type != CoarseFXSplineRenderer.PointType.Bezier);
            point.bezierA.transform = (Transform)EditorGUI.ObjectField(rect, point.bezierA.transform, typeof(Transform), true);
            EditorGUI.EndDisabledGroup();

            rect.x += rect.width + 5f;
            EditorGUI.BeginDisabledGroup(point.type != CoarseFXSplineRenderer.PointType.BezierCorner);
            point.bezierB.transform = (Transform)EditorGUI.ObjectField(rect, point.bezierB.transform, typeof(Transform), true);
            EditorGUI.EndDisabledGroup();

            if (GUI.changed)
                EditorUtility.SetDirty(spline);
        };
        list.drawHeaderCallback = (Rect rect) => { };
        list.drawFooterCallback = (Rect rect) =>
        {
            if (GUI.Button(new Rect(rect.x + rect.width - 49f, rect.y - 2f, 16f, 16f), ReorderableList.defaultBehaviours.iconToolbarPlus, GUIStyle.none))
                list.onAddCallback(list);
            EditorGUI.BeginDisabledGroup(list.index < 0);
            if (GUI.Button(new Rect(rect.x + rect.width - 24f, rect.y - 2f, 16f, 16f), ReorderableList.defaultBehaviours.iconToolbarMinus, GUIStyle.none))
                list.onRemoveCallback(list);
            //ReorderableList.defaultBehaviours.DoRemoveButton(list);
            EditorGUI.EndDisabledGroup();
        };
        list.onChangedCallback = (ReorderableList l) =>
        {
            //TODO: Undo
            EditorUtility.SetDirty(spline);
        };
        list.onAddCallback = (ReorderableList l) =>
        {
            CoarseFXSplineRenderer.Point newPoint = new CoarseFXSplineRenderer.Point();
            newPoint.transform = new GameObject("Point " + l.count).transform;
            points.Add(newPoint);

            newPoint.transform.SetParent(spline.transform, false);

            newPoint.bezierA.transform = new GameObject("Bezier A").transform;
            newPoint.bezierA.transform.SetParent(newPoint.transform, false);

            newPoint.bezierB.transform = new GameObject("Bezier B").transform;
            newPoint.bezierB.transform.SetParent(newPoint.transform, false);
        };
        list.onRemoveCallback = (ReorderableList l) =>
        {
            foreach (Transform c in points[l.index].bezierA.transform.GetComponentsInChildren<Transform>(true))
                if (c == points[l.index].bezierA.transform)
                    continue;
                else
                    c.parent = points[l.index].transform.parent;
            DestroyImmediate(points[l.index].bezierA.transform.gameObject);

            foreach (Transform c in points[l.index].bezierB.transform.GetComponentsInChildren<Transform>(true))
                if (c == points[l.index].bezierB.transform)
                    continue;
                else
                    c.parent = points[l.index].transform.parent;
            DestroyImmediate(points[l.index].bezierB.transform.gameObject);

            foreach (Transform c in points[l.index].transform.GetComponentsInChildren<Transform>(true))
                if (c == points[l.index].transform)
                    continue;
                else
                    c.parent = points[l.index].transform.parent;
            DestroyImmediate(points[l.index].transform.gameObject);

            points.RemoveAt(l.index);
        };
        list.onSelectCallback = (ReorderableList l) =>
        {
            if (points[l.index].transform) EditorGUIUtility.PingObject(points[l.index].transform);
        };
    }

    void OnDisable()
    {
        if (matEditor)
            DestroyImmediate(matEditor);
    }

    public override void OnInspectorGUI()
    {
        EditorGUI.BeginChangeCheck();
        DrawDefaultInspector();
        if (!spline.material)
        {
            if (matEditor)
                DestroyImmediate(matEditor);
            return;
        }
        if (EditorGUI.EndChangeCheck())
        {
            if (matEditor)
                DestroyImmediate(matEditor);
            matEditor = (MaterialEditor)CreateEditor(spline.material);
        }
        showList = EditorGUILayout.Foldout(showList, "Points: " + points.Count);
        if (showList)
            list.DoLayoutList();

        matEditor.DrawHeader();
        using (new EditorGUI.DisabledGroupScope(!AssetDatabase.GetAssetPath(spline.material).StartsWith("Assets")))
            matEditor.OnInspectorGUI();
    }

    public void OnSceneGUI()
    {
        Tools.hidden = true;
        tool = Tools.current;
        pMode = Tools.pivotMode;
        pRot = Tools.pivotRotation;
        //bool center = pMode == PivotMode.Center;
        bool world = pRot == PivotRotation.Global;

        if (tool != toolOld || pMode != pModeOld || pRot != pRotOld)
            UpdateWorldRotation();

        if (Event.current.type == EventType.KeyDown && Event.current.keyCode == KeyCode.C)
            altMode = !altMode;

        Undo.RecordObjects(spline.transform.GetComponentsInChildren<Transform>(), "Transform spline points"); //TODO: This is wonky
        for (int i = 0; i < points.Count; i++)
        {
            Vector3 pos = points[i].position;
            Quaternion rot = points[i].rotation;
            if (tool == Tool.Move)
            {
                pos = Handles.PositionHandle(points[i].position, world ? Quaternion.identity : rot);
                if (GUI.changed)
                {
                    points[i].position = pos;
                    GUI.changed = false;
                    EditorUtility.SetDirty(spline);
                }
            }
            else if (tool == Tool.Rotate)
            {
                rot = Handles.RotationHandle(rot * rotsInv[i], pos) * rots[i];
                if (GUI.changed)
                {
                    points[i].rotation = rot;
                    GUI.changed = false;
                    EditorUtility.SetDirty(spline);
                }
            }
            if (altMode)
            {
                Vector3 bezierA = Handles.PositionHandle(points[i].bezierA.position, Quaternion.identity);
                if (GUI.changed)
                {
                    points[i].bezierA.position = bezierA;
                    GUI.changed = false;
                    EditorUtility.SetDirty(spline);
                }
                Vector3 bezierB = Handles.PositionHandle(points[i].bezierB.position, Quaternion.identity); //TODO: Use parent rotation, or actual rotation in case of transform
                if (GUI.changed)
                {
                    points[i].bezierB.position = bezierB;
                    GUI.changed = false;
                    EditorUtility.SetDirty(spline);
                }
            }
        }
    }

    void UpdateWorldRotation()
    {
        rots.Clear();
        rotsInv.Clear();
        points.ForEach(x => rots.Add(pRot == PivotRotation.Global ? x.rotation : Quaternion.identity));
        rots.ForEach(x => rotsInv.Add(pRot == PivotRotation.Global ? Quaternion.Inverse(x) : Quaternion.identity));
        toolOld = tool;
        pRotOld = pRot;
        pModeOld = pMode;
    }

}