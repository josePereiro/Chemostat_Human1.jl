const PROJ_ROOT = dirname(dirname(@__DIR__))
const DEPS_DIR = joinpath(PROJ_ROOT, "deps")
const DATA_DIR = joinpath(PROJ_ROOT, "data")
    const RAW_DATA_DIR = joinpath(DATA_DIR, "raw")
        const HUMAN1_PROBLICATION_RAW_DATA_DIR = joinpath(RAW_DATA_DIR, HUMAN1_PUBLICATION_PROJ_NAME)
        const HUMAN1_PROBLICATION_ZIP_FILE = joinpath(RAW_DATA_DIR, "$HUMAN1_PUBLICATION_PROJ_NAME.zip")
    const PROCESSED_DATA_DIR = joinpath(DATA_DIR, "processed")
        const HUMAN1_MODELS_DIR = joinpath(PROCESSED_DATA_DIR, "human1_models")
        const FVA_PP_MODELS_DIR = joinpath(PROCESSED_DATA_DIR, "fva_pp_models")
        const HUMAN1_RESULTS_DIR = joinpath(PROCESSED_DATA_DIR, "human1_results")
        const HUMAN1_NCI60_RESULTS_DIR = joinpath(HUMAN1_RESULTS_DIR, "11_cellLines_NCI60")
        const CACHE_DIR = joinpath(PROCESSED_DATA_DIR, "cache")
    const FIGURES_DATA_DIR = joinpath(DATA_DIR, "figures")


function _make_dirs()
    for dir in [DATA_DIR, RAW_DATA_DIR, DEPS_DIR, HUMAN1_MODELS_DIR, 
                HUMAN1_RESULTS_DIR, PROCESSED_DATA_DIR, 
                FIGURES_DATA_DIR, FVA_PP_MODELS_DIR, CACHE_DIR]
        if !isdir(dir)
            mkpath(dir)
        end
    end
end