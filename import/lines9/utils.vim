vim9script
# Other small utils

export def Dyn(Fn: func(number): string): func(number): string
    return (win) => "%{" .. string(Fn) .. "(" .. win .. ")}"
enddef

export def Merge(src: any, dst: any): any
    src.autocmds->extend(dst->get("autocmds", []))
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

