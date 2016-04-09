using UnityEngine;
using System.Collections;

public class Wave : MonoBehaviour {

    Enemy[] m_WaveObjects;
    public bool m_Done;

    public int m_MaxActive;
	void Start () 
	{
        m_WaveObjects = GetComponentsInChildren<Enemy>(true);
	}
	
	void Update () 
	{
        if (!m_Done)
        {
            m_Done = true;
            int t_Active = 0;
            for (int i = 0; i < m_WaveObjects.Length; i++)
            {
                if (m_WaveObjects[i] != null)
                {
                    m_Done = false;
                    if (m_WaveObjects[i].gameObject.activeSelf)
                    {
                        t_Active++;
                    }
                }
            }
            for (int i = 0; i < m_WaveObjects.Length && t_Active < m_MaxActive; i++)
            {
                if (m_WaveObjects[i] != null)
                {
                    if (!m_WaveObjects[i].gameObject.activeSelf)
                    {
                        t_Active++;
                        m_WaveObjects[i].gameObject.SetActive(true);
                    }
                }
            }
        }
        else
        {

        }
    }
}
