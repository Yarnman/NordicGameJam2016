using UnityEngine;
using System.Collections;
using System.Collections.Generic;
public class FragilePanelInstance : MonoBehaviour {
    [SerializeField] DestructiblePanel m_DestructiblePanel;

    public void GetHitByBullet(Vector3 a_Point)
    {
        m_DestructiblePanel.GetHitByBullet();
        AddPatch(a_Point);
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

    }

    public void ResetPatches()
    {

    }
}
