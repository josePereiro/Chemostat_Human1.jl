module Chemostat_Human1

    import Chemostat
    import CSV
    import DataFrames: DataFrame
    
    include("Utils/Utils.jl")

    function __init__()
        _make_dirs()
        _load_NCI60_exchanges_data()
    end
end
