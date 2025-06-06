# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

function objread(fname; lenunit, numbertype)
  vertices = NTuple{3,numbertype}[]
  faceinds = Vector{Int}[]

  open(fname) do io
    while !eof(io)
      line = split(readline(io))
      if !isempty(line)
        if line[1] == "v"
          point = ntuple(i -> parse(numbertype, line[i + 1]), 3)
          push!(vertices, point)
        end

        if line[1] == "f"
          inds = map(2:length(line)) do i
            ind = first(split(line[i], "/"))
            parse(Int, ind)
          end
          push!(faceinds, inds)
        end
      end
    end
  end

  # treat negative indices
  # -1 is equivalet to last index
  nverts = length(vertices)
  for inds in faceinds
    for (i, ind) in enumerate(inds)
      if ind < 0
        inds[i] = nverts + ind + 1
      end
    end
  end

  u = lengthunit(lenunit)
  points = map(v -> Point(v[1]u, v[2]u, v[3]u), vertices)
  connec = map(inds -> connect(Tuple(inds), Ngon), faceinds)
  mesh = SimpleMesh(points, connec)

  georef(nothing, mesh)
end

function objwrite(fname, geotable)
  mesh = domain(geotable)

  if !(mesh isa Mesh && embeddim(mesh) == 3 && paramdim(mesh) == 2)
    throw(ArgumentError("OBJ format only supports 3D Ngon meshes"))
  end

  open(fname, write=true) do io
    for point in eachvertex(mesh)
      coords = ustrip.(to(point))
      write(io, "v $(join(coords, " "))\n")
    end

    for connec in elements(topology(mesh))
      inds = indices(connec)
      write(io, "f $(join(inds, " "))\n")
    end
  end
end
