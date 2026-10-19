// The editor of a community pad, bundled separately
// (priv/static/assets/pad_editor.js) and only loaded on pad pages by the
// PadEditor hook in app.js. The text is a Y.Text synced with PanWeb.PadChannel.
import * as Y from "yjs";
import { yCollab } from "y-codemirror.next";
import { PhoenixChannelProvider } from "y-phoenix-channel";
import { Socket } from "phoenix";
import { EditorView, basicSetup } from "codemirror";
import { EditorState, Compartment } from "@codemirror/state";
import { markdown } from "@codemirror/lang-markdown";

function readOnlyExtension(readOnly) {
  return [EditorState.readOnly.of(readOnly), EditorView.editable.of(!readOnly)];
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
      parent: el,
      extensions: [
        basicSetup,
        markdown(),
        EditorView.lineWrapping,
        readOnly.of(readOnlyExtension(el.dataset.readOnly === "true")),
        yCollab(ydoc.getText(textName), provider.awareness),
      ],
    });

    provider.channel.on("read_only", ({ read_only }) => {
      view.dispatch({ effects: readOnly.reconfigure(readOnlyExtension(read_only)) });
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
