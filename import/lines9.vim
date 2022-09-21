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

# {{{ Toggle, EmitEvent, DefaultConf
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

export def DefaultConf(): any
    var leaving = false
    def LeavingRefresh(..._)
        leaving = true
        Refresh({ scope: "window" })
    enddef
    return {
        schemes: {
            active: ["mode", "fname", "sep", "fileinfo", "index"],
            inactive: ["fname_inactive", "sep", "index_inactive"],
        },
        components: {
            mode: components.ModeIndicator(),
            fname: color.HlComponent(" %F ", "StatusLineNC"),
            fname_inactive: color.HlComponent(" %F ", "CursorLine"),
            sep: color.HlComponent(components.Sep, "CursorLine"),
            fileinfo: " %{&ff} | %{&enc} | %{&ft ?? '(no ft)'} ",
            index: color.HlComponent(" %l:%c ", "StatusLine"),
            index_inactive: color.HlComponent(" %l:%c ", "StatusLineNC"),
        },
        dispatch: (loc): any => {
            if loc.type == "tabline"
                return null
            elseif leaving || win_getid() != loc.winid
                leaving = false
                return "inactive"
            else
                return "active"
            endif
        },
        autocmds: [ "WinLeave" ],
        listeners: {
            "autocmd:WinLeave": { 0: [LeavingRefresh] },
        },
    }
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
    g:lines9_scheme_cache = {}

    # Save global values
    saved_tabline = &tabline
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
    final schemes = loc.type == "tabline" ? g:lines9_scheme_cache : win->getwinvar("lines9_scheme_cache", {})
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
            final cache = win->getwinvar("lines9_scheme_cache")
            cache[scheme] = null
        endif
    endif
    Regenerate(loc)
enddef

# {{{ CalcScheme and CalcComponent
export def CalcComponent(component: any, win: number): string
    return type(component) == v:t_string ? component : call(component.value, [win])
enddef

export def CalcScheme(schname: string, win: number): string
    var res = ""
    for name in conf.schemes[schname]
        res ..= CalcComponent(conf.components[name], win)
    endfor
    return res
enddef
# }}} End CalcScheme

