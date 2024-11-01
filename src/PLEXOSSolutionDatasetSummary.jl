eval(Expr(
    :struct, true, :PLEXOSSolutionDatasetSummary, Expr(:block,
        [:($(t.fieldname)::Tuple{Int,Int}) for t in plexostables]...
    )
))

PLEXOSSolutionDatasetSummary() =
    PLEXOSSolutionDatasetSummary(((0,0) for _ in 1:length(plexostables))...)

function PLEXOSSolutionDatasetSummary(
    zippath::String, xmlname::String=defaultxml(zippath)
)

    resultsarchive = _open_plexoszip(zippath)
    xml = parsexml(resultsarchive[xmlname])
    return PLEXOSSolutionDatasetSummary(xml)

end

function PLEXOSSolutionDatasetSummary(xml::Document)

    summary = PLEXOSSolutionDatasetSummary()

    for element in eachelement(xml.root)

        # Ignore given tables:
        !(element.name in keys(plexostables_lookup)) && continue
        
        table = plexostables_lookup[element.name]
        count, maxidx = getfield(summary, table.fieldname)

        if isnothing(table.identifier)
            setfield!(summary, table.fieldname, (count + 1, count + 1))
        else
            idx = getchildint(table.identifier, element) + table.indexoffset
            setfield!(summary, table.fieldname, (count + 1, max(maxidx, idx)))
        end

    end

    return summary

end
