using UnityEngine;
using System.Collections;

public class CombatTrigger : MonoBehaviour {
    bool m_HasBeenUsed;
    [SerializeField] CombatEncounter m_CombatEncounter;

    public void PlayerEnters()
    {
        if (m_HasBeenUsed) return;
        m_HasBeenUsed = true;
        m_CombatEncounter.StartEncounter();
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(transform.position, transform.localScale);

        if (m_CombatEncounter)
        {
            if (m_CombatEncounter.GetDoor())
            {
                Gizmos.DrawLine(transform.position, m_CombatEncounter.GetDoor().transform.position);
            }
            Gizmos.color = Color.yellow;
            if (m_CombatEncounter.GetWave())
            {
                if (m_CombatEncounter.GetWave().m_SpawnSpots == null) return;
                for (int i = 0; i < m_CombatEncounter.GetWave().m_SpawnSpots.Length; i ++)
                {
                    Gizmos.DrawLine(transform.position, m_CombatEncounter.GetWave().m_SpawnSpots[i].transform.position);
                }
            }
        }
    }
}
