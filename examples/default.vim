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

g:lines9_config = {
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

