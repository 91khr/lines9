vim9script
# Small components

import "./utils.vim"
import "./color.vim"

export const Trunc = utils.MakeComponent("%<")
export const Sep = utils.MakeComponent("%=")

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
        modemap: {
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
        },
    }, "keep")
    const hlgroups = conf.highlight->mapnew((_, v) => type(v) == v:t_string ? v : v.name)
    function CalcMode(conf, hlgroups)
        function! s:CalcModeImpl(win) closure
            let [cat, text] = a:conf.modemap[mode()[0]]
            return s:color.Highlight(a:hlgroups[cat]) .. printf(a:conf.format, text)
        endfunction
        return function("s:CalcModeImpl")
    endfunction
    return color.HlSchemeComponent(conf.highlight->values()->filter((_, v) => type(v) == v:t_dict), {
        value: utils.Dyn(CalcMode(conf, hlgroups), true),
    })
enddef

export def FileName(config: any = {}): any
    const conf = config->extend({
        full: true,
        format: " %s ",
    }, "keep")
    def CalcFileName(win: number): string
        const buf = winbufnr(win)
        const fname = bufname(buf)
        if empty(fname)
            var bt = getbufvar(buf, '&bt')
            if bt == 'quickfix'
                return !!getwininfo(win)[0].loclist ? '[Location List]' : '[Quickfix List]'
            endif
            var btlist = {
                        \     nofile: '[Scratch]',
                        \     prompt: '[Prompt]',
                        \     popup: '[Popup]',
                        \ }
            return btlist->has_key(bt) ? btlist[bt] : '[No Name]'
        endif
        if getbufvar(buf, '&ft') == 'help' && getbufvar(buf, '&ro') && !getbufvar(buf, '&modifiable')
            return fnamemodify(fname, ":t")
        endif
        const relpath = fnamemodify(fname, ":.")
        return conf.full ? relpath :
                    \ substitute(relpath, '\v([^/])([^/]*)' .. '/', '\1' .. '/', 'g')
    enddef
    return { value: (win) => printf(conf.format, CalcFileName(win)) }
enddef

