# doc

The documents of Lines9's submodules.

As illustrated in the main document, the markdown files are the documents for corresponding modules;
text files (none yet) are Vim documents.

## Notes

### Vim9 closures on dynamic components causes E1271/E1248

A dynamic component (created with `utils.Dyn`) would be evaluated every time when Vim tries to redraw the statusline.
Unfortunately, this is done in legacy context, and this is one of the contexts not allowing Vim9 closures to appear.

So a workaround is to create a legacy closure, and pass it back to Vim9 variables;
typically legacy closures can be created by defining a function with `function` to create a legacy context,
defining the legacy closure in it, and returning the closure.

With `utils.ToLegacyClosure`, this can be done quite simply:

``` vim
# code from components.ModeIndicator, modified
return {
    value: utils.Dyn(utils.ToLegacyClosure((win) => {
        const [cat, text] = conf.modemap->get(mode()[0], ["", "(UNKNOWN)"])
        return color.Highlight(hlgroups->get(cat, "ErrorMsg")) .. printf(conf.format, text)
    }), true),
}
```

