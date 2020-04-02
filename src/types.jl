abstract type AbstractDataset end

# Metadata

struct PLEXOSConfig
    element::String
    value::String
end

PLEXOSConfig(e::Node, ::AbstractDataset) = PLEXOSConfig(
    getchildtext("element", e),
    getchildtext("value", e)
)


struct PLEXOSUnit
    value::String
end

PLEXOSUnit(e::Node, ::AbstractDataset) =
    PLEXOSUnit(getchildtext("value", e))


struct PLEXOSTimeslice
    name::String
end

PLEXOSTimeslice(e::Node, ::AbstractDataset) =
    PLEXOSTimeslice(getchildtext("name", e))


struct PLEXOSModel
    name::String
end

PLEXOSModel(e::Node, ::AbstractDataset) =
    PLEXOSModel(getchildtext("name", e))


struct PLEXOSSample
    name::String
end

PLEXOSSample(e::Node, ::AbstractDataset) =
    PLEXOSSample(getchildtext("sample_name", e))

struct PLEXOSSampleWeight
    sample::PLEXOSSample
    phase::Int # maybe Parametrize on this?
    value::Float64
end

PLEXOSSampleWeight(e::Node, d::AbstractDataset) =
    # TODO: Abstract away zero-indexing here?
    PLEXOSSampleWeight(d.samples[getchildint("sample_id", e) + 1],
                       getchildint("phase_id", e),
                       getchildfloat("value", e))

struct PLEXOSClassGroup
    name::String
end

PLEXOSClassGroup(e::Node, ::AbstractDataset) =
    PLEXOSClassGroup(getchildtext("name", e))

struct PLEXOSClass
    name::String
    classgroup::PLEXOSClassGroup
    state::Int
end

PLEXOSClass(e::Node, d::AbstractDataset) =
    PLEXOSClass(getchildtext("name", e),
                d.classgroups[getchildint("class_group_id", e)],
                getchildint("state", e))


struct PLEXOSCategory
    name::String
    rank::Int
    class::PLEXOSClass

    # PLEXOS sometimes reports categories without reporting the classes they
    # refer to: if that happens, just leave the class undefined
    # (category won't have any objects anyways)

    function PLEXOSCategory(e::Node, d::AbstractDataset)

        class_idx = getchildint("class_id", e)

        if isassigned(d.classes, class_idx)
            new(getchildtext("name", e),
                getchildint("rank", e),
                d.classes[class_idx])
        else
            new(getchildtext("name", e),
                getchildint("rank", e))
        end

    end

end


struct PLEXOSAttribute
    name::String
    description::String
    enum::Int
    class::PLEXOSClass
end

PLEXOSAttribute(e::Node, d::AbstractDataset) =
    PLEXOSAttribute(getchildtext("name", e),
                    getchildtext("description", e),
                    getchildint("enum_id", e),
                    d.classes[getchildint("class_id", e)])


struct PLEXOSCollection
    name::String
    complementname::Union{Nothing,String}
    parentclass::PLEXOSClass
    childclass::PLEXOSClass

    # PLEXOS sometimes reports collections without reporting the classes they
    # refer to: if that happens, just leave the classes undefined
    # (collection won't have any members anyways)

    function PLEXOSCollection(e::Node, d::AbstractDataset)

        name = getchildtext("name", e)
        cname = getchildtext("complement_name", e)
        cname == "" && (cname = nothing)

        parent_idx = getchildint("parent_class_id", e)
        child_idx = getchildint("child_class_id", e)

        if isassigned(d.classes, parent_idx) && isassigned(d.classes, child_idx)
            new(name, cname, d.classes[parent_idx], d.classes[child_idx])
        else
            new(name, cname)
        end

    end

end


struct PLEXOSProperty
    name::String
    summaryname::String
    enum::Int
    unit::PLEXOSUnit 
    summaryunit::PLEXOSUnit
    ismultiband::Bool
    isperiod::Bool
    issummary::Bool
    collection::PLEXOSCollection

    # PLEXOS sometimes reports properties without reporting the collections they
    # refer to: if that happens, just leave the collections undefined
    # (property won't have any data anyways)

    function PLEXOSProperty(e::Node, d::AbstractDataset)

        collection_idx = getchildint("collection_id", e)

        name = getchildtext("name", e)
        summary_name = getchildtext("summary_name", e)
        enum = getchildint("enum_id", e)
        unit = d.units[getchildint("unit_id", e) + 1]
        summary_unit = d.units[getchildint("summary_unit_id", e) + 1]
        is_multiband = getchildbool("is_multi_band", e)
        is_period = getchildbool("is_period", e)
        is_summary = getchildbool("is_summary", e)

        if isassigned(d.collections, collection_idx)
            new(name, summary_name, enum,
                unit, summary_unit,
                is_multiband, is_period, is_summary,
                d.collections[collection_idx])
        else
            new(name, summary_name, enum,
                unit, summary_unit,
                is_multiband, is_period, is_summary)
        end

    end

end

# System Data

struct PLEXOSObject
    name::String
    class::PLEXOSClass
    category::PLEXOSCategory
    index::Int
    show::Bool
end

PLEXOSObject(e::Node, d::AbstractDataset) =
    PLEXOSObject(getchildtext("name", e),
                 d.classes[getchildint("class_id", e)],
                 d.categories[getchildint("category_id", e)],
                 getchildint("index", e),
                 getchildbool("show", e))


struct PLEXOSMembership
    parentclass::PLEXOSClass
    childclass::PLEXOSClass
    collection::PLEXOSCollection
    parentobject::PLEXOSObject
    childobject::PLEXOSObject
end

PLEXOSMembership(e::Node, d::AbstractDataset) =
    PLEXOSMembership(d.classes[getchildint("parent_class_id", e)],
                     d.classes[getchildint("child_class_id", e)],
                     d.collections[getchildint("collection_id", e)],
                     d.objects[getchildint("parent_object_id", e)],
                     d.objects[getchildint("child_object_id", e)])


struct PLEXOSAttributeData
    value::Float64
    attribute::PLEXOSAttribute
    object::PLEXOSObject
end

PLEXOSAttributeData(e::Node, d::AbstractDataset) =
    PLEXOSAttributeData(getchildfloat("value", e),
                        d.attributes[getchildint("attribute_id", e)],
                        d.objects[getchildint("object_id", e)])


# Results

struct PLEXOSPeriod0
    periodofday::Int
    hour::Int
    day::Int
    week::Int
    month::Int
    quarter::Int
    fiscalyear::Int
    datetime::String
end

PLEXOSPeriod0(e::Node, d::AbstractDataset) =
    PLEXOSPeriod0(getchildint("period_of_day", e),
                  getchildint("hour_id", e),
                  getchildint("day_id", e),
                  getchildint("week_id", e),
                  getchildint("month_id", e),
                  getchildint("quarter_id", e),
                  getchildint("fiscal_year_id", e),
                  getchildtext("datetime", e))


struct PLEXOSPeriod1
    week::Int
    month::Int
    quarter::Int
    fiscalyear::Int
    date::String
end

PLEXOSPeriod1(e::Node, d::AbstractDataset) =
    PLEXOSPeriod1(getchildint("week_id", e),
                  getchildint("month_id", e),
                  getchildint("quarter_id", e),
                  getchildint("fiscal_year_id", e),
                  getchildtext("date", e))


struct PLEXOSPeriod2
    week_ending::String
end

PLEXOSPeriod2(e::Node, d::AbstractDataset) =
    PLEXOSPeriod2(getchildtext("week_ending", e))


struct PLEXOSPeriod3
    month_beginning::String
end

PLEXOSPeriod3(e::Node, d::AbstractDataset) =
    PLEXOSPeriod3(getchildtext("month_beginning", e))


struct PLEXOSPeriod4
    year_ending::String
end

PLEXOSPeriod4(e::Node, d::AbstractDataset) =
    PLEXOSPeriod4(getchildtext("year_ending", e))


struct PLEXOSPeriod6
    day::Int
    datetime::String
end

PLEXOSPeriod6(e::Node, d::AbstractDataset) =
    PLEXOSPeriod6(getchildint("day_id", e),
                  getchildtext("datetime", e))


struct PLEXOSPeriod7
    quarter_beginning::String
end

PLEXOSPeriod7(e::Node, d::AbstractDataset) =
    PLEXOSPeriod7(getchildtext("quarter_beginning", e))


# TODO: LT support?

struct PLEXOSPhase2
    interval::PLEXOSPeriod0
    period::Int # PASA period
end

PLEXOSPhase2(e::Node, d::AbstractDataset) =
    PLEXOSPhase2(d.intervals[getchildint("interval_id", e)],
                 getchildint("period_id", e))

struct PLEXOSPhase3
    interval::PLEXOSPeriod0
    period::Int # MT period
end

PLEXOSPhase3(e::Node, d::AbstractDataset) =
    PLEXOSPhase3(d.intervals[getchildint("interval_id", e)],
                 getchildint("period_id", e))


struct PLEXOSPhase4 # are these values always 1:1 matches?
    interval::PLEXOSPeriod0
    period::Int # ST period
end

PLEXOSPhase4(e::Node, d::AbstractDataset) =
    PLEXOSPhase4(d.intervals[getchildint("interval_id", e)],
                 getchildint("period_id", e))


struct PLEXOSKey
    membership::PLEXOSMembership
    model::PLEXOSModel
    phase::Int
    property::PLEXOSProperty
    periodtype::Int # not accurate, use KeyIndex.periodtype instead
    band::Int
    sample::PLEXOSSample
    timeslice::PLEXOSTimeslice
end

PLEXOSKey(e::Node, d::AbstractDataset) =
    PLEXOSKey(d.memberships[getchildint("membership_id", e)],
              d.models[getchildint("model_id", e)],
              getchildint("phase_id", e),
              d.properties[getchildint("property_id", e)],
              getchildint("period_type_id", e),
              getchildint("band_id", e),
              d.samples[getchildint("sample_id", e) + 1],
              d.timeslices[getchildint("timeslice_id", e) + 1])

struct PLEXOSKeyIndex
    key::PLEXOSKey
    periodtype::Int # maybe parametrize on this?
    position::Int # bytes from binary file start
    length::Int # 8-byte (Float64) increments
    periodoffset::Int
end

PLEXOSKeyIndex(e::Node, d::AbstractDataset) =
    PLEXOSKeyIndex(d.keys[getchildint("key_id", e)],
                   getchildint("period_type_id", e),
                   getchildint("position", e),
                   getchildint("length", e),
                   getchildint("period_offset", e))
