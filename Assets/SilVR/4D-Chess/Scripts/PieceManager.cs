
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class PieceManager : UdonSharpBehaviour
{
    public ChessPiece[] pieces;
    public GridInterface gi;
    public GameObject rootObject;

    // This program mainly serves to inialize all the neccesary information on runtime. Largely unneccesary, but
    // since multi-editing isnt supported for udon behaviors, this was the easiest way for me to routinely update
    // and modify specific fields.

    // Upon program start
    void Start()
    {
        // Get the position of the root object, acting as the orgin for our coordinate systems
        Vector3 pos_input = rootObject.transform.position;

        // Get all the chess pieces in the children of this object
        pieces = GetComponentsInChildren<ChessPiece>();
        
        // and for each chess piece
        foreach (ChessPiece p in pieces)
        {
            // Assign the grid interface so it can access the visualizer
            p.gi = gi;

            // Assign the root object in case we want to access its transform
            p.rootObject = rootObject;

            // Make sure each piece has recorded its initial positions and rotations to reset to
            p.r0 = p.transform.rotation;
            p.p0 = p.transform.position;

            // Update the basis of the pieces in case the board has been rotated and/or scaled
            p.PerformSnap();
        }
    }

    // Method for resetting the game board
    public void ResetPieces()
    {
        foreach (ChessPiece p in pieces)
        {
            // First off, make sure that the person who owns all the pieces is the person who hit the reset button
            Networking.SetOwner(Networking.LocalPlayer, p.gameObject);
            
            // Reset the positions and rotations of each piece
            p.transform.position = p.p0;
            p.transform.rotation = p.r0;
        }
    }
}
