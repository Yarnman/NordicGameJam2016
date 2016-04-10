using UnityEngine;
using System.Collections;

public class CombatEncounter : MonoBehaviour {
    [SerializeField] Wave m_Wave;
    [SerializeField] Door m_Door;
    [SerializeField] bool m_TriggersEnding;
    bool m_IsDone;
	void Start () 
	{
	
	}
	
	void Update () 
	{
	    if (m_Wave.m_Done)
        {
            if (!m_IsDone)
            { 
                if (m_TriggersEnding)
                {
                    EndGameCINEMATICS t = FindObjectOfType<EndGameCINEMATICS>();
                    t.TriggerCutscene3();
                }
                Debug.Log("Wave done");
                m_IsDone = true;
                if (m_Door != null)
                {
                    m_Door.StartOpening();
                }
            }
        }
	}

    public void StartEncounter()
    {
        if (m_Wave.m_Done || m_Wave.m_IsSpawning)
        {
            return;
        }
        Debug.Log("Starting encounter " + transform.name);
        m_Wave.StartSpawning();
    }

    public Door GetDoor()
    {
        return m_Door;
    }
    public Wave GetWave()
    {
        return m_Wave;
    }
}
