# StorageDetective Justfile

# Default recipe
default:
    just run

# Format code with nph
format:
    nph src

# Build the project
# Usage: just build [mode]

# mode: r (release), d (danger), or empty (debug, default)
build mode="":
    {{ if mode == "" { "nimble build" } else if mode == "r" { "nimble build -d:release" } else if mode == "d" { "nimble build -d:danger" } else { "echo 'Unknown mode: " + mode + ". Use r for release or d for danger.'; false" } }}
    mv sd bin/

# Build and run the binary
run mode="":
    just build {{ mode }}
    ./bin/sd

# Watch for changes and rebuild
watch:
    watchexec -c -e nim 'just build'
