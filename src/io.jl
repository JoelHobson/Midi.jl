import FileIO
export FileIO.load, FileIO.save

"""
    load(filename_ending_with_.mid)
Load a file into a [`MIDIFile`](@ref) data type.
This function simply overloads [`FileIO.load`](https://juliaio.github.io/FileIO.jl/stable/).
"""
function FileIO.load(f::File{format"MIDI"})
    open(f) do s
        skipmagic(s)
        midifile = load(s)
    end
end

function FileIO.load(s::Stream{format"MIDI"})
    midifile = MIDIFile()

    # Skip the next four bytes - this is the header size, and it's always equal to 6.
    skip(s, 4)

    # Read the format code. 0 = single track, 1 = multiple tracks, 2 = multiple songs
    # Remember - MIDI files store data in big-endian format, which is why ntoh is used
    midifile.format = ntoh(read(s, UInt16))

    # Get the number of tracks and time division
    numberoftracks = ntoh(read(s, UInt16))
    midifile.tpq = ntoh(read(s, Int16))
    midifile.tracks = [readtrack(s.io) for x in 1:numberoftracks]

    midifile
end

"""
    save(filename, data::MIDIFile)
Write a `MIDIFile` as a ".mid" file to the given `filename`.

    save(filename, notes::Notes)
Create a `MIDIFile` directly from `notes`, using format 1, and then save it.

This function simply overloads [`FileIO.load`](https://juliaio.github.io/FileIO.jl/stable/).
"""
function FileIO.save(f::File{format"MIDI"}, data::MIDIFile)
    open(f, "w") do s
        save(s, data)
    end
end

function FileIO.save(s::Stream{format"MIDI"}, data::MIDIFile)
    write(s, magic(format"MIDI"))

    write(s, hton(convert(UInt32, 6))) # Header length
    write(s, hton(data.format))
    write(s, hton(convert(UInt16, length(data.tracks))))
    write(s, hton(data.tpq))

    map(track->writetrack(s.io, track), data.tracks)
    return data
end

function FileIO.save(s::Union{File{format"MIDI"}, Stream{format"MIDI"}}, notes::Notes)
    track = MIDITrack()
    addnotes!(track, notes)
    midi = MIDIFile(1, notes.tpq, [track])
    save(s, midi)
    return midi
end
