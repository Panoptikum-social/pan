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
    const view = new EditorView({
      parent: el.querySelector("[data-editor]"),
      extensions: [
        setup,
        EditorView.lineWrapping,
        // fill the pane and scroll inside it, for the scroll sync
        EditorView.theme({ "&": { height: "100%" }, ".cm-scroller": { overflow: "auto" } }),
        readOnly.of(readOnlyExtension(el.dataset.readOnly === "true")),
        yCollab(ydoc.getText(textName), provider.awareness),
      ],
    });

    const setToolbarReadOnly = mountToolbar(el.querySelector("[data-toolbar]"), view);
    setToolbarReadOnly(el.dataset.readOnly === "true");

    syncScroll([view.scrollDOM, el.querySelector("[data-pane=preview]")]);

    // rendered on the server by PanWeb.PadServer, sanitized like all user markdown
    const preview = el.querySelector("[data-preview]");
    provider.channel.on("preview", ({ html }) => (preview.innerHTML = html));

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
