## --------------------------------------------------------------------
import DrWatson: quickactivate
quickactivate(@__DIR__, "Chemostat_Human1")

import MAT
import ProgressMeter: Progress, next!, update!, finish!
import Chemostat_Human1
const H1 = Chemostat_Human1
import Chemostat_Human1: Chemostat
ChU = Chemostat.Utils
ChLP = Chemostat.LP

## --------------------------------------------------------------------
function test_fba(model)
    fbaout = ChLP.fba(model, H1.BIOMASS_IDER)
    println("FBA TEST")
    println("Biomass flux: ", fbaout.obj_val)
end

## --------------------------------------------------------------------
model_file = joinpath(H1.MODELS_DIR, "constLevel_0", "HOP62__ecModel.mat")
@assert isfile(model_file)
model_mat = MAT.matread(model_file)["ecModel_batch"];
model = ChU.MetNet(model_mat; reshape = true);
test_fba(model)

## --------------------------------------------------------------------
# Redefine all rxns to be a single reaction fwd defined
function is_exchange(model::ChU.MetNet, ider::ChU.IDER_TYPE)
    idx = ChU.rxnindex(model, ider)
    subsys = model.subSystems[idx]
    return occursin(H1.EXCH_SUBSYS_HINT, string(subsys))
end
exchs = filter((rxn) -> is_exchange(model, rxn), model.rxns);
let found_buffer = Set()
    prog = Progress(length(exchs))
    for exch in exchs
        exch in found_buffer && continue
        if endswith(exch, "_REV")
            rxn_rev = exch
            rxn = replace(exch, "REV_")
        else
            rxn = exch
            rxn_rev = string(exch, "_REV")
            rxn_rev = rxn_rev in exchs ? rxn_rev : nothing
        end
        push!(found_buffer, rxn, rxn_rev)

        rxn_exist = rxn in exchs
        rxn_rev_exist = rxn_rev in exchs

        if rxn_exist && rxn_rev_exist
            # merge bounds
            ChU.bounds!(model, rxn, 
                # [A <- ]lb == -[ -> A]ub
                min(ChU.lb(model, rxn), -ChU.ub(model, rxn_rev)),
                max(ChU.ub(model, rxn), -ChU.lb(model, rxn_rev)),
            )
            # Close rev
            ChU.bounds!(model, rxn_rev, 0.0, 0.0)
        elseif rxn_rev_exist
            # revert rev reaction
            ChU.invert_rxn!(model, rxn_rev; rename = rxn)
        end

        # println(rxn, ": ", ChU.rxn_str(model, rxn))
        next!(prog)
    end
    finish!(prog)
end
@assert filter(model.rxns) do rxn
    return is_exchange(model, rxn) && ChU.isbkwd_bounded(model, rxn)
end |> isempty
test_fba(model)

## --------------------------------------------------------------------
