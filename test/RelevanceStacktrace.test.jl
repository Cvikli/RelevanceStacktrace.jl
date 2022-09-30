
# push_ifne!(arr, elem) = (!(elem in arr) && push!(arr, elem))
# push_ifne!(LOAD_PATH, "src/");
# using RelevanceStacktrace
using Revise
includet("../src/RelevanceStacktrace.jl")


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

#%%
show_full_backtrace(io::IO, trace::Vector{Tuple{Base.StackTraces.StackFrame, Int}}; print_linebreaks::Bool)
#%%
using Plots
using BenchmarkTools, Plots
plot([1,2,3], seriestype=:blah)
# @btime plot([1,2,3], seriestype=:blah)
#%%
sum([])
#%%

# func4(x) = x .* ["32", 3]
# func3(x) = x+5 + func4(x)
# func2(x) = x+3 + func3(x)
# func1(x) = begin
# 	func2(x)
# end
# func1(3)
using Base: stacktrace_linebreaks, process_backtrace, StackFrame
using .RelevanceStacktrace: show_full_backtrace_relevance
try
	# eval(Meta.parse("invalidfn()"))
	func1(3)
catch e
	# x= process_backtrace(catch_backtrace())
	# @show x
	# for (f,i) in x
	# 	@show typeof(f)
	# 	@show typeof(i)
	# end
	# @show e
	# @show process_backtrace(catch_backtrace())
	# @show "eq"
	# @show convert(Vector{Tuple{StackFrame, Int}}, process_backtrace(catch_backtrace()))
	@code_warntype show_full_backtrace_relevance(stdout, process_backtrace(catch_backtrace()), false)
	# @edit showerror(stdout, e, catch_backtrace())
	# showerror(stdout, e)
	# @edit Base.show_backtrace(stdout, catch_backtrace())
end
#%%
@code_warntype catch_backtrace()
#%%
typeof(catch_backtrace())
#%%
process_backtrace(catch_backtrace())
#%%
using Base: stacktrace_linebreaks,process_backtrace
stacktrace_linebreaks()
#%%

process_backtrace(catch_backtrace())

#%%
error("bla")
#%%


func4(x) = x.+ @assert false

func1(3)

#%%
using Revise
using RelevanceStacktrace
@show "OK"
assert_no_stacktrace(true,)
@assert_no_stacktrace false "OKAY"
