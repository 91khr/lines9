vim9script
# Other small utils

export def MakeComponent(val: any): any
    if type(val) == v:t_string
        return { value: (win) => val }
    elseif type(val) == v:t_func
        return { value: val }
    else
        throw "Lines9.utils.MakeComponent: Incorrect component type"
    endif
    return {}  # Make type check happy
enddef

export def Dyn(Fn: func, rec: bool = false): func(number): string
    return (win) => "%{" .. (rec ? "%" : "") .. string(Fn) .. "(" .. win .. ")" .. (rec ? "%" : "") .. "}"
enddef

export def Merge(src: any, dst: any): any
    if type(src) == v:t_string
        const ctnt = src
        final res = copy(dst)
        res.value = (win) => ctnt
        return res
    elseif type(dst) == v:t_string
        return src
    endif
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

export def WithSep(sep: string, ...components: list<any>): any
    const fnlist = components->mapnew((_, comp) => type(comp) == v:t_string ? (win) => comp : comp.value)
    final res = { value: (win) => fnlist->mapnew((_, F) => F(win))->join(sep) }
    for comp in components
        res->Merge(comp)
    endfor
    return res
enddef

