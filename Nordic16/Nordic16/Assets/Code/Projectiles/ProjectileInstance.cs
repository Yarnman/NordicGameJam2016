﻿using UnityEngine;
using System.Collections;

public class ProjectileInstance : MonoBehaviour {
    [SerializeField] float m_Speed;
    [SerializeField] Rigidbody m_Rigidbody;
    [SerializeField] float m_Damage;
    [SerializeField] string m_ImpactParticle;
    [SerializeField] string m_ImpactSound;
    float m_StartTime;
	public void StartProjectile()
    {
        m_Rigidbody.angularVelocity = Vector3.zero;
        m_Rigidbody.velocity = m_Speed * transform.forward;
        m_StartTime = Time.time;
    }

    void Update()
    {
        if (Time.time - m_StartTime >= 8.0f)
        {
            this.gameObject.SetActive(false);
        }
    }

    void OnCollisionEnter(Collision a_Other)
    {
        Player t_Player = a_Other.transform.GetComponent<Player>();
        if (t_Player)
        {
            t_Player.GetHit(m_Damage);
        }
        if (m_ImpactSound.Length != 0) AudioManager.SpawnAudioInstance(m_ImpactSound, transform.position);
        if (m_ImpactParticle.Length != 0) ParticleInstanceManager.SpawnSystem(m_ImpactParticle, transform.position, Quaternion.LookRotation(a_Other.contacts[0].normal));
        this.gameObject.SetActive(false);
    }
}
