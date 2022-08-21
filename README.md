# RelevanceStacktrace.jl

Most important elements in the stacktrace:
1. source file of the error
	1. you can change with location of the file + filename + line number
	2. function name
	3. stack depth counter
	4. modul name
2. other project files
3. other internal files
So let's design it like this! -> RelevanceStacktrace



# Why

Stacktrace is for locating the error. Let's FOCUS ONLY on that.

With this package in the past years I literally forgot what does searching for error is as I just click on the <span  style="color:green; text-decoration: underline">**BOLD GREEN**</span> filename with a ctrl + click in vscode each time.
  
Green! Because locating the error is actually good. Not bad! So "We have to locate the right file, so we highlight it!"

Finding error has to be a good thing!

# Goal
Keep it short and fast to find the file for the error! 

I think 99% of the time the error will be in the **the first error of the stacktrace from your project's files**. >> **So it highlights it! :)**

Any other time you will have the unhighlighted parts. :)

# INSTALL

Many way... but easiest:

```
julia
] add https://github.com/Cvikli/RelevanceStacktrace.jl.git
then: using RelevanceStacktrace
```

or

`include(path_to_file * "RelevanceStacktrace.jl/src/RelevanceStacktrace.jl")`

or from a folder next to the cloned repo you can try using this version


```
push!(LOAD_PATH, "../RelevanceStacktrace.jl/"); Base.load_path()
using RelevanceStacktrace
```

# Demo
Artificial error, to see it's power:
```
using RelevanceStacktrace
func4(x) = begin
	x+=x
	x=sum(x) .* [5, 3]
	x=sum(x[3])
	return x/3
end
func3(x) = x+5 + func4(x)
func2(x) = x+3 + func3(x)
func1(x) = begin
	func2(x)
end
func1(3)
```
![artificial error example](/assets/artificial_error.png)
In real life example if will be even more useful.

Long stacktrace error:
```
sum([])
```
![long internal error example](/assets/sum([])_error.png)
This is still nice I think, but to be honest RelevanceStacktrace shines better when the error is in some of your project file.


# Fun fact

**Debug the Debug.** :D We catch the error in the error handling and do a very basic error printing mechanism, so we can debug the backtrace printing error.
**The relevant errors are green, because finding one is a good thing!** ;)
**Fallback to raw stacktrace printing.** As the project is sort of experimental, if a special case happen that we just don't bother to handle, it will fall back to print it in a basic format.

# Future works?
**Module names are useless.** Actually we could drop the modul names as it just waste of space
**Function param types are pretty useless.** Maybe we could just show function names and parameters::types if it is actually matters... (As it is used very very rarely!) 
**AbbreviatedStackTraces sounds interesting** We could merge it into this project with an optional flag maybe? 

# Great stacktraces
- AbbreviatedStackTraces: great project. :) https://github.com/BioTurboNick/AbbreviatedStackTraces.jl
- ClearStacktrace: was great for inspiration! https://github.com/jkrumbiegel/ClearStacktrace.jl

# Note

(**only tested on Ubuntu for Julia 1.8!** )

(**later version was tested on Ubuntu for Julia 1.6 and 1.7!** )