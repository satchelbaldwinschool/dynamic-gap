# dynamic-gap
A utility to manage BSPWM config such that the window gap and padding are
relative to the amount of open nodes; the more windows you have open, the smaller the gap.
Padding is kept so that all windows are in subset rectangle of the desktop.
While open, the program reads from `bspc subscribe all` to wait for new or
removed nodes and desktop changes.

# Usage
`dynamic-gap gap top left right bottom [slope = 2.0]`  
`gap` is the target gap - current window gap is found via `floor ( (slope * gap) / (visible nodes) )`, except for the case of a single node which has no gap.    
`top`, `left`, `right`, `bottom` are padding values - they define the subset rectangle for visible notes to inhabit.  
`slope` is a decimal that if not provided is set to two.  


