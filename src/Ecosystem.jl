using Pkg: TOML.parsefile, Types.VersionRange
using DataFrames, CSV

function parse_package(name)
    dir = "$(homedir())/.julia/registries/General/$(name[1:1])/$name"
    version = parsefile("$dir/Versions.toml") |>
        keys |>
        (k -> maximum(VersionNumber, k))
    compat = parsefile("$dir/Compat.toml") |>
        (x -> [ ((name = n,
                  version = VersionRange(v))
                  for (n, v) in v) for (k, v) ∈ x if version ∈ VersionRange(k) ] ) |>
        Iterators.flatten |>
        collect |>
        sort!
    if v"1" ∈ compat[findfirst(x-> isequal("julia", x.name), compat)].version
        package = parsefile("$dir/Package.toml") |>
            (x -> (name = x["name"], uuid = x["uuid"], repo = x["repo"][1:end - 4]))
        output = DataFrame(name = package.name,
                           repository = package.repo,
                           version = version,
                           dependency = getproperty.(compat, :name))
    else
        output = DataFrame([String, String, VersionNumber, String],
                           [:name, :repository, :version, :dependency],
                           0)
    end
    output
end

data = readdir.(string.("$(homedir())/.julia/registries/General/", 'A':'Z')) |>
    Iterators.flatten |>
    collect |>
    (x -> filter!(x -> !any(x ∈ ["julia", ".DS_Store"]) , x)) |>
    (x -> vcat(parse_package.(x)...))
CSV.write("data/data.tsv", data, delim = '\t')
