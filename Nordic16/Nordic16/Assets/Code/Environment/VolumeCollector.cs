using UnityEngine;
using System.Collections;
using System.Collections.Generic;
public class VolumeCollector : MonoBehaviour {
    List<Rigidbody> m_CollectedList = new List<Rigidbody>();
    [SerializeField] bool m_KillEnemyOnLeave;
    public bool m_KillPlayerOnEnter;
	void Start () 
	{
	
	}
	
	void Update () 
	{
        for (int i = 0; i < m_CollectedList.Count; )
        {
            if (m_CollectedList[i] == null)
            {
                m_CollectedList.RemoveAt(i);
            }
            else
            {
                i++;
            }
        }
	}

    void OnTriggerEnter(Collider a_Collider)
    {
        if (a_Collider.transform.GetComponent<ProjectileInstance>() != null)
        {
            return;
        }
        m_CollectedList.Add(a_Collider.attachedRigidbody);
    }
    void OnTriggerExit(Collider a_Collider)
    {
        m_CollectedList.Remove(a_Collider.attachedRigidbody);
        if (m_KillEnemyOnLeave)
        {
            Enemy t_Enemy = a_Collider.transform.GetComponent<Enemy>();
            if (t_Enemy)
            {
                t_Enemy.Explode();
            }
        }
    }

    public List<Rigidbody> GetList()
    {
        return m_CollectedList;
    }
}
