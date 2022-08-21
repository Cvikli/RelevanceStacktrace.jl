module RelevanceStacktrace
import Base: find_source_file, show_full_backtrace, StackFrame, fixup_stdlib_path,
stacktrace_expand_basepaths, stacktrace_contract_userdir, contractuser

KNOWN_MODULES = ["VSCodeServer", "Core", "Distributed"]
KNOWN_MODULES_PATHS_1 = ["."]
KNOWN_MODULES_PATHS_2 = [".vscode", ".julia", "buildworker"]

is_project_file(modul, pathparts) = (
	!(string(modul) in KNOWN_MODULES) && 
	!(pathparts[1] in KNOWN_MODULES_PATHS_1) && 
	!(length(pathparts)>1 && pathparts[2] in KNOWN_MODULES_PATHS_2))

# This is useful because of  
function print_stackframe_relevance(io, i, frame::Base.StackFrame, n::Int, digit_align_width, modulecolordict, ownmodulescounter)
  print_stackframe_relevance_print(io, i, frame, n, digit_align_width, modulecolordict, ownmodulescounter)
end

@info "Overloading Base.print_stackframe(...), Base.show_full_backtrace(io::IO, trace::Vector, print_linebreaks::Bool) and Base.showerror(...) with Experimental version"

# Print a stack frame where the module color is set manually with `modulecolor`.
function print_stackframe_relevance_print(io, i, frame::Base.StackFrame, n::Int, digit_align_width, modulecolor, ownmodulescounter)

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

  # @
  printstyled(io, " @ ", color = :light_black)

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

  colored = get(io, :color, false)::Bool
  # filename, separator, line
  # use escape codes for formatting, printstyled can't do underlined and color
  # codes are bright black (90) and underlined (4)
  printstyled(io, pathparts[end], ":", line, ; color = isprojectfile && colored ? :green : :default, bold=firstofitsmodule, underline = true)

  # inlined
  printstyled(io, inlined ? " [inlined]" : "", color = :light_black)
end


function Base.show_full_backtrace(io::IO, trace::Vector; print_linebreaks::Bool)
  num_frames = length(trace)
  ndigits_max = ndigits(num_frames)
  
  modulecolordict = copy(Base.STACKTRACE_FIXEDCOLORS)
  ownmodulescounter = IdDict()
  
  println(io, "\nStacktrace:")

  try
    for (i, (frame, n)) in enumerate(trace)
      print_stackframe_relevance(io, i, frame, n, ndigits_max, modulecolordict, ownmodulescounter)
      if i < num_frames
          println(io)
          print_linebreaks && println(io)
      end
    end
  catch e
    println(io)
    @error "during custom show_full_backtrace in RelevanceStacktrace.jl, FALLBACK to RAW format:"
    println(io, e)
    bt = catch_backtrace()
    filtered = Base.process_backtrace(bt)
    frames = map(x->first(x)::Base.StackFrame, filtered)
    for (i, frame) in enumerate(frames)
      print(io, lpad("[$i] ", 6))
      StackTraces.show_spec_linfo(IOContext(io, :backtrace=>true), frame)
      println(io, " @ $(frame.file):$(frame.line)") 
    end
  end
end


end # module
