vim9script
# Various helpers for colorscheme of the statusline

import "./utils.vim"

export def Highlight(group: string): string
    return "%#" .. group .. "#"
enddef

export def HlComponent(component: dict<any>, group: string): dict<any>
    const hl = Highlight(group)
    return {
        value: (win) => hl .. call(component.value, [win]),
        autocmds: component->get("autocmds", []),
        listeners: component->get("listeners", {}),
    }
enddef

export def HlSchemeComponent(scheme: list<any>, src: dict<any> = {}): dict<any>
    def AddGroups()
        for it in scheme
            var val = copy(it)
            if val->has_key("base")
                val->extend(hlget(val.base, true)->get(0, {}), "keep")
            endif
            try
                hlset([val])
            catch
                throw "Lines9.color: " .. v:exception
            endtry
        endfor
    enddef
    def DelGroups()
        for it in scheme
            hlset([{ name: it.name, cleared: true }])
        endfor
    enddef
    return utils.Merge(src, {
        autocmds: ["ColorScheme"],
        listeners: {
            "autocmd:ColorScheme": { 1: [(..._) => AddGroups()] },
            "lines9:BeforeEnable": { 1: [AddGroups] },
            "lines9:BeforeDisable": { 1: [DelGroups] },
        }
    })
enddef

