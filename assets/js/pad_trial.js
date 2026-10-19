// Trial for community pads, bundled separately (priv/static/assets/pad_trial.js)
// and only loaded on /dev/pad_trial by the PadTrial hook in app.js.
import * as Y from "yjs";
import { yCollab } from "y-codemirror.next";
import { PhoenixChannelProvider } from "y-phoenix-channel";
import { Socket } from "phoenix";
import { EditorView, basicSetup } from "codemirror";
import { markdown } from "@codemirror/lang-markdown";

const colors = ["#30bced", "#6eeb83", "#ffbc42", "#ee6352", "#9ac2c9", "#8acb88"];

window.PanPadTrial = {
  mount(el) {
    const ydoc = new Y.Doc();
    const socket = new Socket("/socket", {});
    socket.connect();
    const provider = new PhoenixChannelProvider(socket, el.dataset.topic, ydoc);
    const ytext = ydoc.getText("body");
    const color = colors[Math.floor(Math.random() * colors.length)];

    provider.awareness.setLocalStateField("user", {
      name: "Trial user " + Math.floor(Math.random() * 100),
      color: color,
      colorLight: color + "33",
    });

    const view = new EditorView({
      parent: el,
      extensions: [
        basicSetup,
        markdown(),
        EditorView.lineWrapping,
        yCollab(ytext, provider.awareness),
      ],
    });

    return () => {
      view.destroy();
      provider.destroy();
      socket.disconnect();
      ydoc.destroy();
    };
  },
};
