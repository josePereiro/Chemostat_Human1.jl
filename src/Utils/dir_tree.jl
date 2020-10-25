const PROJ_ROOT = dirname(dirname(@__DIR__))
const DEPS_DIR = joinpath(PROJ_ROOT, "deps")
const DATA_DIR = joinpath(PROJ_ROOT, "data")
    const RAW_DATA_DIR = joinpath(DATA_DIR, "raw")
        const HUMAN1_PROBLICATION_RAW_DATA_DIR = joinpath(RAW_DATA_DIR, HUMAN1_PROBLICATION_PROJ_NAME)
        const HUMAN1_PROBLICATION_ZIP_FILE = joinpath(RAW_DATA_DIR, "$HUMAN1_PROBLICATION_PROJ_NAME.zip")
    const PROCESSED_DATA_DIR = joinpath(DATA_DIR, "processed")
        const MODELS_DIR = joinpath(PROCESSED_DATA_DIR, "models")
        const PREDICTION_RESULTS_DIR = joinpath(PROCESSED_DATA_DIR, "prediction_results")
        const CACHE_DIR = joinpath(PROCESSED_DATA_DIR, "cache")
    const FIGURES_DATA_DIR = joinpath(DATA_DIR, "figures")


function _make_dirs()
    for dir in [DATA_DIR, RAW_DATA_DIR, DEPS_DIR, MODELS_DIR, 
                PREDICTION_RESULTS_DIR, PROCESSED_DATA_DIR, 
                FIGURES_DATA_DIR, CACHE_DIR]
        if !isdir(dir)
            mkpath(dir)
        end
    end
end