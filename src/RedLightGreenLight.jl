module RedLightGreenLight

const libdir = @__DIR__

"""
  stdavg(x)

Finds the average value and standard deviation of an input vector of values `x`
"""
function stdavg(x::Array{W,1}) where W <: Real
  avgval = sum(x)/length(x)
  if length(x) == 1
    stdval = 0
  else #if typeof(x) <: Union{Tuple,Array}
    stdval = sqrt(sum(w->(x[w]-avgval)^2,1:length(x))/(length(x)*(length(x)-1)))
  end
  return avgval,stdval
end

"""
  testfct(test,message)

Prints out styled PASS (true) or FAIL (false) flag depending on value of `test` and also tags `message` provided as a string
"""
function testfct(test::Bool,message::String)
#  try test
  if test
    printstyled("PASS",color=:green)
  else
    printstyled("FAIL",color=:red)
  end
  println(" "*message)
#  catch
#    error(message)
#  end
  return test
end

"""
   timeflag

String to designate if stored values are time values
"""
const timeflag = "_time"

"""
   memflag

String to designate if stored values are memory values
"""
const memflag = "_mem"

"""
  comparrow!(xvec,y,σ,tol=2)

Creates a list of arrows signifying if the last value `y` compared against previous runs stored in `xvec` were above (^), below (v), or nearly the same (-) as the previous runs. Values are compared against the standard deviation `σ` times `tol` (number of standard deviations)
"""
function comparrow!(xvec::Array{W,1},y::Float64,σ::Float64;tol::Real=2) where W <: Float64

  print("  ")

  for w = 1:length(xvec)
    x = xvec[w]
    diffxy = abs(x - y)

    if diffxy > tol*σ
      if x < y
        printstyled("v",color=:green)
      else
        printstyled("^",color=:red)
      end
    else
      printstyled(".",color=:yellow)
    end
  end
  print(" ")
end

"""
  SI_units

SI prefixes
"""
const SI_units = [("T",12),("G",9),("M",6),("k",3),("",0),("c",-2),("m",-3),("μ",-6),("n",-9),("p",-12),("f",-15),("a",-18)]

"""
  findSI(x)

Finds most appropriate SI unit prefix for input value `x`
"""
function findSI(x::Real)
  w = 1 #length(SI_units)
#  println()
#  println(x)
#  println()
  while w < length(SI_units) && !(SI_units[w][2] > x >= SI_units[w+1][2])
    w += 1
  end
  return SI_units[w+1][1],10^(-1.0*SI_units[w+1][2])
end

"""
  countnum

How many values to store in the values computed previously
"""
const countnum = 10

function compareval!(storedict::Dict,message::String,value::Number;tol::Number=5)

  if typeof(value) <: Integer
    printval = "$(value)"
  else
    p = Base.log(10,value)

    power = floor(intType,p)
#    val = round(value*10^(-power),digits=3)

    prefix,adjustval = findSI(power)
    printval = round(value*adjustval,digits=4)
    printval = "$(printval)$(prefix)s"
  end

  if haskey(storedict,message)
    checkval = storedict[message]
    avgval,stdval = stdavg(checkval)

    diffval = abs(value - avgval)
    
    colourbool = diffval > tol*stdval
    printstyled(printval,color = colourbool ? (:red) : (:green))
    if colourbool
      sigval = length(checkval) == 1 ? 0 : round(diffval/stdval,digits=2)
      printstyled(" (+/- ",sigval,"σ)",color= :yellow)
    end

#    comparrow_vec = [ for w = 1:length(checkval)]

#    compstring = comparrow(checkval,avgval#=value=#,stdval)
#    print(" "*compstring*" ")

    if typeof(checkval) <: Number
      outval = (checkval,value)
    else
      if typeof(checkval) <: Tuple
        if length(checkval) >= countnum
          outval = (Base.tail(checkval)...,value)
        else
          outval = (checkval...,value)
        end
      else
        outval = (value,)
      end
    end

    comparrow!(checkval,avgval,stdval,tol=tol)

  else
    printstyled(printval,color=:blue)
    outval = value
  end

  setindex!(performancevals,outval,message)
end

"""
  
"""
function get_testvals(;testpath=libdir*"/test/",file_extension=".redlightgreenlight")
  file = testpath*"dict"*file_extension
  if isfile(file)
    performancevals = Serialization.deserialize(file)
  else
    performancevals = Dict()
  end
  return performancevals
end
export get_testvals

"""
  testfct(evalstring,message,storedict)

Main printout function for input test `evalstring` (a String) with output `message` (String) and stored previous test values `storedict` (Dict type) 
"""
function testfct(evalstring::String,message::String,storedict::Dict)

  base = Meta.parse(evalstring)
  test = eval(base)

  #  try test
    if test
      printstyled("PASS",color=:green)
    else
      printstyled("FAIL",color=:red)
    end
    println(" "*message)
  #  catch
  #    error(message)
  #  end


    t1 = time()
    alloc = @allocations eval(base)
    t2 = time()



    memstring = message * memflag
    print("     mem: ")

    compareval!(storedict,memstring,alloc)

    print(" | ")

    timestring = message * timeflag
    print("time: ")
    timer = t2-t1#@time eval(base)
    compareval!(storedict,timestring,timer)
    println()

    return test
  end
#=
#define macro like in profileview
function score(fct::Function,inputs...)
  alloc = @allocations fct(inputs...)
  timer = @time fct(inputs...)
  print("memory: ")
  printstyled("$alloc",color=alloc > storedict ? (:red) : (:green))
  print(" ")
  print("time: ")
  printstyled("$timer",color=timer > storedict ? (:red) : (:green))
  println()
end
  =#
"""
  checkall(fulltestrecord,i,fulltest)

Records tests result `fulltest` into a vector `fulltestrecord` (an array of Boolean values) on test number `i`
"""
function checkall(fulltestrecord::Array{Bool,1},i::Integer,fulltest::Bool)
  fulltestrecord[i] = fulltest
  print("All tests passed? ")
  if fulltest
    printstyled(fulltest,color=:green)
  else
    printstyled(fulltest,color=:red)
  end
  println()
end

"""
  testlib([,tests=,path=libdir*"/test/"])

Tests all functions in the files enumerated in `tests`. Default is to check all test functionality in the library. Used in nightly builds. See format in `/tests/` folder

See also: [`libdir`](@ref)
"""
function testlib(tests::Array{String,1}=tests;dir::String=libdir,testpath::String=dir*"/test/")

  fulltestrecord = Array{Bool,1}(undef,length(tests))

  for i = 1:length(tests)
    testpath = testpath
    @time fulltest = include(testpath*tests[i])
    checkall(fulltestrecord,i,fulltest)
  end

  println()

  for i = 1:length(tests)
    if fulltestrecord[i]
      printstyled(fulltestrecord[i],color=:green)
    else
      printstyled(fulltestrecord[i],color=:red)
    end
    println("    ",i,"   ",tests[i])
  end

  println()

  if sum(fulltestrecord) == length(tests)
    println("All passed. Good work. We happy :^)")
  else
    println("These passed:")
    printstyled(tests[fulltestrecord],color=:green)
    println()
    println()
    println("These did not pass:")
    notfulltestrecord = [!fulltestrecord[w] for w = 1:length(tests)]
    printstyled(tests[notfulltestrecord],color=:red)
  end
end
export testlib

end
