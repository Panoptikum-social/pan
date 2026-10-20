// Highlights in the pad preview what is selected in the editor. The preview's
// elements carry data-sourcepos="line:column-line:column" (MDEx, columns in
// bytes, end inclusive). Highlighted are the innermost blocks the selection
// touches, or a single inline element (bold, link, ...) if the selection lies
// within it.
import { EditorView } from "@codemirror/view";

const highlightClasses = ["bg-warning/30", "rounded-sm"];
const inline = new Set(["STRONG", "EM", "DEL", "A", "CODE"]);
const encoder = new TextEncoder();

// [line, byte column], both 1-based, comparable as numbers
function position(doc, pos) {
  const line = doc.lineAt(pos);
  const column = encoder.encode(line.text.slice(0, pos - line.from)).length + 1;
  return line.number * 1e6 + column;
}

function sourceRange(element) {
  const [start, end] = element.dataset.sourcepos.split("-").map((part) => {
    const [line, column] = part.split(":").map(Number);
    return line * 1e6 + column;
  });
  return { start, end };
}

function highlight(preview, state) {
  for (const element of preview.querySelectorAll("." + CSS.escape(highlightClasses[0]))) {
    element.classList.remove(...highlightClasses);
  }

  const { from, to, empty } = state.selection.main;
  if (empty) return;

  const start = position(state.doc, from);
  const end = position(state.doc, to - 1);
  const overlapping = [...preview.querySelectorAll("[data-sourcepos]")].filter((element) => {
    const range = sourceRange(element);
    return range.start <= end && range.end >= start;
  });

  const surroundingInline = overlapping.filter((element) => {
    const range = sourceRange(element);
    return inline.has(element.tagName) && range.start <= start && range.end >= end;
  });

  const blocks = overlapping.filter((element) => !inline.has(element.tagName));
  const innermostBlocks = blocks.filter(
    (element) => !blocks.some((other) => other !== element && element.contains(other)),
  );

  const targets = surroundingInline.length ? surroundingInline.slice(-1) : innermostBlocks;
  for (const element of targets) element.classList.add(...highlightClasses);
}

// the extension for the editor, and a function to call after the preview changed
export function selectionHighlight(preview) {
  let view = null;

  const extension = EditorView.updateListener.of((update) => {
    view = update.view;
    // after an edit the preview catches up a moment later and calls refresh
    if (update.selectionSet) highlight(preview, update.state);
  });

  return [extension, () => view && highlight(preview, view.state)];
}
