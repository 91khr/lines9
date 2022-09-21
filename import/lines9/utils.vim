vim9script
# Other small utils

export def Dyn(Fn: func, rec: bool = false): func(number): string
    return (win) => "%{" .. (rec ? "%" : "") .. string(Fn) .. "(" .. win .. ")" .. (rec ? "%" : "") .. "}"
enddef

export def Merge(src: any, dst: any): any
    src.autocmds = src->get("autocmds", [])->extend(dst->get("autocmds", []))
    if !src->has_key("listeners")
        src.listeners = {}
    endif
    for [name, priolist] in dst->get("listeners", {})->items()
        if !src.listeners->has_key(name)
            src.listeners[name] = {}
        endif
        final listeners = src.listeners[name]
        for [prio, fnlist] in priolist->items()
            if !listeners->has_key(prio)
                listeners[prio] = []
            endif
            listeners[prio]->extend(fnlist)
        endfor
    endfor
    return src
enddef

