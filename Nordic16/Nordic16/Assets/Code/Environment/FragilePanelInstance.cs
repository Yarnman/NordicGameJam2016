using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class FragilePanelInstance : MonoBehaviour {
    [SerializeField] DestructiblePanel m_DestructiblePanel;
    List<GameObject> m_Patches = new List<GameObject>();
    public void GetHitByBullet(Vector3 a_Point)
    {
        AddPatch(a_Point);
        m_DestructiblePanel.GetHitByBullet();
    }

    void OnCollisionEnter(Collision a_Other)
    {
        if (a_Other.transform.GetComponent<ProjectileInstance>() != null)
        {
            AddPatch(a_Other.contacts[0].point);
            m_DestructiblePanel.GetHitByBullet();
            return;
        }
        m_DestructiblePanel.GetHitByCollider(a_Other.transform);
    }

    void AddPatch(Vector3 a_Point)
    {
        GameObject t_Object = PatchInstanceManager.SpawnPatch("Patch", a_Point, -transform.forward).gameObject;
        m_Patches.Add(t_Object);
    }

    public GameObject GetClosestPatch(Vector3 a_Point)
    {
        GameObject t_Ret = null;
        float t_C = float.MaxValue;
        for (int i = 0; i < m_Patches.Count; i++)
        {
            float t_D = (m_Patches[i].transform.position - a_Point).magnitude;
            if (t_D < t_C)
            {
                t_C = t_D;
                t_Ret = m_Patches[i];
            }
        }
        return t_Ret;
    }

    public void ResetPatches()
    {
        for (int i = 0; i < m_Patches.Count; i ++)
        {
            m_Patches[i].SetActive(false);
        }
        m_Patches.Clear();
    }
}
