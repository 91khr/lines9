# `lines9/utils.vim`

Collection of utility functions.

## `Dyn(fn: func(number): string, rec: bool = false): func(number): string`

Turn a static component function into dynamic function.
By default, the return value of the component function is directly replaced into the statusline,
which means the value of the component only changes at update.
"Dynamic" here refers to the Vim statusline feature that evaluate the expression
every time when calculate statusline value.

The window number passed to the underlying function would always be
the number passed to the wrapper when refreshing the line.

`rec` specifies whether the result of the result of the function should be
expanded recursively, i.e. use `%{%...%}` instead of `%{...}`

## `Merge(src: Component, dst: Component): Component`

Merge the data: autocmds and listeners in `dst` into `src`.
Modifies `src` in place, returning `src`.

