# Module `lines9/color.vim`

Utilities for applying colorscheme/highlight groups on the components and the statusline.

## `Highlight(group: string): string`

Return the statusline string that applies the highlight group to following components.

## `HlComponent(component: Component, group: string): Component`

Return a component that wraps highlight on the component.
Note that when the component is already highlighted, the highlighting would not effect.
And the highlight would affect following components.

## `HlSchemeComponent(scheme: list<HlProp>, src: Component = {}): Component`

Return a component with listeners to add highlight groups.

`HlProp` is of the same structure as those returned by `hlget()`,
with an extra key `base` indicating from which group it's derived.

The component should not be used in lines directly since its content is empty.
On the other hand, you may derive your custom highlighted components based on the component.
If `src` is provided, the generated content would be merged with `src`.

