function open_zip(zippath::String)

    archive = ZipArchive(zippath)
    result = Dict(archive[i] for i in 1:length(archive))
    discard(archive)

    return result

end

struct ZipArchive

    ptr::Ptr{Cvoid}

    function ZipArchive(zippath::String)

        flags = 16 # open archive read-only
        errorp = Ref(Int32(0)) # receive an error code

        ptr = @ccall libzip.zip_open(
            zippath::Cstring, flags::Cint, errorp::Ptr{Cint})::Ptr{Cvoid}

        # Could provide more details here from value of errorp
        ptr == C_NULL && error("Error opening zipfile at " * zippath)

        return new(ptr)

    end

end

function Base.length(archive::ZipArchive)
    i = @ccall libzip.zip_get_num_entries(archive.ptr::Ptr{Cvoid}, 0::Cint)::Int64
    return UInt64(i)
end

function discard(archive::ZipArchive)
    @ccall libzip.zip_discard(archive.ptr::Ptr{Cvoid})::Cvoid
    return
end

function Base.getindex(archive::ZipArchive, i::UInt64)

    i -= 1

    meta = ZipFileMetadata(archive, i)

    filename = unsafe_string(meta.name)
    filedata = Vector{UInt8}(undef, meta.size)

    fileptr = @ccall libzip.zip_fopen_index(
        archive.ptr::Ptr{Cvoid}, i::UInt64, 0::Cint)::Ptr{Cvoid}

    n_bytes_read = @ccall libzip.zip_fread(
        fileptr::Ptr{Cvoid}, pointer(filedata)::Ptr{UInt8}, meta.size::UInt64)::Int64

    n_bytes_read == meta.size || error("Error reading the file")
    # Could check against meta.crc here to be safe

    return filename => filedata

end

mutable struct ZipFileMetadata

    valid::UInt64             # which fields have valid values
    name::Cstring             # name of the file
    index::UInt64             # index within archive
    size::UInt64              # size of file (uncompressed)
    comp_size::UInt64         # size of file (compressed)

    # libzip provides the following additional fields as well, but since the
    # size of time_t is a bit fuzzy, they may be misaligned. It's probably best
    # not to use these. Note this approach would cause big problems
    # if we were ever receiving a pointer to an array of zip_stat from C. But
    # we're not, so...

    mtime::UInt64             # modification time - assume 64-bit, but might be 32...
    crc::UInt32               # crc of file data
    comp_method::UInt16       # compression method used
    encryption_method::UInt16 # encryption method used
    flags::UInt32             # reserved for future use

    function ZipFileMetadata(archive::ZipArchive, i::UInt64)
     
        meta = new()

        err = @ccall libzip.zip_stat_index(
            archive.ptr::Ptr{Cvoid}, i::UInt64, 0::Cint,
            Ref(meta)::Ptr{ZipFileMetadata})::Cint

        iszero(err) || error("Error loading file $i from archive")
        meta.index == i || error("Metadata for file $i is corrupted")

        return meta

    end

end
