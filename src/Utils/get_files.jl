
get_human1_model_file(id, constLevel::Int, type) = joinpath(HUMAN1_MODELS_DIR, 
                                                string("constLevel_", constLevel), 
                                                string(id, type == MODEL_TYPE_KEY ? 
                                                            MODEL_TYPE_SUFFIX : EC_MODEL_TYPE_SUFFIX, 
                                                        ".mat"))


get_fva_pp_model_file(id, constLevel::Int, type) = joinpath(FVA_PP_MODELS_DIR, 
                                                string("constLevel_", constLevel), 
                                                string(id, type == MODEL_TYPE_KEY ? 
                                                            MODEL_TYPE_SUFFIX : EC_MODEL_TYPE_SUFFIX, 
                                                        ".bson"))