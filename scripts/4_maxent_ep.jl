import DrWatson: quickactivate
quickactivate(@__DIR__, "Chemostat_Human1")

# --------------------------------------------------------------------
using ArgParse

set = ArgParseSettings()
@add_arg_table! set begin
    "--name", "-n"
        help = "A name that uniquely identify the simulation, it is used in caching"
        default = "maxent_ep_v1"
        required = false
    "--beta0"
        help = "the lower limit of the range to search experimental beta"
        default = "0.0"
        required = false
    "--beta1"
        help = "the upper limit of the range to search experimental beta"
        default = "10000.0"
        required = false
end

if isinteractive()
    # This must uniquely identify the script
    const SIM_IDER = "maxent_ep_v1"
    const beta0 = 0.0
    const beta1 = 10000.0
else
    const parsed_args = parse_args(set)
    # This must uniquely identify the script
    const SIM_IDER = parsed_args["name"]
    const beta0 = parse(Float64, parsed_args["beta0"])
    const beta1 = parse(Float64, parsed_args["beta1"])
    
end
println("sim_ider: ", SIM_IDER)
println("beta0: ", beta0)
println("beta1: ", beta1)

## --------------------------------------------------------------------
import MAT
import SparseArrays

import Chemostat_Human1
const H1 = Chemostat_Human1

import Chemostat
const Ch = Chemostat
const ChU = Ch.Utils
const ChLP = Ch.LP
const ChSU = Ch.SimulationUtils
ChU.set_cache_dir(H1.CACHE_DIR)

## --------------------------------------------------------------------
# Tools
fba_objval(model) = ChLP.fba(model, H1.BIOMASS_IDER).obj_val
# data/processed/fva_pp_models/constLevel_0/HS_578T__ecModel.bson

## --------------------------------------------------------------------
# here I should load a fva_pp_model
cell_line = "HS_578T"
const_level = 0
model_type = :ecModel
model_file = H1.get_human1_model_file(cell_line, const_level, model_type)
@assert isfile(model_file)
exp_grate = H1.get_NCI60_exchange(model_type, cell_line, const_level, :exp, "biomass") 
println("exp objval:   ", exp_grate)
model = ChU.read_mat(model_file);
# model = ChU.clampfields!(model, [:b, :lb, :ub]; abs_max = 100.0, zeroth = 1e-8)
println("model size:   ", size(model))
println("model objval: ", fba_objval(model))
# model = ChLP.fva_preprocess(model; check_obj = H1.BIOMASS_IDER)
# println("model objval: ", fba_objval(model))
# fvafile = joinpath(H1.FVA_PP_MODELS_DIR, "fva_pp_model.bson")
# ChU.save_data(fvafile, ChU.compressed_model(model))

## --------------------------------------------------------------------
# load cache Test
# model = ChU.load_data(model_file);
# model = ChU.uncompressed_model(model)
# model = ChU.clampfields!(model, [:b, :lb, :ub]; abs_max = 100.0, zeroth = 1e-8)
# println("model size:   ", size(model))
# println("model objval: ", fba_objval(model))


## --------------------------------------------------------------------
# epouts
const cache_id = (:EP_OUTS, SIM_IDER)
dat = ChU.load_cache(cache_id; verbose = false)
const epouts = something(dat, Dict())

## --------------------------------------------------------------------
# find exp_beta
exp_beta = ChSU.find_beta(model; beta0, beta1, 
    obj_ider = H1.BIOMASS_IDER, errorth = 0.1,
    target_objval = exp_grate, epouts,
    after_maxent_ep = function(epout)
        # caching results
        ChU.save_cache(cache_id, epouts)
    end
)

## --------------------------------------------------------------------
# saving
ChU.save_data("maxent_ep_data.bson", (exp_beta, ChU.compressed_model(model), epouts))

