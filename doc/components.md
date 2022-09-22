# `lines9/components.vim`

Small components.

All components receiving a config would take the config's ownership,
don't use it after initializing the component.

## String components

`Trunc`: Indicate where truncation begins, `%<`.

`Sep`: Seperator of left and right aligned parts of the statusline, `%=`.

`CloseCurTab`: A button for closing current tabpage, `%999X X `.

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

## `FileName(conf): Component`, `FileNameFunc(conf): func(number): string`

`FileName` returns a component indicating the file name of current window.
`FileNameFunc` returns a function retrieving the file name of the given window.

`conf` has the following type:

``` vim
class FileNameConfig
    # The format used for the filename component content,
    # not available for FileNameFunc
    var format: string = " %s "
    # Whether use the full format
    var full: bool = true
endclass
```

## `TabpageList(conf): Component`

Returns a component listing current tabpages, used for tablines.

`conf` has the following type:

``` vim
class TabpageListConfig
    # Highlight on different modes
    # Possible keys are normal, insert and visual
    # If is a string, use it as the name of the highlight group.
    var highlight: dict<HlProp | string> = (omitted)
    # Separator between different inactive tabs
    var sep_inactive: string = "|"
    # Separator between active and inactive tabs
    var sep_active: string = ""
    # Component function for inactive tabs
    # tabnr -> string
    var tab_inactive: func(number): string = (omitted)
    # Component function for active tabs
    # tabnr -> string
    var tab_active: func(number): string = (omitted)
endclass
```

