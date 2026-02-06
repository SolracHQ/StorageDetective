# StorageDetective

Storage Detective is a TUI tool that allows you to quickly, interactively and easily view the size of your files and directories.

## Build

### Requirements

- Nim >= 2.0.8
- Nimble
- Just (for recipe management)

### Download the source code

```shell
git clone https://github.com/carlosEduardoL/StorageDetective.git
cd StorageDetective
```

### Build

Using Just:

```shell
# Default debug build
just build

# Release build
just build r

# Danger build
just build d
```

Or with Nimble directly:

```shell
nimble build -d:release
```

### Run

Using Just:

```shell
just run
```

Or directly:

```shell
./bin/sd <path>
```

### Development

Format code:
```shell
just format
```

Watch mode (automatically rebuild on file changes):
```shell
just watch
```