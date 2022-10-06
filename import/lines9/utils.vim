vim9script
# Other small utils

export def MakeComponent(val: any): dict<any>
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

export function ToLegacyClosure(Fn)
    return { ... -> call(a:Fn, a:000) }
endfunction

export def Merge(src: dict<any>, dst: dict<any>): dict<any>
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

export def Pipe(component: dict<any>, Fn: func(string): string): dict<any>
    const Old = component.value
    component.value = (win) => Fn(Old(win))
    return component
enddef

export def WithSep(sep: string, ...components: list<dict<any>>): dict<any>
    const fnlist = components->mapnew((_, comp) => comp.value)
    final res = { value: (win) => fnlist->mapnew((_, F) => F(win))->join(sep) }
    for comp in components
        res->Merge(comp)
    endfor
    return res
enddef

