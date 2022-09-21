# `lines9/components.vim`

Small components.

## String components

`Trunc`: Indicate where truncation begins, `%<`.

`Sep`: Seperator of left and right aligned parts of the statusline, `%=`.

## `ModeIndicator(conf): Component`

Returns a component indicating current mode.

Would take `conf`'s ownership, don't use it afterwards.
`conf` has following type:

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

