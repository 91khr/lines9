vim9script
# vim: fdm=marker

import "./lines9/utils.vim"

# The cached configuration
var conf: any = null
# Whether lines9 is enabled
var enabled: bool = false
# The saved tabline
var saved_tabline: string = ""
var saved_qf_statusline: number = 0
# The tabline value
var tabline_val = ""
var tabline_scheme_cache = {}

# {{{ Toggle, EmitEvent, GetPreset
export def Toggle()
    if enabled
        Disable()
    else
        Enable()
    endif
enddef

export def EmitEvent(name: string, ...args: list<any>)
    for fnlist in conf.listeners->get(name, [])
        for fn in fnlist
            call(fn, args)
        endfor
    endfor
enddef

export def GetPreset(name: string): any
    exec "source " .. expand("<script>:h") .. "/../examples/" .. name .. ".vim"
    return g:lines9_config
enddef
# }}} End assets

# {{{ Init
export def Init(config: any)
    conf = config->extend({
        components: {},
        schemes: {},
        autocmds: [],
        listeners: {},
    }, "keep")

    # Fetch values of components
    for comp in conf.components->values()
        if type(comp) != v:t_string
            utils.Merge(conf, comp)
        endif
    endfor

    # Refactor listeners
    conf.listeners = conf.listeners->mapnew((_, fns) =>
                \ fns->items()->sort((a, b) => a[0] == b[0] ? 0 : a[0] < b[0] ? 1 : -1)
                \    ->mapnew((_, pair) => pair[1]))
enddef
# }}} End init

# {{{ Enable
export def Enable()
    EmitEvent("lines9:BeforeEnable")

    # Listen to the autocmds
    var autocmds = {}
    for cmd in conf.autocmds
        var [name, pattern] = type(cmd) == v:t_list ? cmd : [cmd, "*"]
        if !autocmds->has_key(name)
            autocmds[name] = {}
        endif
        autocmds[name][pattern] = 1
    endfor
    augroup Lines9
        au!
        for [name, patterns] in autocmds->items()
            exec "au " .. name .. " " .. patterns->keys()->join(",") ..
                        \ " EmitEvent('autocmd:" .. name .. "', '" .. name .. "', expand('<amatch>'))"
        endfor
        au BufEnter,WinEnter * Refresh({ scope: "window" })
        au TabEnter * Refresh({ scope: "tabpage" })
    augroup END

    # Create cache
    tabline_scheme_cache = {}

    # Save global values
    saved_tabline = &tabline
    &tabline = "%!" .. string(() => tabline_val) .. "()"
    saved_qf_statusline = get(g:, "qf_disable_statusline", 0)
    g:qf_disable_statusline = 1
    for tab in range(1, tabpagenr("$"))
        for win in range(1, tabpagewinnr(tab, "$"))
            settabwinvar(tab, win, "lines9_scheme_cache", {})
        endfor
    endfor

    Refresh({ scope: "tabpage" })
    Refresh({ scope: "tabline" })

    EmitEvent("lines9:AfterEnable")
enddef
# }}} End Enable

# {{{ Disable
export def Disable()
    EmitEvent("lines9:BeforeDisable")

    # Disable the autocmds
    augroup Lines9
        au!
    augroup END
    augroup! Lines9

    # Restore the lines
    &tabline = saved_tabline
    g:qf_disable_statusline = saved_qf_statusline
    # Unset the local lines
    for tab in range(1, tabpagenr("$"))
        for win in range(1, tabpagewinnr(tab, "$"))
            settabwinvar(tab, win, "&statusline", "")
        endfor
    endfor

    EmitEvent("lines9:AfterDisable")
enddef
# }}} End Disable

# {{{ Refresh
export def Refresh(loc: any)
    const scope = loc.scope
    if scope == "tabline"
        Regenerate({ type: "tabline" })
    elseif scope == "tabpage"
        const tab = loc->get("id", tabpagenr())
        for nr in range(1, tabpagewinnr(tab, "$"))
            const win = win_getid(nr)
            Regenerate({ type: "statusline", winid: win_getid(nr) })
        endfor
    elseif scope == "window"
        Regenerate({ type: "statusline", winid: loc->get("id", win_getid()) })
    endif
enddef

# Regenerate the statusline of the window
def Regenerate(loc: any)
    # Get the scheme
    const schname = conf.dispatch(loc)
    if !schname
        return
    endif
    const win = loc.type == "tabline" ? -1 : loc.winid
    final schemes = loc.type == "tabline" ? tabline_scheme_cache : win->getwinvar("lines9_scheme_cache", {})
    const res = schemes->get(schname, null) == null ? CalcScheme(schname, win) : schemes[schname]
    schemes[schname] = res
    if loc.type == "tabline"
        tabline_val = res
    else
        setwinvar(win, "&statusline", res)
    endif
enddef
# }}} End Refresh

# {{{ Update
export def Update(loc: any, scheme: any = null)
    if loc.type == "tabline"
        if scheme == null
            tabline_scheme_cache = {}
        else
            tabline_scheme_cache[scheme] = null
        endif
    else
        const win = loc->get("winid", win_getid())
        if scheme == null
            setwinvar(win, "lines9_scheme_cache", {})
        else
            final cache = win->getwinvar("lines9_scheme_cache")
            cache[scheme] = null
        endif
    endif
enddef
# }}} End update

# {{{ CalcScheme
export def CalcScheme(schname: string, win: number): string
    var res = ""
    for name in conf.schemes[schname]
        res ..= call(conf.components[name].value, [win])
    endfor
    return res
enddef
# }}} End CalcScheme

