using UnityEngine;
using System.Collections;

//Class for oneshot audio effects. Can have multiple audioclips to choose from, as well as random volume/pitch. 
//Deactivates itself when done so that it can be reused.
//Managed by AudioManager
public class AudioInstance : MonoBehaviour {
    [SerializeField] AudioSource m_AudioSource = null;
    [SerializeField] float m_MinVolume = 0;
    [SerializeField] float m_MaxVolume = 0;
    [SerializeField] float m_MinPitch = 0;
    [SerializeField] float m_MaxPitch = 0;
    [SerializeField] AudioClip[] m_PossibleClips = null;
	void Update ()
    {
	    if (!m_AudioSource.isPlaying)
        {
            this.gameObject.SetActive(false);
        }
	}

    public void Play()
    {
        m_AudioSource.Stop();
        m_AudioSource.clip = m_PossibleClips[Random.Range(0, m_PossibleClips.Length)];
        m_AudioSource.pitch = Random.Range(m_MinPitch, m_MaxPitch);
        m_AudioSource.volume = Random.Range(m_MinVolume, m_MaxVolume);
        m_AudioSource.Play();
    }
}
