using UnityEngine;
using System.Collections;

//Class for oneshot particle effects. Can have multiple systems.
//Deactivates itself when all particle systems are done so that it can be reused.
//Managed by ParticleInstanceManager
public class ParticleInstance : MonoBehaviour {
    [SerializeField] ParticleSystem[] m_Systems = null;

	public void StartParticles()
    {
        for (int i = 0; i < m_Systems.Length; i ++)
        { 
            m_Systems[i].Clear();
            m_Systems[i].Play();
        }
    }

    void Update()
    {
        bool t_Finished = true;
        for (int i = 0; i < m_Systems.Length; i ++)
        {
            if (m_Systems[i].isPlaying)
            {
                t_Finished = false;
            }
        }
        if (t_Finished)
        {
            this.gameObject.SetActive(false);
        }
    }
}
