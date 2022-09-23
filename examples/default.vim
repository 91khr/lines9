vim9script
# Default config, lightline-like

import "../import/lines9.vim"
import "../import/lines9/color.vim"
import "../import/lines9/utils.vim"
import "../import/lines9/components.vim"

var leaving = false
def LeavingRefresh(..._)
    leaving = true
    lines9.Refresh({ scope: "window" })
enddef

final fname = components.FileName()
const FnameFn = fname.value
fname.value = (win) => (getbufvar(winbufnr(win), "&ro") ? " RO |" : "") .. FnameFn(win)

g:lines9_config = {
    schemes: {
        active: ["mode", "paste", "spell", "fname", "modified", "sep", "fileinfo", "percentage", "index"],
        inactive: ["fname_inactive", "modified", "sep", "index_inactive"],
        tabline: ["tablist", "sep", "closecur"],
    },
    components: {
        mode: components.ModeIndicator(),
        paste: utils.MakeComponent("%{&paste ? '| paste ' : ''}"),
        spell: utils.MakeComponent("%{&spell ? '| ' .. &spelllang .. ' ' : ''}"),
        fname: color.HlComponent(fname, "StatusLineNC"),
        modified: utils.MakeComponent("%{&modified ? '| + ' : ''}"),
        fname_inactive: color.HlComponent(components.FileName(), "CursorLine"),
        sep: color.HlComponent(components.Sep, "CursorLine"),
        fileinfo: utils.MakeComponent(" %{&ff} | %{&enc} | %{&ft ?? '(no ft)'} "),
        percentage: color.HlComponent(utils.MakeComponent(" %p%% "), "StatusLineNC"),
        index: color.HlComponent(utils.MakeComponent(" %l:%c "), "StatusLine"),
        index_inactive: color.HlComponent(utils.MakeComponent(" %l:%c "), "StatusLineNC"),
        tablist: components.TabpageList(),
        closecur: color.HlComponent(components.CloseCurTab, "StatusLineNC"),
    },
    dispatch: (loc): any => {
        if loc.type == "tabline"
            return "tabline"
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
        "lines9:GetTabline": {
            1: [() => {
                lines9.Update({ type: "tabline" })
                lines9.Refresh({ scope: "tabline" })
            }],
        },
    },
}

