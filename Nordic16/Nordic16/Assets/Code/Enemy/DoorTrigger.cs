using UnityEngine;
using System.Collections;

public class DoorTrigger : MonoBehaviour {
    bool m_HasBeenUsed;
    [SerializeField] Door m_Door;
    public void PlayerEnters()
    {
        if (m_HasBeenUsed) return;
        m_HasBeenUsed = true;
        m_Door.StartOpening();
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.blue;
        Gizmos.DrawWireCube(transform.position, transform.localScale);
        if (m_Door)
        {
            Gizmos.DrawLine(transform.position, m_Door.transform.position);
        }
    }
}
