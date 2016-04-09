using UnityEngine;
using System.Collections;

public class PatchInstance : MonoBehaviour {
    [SerializeField] AudioSource m_AudioSource = null;
    [SerializeField] float m_MinVolume = 0;
    [SerializeField] float m_MaxVolume = 0;
    [SerializeField] float m_MinPitch = 0;
    [SerializeField] float m_MaxPitch = 0;
    [SerializeField] AudioClip[] m_PossibleClips = null;

    public void StartPatch()
    {
        m_AudioSource.Stop();
        m_AudioSource.clip = m_PossibleClips[Random.Range(0, m_PossibleClips.Length)];
        m_AudioSource.pitch = Random.Range(m_MinPitch, m_MaxPitch);
        m_AudioSource.volume = Random.Range(m_MinVolume, m_MaxVolume);
        m_AudioSource.Play();
    }
}
