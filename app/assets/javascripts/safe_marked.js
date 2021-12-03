import DOMPurify from "dompurify";
import {marked} from "marked";

export default function safe_marked(markdownString, options, callback) {
  const s = marked(markdownString, options, callback);
  return DOMPurify.sanitize(s);
}
