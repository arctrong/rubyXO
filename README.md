# rubyXO

## tic-tac-toe in Ruby

Detecting arrow keyboard keys is a difficult problem. So a simpler solution is used.

The current version looks like working correctly (no strict tests done).

The Minimax depth is limited for boards greater than 3x3. Otherwise it makes a move unreasonably long.

On board 3x3 Alpha-beta pruning gives about 4 times less operations (see profiling files).

On board 4x4 Alpha-beta pruning gives about 20 times less operations (see profiling files).
