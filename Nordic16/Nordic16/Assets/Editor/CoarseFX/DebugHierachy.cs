using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.Linq;
#pragma warning disable 0219, 0414, 0168

public class DebugHierarchy : EditorWindow
{
    [MenuItem("Debug/Debug Hierarchy")]
    private static void OpenWindow()
    {
        EditorWindow.GetWindow<DebugHierarchy>("Debug Hierarchy");
    }

    private Object[] allSceneGameObjects = new Object[] { };
    private string[] allSceneGameObjects_displaystring = new string[]{};


    private void OnHierarchyChange() { RefreshCollection(); }
    private void OnFocus() { RefreshCollection(); }
    private void OnSelectionChange() { RefreshCollection(); }

    private char[] strsep = new char[] { ')', '(' };
    private string buildstr( Object obj )
    {
        string ret;
        if( !obj )
        {
            ret = "<missing>";
        }
        else
        {
            string typestr = obj.GetType().Name;
            ret = "\"" + obj.name + "\" (" + typestr + ")";
            if( string.IsNullOrEmpty(obj.name) && typestr == "Object" )
            {
                string str = obj.ToString();
                if( !string.IsNullOrEmpty(str) )
                {
                    string[] strs = str.Split(strsep);
                    ret += " [" + strs[1] + "]";
                }
                else
                    ret += " []";
            }
        }

        return ret;
    }

    private void RefreshCollection()
    {
        IEnumerable<Object> collection = Resources.FindObjectsOfTypeAll(typeof(Object)) as Object[];
        collection = collection.Where(Filter);
        collection = collection.OrderBy(t => GetName(t));

        allSceneGameObjects = collection.ToArray();

        allSceneGameObjects_displaystring = new string[ allSceneGameObjects.Length ];
        for (int i = 0, n = allSceneGameObjects.Length; i < n; ++i)
            allSceneGameObjects_displaystring[i] = buildstr( allSceneGameObjects[i] );

        Repaint();
    }

    private static string GetName(Object obj)
    {
        return string.IsNullOrEmpty(obj.name) ? obj.GetType().Name : obj.name;
    }

    private bool showHideAndDontSave = true, showDontSave = true, showHideInHierachy = true;
    private Vector2 scrollPosition = new Vector2();
    private static GUIContent content = new GUIContent();
    private void OnGUI()
    {
        Color oldColor = GUI.color;
        GUIStyle style = GUI.skin.label;

        Rect toolbarRect = new Rect(0, 0, position.width, 25);
        GUILayout.BeginArea(toolbarRect, EditorStyles.toolbar);
        {
            GUILayout.BeginHorizontal();
            {
                GUI.color = Color.cyan;
                if (GUILayout.Button("HideAndDontSave", GUILayout.ExpandWidth(false)))
                    showHideAndDontSave = !showHideAndDontSave;

                GUILayout.Space(20f);

                GUI.color = Color.yellow;
                if (GUILayout.Button("DontSave", GUILayout.ExpandWidth(false)))
                    showDontSave = !showDontSave;

                GUILayout.Space(20f);

                GUI.color = Color.magenta;
                if (GUILayout.Button("HideInHierarchy", GUILayout.ExpandWidth(false)))
                    showHideInHierachy = !showHideInHierachy;
            }
            GUILayout.EndHorizontal();
        }
        GUILayout.EndArea();
        GUI.color = oldColor;

        Vector2 size = style.CalcSize(GUIContent.none);
        Rect labelRect = new Rect(10f, 0, position.width - 10f, size.y);

        Rect viewRect = new Rect(0, 0, position.width, size.y * allSceneGameObjects.Length);
        Rect scrollRect = new Rect(0, 20, position.width, position.height - 20);
        scrollPosition = GUI.BeginScrollView(scrollRect, scrollPosition, viewRect);

        for (int i = 0, j = 0, n = allSceneGameObjects.Length; i < n; ++i)
        {
            Object obj = allSceneGameObjects[i];
            string objstr = allSceneGameObjects_displaystring[i];

            labelRect.y = j * labelRect.height;
            content.text = objstr;

            bool show = obj;
            if (show && obj.hideFlags == HideFlags.HideAndDontSave && !showHideAndDontSave)
                show = false;
            if (show && obj.hideFlags == HideFlags.DontSave && !showDontSave)
                show = false;
            if (show && obj.hideFlags == HideFlags.HideInHierarchy && !showHideInHierachy)
                show = false;

            if (obj is GameObject)
                show = false;

            if (obj is Component)
                show = false;

            if (!show)
            {
               // GUI.color = Color.gray;
                //GUI.Button(labelRect, content, style);
                //GUI.color = oldColor;
                continue;
            }

            if(Selection.activeObject == obj)
                GUI.Box(labelRect, GUIContent.none);

            GUI.color = GetColorForGameObject(obj);
            
            if(GUI.Button(labelRect, content, style))
                if(obj is Component)
                    Selection.activeGameObject = (obj as Component).gameObject;
                else
                    Selection.activeObject = obj;

            GUI.color = oldColor;
            j++;
        }

        GUI.EndScrollView();

        GUI.color = oldColor;
    }


    private static Color GetColorForGameObject(Object gobj)
    {
        if ((gobj.hideFlags & HideFlags.HideAndDontSave) == HideFlags.HideAndDontSave)
            return Color.cyan;
        if ((gobj.hideFlags & HideFlags.DontSave) == HideFlags.DontSave)
            return Color.yellow;
        if ((gobj.hideFlags & HideFlags.HideInHierarchy) == HideFlags.HideInHierarchy)
            return Color.magenta;
        else
            return Color.white;
    }

    private static bool Filter(Object obj)
    {
        if (EditorUtility.IsPersistent(obj))
            return false;
        else if (obj is GameObject && (obj as GameObject).transform.parent != null)
            return false;
        else if (obj is Component && (obj as Component).gameObject != null)
            return false;
        else
            return true;
    }
}
