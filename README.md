# LUnit

Example of sandboxed tests for Lua scripts using isolated field environments for sandboxing.

## Compatibility

Tested and working with `luajit`/`5.1`, and `5.4.4`.

## Manifest

`lunit.lua` - the main file, provides the `LUnit` global. See `example.lua` for a usage example, which tests `testable.lua`.

`assertions.lua` - provides the `Assertions` global table. (Included by `lunit.lua`)

`lib.lua` - general helpers abstracted out for organizational purposes. (Included by `lunit.lua`)
