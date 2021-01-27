import DrWatson: quickactivate
quickactivate(@__DIR__, "Chemostat_Human1")

# ------------------------------------------------------------------
# ARGS
import ArgParse: ArgParseSettings, @add_arg_table!, parse_args

set = ArgParseSettings()
@add_arg_table! set begin
    "--no-restart"
        help = "Do not restart env"
        action = :store_true
    "--comparativeFVA"
        help = "run comparativeFVA_humanModels function"
        action = :store_true
    "--predictGRate"
        help = "run predict_cellLines_gRates script"   
        action = :store_true
end

if isinteractive()
    no_restart_flag = false
    comparativeFVA_flag = false
    predictGRate_flag = false
else
    parsed_args = parse_args(set)
    no_restart_flag = parsed_args["no-restart"]
    comparativeFVA_flag = parsed_args["comparativeFVA"]
    predictGRate_flag = parsed_args["predictGRate"]
end

# --------------------------------------------------------------------

import Chemostat_Human1
const H1 = Chemostat_Human1
import Chemostat_Human1: Chemostat
const ChU = Chemostat.Utils

import MATLAB
import MATLAB: @mat_str, eval_string, @mget, mxcall, @show 
import ProgressMeter: ProgressUnknown, next!, finish!

## --------------------------------------------------------------------
# Systems
const PATHS_TO_DEL = Set{String}()
atexit() do
    for path in PATHS_TO_DEL
        try; rm(path, force = true, recursive = true) catch end
    end
    try; string_eval("path('$(MATPATH0)')") catch end # restore initial path
end

# flushing buffers
@async while true
    flush.([stderr, stdout])
    sleep(5 + 10 * rand())
end

## --------------------------------------------------------------------
# testing MATLAB connection
println("Testing MATLAB connection")
try; mat"disp(['Hello from MATLAB ' version])"
    @eval string("Connection OK")
catch err
    error("ERROR CALLING MATLAB:\n"*
          "I use MATLAB.jl, see https://github.com/JuliaInterop/MATLAB.jl for help:\n"*
          ChU.err_str(err)
        )
end
# Initial path
const MATPATH0 = let
    mat"str_path = path"
    str_path = @mget str_path
    mat"clear str_path"
    str_path
end;

## --------------------------------------------------------------------
# MAT TOOLS
function get_matpath()
    mat"str_path = path"
    str_path = @mget str_path
    mat"clear str_path"
    split(str_path, ":")
end

matwhich(ider) = mxcall(:which, 1, string(ider));
matcd(dir) = (mxcall(:cd, 1, string(dir)); mat"disp(['pwd: ' pwd])")
addto_matpath(path; addsubs = true) = addsubs ? 
    eval_string("path([genpath('$path') pathsep path])") : 
    eval_string("path('$path', path)")
mxcall_ans(x...) = (mxcall(x...); @mget ans)
meval_ans(exp::String) = (eval_string(exp); @mget ans)

function plant_matlocator(path)
    path = endswith(path, ".m") ? path : path * ".m"
    fun_name = replace(basename(path), ".m" => "")
    src = """
    function [ dir ] = $fun_name()
        % return the directory where this function is placed
            script_file = mfilename('fullpath');
            parts = strsplit(script_file, filesep);
            dir  = strjoin(parts(1:end-1), filesep);
        end
    """
    write(path, src)
    addto_matpath(path |> dirname; addsubs = false)
    push!(PATHS_TO_DEL, path)
    @assert abspath(path |> dirname) == mxcall_ans(Symbol(fun_name), 0)
    path
end

## --------------------------------------------------------------------
# SETTING HUMAN1 DEPS
println("Setting up Human1 deps")
HERE = @__DIR__
cd(HERE); matcd(HERE)
mat"clear"

## --------------------------------------------------------------------
println("Setting up COBRA Toolbox")
cobra_dir = joinpath(H1.DEPS_DIR, "cobratoolbox")
if !isdir(cobra_dir)
    run(`git clone --depth=1 https://github.com/opencobra/cobratoolbox.git $cobra_dir`)
    @info string("cobratoolbox cloned at: ", relpath(cobra_dir))
else
    @info string("cobratoolbox found at: ", relpath(cobra_dir))
    cd(cobra_dir); run(`git checkout -- .`); cd(HERE)
end
# run initCobraToolbox
@info string("running initCobraToolbox")
addto_matpath(cobra_dir; addsubs = false)
matcd(cobra_dir)
mat"initCobraToolbox(false)"
matcd(HERE)

## --------------------------------------------------------------------
println("Setting up GECKO Toolbox")
gecko_dir = joinpath(H1.DEPS_DIR, "GECKO")
if !isdir(gecko_dir)
    # run(`git clone https://github.com/SysBioChalmers/GECKO $gecko_dir`)
    run(`git clone /Users/Pereiro/Documents/MATLAB/GECKO $gecko_dir`) # dev
    @info string("GECKO cloned at: ", relpath(gecko_dir))
else
    @info string("GECKO found at: ", relpath(gecko_dir))
    cd(gecko_dir); run(`git checkout -- .`); cd(HERE)
end
addto_matpath(gecko_dir; addsubs = true)

## --------------------------------------------------------------------
println("Setting up RAVEN Toolbox")
raven_dir = joinpath(H1.DEPS_DIR, "RAVEN")
if !isdir(raven_dir)
    run(`git clone https://github.com/SysBioChalmers/RAVEN $raven_dir`)
    # run(`git clone /Users/Pereiro/Documents/MATLAB/RAVEN $raven_dir`) # Dev
    @info string("RAVEN cloned at: ", relpath(raven_dir))
else
    @info string("RAVEN found at: ", relpath(raven_dir))
    cd(raven_dir); run(`git checkout -- .`); cd(HERE)
end
addto_matpath(raven_dir; addsubs = true)

## --------------------------------------------------------------------
# Prepare playground
temp_dir = joinpath(H1.PROJ_ROOT, "temp")
if !no_restart_flag
    push!(PATHS_TO_DEL, temp_dir)
    rm(temp_dir, force = true, recursive = true)
    cp(H1.HUMAN1_PROBLICATION_RAW_DATA_DIR, temp_dir, force = true);
    addto_matpath(temp_dir; addsubs = true)
    cd(HERE)
end
@assert isdir(temp_dir)

## --------------------------------------------------------------------
# Plant markers
plant_matlocator(joinpath(H1.HUMAN1_MODELS_DIR, "get_models_folder"))
plant_matlocator(joinpath(H1.CACHE_DIR, "get_cache_folder"))
plant_matlocator(joinpath(H1.HUMAN1_RESULTS_DIR, "get_results_folder"))
plant_matlocator(joinpath(temp_dir, "get_proj_folder"))

## --------------------------------------------------------------------
matscripts_dir = joinpath(H1.PROJ_ROOT, "scripts", "matlab_scripts")

## --------------------------------------------------------------------
# Run coparative_FVA_humanModels
if comparativeFVA_flag
    # prepare comparativeFVA_humanModels
    cd(matscripts_dir)
    try
        cp("my_comparativeFVA_humanModels", matwhich("comparativeFVA_humanModels"); force = true);
        @info "comparativeFVA_humanModels updated"
    catch; rethrow() end

    # prepare GECKO
    cd(gecko_dir); wait(run(`git checkout 45804e1`))
    cd(matscripts_dir)
    try
        cp("my_comparativeFVA", matwhich("comparativeFVA"); force = true);
        @info "comparativeFVA updated"
    catch; rethrow() end

    # prepare RAVEN
    cd(raven_dir); wait(run(`git checkout -- .`))
    cd(matscripts_dir)
    try
        cp("my_setExchangeBounds", matwhich("setExchangeBounds"); force = true);
        @info "setExchangeBounds updated"
    catch; rethrow() end
    cd(HERE)

    @assert isdir(matscripts_dir)
    # run simulation
    mat"clear"
    mat"cellLine = 'HOP62'"
    mat"comparativeFVA_humanModels(cellLine)"
end

## --------------------------------------------------------------------
# run predict cellLines
if predictGRate_flag
    # prepare GECKO
    cd(gecko_dir); wait(run(`git checkout 45804e1`))
    # prepare RAVEN
    cd(raven_dir); wait(run(`git checkout -- .`))
    cd(matscripts_dir)
    try
        cp("my_setExchangeBounds", matwhich("setExchangeBounds"); force = true);
        @info "setExchangeBounds updated"
    catch; rethrow() end
    # prepare comparativeFVA_humanModels
    try
        cp("my_predict_cellLines_gRates", matwhich("predict_cellLines_gRates"); force = true);
        @info "predict_cellLines_gRates updated"
    catch; rethrow() end
    try
        cp("my_ExchFluxesComparison_NCI60", matwhich("ExchFluxesComparison_NCI60"); force = true);
        @info "ExchFluxesComparison_NCI60 updated"
    catch; rethrow() end

    # run simulation
    sim_folder = joinpath(temp_dir, "ec_GEMs/ComplementaryScripts")
    matcd(sim_folder); cd(sim_folder)
    mat"clear"
    mat"predict_cellLines_gRates"
    cd(HERE)
end
