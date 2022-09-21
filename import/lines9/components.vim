vim9script
# Small components

import "./utils.vim"
import "./color.vim"

export const Trunc = "%<"
export const Sep = "%="

export def ModeIndicator(config: any = {}): any
    const conf = config->extend({
        highlight: {
            normal: { base: "Identifier", name: "Lines9ModeIndicatorNormal",
                gui: { reverse: true }, term: { reverse: true }, cterm: { reverse: true }, },
            command: "Lines9ModeIndicatorNormal",
            insert: { base: "Keyword", name: "Lines9ModeIndicatorInsert",
                gui: { reverse: true }, term: { reverse: true }, cterm: { reverse: true }, },
            replace: { base: "Error", name: "Lines9ModeIndicatorReplace",
                gui: { reverse: true, bold: false }, term: { reverse: true, bold: false },
                cterm: { reverse: true, bold: false }, },
            visual: { base: "Todo", name: "Lines9ModeIndicatorVisual",
                gui: { reverse: true }, term: { reverse: true }, cterm: { reverse: true }, },
        },
        format: " %s ",
    })
    const hlgroups = conf.highlight->mapnew((_, v) => type(v) == v:t_string ? v : v.name)
    const hlmap = {
        'n': ["normal", "NORMAL"],
        'v': ["visual", "VISUAL"],
        's': ["visual", "VISUAL"],
        'V': ["visual", "V-LINE"],
        'S': ["visual", "V-LINE"],
        '': ["visual", "V-BLOCK"],
        '': ["visual", "V-BLOCK"],
        'i': ["insert", "INSERT"],
        't': ["insert", "INSERT"],
        'R': ["replace", "REPLACE"],
        'c': ["command", "COMMAND"],
        'r': ["command", "COMMAND"],
        '!': ["command", "COMMAND"],
    }
    function Calc(hlgroups, hlmap, fmt)
        function s:CalcImpl(win) closure
            let mod = mode()[0]
            let [cat, text] = a:hlmap[mod]
            return s:color.Highlight(a:hlgroups[cat]) .. printf(a:fmt, text)
        endfunction
        return function("s:CalcImpl")
    endfunction
    return color.HlSchemeComponent(conf.highlight->values()->filter((_, v) => type(v) == v:t_dict), {
        value: utils.Dyn(Calc(hlgroups, hlmap, conf.format), true),
    })
enddef

