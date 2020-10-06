
using UdonSharp;
using UnityEngine;
using VRC.SDKBase;
using VRC.Udon;

public class GridInterface : UdonSharpBehaviour
{
    //public Transform[] planes;
    public Vector4 coordinate;

    // The reference piece is the current piece from which the moveset and position of the move
    // visualizer uses to highlight available moves.
    public ChessPiece refPiece;

    // The grid interface is a material that uses a vector and int parameter to determine the
    // current coordinate we're visualizing from and the piece we are visualizing respectively.
    public Material gpuGridInterface;


    // This is the udon script that manages the gpu grid underneath the chess board. I sets the vector and
    // piece reference to the piece last picked up. This one isn't very autonomous, and isnt very
    // complicated either. For the most part, the individual chess pieces will be calling this objects
    // methods. It serves as the interface between the visualizer and pieces

    // When a chess piece calls this method through the interface, this will update the visualizer
    public void UpdateGpuGrid()
    {
        // So long as we have a valid reference piece
        if (refPiece != null)
        {
            // Get the reference pieces coordinate, and piece id, then give that to the material
            gpuGridInterface.SetVector("_Vector", refPiece.coordinate);
            gpuGridInterface.SetInt("_Piece", refPiece.pieceType);
        }
    }

    // When a chess piece calls this method through the interface, it will hide the visualizer
    public void HideGpuGrid()
    {
        // Clear the reference piece
        refPiece = null;

        // Set the piece ID to 0 (default value, hiding all grid cubes.
        gpuGridInterface.SetInt("_Piece", 0);
    }


}
