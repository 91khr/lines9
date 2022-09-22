# `lines9/components.vim`

Small components.

All components receiving a config would take the config's ownership,
don't use it after initializing the component.

## String components

`Trunc`: Indicate where truncation begins, `%<`.

`Sep`: Seperator of left and right aligned parts of the statusline, `%=`.

## `ModeIndicator(conf): Component`

Returns a component indicating current mode.

`conf` has the following type:

``` vim
class ModeIndicatorConfig
    # The format used for the mode string
    var format: string = " %s "
    # Highlight on different modes
    # Possible keys are normal, insert and visual
    # If is a string, use it as the name of the highlight group.
    var highlight: dict<HlProp | string> = (omitted)
    # first char of mode() -> [highlight group, statusline text]
    var modemap: dict<list<string>>
endclass
```

## `FileName(conf): Component`

Returns a component indicating the file name of current window.

`conf` has the following type:

``` vim
class FileNameConfig
    # The format used for the filename string
    var format: string = " %s "
    # Whether use the full format
    var full: bool = true
endclass
```
