using UnityEngine;
using System.Collections.Generic;

[ExecuteInEditMode]
public class CoarseFXSplineRenderer : MonoBehaviour
{
    public enum PointType
    {
        Corner = 0,
        Bezier = 1,
        BezierCorner = 2,
        Smooth = 3
    };
    [System.Serializable]
    public class Point
    {
        public PointType type;

        public bool useTransform;
        public Transform transform;

        [SerializeField] Vector3 m_position;
        public Vector3 position
        {
            get
            {
                return useTransform && transform ? transform.position : m_position;
            }
            set
            {
                if (useTransform && transform)
                    transform.position = value;
                m_position = value;
            }
        }

        [SerializeField]
        Quaternion m_rotation; //TODO: if there's no transform, return this
        public Quaternion rotation
        {
            get
            {
                if (useTransform && transform)
                    return transform.rotation;

                if (type == PointType.Bezier)
                    return Quaternion.LookRotation(bezierB.position - position);
                else if (type == PointType.BezierCorner)
                    return Quaternion.LookRotation(bezierB.position - bezierA.position, (bezierA.position + bezierB.position) * 0.5f - position);

                return Quaternion.identity; //TODO: Get smooth/corner rotation
            }
            set
            {
                if (useTransform && transform)
                    transform.rotation = value;
                m_rotation = value; //TODO: Set rotation of potential children instead
            }
        }

        public Color color = Color.white;

        public Bezier bezierA = new Bezier();
        public Bezier bezierB = new Bezier();

        public bool showBezier; //TODO: Move this to editor script with... Idunno, a dictionary?
    }
    [System.Serializable]
    public class Bezier
    {
        public bool useTransform;
        public Transform transform;

        [SerializeField] Vector3 m_position;
        public Vector3 position
        {
            get
            {
                return useTransform && transform ? transform.position : m_position;
            }
            set
            {
                if (useTransform && transform)
                    transform.position = value;
                m_position = value;
            }
        }
    }
    public UnityEngine.Rendering.ShadowCastingMode castShadows = UnityEngine.Rendering.ShadowCastingMode.On;
    public bool recieveShadows = true;
    public Material material;
    [HideInInspector, SerializeField]
    public List<Point> points = new List<Point>();

    Mesh mesh;

    void OnEnable()
    {
        mesh = new Mesh();
        mesh.MarkDynamic();
        mesh.subMeshCount = 1;
        mesh.hideFlags = HideFlags.DontSave;
    }

    void OnDisable()
    {
        DestroyImmediate(mesh);
    }

    void Update()
    {
        if (points.Count < 2)
            return;

        UpdateMesh();
        Graphics.DrawMesh(mesh, Matrix4x4.identity, material, gameObject.layer, null, 0, null, castShadows, recieveShadows);
    }

    void UpdateMesh()
    {
        mesh.Clear();
        int linePoints = points.Count * 2 - 2;
        Vector3[] verts = new Vector3[linePoints];
        Vector3[] norms = new Vector3[linePoints];
        Color[] cols = new Color[linePoints];
        int[] indicies = new int[linePoints];
        for (int i = 0, j = 1; j < points.Count; i++, j++)
        {
            int a = i * 2;
            int b = i * 2 + 1;
            verts[a] = points[i].position;
            verts[b] = points[j].position;
            cols[a] = points[i].color;
            cols[b] = points[j].color;
            norms[a] = points[i].bezierB.position;
            norms[b] = points[j].bezierA.position;
        }

        for (int i = 0; i < indicies.Length; i++)
            indicies[i] = i;

        mesh.vertices = verts;
        mesh.colors = cols;
        mesh.normals = norms;
        mesh.SetIndices(indicies, MeshTopology.Lines, 0);
        mesh.RecalculateBounds();
    }
}