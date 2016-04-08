using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Renderer))]
public class SortingOffset : MonoBehaviour
{
    public int offset = 0;
    Renderer rend;

	void Awake()
    {
        rend = GetComponent<Renderer>();
        rend.sortingOrder = offset;
    }

    void OnDisable()
    {
        rend.sortingOrder = 0;
    }
	
	void OnValidate()
    {
    	if (rend)
        	rend.sortingOrder = offset;
	}
}
