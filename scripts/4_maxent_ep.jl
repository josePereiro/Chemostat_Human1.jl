## --------------------------------------------------------------------
import DrWatson: quickactivate
quickactivate(@__DIR__, "Chemostat_Human1")

import MAT
import SparseArrays
import Chemostat_Human1
const H1 = Chemostat_Human1
import Chemostat_Human1: Chemostat
ChU = Chemostat.Utils
ChLP = Chemostat.LP
ChSU = Chemostat.SimulationUtils
ChU.set_cache_dir(H1.CACHE_DIR)

## --------------------------------------------------------------------
# Tools
fba_objval(model) = ChLP.fba(model, H1.BIOMASS_IDER).obj_val

## --------------------------------------------------------------------
# here I should load a fva_pp_model
cell_line = "RPMI_8226"
const_level = 0
model_type = :ecModel
model_file = H1.get_human1_model_file(cell_line, const_level, model_type)
exp_grate = H1.get_NCI60_exchange(model_type, cell_line, const_level, :exp, "biomass") 
println("exp objval:   ", exp_grate)
model = ChU.read_mat(model_file);
model = ChU.clampfields!(model, [:b, :lb, :ub]; abs_max = 100.0, zeroth = 1e-8)
println("model objval: ", fba_objval(model))
model = ChLP.fva_preprocess(model; check_obj = H1.BIOMASS_IDER)
println("model objval: ", fba_objval(model))
fvafile = joinpath(H1.FVA_PP_MODELS_DIR, "fva_pp_model.bson")
ChU.save_data(fvafile, ChU.compressed_model(model))

## --------------------------------------------------------------------
# loda cached
# model = ChU.load_data(fvafile);
# model = ChU.uncompressed_model(model)
# model = ChU.clampfields!(model, [:b, :lb, :ub]; abs_max = 100.0, zeroth = 1e-8)
# println("model size:   ", size(model))
# println("model objval: ", fba_objval(model))

## --------------------------------------------------------------------
# This must uniquely identify the script
const SIM_IDER = "maxent_ep_v1"

## --------------------------------------------------------------------
# epouts
const cache_id = (:EP_OUTS, SIM_IDER)
dat = ChU.load_cache(cache_id; verbose = false)
const epouts = something(dat, Dict())

## --------------------------------------------------------------------
# find exp_beta
exp_beta = ChSU.find_beta(model; beta0 = 0.0, beta1 = 1000.0, 
    obj_ider = H1.BIOMASS_IDER, errorth = 0.1,
    target_objval = exp_grate, epouts,
    after_maxent_ep = function(epout)
        # caching results
        ChU.save_cache(cache_id, epouts)
    end
)

## --------------------------------------------------------------------
# saving
ChU.save_data("maxent_ep_data.bson", (exp_beta, ChU.compressed_model(fva_pp_model), epouts))

