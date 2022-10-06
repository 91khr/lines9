vim9script
# Small components

import "../lines9.vim"
import "./utils.vim"
import "./color.vim"

export const Trunc = utils.MakeComponent("%<")
export const Sep = utils.MakeComponent("%=")
export const CloseCurTab = utils.MakeComponent("%999X X ")

export def ModeIndicator(config: dict<any> = {}): dict<any>
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
    return color.HlSchemeComponent(conf.highlight->values()->filter((_, v) => type(v) == v:t_dict), {
        value: utils.Dyn(utils.ToLegacyClosure((win) => {
            const [cat, text] = conf.modemap->get(mode()[0], ["", "(UNKNOWN)"])
            return color.Highlight(hlgroups->get(cat, "ErrorMsg")) .. printf(conf.format, text)
        }), true),
    })
enddef

export def FileNameFunc(config: dict<any> = {}): func(number): string
    const conf = config->extend({
        full: true,
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
        echom buf
        if getbufvar(buf, '&ft') == 'help' && getbufvar(buf, '&ro') && !getbufvar(buf, '&modifiable')
            return fnamemodify(fname, ":t")
        endif
        const relpath = fnamemodify(fname, ":.")
        echom conf
        return conf.full ? relpath : substitute(relpath, '\v([^/])([^/]*)' .. '/', '\1' .. '/', 'g')
    enddef
    return CalcFileName
enddef

export def FileName(config: dict<any> = {}): dict<any>
    const conf = config->extend({
        full: true,
        format: " %s ",
    }, "keep")
    const Func = FileNameFunc(conf)
    return {
        value: (win) => printf(conf.format, Func(win)),
        autocmds: ["BufWinEnter"],
        listeners: {
            "autocmd:BufWinEnter": {
                0: [(..._) => lines9.Refresh({ scope: "window" })],
                1: [(..._) => lines9.Update({ type: "statusline" })],
            },
        },
    }
enddef

const FnameFuncShort = FileNameFunc({ full: false })
def TabpageDefaultFname(tabnr: number, win: number): string
    var buf = winbufnr(win)
    var mo_ro = ""
    if getbufinfo(buf)[0].changed
        mo_ro = " +"
    elseif getbufvar(buf, "&ro")
        mo_ro = " -"
    endif
    return string(tabnr) .. " " .. FnameFuncShort(win) .. mo_ro .. " "
enddef
export def TabpageList(config: dict<any> = {}): dict<any>
    const conf = config->extend({
        tab_inactive: (tabnr) => " " .. TabpageDefaultFname(tabnr, win_getid(tabpagewinnr(tabnr), tabnr)),
        tab_active: (tabnr) => " %{" .. string(TabpageDefaultFname) .. "(" .. tabnr .. ", win_getid())}",
        sep_inactive: "|",
        sep_active: "",
        highlight: {
            active: "StatusLine",
            inactive: "StatusLineNC",
        },
    }, "keep")
    const hlgroups: dict<any> = conf.highlight->mapnew((_, v) => type(v) == v:t_string ? v : v.name)
    def CalcTabList(win: number): string
        var res = color.Highlight(hlgroups.inactive)
        const curtab = tabpagenr()
        const alltab = range(1, tabpagenr("$"))
        if curtab > 1
            res ..= alltab[0 : curtab - 2]->mapnew((_, v) => "%" .. v .. "T" .. conf.tab_inactive(v))
                        \ ->join(conf.sep_inactive)
            res ..= conf.sep_active
        endif
        res ..= color.Highlight(hlgroups.active)
        res ..= "%" .. curtab .. "T" .. conf.tab_active(curtab)
        res ..= color.Highlight(hlgroups.inactive)
        if curtab < alltab[-1]
            res ..= conf.sep_active
            res ..= alltab[curtab : -1]->mapnew((_, v) => "%" .. v .. "T" .. conf.tab_inactive(v))
                        \ ->join(conf.sep_inactive)
        endif
        return res
    enddef
    var enter_tab = false
    return color.HlSchemeComponent(conf.highlight->values()->filter((_, v) => type(v) == v:t_dict), {
        value: CalcTabList,
        autocmds: ["TabEnter", "BufEnter"],
        listeners: {
            "autocmd:TabEnter": {
                1: [(..._) => {
                    enter_tab = true
                }],
            },
            "autocmd:BufEnter": {
                1: [(..._) => {
                    if enter_tab
                        enter_tab = false
                        lines9.Update({ type: "tabline" })
                        lines9.Refresh({ scope: "tabline" })
                    endif
                }],
            },
        },
    })
enddef

