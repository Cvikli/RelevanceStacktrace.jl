# RelevanceStacktrace.jl
Julia relevance Stacktrace. 

# Goal
What are you searching during development?
99% of the time for the **TOP error of the stacktrace from your project's files**. >> **So it highlights it! :)**
1% you can use the unhighlighted parts. :)

# Why
Julia stacktrace is for finding error. Why don't we use it to help us right? ;) 

# Usage
Many way... but easiest:
include(path_to_file * "RelevanceStacktrace.jl/src/RelevanceStacktrace.jl")
or from a folder next to the cloned repo you can try using this version
push!(LOAD_PATH, "../RelevanceStacktrace.jl/"); Base.load_path()
using RelevanceStacktrace
But for me it doesn't perform well in certain situation, which I didn't have time to figure out... It only loads the package for the second time in this case...

(**only tested on Ubuntu for Julia 1.6!** )