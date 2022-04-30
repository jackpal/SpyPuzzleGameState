# Spy Puzzle Level Text Format Specification

Spy Puzzle levels are represented using the `GameState` struct. You can define a level programmatically by
creating a GameState instance. There's also a convenience function, `parse(level:String)throws -> GameState`,
that creates a GameState from a String.

Some places you can use text-based puzzle levels:

+ The SpyPuzzleApp's source code, to add levels to the app.
+ The SpyPuzzleCLI command line tool, to test the puzzle solver.
+ Tests.

The format of the `level` argument is an ASCII-art representation of the level. The simplest level is:

```
A-X
```

This level has two `nodes`, connected by a plain `edge`. The 'A' indicates the node that the Spy starts on.
The 'X' indicates the node that is the exit for the level.
The '-' indicates that there is a plain horizontal edge connecting the two nodes.

A more complicated level will have "subroutines" that describe what is
placed on a node using a simple language.

```
A-1-X

1: enemy(blue,east)
```

In this level there is a blue enemy, facing east, between the spy and the
exit.

Here's a "kill your mark" level that doesn't have an exit, but does have a
"mark" enemy that must be killed.

```
A-+-1

1: enemy(mark,east)
```

Finally, here's a more complicated level:

```
A-+-r-+-1-X
|
+rG

1:enemy(blue,west);target()
```

# Node types

Character | Meaning
--------: | -------
'-'       | a plain node
'&#124;'  | a plain node
'+'       | a plain node
0-9, α-ω  | a subroutine. The contents of the node are specified in the corresponding subroutine definition. (α-ω is the lower-case Greek alphabet.)
A         | where the Spy is placed at the start of the level.
C         | a briefcase
E         | a pair of pistols
G         | a rifle
P         | a potted plant
R         | a rock
S         | a statue
T         | a target
W         | a waitpoint
X         | the exit node. A level can have zero or one exits.
a         | where the Spy is placed, wearing a trenchcoat, at the start of the level.
b         | a blue key
g         | a green key
r         | a red key
y         | a yellow key

# Edge types

Character | Meaning
--------- | -------
space     | no edge
'-'       | a horizontal edge
'&#124;'  | a vertical edge
b         | a blue door
g         | a green door
r         | a red door
y         | a yellow door

# Subroutine format

A subroutine is a single line of text, like this:

```
0: enemy(blue,east);enemy(yellow,north);plant();target()
```

The format is a single character, in the range 0-9 or α-ω, that is the subroutine name, followed by a colon, followed by
zero or more function calls which are separated by semicolons. Each function call has an argument list of zero or more
arguments.

Function | Meaning
--------:| -------
e,enemy  | an enemy with a given (type,extra arguments...)
exit     | an exit
gun      | a rifle
hitman   | the spy begins the level here.
key      | a key of the given (color)
pistols  | a pair of pistols
plant    | a plant
rock     | a rock
statue   | a statue
subway   | a subway with a (name, destinations)
suit     | a costume suit of the given (enemy type)
target   | a target
walkway  | a walkway traveling in a given (direction).

# Enemy types

Type | Extra arguments
---: | ---------
b,blue | direction
B,blue_armored | direction
d,dog | direction
2,duo | direction
f,flashlight | direction
g,green | direction
m,mark | direction
p,patrol | route_left, route_top, route_right, route_bottom
s,sniper | direction
y,yellow | direction
Y,yellow_armored | direction

# Direction types

```
n,north
e,east
w,west
s,south
```
