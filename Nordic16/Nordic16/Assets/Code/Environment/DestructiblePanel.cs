using UnityEngine;
using System.Collections;
using System.Collections.Generic;
public class DestructiblePanel : MonoBehaviour {
    public enum State
    {
        Whole,
        Broken,
        Repairing
    }
    [SerializeField] GameObject m_CompletePanel;
    [SerializeField] GameObject m_BrokenPanel;
    [SerializeField] int m_BulletHitLimit;
    [SerializeField] float m_BrokenTime;
    [SerializeField] float m_RepairTime;
    [SerializeField] float m_BrokenSuction;
    [SerializeField] float m_HoleSuction;
    [SerializeField] VolumeCollector m_CollectingVolume;
    [SerializeField] FragilePanelInstance m_PanelInstance;
    float m_LastTime;
    int m_BulletHits;
    State m_State;
    
	void Start () 
	{
        FinishRepair();
	}
	
	void FixedUpdate () 
	{
	    switch (m_State)
        {
            case State.Whole:
                UpdateAttraction(m_HoleSuction);
                break;
            case State.Broken:
                UpdateAttraction(m_BrokenSuction);
                if (Time.time - m_LastTime >= m_BrokenTime)
                {
                    StartRepair();
                }
                break;
            case State.Repairing:

                if (Time.time - m_LastTime >= m_RepairTime)
                {
                    FinishRepair();
                }
                break;
        }
	}

    void UpdateAttraction(float a_Suction)
    {
        if (a_Suction <= 0)
        {
            return;
        }
        List<Rigidbody> t_Bodies = m_CollectingVolume.GetList();

        for (int i =0; i < t_Bodies.Count; i ++)
        {
            if (t_Bodies[i] != null)
            { 
                DroneMovement t_Enemy = t_Bodies[i].GetComponent<DroneMovement>();
                if (t_Enemy)
                {
                    t_Enemy.enabled = false;
                }
                if (t_Bodies[i].isKinematic)
                {
                    t_Bodies[i].isKinematic = false;
                }

                Vector3 t_Direction = (transform.position - m_CollectingVolume.transform.position).normalized;
                t_Bodies[i].AddForce(t_Direction * a_Suction * Time.fixedDeltaTime, ForceMode.Acceleration);
            }
        }
    }

    void Break()
    {
        m_BrokenPanel.SetActive(true);
        m_CompletePanel.SetActive(false);
        m_LastTime = Time.time;
        m_State = State.Broken;
        m_PanelInstance.ResetPatches();
    }

    void StartRepair()
    {
        //Shutters.close

        m_LastTime = Time.time;
        m_State = State.Repairing;
    }

    void FinishRepair()
    {
        m_BrokenPanel.SetActive(false);
        m_CompletePanel.SetActive(true);
        m_BulletHits = 0;
        //Shutters.open
        m_State = State.Whole;
    }

    public void GetHitByBullet()
    {
        if (m_State != State.Whole)
        {
            return;
        }
        m_BulletHits++;
        if (m_BulletHits >= m_BulletHitLimit)
        {
            Break();
        }
    }

    public void GetHitByCollider(Transform a_Other)
    {
        if (m_State != State.Whole)
        {
            return;
        }
        Break();
    }
}
