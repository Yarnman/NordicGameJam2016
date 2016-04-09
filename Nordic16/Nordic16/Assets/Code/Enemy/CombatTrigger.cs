using UnityEngine;
using System.Collections;

public class CombatTrigger : MonoBehaviour {
    bool m_HasBeenUsed;
    [SerializeField] CombatEncounter m_CombatEncounter;

    public void PlayerEnters()
    {
        m_HasBeenUsed = true;
        m_CombatEncounter.StartEncounter();
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(transform.position, transform.localScale);
    }
}
