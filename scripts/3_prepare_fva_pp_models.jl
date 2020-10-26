## --------------------------------------------------------------------
import DrWatson: quickactivate
quickactivate(@__DIR__, "Chemostat_Human1")

import MAT
import Chemostat_Human1
const H1 = Chemostat_Human1
import Chemostat_Human1: Chemostat
ChU = Chemostat.Utils
ChLP = Chemostat.LP

## --------------------------------------------------------------------
# Tools
fba_objval(model) = ChLP.fba(model, H1.BIOMASS_IDER).obj_val

## --------------------------------------------------------------------
# Processing all models
for cell_line in H1.CELL_NAMES
    for (const_name, const_level) in zip(H1.CONSTRAINTS_NAMES, 
                                        H1.CONSTRAINTS_LEVELS)
        for model_type in [H1.MODEL_TYPE_KEY, H1.EC_MODEL_TYPE_KEY]    
            
            ChU.println_inmw("\n")
            ChU.tagprintln_inmw("PROCESSING:",  
                "\ncellLine:     ", cell_line, 
                "\nconst_level:  ", const_level, 
                "\nconst_name:   ", const_name, 
                "\nmodel_type:   ", model_type, 
                "\n"
            )

            model_file = H1.get_human1_model_file(cell_line, const_level, model_type)
            isfile(model_file) ? ChU.println_inmw(string(relpath(model_file), " found!!")) : 
                    (ChU.println_inmw(string("ERROR: ", relpath(model_file), " not found!!")), continue)

            
            ## --------------------------------------------------------------------
            # Check for existing file
            fva_pp_model_file = H1.get_fva_pp_model_file(cell_line, const_level, model_type)
            if isfile(fva_pp_model_file)
                ChU.println_inmw(relpath(fva_pp_model_file), " exist, skipping!")
                continue
            end
            
            ## --------------------------------------------------------------------
            # Loading
            model_key, model_mat = first(MAT.matread(model_file));
            model = ChU.MetNet(model_mat; reshape = true);
            ChU.clampfileds!(model, [:b, :lb, :ub]; 
                abs_max = H1.MAX_ABS_BOUND, zeroth = H1.ZEROTH)
            ChU.println_inmw("size: ", size(model))
            println("Orig model objval: ", fba_objval(model))

            ## --------------------------------------------------------------------
            # Redefine all rxns to be a single reaction fwd defined
            function is_exchange(model::ChU.MetNet, ider::ChU.IDER_TYPE)
                idx = ChU.rxnindex(model, ider)
                subsys = model.subSystems[idx]
                return occursin(H1.EXCH_SUBSYS_HINT, string(subsys))
            end
            exchs = filter((rxn) -> is_exchange(model, rxn), model.rxns);
            found_buffer = Set()
            for exch in exchs
                exch in found_buffer && continue
                if endswith(exch, "_REV")
                    rxn_rev = exch
                    rxn = replace(exch, "REV_")
                else
                    rxn = exch
                    rxn_rev = string(exch, "_REV")
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
            end
            ChU.println_inmw("After first preprocessing, objval: ", fba_objval(model))

            # Checking
            for exch in exchs
                if ChU.isbkwd_defined(model, exch) && 
                        ChU.isopen(model, exch)
                    error(string(exch, "is an open backward defined reaction"))
                end
            end
            
            ## --------------------------------------------------------------------
            # FVA preprocessing
            fva_pp_model = ChLP.fva_preprocess(model, check_obj = H1.BIOMASS_IDER);
            ChU.println_inmw("size: ", size(fva_pp_model))
            fva_pp_model = model # test

            # Checking
            ChU.println_inmw("fva preprocessed model, objval: ", fba_objval(model))

            ## --------------------------------------------------------------------
            # Saving
            mkpath(fva_pp_model_file |> dirname)
            ChU.save_data(fva_pp_model_file, ChU.compressed_model(fva_pp_model))

        end

    end
end

