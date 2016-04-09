using UnityEngine;

public class PlayAnimOnAwake : MonoBehaviour
{
	void OnEnable()
    {
        Animation anim = GetComponent<Animation>();
        if (anim)
            anim.Play();
	}
}
