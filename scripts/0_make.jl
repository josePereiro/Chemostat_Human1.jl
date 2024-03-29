#TODO: find julia native alternative for it
#=
    This script just run all the other scripts in the correct order.
=#

## ------------------------------------------------------------------------
using ArgParse

# function check_clear_args(args)
#     for arg in split(args, ",")
#         !(arg in ["all", "base", "maxent_ep", "fva_pp", "cache"]) && return false
#     end
#     return true
# end

set = ArgParseSettings()
@add_arg_table! set begin
    "--force-pull"
        help = "make a sync with the remote"
        action = :store_true
    "--install"
        help = "run an installation script"
        action = :store_true
    "--clear-cache"
        help = "clear the cache folder"
        action = :store_true
    "--clear-fva-models"
        help = "clear the fva_pp_models folder"
        action = :store_true
    
    # "--dry-run"
    #     help = "run without consecuences, just printing"
    #     action = :store_true
    # "--run", "-r", "-x"
    #     help = "possible values: \"all\" (run all the scripts),  " *
    #                              "\"base\" (run only the base model scripts), " *
    #                              "\"none\" (run nothing)"
    #     default = "base"
    #     required = false
    #     range_tester = (x -> x in ["all", "base", "none"])
    # "--clear", "-c"
    #     help = "possible values: \"raw\" (clear raw data folder), " *
    #                             "\"all\" (clear all the scripts targets), " *
    #                             "\"base\" (clear only the base model scripts targets), " *
    #                             "\"maxent_ep\" (clear only the maxent_ep bundles), " *
    #                             "\"fva_pp\" (clear only the fva preprocess models), " *
    #                             "\"cache\" (clear the cache forder). " *
    #                             "You can pass several using comma Ex: --clear=cache,maxent"
    #     required = false
    #     range_tester = check_clear_args
end

if isinteractive()
    # Dev vals
    force_pull_flag = false
    install_flag = false
    clear_cache_flag = false
    clear_fva_models_flag = false
else
    parsed_args = parse_args(set)
    force_pull_flag = parsed_args["force-pull"]
    install_flag = parsed_args["install"]
    clear_cache_flag = parsed_args["clear-cache"]
    clear_fva_models_flag = parsed_args["clear-fva-models"]
    # clear_args = parsed_args["clear"]
    # clear_args = isnothing(clear_args) ? nothing : split(clear_args, ",")
end

## ------------------------------------------------------------------------
using Pkg
try import DrWatson
catch
    import Pkg
    pkg"add DrWatson"
end
import DrWatson: quickactivate
quickactivate(@__DIR__, "Chemostat_Human1")

## ------------------------------------------------------------------------
function force_pull()
    here = pwd()
    cd(@__DIR__)
    run(`git reset -q HEAD -- .`)
    run(` git checkout -- .`)
    try;
        run(`git pull`)
    catch err
        @warn string("fail to pull: error ", err)
    end
    cd(here)
end
force_pull_flag && force_pull()

## ------------------------------------------------------------------------
if install_flag
    # sync
    force_pull()
    # Install unregistered packages
    try
        pkg"rm Chemostat"
        pkg"rm UtilsJL"
    catch; end
    pkg"add https://github.com/josePereiro/UtilsJL.git#master"
    pkg"add https://github.com/josePereiro/Chemostat#adbeb2f"
    pkg"instantiate"
    pkg"build"
    pkg"test Chemostat"
end

## ------------------------------------------------------------------------
import Chemostat_Human1
const H1 = Chemostat_Human1
cd(H1.PROJ_ROOT)

## ------------------------------------------------------------------------
# clear stuff
if clear_cache_flag
    if isdir(H1.CACHE_DIR)
        rm(H1.CACHE_DIR, force = true, recursive = true)
        @info string(relpath(H1.CACHE_DIR), " deleted!!!")
    end
end

if clear_fva_models_flag
    if isdir(H1.FVA_PP_MODELS_DIR)
        rm(H1.FVA_PP_MODELS_DIR, force = true, recursive = true)
        @info string(relpath(H1.FVA_PP_MODELS_DIR), " deleted!!!")
    end
end