module FrontendSSE

import JS
import Web.MVC

%default total

%foreign "javascript:lambda: (url, onMsg) => (world) => { const es = new EventSource(url); es.onmessage = (ev) => { const act = onMsg(ev.data); if (typeof act === 'function') { act(world); } }; if (!window.__sse) window.__sse = {}; window.__sse[url] = es; return {h: 1, a1: undefined}; }"
prim__subscribeSSE : String -> (String -> JSIO ()) -> JSIO ()

%foreign "javascript:lambda: (url) => (world) => { const m = window.__sse || {}; const es = m[url]; if (es) { es.close(); delete m[url]; } return {h: 1, a1: undefined}; }"
prim__closeSSE : String -> JSIO ()

%foreign "javascript:lambda: () => (world) => { const mk = () => 'c-' + Math.random().toString(36).slice(2); const id = (crypto && crypto.randomUUID) ? crypto.randomUUID() : mk(); return {h: 1, a1: id}; }"
prim__clientId : JSIO String

public export
requestClientId : (String -> msg) -> Cmd msg
requestClientId tag =
  cmd (prim__clientId >>= \cid => pure (tag cid))

public export
subscribe : String -> (String -> msg) -> Cmd msg
subscribe url tag = C $ \h => prim__subscribeSSE url (\msg => h (tag msg))

public export
close : String -> Cmd msg
close url = cmd_ (prim__closeSSE url)
