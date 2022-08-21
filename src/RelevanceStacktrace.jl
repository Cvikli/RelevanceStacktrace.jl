module RelevanceStacktrace
import Base: find_source_file, print_stackframe, StackFrame, fixup_stdlib_path,
stacktrace_expand_basepaths, stacktrace_contract_userdir, contractuser

KNOWN_MODULES = ["VSCodeServer", "Core", "Distributed"]
KNOWN_MODULES_PATHS_1 = ["."]
KNOWN_MODULES_PATHS_2 = [".vscode", ".julia", "buildworker"]

is_project_file(modul, pathparts) = (
	!(string(modul) in KNOWN_MODULES) && 
	!(pathparts[1] in KNOWN_MODULES_PATHS_1) && 
	!(length(pathparts)>1 && pathparts[2] in KNOWN_MODULES_PATHS_2))

# This is useful because of  
# function Base.print_stackframe(io, i, frame::Base.StackFrame, n::Int, digit_align_width, modulecolordict, ownmodulescounter)
# 		RelevanceStacktrace.print_stackframe(io, i, frame, n, digit_align_width, ownmodulescounter, false)
# end

@info "Overloading Base.print_stackframe(...), Base.show_full_backtrace(io::IO, trace::Vector, print_linebreaks::Bool) and Base.showerror(...) with Experimental version"

ownmodulescounter::IdDict{Any, Any} = IdDict()

# Print a stack frame where the module color is set manually with `modulecolor`.
function print_stackframe(io, i, frame::StackFrame, n::Int, digit_align_width, modulecolor)

  modulecolor = copy(Base.STACKTRACE_FIXEDCOLORS)  # We don't color the module!
  
  file, line = string(frame.file), frame.line
  file = fixup_stdlib_path(file)
  stacktrace_expand_basepaths() && (file = something(find_source_file(file), file))
  stacktrace_contract_userdir() && (file = contractuser(file))
  
  # Used by the REPL to make it possible to open
  # the location of a stackframe/method in the editor.
  if haskey(io, :last_shown_line_infos)
    push!(io[:last_shown_line_infos], (string(frame.file), frame.line))
  end
  
  inlined = getfield(frame, :inlined)
  modul = parentmodule(frame)
  pathparts = splitpath(file)
  
  isprojectfile = is_project_file(modul, pathparts)

  firstofitsmodule = false
  if isprojectfile
    if !haskey(ownmodulescounter, modul)
      ownmodulescounter[modul] = 0
      firstofitsmodule =  length(ownmodulescounter) == 1
    end
    ownmodulescounter[modul] += 1
  end

  # frame number
  print(io, " ", lpad("[" * string(i) * "]", digit_align_width + 2))
  print(io, " ")

  StackTraces.show_spec_linfo(IOContext(io, :backtrace=>true), frame)
  if n > 1
      printstyled(io, " (repeats $n times)"; color=:light_black)
  end
  println(io)

  # @
  printstyled(io, " " ^ (digit_align_width + 2) * "@ ", color = :light_black)

  # module
  if modul !== nothing
      printstyled(io, modul, color = :default)
      print(io, " ")
  end

  # filepath
  folderparts = pathparts[1:end-1]
  if !isempty(folderparts)
      printstyled(io, joinpath(folderparts...) * (Sys.iswindows() ? "\\" : "/"), color = :light_black)
  end

  # filename, separator, line
  # use escape codes for formatting, printstyled can't do underlined and color
  # codes are bright black (90) and underlined (4)
  printstyled(io, pathparts[end], ":", line; color = :light_black, underline = true)

  colored = get(io, :color, false)::Bool
  start_s = colored && isprojectfile ? "\u001b[32;" * (firstofitsmodule ? "1;4m" : "4m") : ""
  end_s   = colored && isprojectfile ? "\033[0m"    : ""
  print(io, start_s, s..., end_s)

  # inlined
  printstyled(io, inlined ? " [inlined]" : "", color = :light_black)
end




# A different version of print_stackframe
# function Base.print_stackframe(io, i, frame::Base.StackFrame, n::Int, digit_align_width, ownmodulescounter, debug=false)
#     file, line = string(frame.file), frame.line
#     Base.stacktrace_expand_basepaths() && (file = something(find_source_file(file), file))
#     Base.stacktrace_contract_userdir() && (file = Base.contractuser(file))
#     # Used by the REPL to make it possible to open
#     # the location of a stackframe/method in the editor.
#     if haskey(io, :last_shown_line_infos)
#         push!(io[:last_shown_line_infos], (string(frame.file), frame.line))
# 		end
		
# 		inlined = getfield(frame, :inlined)
# 		modul = parentmodule(frame)
# 		pathparts = splitpath(file)
		
#     (debug && println(io,"Stack preprocessing is ok"))
# 		isprojectfile = is_project_file(modul, pathparts)
		
#     (debug && println(io,"Project's file check is ok"))
# 		firstofitsmodule = false
# 		if isprojectfile
# 			if !haskey(ownmodulescounter, modul)
# 				ownmodulescounter[modul] = 0
# 				firstofitsmodule =  length(ownmodulescounter) == 1
# 			end
# 			ownmodulescounter[modul] += 1
# 		end
#     (debug && println(io,"Module counter is ok"))
#     # frame number
#     print(io, lpad(" [" * string(i) * "] ", digit_align_width + 4))

#     StackTraces.show_spec_linfo(IOContext(io, :backtrace=>true), frame)
#     if n > 1
#         printstyled(io, " (repeats $n times)"; color=:white)
#     end
#     # @
#     printstyled(io, " @ ", color = :light_black)

#     # module
#     if modul !== nothing
#         printstyled(io, modul, color = :default)
#         print(io, " ")
#     end

#     # filepath
#     folderparts = pathparts[1:end-1]
#     if !isempty(folderparts)
#         printstyled(io, joinpath(folderparts...) * (Sys.iswindows() ? "\\" : "/"), color = :light_black)
#         # printstyled(io,  "\033[90;4m" * joinpath(folderparts...) * (Sys.iswindows() ? "\\" : "/") *  "\033[0m", color = :light_black)
#     end

#     # use escape codes for formatting, printstyled can't do underlined and color
#     # codes are bright black (90) and underlined (4)
#     function print_underlined(io::IO, s...)
#         colored = get(io, :color, false)::Bool
#         start_s = colored && isprojectfile ? "\u001b[32;" * (firstofitsmodule ? "1;4m" : "4m") : ""
#         end_s   = colored && isprojectfile ? "\033[0m"    : ""
#         print(io, start_s, s..., end_s)
#     end
#     # filename, separator, line
#     print_underlined(io, pathparts[end], ":", line)

#     # inlined
# 		printstyled(io, inlined ? " [inlined]" : "", color = :light_black)
		
#     (debug && print(io, "\nPrinting is ok for 1 file as you see..."))
# end








# function show_backtrace(io::IO, t::Vector)
#   if haskey(io, :last_shown_line_infos)
#       empty!(io[:last_shown_line_infos])
#   end

#   # t is a pre-processed backtrace (ref #12856)
#   if t isa Vector{Any}
#       filtered = t
#   else
#       filtered = process_backtrace(t)
#   end
#   isempty(filtered) && return

#   if length(filtered) == 1 && StackTraces.is_top_level_frame(filtered[1][1])
#       f = filtered[1][1]::StackFrame
#       if f.line == 0 && f.file === Symbol("")
#           # don't show a single top-level frame with no location info
#           return
#       end
#   end

#   if length(filtered) > BIG_STACKTRACE_SIZE
#       show_reduced_backtrace(IOContext(io, :backtrace => true), filtered)
#       return
#   end

#   try invokelatest(update_stackframes_callback[], filtered) catch end
#   # process_backtrace returns a Vector{Tuple{Frame, Int}}
#   show_full_backtrace(io, filtered; print_linebreaks = stacktrace_linebreaks())
#   return
# end




# function Base.show_full_backtrace(io::IO, trace::Vector; print_linebreaks::Bool)
#     num_frames = length(trace)
#     ndigits_max = ndigits(num_frames)
    
#     modulecolordict = copy(Base.STACKTRACE_FIXEDCOLORS)
# 		ownmodulescounter = IdDict()
# 		println(io, "\nStacktrace:")
# 		try
# 			for (i, (frame, n)) in enumerate(trace)
# 					Base.print_stackframe(io, i, frame, n, ndigits_max, modulecolordict, ownmodulescounter)
# 					if i < num_frames
# 							println(io)
# 							print_linebreaks && println(io)
# 					end
#       end	
# 		catch e
#       println(io)
#       @error "Error: during show_full_backtrace in RelevanceStacktrace.jl, we try to print a the error with a basic format:"
#       println(io, e)
#       bt = catch_backtrace()
#       filtered = Base.process_backtrace(bt)
#       frames = map(x->first(x)::Base.StackFrame, filtered)
#       for (i, frame) in enumerate(frames)
#         print(io, lpad(" [$i] ", 6))
#         StackTraces.show_spec_linfo(IOContext(io, :backtrace=>true), frame)
#         println(io, " @ $(frame.file):$(frame.line)") 
#       end
# 		end
# end


# function show_full_backtrace(io::IO, trace::Vector; print_linebreaks::Bool)
#   num_frames = length(trace)
#   ndigits_max = ndigits(num_frames)

#   modulecolordict = copy(STACKTRACE_FIXEDCOLORS)
#   modulecolorcycler = Iterators.Stateful(Iterators.cycle(STACKTRACE_MODULECOLORS))

#   println(io, "\nStacktrace:")

#   for (i, (frame, n)) in enumerate(trace)
#       print_stackframe(io, i, frame, n, ndigits_max, modulecolordict, modulecolorcycler)
#       if i < num_frames
#           println(io)
#           print_linebreaks && println(io)
#       end
#   end
# end



# function Base.showerror(io::IO, ex::LoadError, bt; backtrace=true)
#   try
#     print(io, "LoadError: ")
#     Base.showerror(io, ex.error, bt, backtrace=backtrace)
#     pathparts = splitpath(ex.file)
#     folderparts = pathparts[1:end-1]
#     if length(folderparts) ==0
#       print(io, "\nin expression starting at REPL? \u001b[32;4m$(pathparts[end]):$(ex.line)\033[0m")
#     else
#       folderpath=(joinpath(folderparts...) * (Sys.iswindows() ? "\\" : "/"))
#       print(io, "\nin expression starting at $(folderpath)\u001b[32;4m$(pathparts[end]):$(ex.line)\033[0m")
#     end
#   catch e
#     println(io)
#     @error "Error: during showerror in RelevanceStacktrace.jl, we try to print a the error with a basic format:"
#     println(io)
#     println(io, e)
#     println(io)
#     bt = catch_backtrace()
#     println(io,"k")
#     filtered = Base.process_backtrace(bt)
#     println(io,"k3")
#     frames = map(x->first(x)::Base.StackFrame, filtered)
#     println(io,"k35")
#     for (i, frame) in enumerate(frames)
#       println(io,"k37")
#       print(io, lpad(" [$i] ", 6))
#       StackTraces.show_spec_linfo(IOContext(io, :backtrace=>true), frame)
#       println(io, " @ $(frame.file):$(frame.line)") 
#     end
#   end
# end

end # module
