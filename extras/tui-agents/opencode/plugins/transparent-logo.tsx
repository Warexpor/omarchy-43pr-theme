/** @jsxImportSource @opentui/solid */
import { TextAttributes, RGBA } from "@opentui/core"
import type { JSX } from "@opentui/solid"
import { For } from "solid-js"
import type { TuiPlugin, TuiPluginModule } from "@opencode-ai/plugin/tui"

// Same glyph map as OpenCode's built-in Logo.
const logo = {
  left: ["                   ", "█▀▀█ █▀▀█ █▀▀█ █▀▀▄", "█__█ █__█ █^^^ █__█", "▀▀▀▀ █▀▀▀ ▀▀▀▀ ▀~~▀"],
  right: ["             ▄     ", "█▀▀▀ █▀▀█ █▀▀█ █▀▀█", "█___ █__█ █__█ █^^^", "▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀"],
}

function tint(base: RGBA, overlay: RGBA, alpha: number): RGBA {
  const r = base.r + (overlay.r - base.r) * alpha
  const g = base.g + (overlay.g - base.g) * alpha
  const b = base.b + (overlay.b - base.b) * alpha
  return RGBA.fromInts(Math.round(r * 255), Math.round(g * 255), Math.round(b * 255))
}

function TransparentLogo(props: { background: RGBA; text: RGBA; textMuted: RGBA }) {
  // OpenCode's stock Logo always paints letter-counters with tint(background).
  // tint() drops alpha, so a transparent theme becomes opaque black blobs.
  // Skip those fills when the theme background is transparent.
  const transparent = props.background.a === 0

  const renderLine = (line: string, fg: RGBA, bold: boolean): JSX.Element[] => {
    const shadow = transparent ? undefined : tint(props.background, fg, 0.25)
    // Soft half-blocks: stock uses shadow-as-fg; when transparent, mute instead.
    const soft = shadow ?? props.textMuted
    const attrs = bold ? TextAttributes.BOLD : undefined
    return Array.from(line).map((char) => {
      if (char === "_") {
        return (
          <text fg={fg} bg={shadow} attributes={attrs} selectable={false}>
            {" "}
          </text>
        )
      }
      if (char === "^") {
        return (
          <text fg={fg} bg={shadow} attributes={attrs} selectable={false}>
            ▀
          </text>
        )
      }
      if (char === "~") {
        return (
          <text fg={soft} attributes={attrs} selectable={false}>
            ▀
          </text>
        )
      }
      if (char === ",") {
        return (
          <text fg={soft} attributes={attrs} selectable={false}>
            ▄
          </text>
        )
      }
      return (
        <text fg={fg} attributes={attrs} selectable={false}>
          {char}
        </text>
      )
    })
  }

  return (
    <box>
      <For each={logo.left}>
        {(line, index) => (
          <box flexDirection="row" gap={1}>
            <box flexDirection="row">{renderLine(line, props.textMuted, false)}</box>
            <box flexDirection="row">{renderLine(logo.right[index()], props.text, true)}</box>
          </box>
        )}
      </For>
    </box>
  )
}

const tui: TuiPlugin = async (api) => {
  api.slots.register({
    order: 0,
    slots: {
      home_logo() {
        const theme = api.theme.current
        return (
          <TransparentLogo background={theme.background} text={theme.text} textMuted={theme.textMuted} />
        )
      },
    },
  })
}

const plugin: TuiPluginModule & { id: string } = {
  id: "43pr.transparent-logo",
  tui,
}

export default plugin
