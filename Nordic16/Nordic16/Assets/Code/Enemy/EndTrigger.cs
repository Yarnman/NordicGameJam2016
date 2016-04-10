using UnityEngine;
using System.Collections;

public class EndTrigger : MonoBehaviour {
    bool m_HasBeenUsed;
    public void PlayerEnters()
    {
        if (m_HasBeenUsed) return;
        m_HasBeenUsed = true;
        EndGameCINEMATICS t = FindObjectOfType<EndGameCINEMATICS>();
        t.TriggerCutscene1();
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.magenta;
        Gizmos.DrawWireCube(transform.position, transform.localScale);

    }
}
