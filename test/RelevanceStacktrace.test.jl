
# push_ifne!(arr, elem) = (!(elem in arr) && push!(arr, elem))
# push_ifne!(LOAD_PATH, "src/");
# using RelevanceStacktrace
using Revise
includet("../src/RelevanceStacktrace.jl")


func4(x) = x .* ["32", 3]
func3(x) = x+5 + func4(x)
func2(x) = x+3 + func3(x)
func1(x) = begin
	func2(x)
end
func1(3)

#%%
try
	eval(Meta.parse("invalidfn()"))
catch e
	# @edit showerror(stdout, e, catch_backtrace())
	# showerror(stdout, e)
	@edit Base.show_backtrace(stdout, catch_backtrace())
end
#%%

Base.show_full_backtrace(io, filtered; print_linebreaks = stacktrace_linebreaks())
#%%
#%%


func4(x) = x.+ @assert false

func1(3)

