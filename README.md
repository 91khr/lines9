# Lines9

A light and configurable statusline/tabline plugin.

This plugin aims at:

- Minimalism: As small as possible, build up with straightforward concepts and implementation;
- Flexibility: Able to support as many features as possible;
- Efficiency: No extra calculation; reuse everything as possible.

**This plugin needs some configuration to roll up to work
and may not work as you expect if you work out a configuration from scratch
without acknowledging what Lines9 does beneath the surface.**

## Why another statusline plugin

- [`vim-powerline`](https://github.com/Lokaltog/vim-powerline) is already deprecated;
- [`powerline`](https://github.com/powerline/powerline) is good, but requires python and is hard to configure;
- [`vim-airline`](https://github.com/vim-airline/vim-airline) is nice, but integrates too many assets;
- [`lightline.vim`](https://github.com/itchyny/lightline.vim) is pretty, but too light, and lacks flexibility on many
  occasions.

## Usage

Basic usage:

``` vim
import "lines9.vim"

lines9.Init(lines9.GetPreset("default"))

# To enable/disable/toggle vim-lines
lines9.Enable()
lines9.Disable()
lines9.Toggle()

# To derive a configuration from the default configuration
var lines9_conf = lines9.GetPreset("default")
# Add a component to the statusline
lines9_conf.schemes["bufnr"] = { value: (win) => winbufnr(win) }
# Re-init with the configuration
lines9.Init(lines9_conf)
```

`lines9.GetPreset()` creates a brand-new dictionary every time it's invoked,
so modifications to the returned configurations would only affect the modified configuration.

**Note**: `Init` would take ownership of the configuration, don't use the configuration after initialization.

For more complicated configurations, see files under the `examples` directory;
they can be previewed by changing directory to `examples` directory and execute `vim -S view.vim example.vim`,
where `example` is the name of the example.

---

The core library of Lines9 only provides most foundamental features, for more utilities that make life easier,
import submodules `lines9/xxx.vim`, where `xxx` is the module name. Their documents are in `doc/xxx.md`.

There are also some tips and notes in `doc/README.md`; check it out if you find something behaves wierd.

## Configuration

The type of the configuration can be expressed as:

``` vim
class Config
    # name -> component value
    var components: dict<Component>
    # scheme name -> list of components by names
    var schemes: dict<list<string>>
    # Decide which scheme should be used on the statusline/tabline.
    # Return null to use the global statusline.
    var dispatch: func(tuple<type: "statusline", winid: number> | tuple<type: "tabline">): string | null
    # Autocmds that should be listened to.
    # Each item can be a name-pattern pair, or a name to listen to all patterns
    var autocmds: list<list<string> | string>
    # Listeners to the events
    # event name -> priority group -> function list
    # The functions of higher priority would be executed before those of lower
    # For details, see document below.
    var listeners: dict<dict<list<func>>>
endclass

class Component
    # The function, the window id would be passed to the function, -1 for tabline.
    var value: func(number): string
    # Names of autocmds the component listens to
    var autocmds: list<list<string> | string>
    # The listeners in the component, akin to that in Config
    var listeners: dict<dict<list<func>>>
endclass
```

The name returned by `dispatch` should be a valid scheme name.

### Events

Some events are defined by default:

- `lines9:BeforeEnable`: triggered before enabling, no arguments;
- `lines9:AfterEnable`: triggered after enabling, no arguments;
- `lines9:BeforeDisable`: triggered before disabling, no arguments;
- `lines9:AfterDisable`: triggered after disabling, no arguments.
- `lines9:GetTabline`: triggered every time before Vim retrieves the tabline.

Events originating from listening to autocmds are named `autocmd:AutocmdEventName` or
`autocmd:AutocmdEventName:Pattern`,
in which `AutocmdEventName` is the event name in the specification, and `Pattern` is the matched pattern.
If the pattern part is not present, every pattern of the event would invoke the listener;
and when the pattern is present, only the specified pattern would invoke the listener.
Note that the matched pattern is directly used as the event name,
which means patterns like `Cargo.toml` can be used in event name, while `*.toml` cannot;
if the more complex pattern is needed, omit the pattern and match it in the listener instead.
Furthermore, events are not automatically listened to, i.e. they must be listed both in `autocmds` and in `listeners`.

The autocmd event name and the matched pattern would be passed to the listener.

Events may be directly invoked with their name and arbitrary arguments.
However, arguments passed to the event should agree with the event's requirements.

### Listeners

Basically, listener list should look like this:

``` vim
conf.listeners = {
    "autocmd:BufEnter": { 1: [BufEnterHandler1, BufEnterHandler2], },
    "autocmd:BufLeave": { 1: [BufLeaveHandler1, BufLeaveHandler2], 2: [BufLeaveHandler3], },
}
```

In this example, `BufLeaveHandler3` is invoked before `BufLeaveHandler1`, `BufLeaveHandler2`,
and other listeners to event `autocmd:BufLeave`,
while unspecified and maybe varying is the invocation order of
`BufLeaveHandler1`, `BufLeaveHandler2`, and other `autocmd:BufLeave` listeners.

## Functions

### `lines9.Init(conf: Config)`

Initialize vim-lines with configuration, if already initialized, reinitialize.

### `lines9.Enable()`, `lines9.Disable()`, `lines9.Toggle()`

Enable/disable/toggle Lines9.

Enabling would refresh in global scope; disabling would iterate all windows to unset the statuslines.

### `lines9.Refresh(scope)`

Refresh statuslines in the scope, regenerating lines if possible. Possible scopes are:

- `{ scope: "tabline" }`: Refresh the tabline;
- `{ scope: "tabpage", id: number }`: Refresh the tabpage of the ID; if id not given, refresh current tabpage;
- `{ scope: "window", id: number }`: Refresh the window of the ID; if id not given, refresh current window.

### `lines9.Update(loc, scheme: string | null)`

Update the scheme of the line at the location.
`loc` follows the same format as the argument of `Config.dispatch`.
`scheme` can be omitted to update all schemes.

### `lines9.GetPreset(name: string): Config`

Get the config in the example `examples/name.vim`.

### `lines9.EmitEvent(name: string, ...args: list<any>)`

Emit an event, invoking all its listeners.

### `lines9.CalcScheme(name: string, win: number): string`

Calculate the scheme for the window of given ID, returning its statusline value.

## Architecture and details

Different windows or different states of the same window may use different types of statuslines.
In Lines9, we use *schemes* to refer to a list of *components* that concatenates to make up a statusline.
Here, a component should generate a string as a part of the statusline option.

Generating the statusline may be expensive;
for example, there may be a component using a complex algorithm to work out its content.
Thus contents of statuslines are cached per window by schemes,
*refreshing* the statusline would reset the statusline option with the cached value,
and only *updating* the statusline would forcefully regenerate the scheme.

The tabline is similar to statuslines, and uses similar strategy.

By default, following autocmds would trigger refreshing:

- `BufEnter` and `WinEnter`: refresh current window;
- `TabEnter`: refresh current tabpage and the tabline.

**Note** that the refreshments are hard-coded, happens *after* events are processed,
and are not a part of the event system.

## Todo

- [ ] Use actual types for the components instead of `any`.
- [ ] Use Vim9 closures for dynamic statusline when it's possible.

