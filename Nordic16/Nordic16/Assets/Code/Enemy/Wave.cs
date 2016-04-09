using UnityEngine;
using System.Collections;
using System.Collections.Generic;
public class Wave : MonoBehaviour {
    [HideInInspector] public SpawnSpot[] m_SpawnSpots;
    List<Enemy> m_SpawnedEnemies = new List<Enemy>();
    public bool m_Done;
    public bool m_IsSpawning;
    public int m_MaxActive;
    public int m_StartSpawns;
    public float m_SpawnTime;
    public int m_TotalSpawns;

    int m_SpawnsLeft;
    float m_LastSpawnTime;
	void Start () 
	{
        m_SpawnSpots = GetComponentsInChildren<SpawnSpot>();
	}
	
	void Update () 
	{
        if (!m_IsSpawning) return;
        if (m_Done) return;

        int t_CurrentActive = 0;
        for (int i = 0; i < m_SpawnedEnemies.Count;)
        {
            if (!m_SpawnedEnemies[i].gameObject.activeSelf)
            {
                m_SpawnedEnemies.RemoveAt(i);
            }
            else
            {
                i++;
                t_CurrentActive++;
            }
        }
        if (t_CurrentActive < m_TotalSpawns && m_SpawnsLeft > 0)
        {
            float t_Time = Time.time - m_LastSpawnTime;
            if (t_Time >= m_SpawnTime)
            {
                Vector3 t_RandomPos = m_SpawnSpots[Random.Range(0, m_SpawnSpots.Length)].transform.position;
                Spawn(t_RandomPos);
            }
        }
        else
        {
            m_LastSpawnTime = Time.time;
        }
        if (m_SpawnsLeft <= 0 && m_SpawnedEnemies.Count == 0)
        {
            m_Done = true;
        }
    }

    public void StartSpawning()
    {
        m_IsSpawning = true;
        m_SpawnsLeft = m_TotalSpawns;

        int t_InitialSpawnsLeft = m_StartSpawns;
        for (int i =0; i < m_SpawnSpots.Length && t_InitialSpawnsLeft > 0; i ++)
        {
            t_InitialSpawnsLeft--;
            Spawn(m_SpawnSpots[i].transform.position);
        }
    }

    void Spawn(Vector3 a_Position)
    {
        Enemy t_Enemy = EnemyInstanceManager.SpawnEnemy("Drone", a_Position);
        m_SpawnedEnemies.Add(t_Enemy);
        m_SpawnsLeft -= 1;
        m_LastSpawnTime = Time.time;
    }

    void OnDrawGizmos()
    {
        if (m_SpawnSpots == null)
        m_SpawnSpots = GetComponentsInChildren<SpawnSpot>();
    }
}
