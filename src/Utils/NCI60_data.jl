## --------------------------------------------------------------------
# Load exchange NCI60 data
const NCI60_exchanges = Dict()
function _load_NCI60_exchanges_data()
    empty!(NCI60_exchanges)
    for model_type in [EC_MODEL_TYPE_KEY, MODEL_TYPE_KEY]
        dict = get!(NCI60_exchanges, model_type, Dict())
        for const_level in CONSTRAINTS_LEVELS
            filename = string(model_type, "s_const_", const_level, "_exchangeFluxesComp.txt")
            path = joinpath(HUMAN1_NCI60_RESULTS_DIR, filename)
            !isfile(path) && continue
            dict[const_level] = CSV.read(path)
        end
    end
end

## --------------------------------------------------------------------
# INTERFACE
get_NCI60_msd_exchanges(model_type, const_level) = String.(NCI60_exchanges[model_type][const_level][:, :exchangeIDs])
get_NCI60_msd_exchanges_mets(model_type, const_level) = String.(NCI60_exchanges[model_type][const_level][:, :exchangeMets])

function get_NCI60_exchange(model_type, cell_line, const_level, data_type) 
    df = NCI60_exchanges[model_type][const_level]
    k = data_type == :exp ? Symbol(string("exp_", cell_line)) : Symbol(cell_line)
    Float64.(df[:, k])
end

get_NCI60_exchange(model_type, cell_line, const_level, data_type, idx::Int) = 
    get_NCI60_exchange(model_type, cell_line, const_level, data_type)[idx]

function get_NCI60_exchange(model_type, cell_line, const_level, data_type, ider::String)
    exchs = get_NCI60_msd_exchanges(model_type, const_level)
    mets = get_NCI60_msd_exchanges_mets(model_type, const_level)
    idx = something(findfirst(isequal(ider), exchs), findfirst(isequal(ider), mets), -1)
    idx == -1 && error("'$ider' not found")
    get_NCI60_exchange(model_type, cell_line, const_level, data_type, idx)
end