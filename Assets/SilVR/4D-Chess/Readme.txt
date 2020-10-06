Readme


Description:
This prefab is an udon based 4-dimensional chess set. Notable features include a visualization system for valid moves on pickup of a piece, snapping to the board if dropped at a valid coordinate, and a master-locked reset button.

As it stands, the visualizer does not check to see if the squares it shows are occupied or blocked, and the snapping system cannot tell if a square is occupied, so these are things the player needs to be aware of themselves.


Usage:
For the most part, the chess board prefab is just drag and drop. It can be moved, rotated, and even scaled, so long as you move the root object (named ‘4D-chess’ by default), however this must be done before the game is run, as the board does a lot of setup work at runtime to make the snapping feature and move visualization to work properly.

There is a ruleset prefab included as well that helps walk you through the thought process extending 2D chess into 4D, as well as visualizations of a couple trickier or core pieces, though it adds quite a few draw calls so I recommend allowing people to toggle.

For more advanced users, if you want to disable the visualizer, disable the game object 4D-chess>ref_pos>move_visualizer. If you want to set up custom logic for the reset button, there is a public method included called ResetAllPieces() belonging to the ResetButton udon behavior that will send a message to the two piece managers, that will reset the individual pieces to their starting positions and rotations.
