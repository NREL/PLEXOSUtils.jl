using PLEXOSUtils

# TODO: Actually test things
function runtest(zippath::String)
    PLEXOSSolutionDatasetSummary(zippath)
    PLEXOSSolutionDataset(zippath)
end

testfolder = dirname(@__FILE__) * "/"

zipfiles = ["Model Base_8200 Solution.zip",
            "Model DAY_AHEAD_NO_TX Solution.zip",
            "Model DAY_AHEAD_ALL_TX Solution.zip",
            "Model DA_h2hybrid_SCUC_select_lines_Test_1day Solution.zip",
            "Model DAY_AHEAD_PRAS Solution.zip"]

for zipfile in zipfiles
    println(zipfile)
    runtest(testfolder * zipfile)
end
