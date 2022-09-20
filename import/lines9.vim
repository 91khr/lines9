vim9script
# vim: fdm=marker

# The cached configuration
var conf: any = null
# Whether lines9 is enabled
var enabled: bool = false
# The saved tabline
var saved_tabline: string = ""

# {{{ Toggle, EmitEvent, DefaultConf
export def Toggle()
    if enabled
        Disable()
    else
        Enable()
    endif
enddef

export def EmitEvent(name: string, ...args: list<any>)
    for fn in conf.listeners->get(name, [])
        call(fn, args)
    endfor
enddef

export def DefaultConf(): any
    return {}
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
enddef
# }}} End init

# {{{ Enable
export def Enable()
    EmitEvent("lines9:BeforeEnable")

    # Listen to the autocmds
    var autocmds = {}
    def AddCmd(cmd: any)
        var name: string
        var pattern: string
        if type(cmd) == v:t_list
            [name, pattern] = cmd
        else
            [name, pattern] = [cmd, "*"]
        endif
        if autocmds->has_key(name)
            autocmds[name] ..= "," .. pattern
        else
            autocmds[name] = pattern
        endif
    enddef
    for cmd in conf.autocmds
        AddCmd(cmd)
    endfor
    for comp in conf.components->values()
        if type(comp) == v:t_dict
            for cmd in comp->get("autocmds", [])
                AddCmd(cmd)
            endfor
        endif
    endfor
    augroup Lines9
        au!
        for [name, pattern] in autocmds->items()
            exec "au " .. name .. " " .. pattern ..
                        \ " EmitEvent('autocmd:" .. name .. "', '" .. name .. "', expand('<amatch>'))"
        endfor
        au WinNew * w:lines9_scheme_cache = {}
        au BufEnter,WinEnter * Refresh({ scope: "window" })
        au TabEnter * Refresh({ scope: "tabpage" })
    augroup END

    # Create cache
    g:lines9_scheme_cache = {}

    # Save global values
    saved_tabline = &tabline
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
    const schemes = loc.type == "tabline" ? g:lines9_scheme_cache : win->getwinvar("lines9_scheme_cache")
    const res = schemes->get(schname, null) == null ? CalcScheme(schname, win) : schemes[schname]
    schemes[schname] = res
    if loc.type == "tabline"
        &tabline = res
    else
        setwinvar(win, "&statusline", res)
    endif
enddef
# }}} End Refresh

export def Update(loc: any, scheme: any = null)
    if loc.type == "tabline"
        if scheme == null
            g:lines9_scheme_cache = {}
        else
            g:lines9_scheme_cache[scheme] = null
        endif
    else
        const win = loc->get("winid", win_getid())
        if scheme == null
            setwinvar(win, "lines9_scheme_cache", {})
        else
            win->getwinvar("lines9_scheme_cache")[scheme] = null
        endif
    endif
    Regenerate(loc)
enddef

# {{{ CalcScheme
export def CalcScheme(schname: string, win: number): string
    var res = ""
    for name in conf.schemes[schname]
        const component = conf.components[name]
        if type(component) == v:t_string
            res ..= component
        else
            res ..= call(component.value, [win])
        endif
    endfor
    return res
enddef
# }}} End CalcScheme

