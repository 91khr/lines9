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

**Note** that the if `fn` is a closure, it must be a legacy closure.
See notes [README.md](README.md) for workarounds and details.

## `ToLegacyClosure(fn: func): func`

Turn a closure into legacy closure, used for the workaround.

See notes [README.md](README.md) for workarounds and details.

## `MakeComponent(val: string | func(number): string): Component`

Turn the string or function into a component.

## `Merge(src: Component, dst: Component): Component`

Merge the data: autocmds and listeners in `dst` into `src`.
Modifies `src` in place, returning `src`.
`dst` is remained unchanged.

## `Pipe(component: Component, proc: func(string): string): Component`

Pipe the output of `component`'s function into `proc`,
returning the modified component.
Take ownership of `component`.

## `WithSep(sep: string, ...components: list<Component>): Component`

Returns a component that joins the components, separated with `sep`.

## Todo

- [ ] Type `Fn` argument of `Dyn` when vim9 closures can be used in statuslines.

