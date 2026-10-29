// The editor of a community pad, bundled separately
// (priv/static/assets/pad_editor.js) and only loaded on pad pages by the
// PadEditor hook in app.js. The text is a Y.Text synced with PanWeb.PadChannel.
import * as Y from "yjs";
import { yCollab, yUndoManagerKeymap } from "y-codemirror.next";
import { PhoenixChannelProvider } from "y-phoenix-channel";
import { Socket } from "phoenix";
import {
  EditorView,
  keymap,
  lineNumbers,
  highlightActiveLineGutter,
  highlightSpecialChars,
  drawSelection,
  dropCursor,
  rectangularSelection,
  crosshairCursor,
  highlightActiveLine,
} from "@codemirror/view";
import { EditorState, Compartment } from "@codemirror/state";
import { defaultKeymap } from "@codemirror/commands";
import { highlightSelectionMatches, searchKeymap } from "@codemirror/search";
import { mountToolbar } from "./pad_toolbar";
import { selectionHighlight } from "./pad_selection";

// CodeMirror's basicSetup without autocompletion, linting and anything that
// needs a language (no syntax highlighting, by decision, it keeps the bundle
// small). Undo is Yjs' own (yCollab), so it only undoes your own edits.
const setup = [
  lineNumbers(),
  highlightActiveLineGutter(),
  highlightSpecialChars(),
  drawSelection(),
  dropCursor(),
  EditorState.allowMultipleSelections.of(true),
  rectangularSelection(),
  crosshairCursor(),
  highlightActiveLine(),
  highlightSelectionMatches(),
  keymap.of([...yUndoManagerKeymap, ...defaultKeymap, ...searchKeymap]),
];

// CodeMirror's base theme is light (gutter, active line, selection, cursor,
// search panel); our CSS variables make it follow Latte, Mocha and the toggle
const muted = (percent) =>
  `color-mix(in oklab, var(--color-base-content) ${percent}%, transparent)`;

const panTheme = EditorView.theme({
  "&": { height: "100%", color: "var(--color-base-content)" },
  ".cm-scroller": { overflow: "auto" },
  ".cm-content": { caretColor: "var(--color-base-content)" },
  ".cm-cursor, .cm-dropCursor": { borderLeftColor: "var(--color-base-content)" },
  ".cm-gutters": {
    backgroundColor: "var(--color-base-200)",
    color: muted(60),
    borderRight: "1px solid var(--color-base-300)",
  },
  ".cm-activeLineGutter": { backgroundColor: "var(--color-base-300)" },
  ".cm-activeLine": { backgroundColor: muted(6) },
  ".cm-selectionBackground, &.cm-focused > .cm-scroller > .cm-selectionLayer .cm-selectionBackground, .cm-content ::selection":
    { backgroundColor: "color-mix(in oklab, var(--color-primary) 25%, transparent)" },
  ".cm-selectionMatch": { backgroundColor: "color-mix(in oklab, var(--color-warning) 25%, transparent)" },
  ".cm-panels": {
    backgroundColor: "var(--color-base-200)",
    color: "var(--color-base-content)",
    borderColor: "var(--color-base-300)",
  },
  ".cm-textfield": {
    backgroundColor: "var(--color-base-100)",
    color: "var(--color-base-content)",
    borderColor: "var(--color-base-300)",
  },
  ".cm-button": {
    backgroundImage: "none",
    backgroundColor: "var(--color-base-100)",
    color: "var(--color-base-content)",
    borderColor: "var(--color-base-300)",
  },
  ".cm-searchMatch": { backgroundColor: "color-mix(in oklab, var(--color-warning) 35%, transparent)" },
});

function readOnlyExtension(readOnly) {
  return [EditorState.readOnly.of(readOnly), EditorView.editable.of(!readOnly)];
}

// Rough scroll sync by percentage. Only the pane the user is on (pointer,
// touch or focus) drives the other one, so the two don't push each other.
function syncScroll(panes) {
  let leader = null;
  for (const pane of panes) {
    for (const event of ["pointerenter", "touchstart", "focusin"]) {
      pane.addEventListener(event, () => (leader = pane), { passive: true });
    }
    pane.addEventListener(
      "scroll",
      () => {
        if (leader !== pane) return;
        const max = pane.scrollHeight - pane.clientHeight;
        if (max <= 0) return;
        for (const other of panes) {
          if (other === pane) continue;
          other.scrollTop = (pane.scrollTop / max) * (other.scrollHeight - other.clientHeight);
        }
      },
      { passive: true },
    );
  }
}

window.PanPadEditor = {
  mount(el, { onDeleted }) {
    const { padId, token, textName, userName, userColor } = el.dataset;
    const ydoc = new Y.Doc();
    const socket = new Socket("/socket", { params: { token } });
    socket.connect();

    const provider = new PhoenixChannelProvider(socket, `pad:${padId}`, ydoc, {
      disableBc: true,
    });

    provider.awareness.setLocalStateField("user", {
      name: userName,
      color: userColor,
      colorLight: userColor + "33",
    });

    const readOnly = new Compartment();
    const preview = el.querySelector("[data-preview]");
    const [highlightExtension, refreshHighlight] = selectionHighlight(preview);
    const view = new EditorView({
      parent: el.querySelector("[data-editor]"),
      extensions: [
        setup,
        EditorView.lineWrapping,
        // fills the pane and scrolls inside it (scroll sync), in our theme
        panTheme,
        readOnly.of(readOnlyExtension(el.dataset.readOnly === "true")),
        yCollab(ydoc.getText(textName), provider.awareness),
        highlightExtension,
      ],
    });

    const setToolbarReadOnly = mountToolbar(el.querySelector("[data-toolbar]"), view);
    setToolbarReadOnly(el.dataset.readOnly === "true");

    syncScroll([view.scrollDOM, el.querySelector("[data-pane=preview]")]);

    // rendered on the server by PanWeb.PadServer, sanitized like all user markdown
    provider.channel.on("preview", ({ html }) => {
      preview.innerHTML = html;
      refreshHighlight();
    });

    provider.channel.on("read_only", ({ read_only }) => {
      view.dispatch({ effects: readOnly.reconfigure(readOnlyExtension(read_only)) });
      setToolbarReadOnly(read_only);
    });

    provider.channel.on("deleted", () => onDeleted());

    return () => {
      view.destroy();
      provider.destroy();
      socket.disconnect();
      ydoc.destroy();
    };
  },
};
