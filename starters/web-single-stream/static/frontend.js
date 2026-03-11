class IdrisError extends Error { }

function __prim_js2idris_array(x){
  let acc = { h:0 };

  for (let i = x.length-1; i>=0; i--) {
      acc = { a1:x[i], a2:acc };
  }
  return acc;
}

function __prim_idris2js_array(x){
  const result = Array();
  while (x.h === undefined) {
    result.push(x.a1); x = x.a2;
  }
  return result;
}

function __lazy(thunk) {
  let res;
  return function () {
    if (thunk === undefined) return res;
    res = thunk();
    thunk = undefined;
    return res;
  };
};

function __prim_stringIteratorNew(_str) {
  return 0
}

function __prim_stringIteratorToString(_, str, it, f) {
  return f(str.slice(it))
}

function __prim_stringIteratorNext(str, it) {
  if (it >= str.length)
    return {h: 0};
  else
    return {a1: str.charAt(it), a2: it + 1};
}

function __tailRec(f,ini) {
  let obj = ini;
  while(true){
    switch(obj.h){
      case 0: return obj.a1;
      default: obj = f(obj);
    }
  }
}

const _idrisworld = Symbol('idrisworld')

const _crashExp = x=>{throw new IdrisError(x)}

const _bigIntOfString = s=> {
  try {
    const idx = s.indexOf('.')
    return idx === -1 ? BigInt(s) : BigInt(s.slice(0, idx))
  } catch (e) { return 0n }
}

const _numberOfString = s=> {
  try {
    const res = Number(s);
    return isNaN(res) ? 0 : res;
  } catch (e) { return 0 }
}

const _intOfString = s=> Math.trunc(_numberOfString(s))

const _truncToChar = x=> String.fromCodePoint(
  (x >= 0 && x <= 55295) || (x >= 57344 && x <= 1114111) ? x : 0
)

// Int8
const _truncInt8 = x => {
  const res = x & 0xff;
  return res >= 0x80 ? res - 0x100 : res;
}

const _truncBigInt8 = x => Number(BigInt.asIntN(8, x))

// Euclidian Division
const _div = (a,b) => {
  const q = Math.trunc(a / b)
  const r = a % b
  return r < 0 ? (b > 0 ? q - 1 : q + 1) : q
}

const _divBigInt = (a,b) => {
  const q = a / b
  const r = a % b
  return r < 0n ? (b > 0n ? q - 1n : q + 1n) : q
}

// Euclidian Modulo
const _mod = (a,b) => {
  const r = a % b
  return r < 0 ? (b > 0 ? r + b : r - b) : r
}

const _modBigInt = (a,b) => {
  const r = a % b
  return r < 0n ? (b > 0n ? r + b : r - b) : r
}

const _add8s = (a,b) => _truncInt8(a + b)
const _sub8s = (a,b) => _truncInt8(a - b)
const _mul8s = (a,b) => _truncInt8(a * b)
const _div8s = (a,b) => _truncInt8(_div(a,b))
const _shl8s = (a,b) => _truncInt8(a << b)
const _shr8s = (a,b) => _truncInt8(a >> b)

// Int16
const _truncInt16 = x => {
  const res = x & 0xffff;
  return res >= 0x8000 ? res - 0x10000 : res;
}

const _truncBigInt16 = x => Number(BigInt.asIntN(16, x))

const _add16s = (a,b) => _truncInt16(a + b)
const _sub16s = (a,b) => _truncInt16(a - b)
const _mul16s = (a,b) => _truncInt16(a * b)
const _div16s = (a,b) => _truncInt16(_div(a,b))
const _shl16s = (a,b) => _truncInt16(a << b)
const _shr16s = (a,b) => _truncInt16(a >> b)

//Int32
const _truncInt32 = x => x & 0xffffffff

const _truncBigInt32 = x => Number(BigInt.asIntN(32, x))

const _add32s = (a,b) => _truncInt32(a + b)
const _sub32s = (a,b) => _truncInt32(a - b)
const _div32s = (a,b) => _truncInt32(_div(a,b))

const _mul32s = (a,b) => {
  const res = a * b;
  if (res <= Number.MIN_SAFE_INTEGER || res >= Number.MAX_SAFE_INTEGER) {
    return _truncInt32((a & 0xffff) * b + (b & 0xffff) * (a & 0xffff0000))
  } else {
    return _truncInt32(res)
  }
}

//Int64
const _truncBigInt64 = x => BigInt.asIntN(64, x)

const _add64s = (a,b) => _truncBigInt64(a + b)
const _sub64s = (a,b) => _truncBigInt64(a - b)
const _mul64s = (a,b) => _truncBigInt64(a * b)
const _shl64s = (a,b) => _truncBigInt64(a << b)
const _div64s = (a,b) => _truncBigInt64(_divBigInt(a,b))
const _shr64s = (a,b) => _truncBigInt64(a >> b)

//Bits8
const _truncUInt8 = x => x & 0xff

const _truncUBigInt8 = x => Number(BigInt.asUintN(8, x))

const _add8u = (a,b) => (a + b) & 0xff
const _sub8u = (a,b) => (a - b) & 0xff
const _mul8u = (a,b) => (a * b) & 0xff
const _div8u = (a,b) => Math.trunc(a / b)
const _shl8u = (a,b) => (a << b) & 0xff
const _shr8u = (a,b) => (a >> b) & 0xff

//Bits16
const _truncUInt16 = x => x & 0xffff

const _truncUBigInt16 = x => Number(BigInt.asUintN(16, x))

const _add16u = (a,b) => (a + b) & 0xffff
const _sub16u = (a,b) => (a - b) & 0xffff
const _mul16u = (a,b) => (a * b) & 0xffff
const _div16u = (a,b) => Math.trunc(a / b)
const _shl16u = (a,b) => (a << b) & 0xffff
const _shr16u = (a,b) => (a >> b) & 0xffff

//Bits32
const _truncUBigInt32 = x => Number(BigInt.asUintN(32, x))

const _truncUInt32 = x => {
  const res = x & -1;
  return res < 0 ? res + 0x100000000 : res;
}

const _add32u = (a,b) => _truncUInt32(a + b)
const _sub32u = (a,b) => _truncUInt32(a - b)
const _mul32u = (a,b) => _truncUInt32(_mul32s(a,b))
const _div32u = (a,b) => Math.trunc(a / b)

const _shl32u = (a,b) => _truncUInt32(a << b)
const _shr32u = (a,b) => _truncUInt32(a <= 0x7fffffff ? a >> b : (b == 0 ? a : (a >> b) ^ ((-0x80000000) >> (b-1))))
const _and32u = (a,b) => _truncUInt32(a & b)
const _or32u = (a,b)  => _truncUInt32(a | b)
const _xor32u = (a,b) => _truncUInt32(a ^ b)

//Bits64
const _truncUBigInt64 = x => BigInt.asUintN(64, x)

const _add64u = (a,b) => BigInt.asUintN(64, a + b)
const _mul64u = (a,b) => BigInt.asUintN(64, a * b)
const _div64u = (a,b) => a / b
const _shl64u = (a,b) => BigInt.asUintN(64, a << b)
const _shr64u = (a,b) => BigInt.asUintN(64, a >> b)
const _sub64u = (a,b) => BigInt.asUintN(64, a - b)

//String
const _strReverse = x => x.split('').reverse().join('')

const _substr = (o,l,x) => x.slice(o, o + l)

const Prelude_Types_fastUnpack = ((str)=>__prim_js2idris_array(Array.from(str)));
const Prelude_Types_fastPack = ((xs)=>__prim_idris2js_array(xs).join(''));
const Prelude_Types_fastConcat = ((xs)=>__prim_idris2js_array(xs).join(''));
const Prelude_IO_prim__putStr = (x=>console.log(x));
const JS_Util_prim__typeOf = (v=>typeof(v));
const JS_Util_prim__show = (x=>String(x));
const JS_Util_prim__eqv = ((a,b)=>a === b?1:0);
const JS_Util_prim__consoleLog = (x=>console.log(x));
const JS_Inheritance_prim__hasProtoName = ((s,v)=>{
var o = v;
  while (o != null) {
    var p = Object.getPrototypeOf(o);
    var cn = p.constructor.name;
    if (cn === s) {
      return 1;
    } else if (cn === "Object") {
      return 0;
    }
    o = p;
  }
  return 0;
});
const JS_Undefined_undefined = (()=>undefined);
const JS_Nullable_prim__null = (()=>null);
const JS_Boolean_true$ = (()=>true);
const JS_Boolean_false$ = (()=>false);
const JS_Array_prim__writeIO = ((u,arr,n,v) => { arr[n] = v });
const JS_Array_prim__newArrayIO = ((u,n) => { return new Array(n) });
const Web_Internal_XhrPrim_XMLHttpRequest_prim__timeout = (x=>x.timeout);
const Web_Internal_XhrPrim_XMLHttpRequest_prim__status = (x=>x.status);
const Web_Internal_XhrPrim_XMLHttpRequest_prim__setTimeout = ((x,v)=>{x.timeout = v});
const Web_Internal_XhrPrim_XMLHttpRequest_prim__setRequestHeader = ((x,a,b)=>x.setRequestHeader(a,b));
const Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__setOntimeout = ((x,v)=>{x.ontimeout = v});
const Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__setOnload = ((x,v)=>{x.onload = v});
const Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__setOnerror = ((x,v)=>{x.onerror = v});
const Web_Internal_XhrPrim_XMLHttpRequest_prim__send = ((x,a)=>x.send(a));
const Web_Internal_XhrPrim_XMLHttpRequest_prim__responseText = (x=>x.responseText);
const Web_Internal_XhrPrim_XMLHttpRequest_prim__open = ((x,a,b)=>x.open(a,b));
const Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__ontimeout = (x=>x.ontimeout);
const Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__onload = (x=>x.onload);
const Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__onerror = (x=>x.onerror);
const Web_Internal_XhrPrim_XMLHttpRequest_prim__new = (()=> new XMLHttpRequest());
const Web_Internal_XhrPrim_FormData_prim__new = ((a)=> new FormData(a));
const Web_Internal_XhrPrim_FormData_prim__append1 = ((x,a,b,c)=>x.append(a,b,c));
const Web_Internal_XhrPrim_FormData_prim__append = ((x,a,b)=>x.append(a,b));
const Web_Internal_HtmlPrim_EventHandlerNonNull_prim__toEventHandlerNonNull = (x=>(a)=>x(a)());
const Web_Internal_HtmlPrim_HTMLTemplateElement_prim__content = (x=>x.content);
const JSON_Parser_jdouble = ((s) => Number(s));
const Data_Buffer_Core_prim__newBuf = ((s,w)=>new Uint8Array(Number(s)));
const Data_Buffer_Core_prim__getString = ((buf,offset,len)=> new TextDecoder().decode(buf.subarray(Number(offset), Number(offset+len))));
const Data_Buffer_Core_prim__getByteOffset = ((buf,at,offset)=>buf[Number(offset) + Number(at)]);
const Data_Buffer_Core_prim__getByte = ((buf,offset)=>buf[Number(offset)]);
const Data_Buffer_Core_prim__fromString = ((v)=> new TextEncoder().encode(v));
const Data_Buffer_stringByteLength = ((string)=>new TextEncoder().encode(string).length);
const Data_Array_Core_prim__newArray = ((bi,x,w) => Array(Number(bi)).fill(x));
const Data_Array_Core_prim__copyArray = ((b1,bo1,blen,b2,bo2,t)=> {const o1 = Number(bo1); const len = Number(blen); const o2 = Number(bo2); for (let i = 0; i < len; i++) {b2[o2+i] = b1[o1+i];}; return t});
const Data_Array_Core_prim__arraySet = ((x,bi,w) => {const i = Number(bi); x[i] = w});
const Data_Array_Core_prim__arrayGet = ((x,bi) => x[Number(bi)]);
const Text_ILex_Parser_prim__newMachine = ((i,x,w) => Array(i).fill(x));
const Text_ILex_Parser_prim__machineSet = ((x,i,w) => {x[i] = w});
const Text_ILex_Parser_prim__machineGet = ((x,bi) => x[bi]);
const Web_MVC_View_prim__observeResize = ((e,f,w) => {const o = new ResizeObserver((es) => f(e.getBoundingClientRect())(w));o.observe(e)});
const Web_Internal_GeometryPrim_DOMRectReadOnly_prim__y = (x=>x.y);
const Web_Internal_GeometryPrim_DOMRectReadOnly_prim__x = (x=>x.x);
const Web_Internal_GeometryPrim_DOMRectReadOnly_prim__width = (x=>x.width);
const Web_Internal_GeometryPrim_DOMRectReadOnly_prim__top = (x=>x.top);
const Web_Internal_GeometryPrim_DOMRectReadOnly_prim__right = (x=>x.right);
const Web_Internal_GeometryPrim_DOMRectReadOnly_prim__left = (x=>x.left);
const Web_Internal_GeometryPrim_DOMRectReadOnly_prim__height = (x=>x.height);
const Web_Internal_GeometryPrim_DOMRectReadOnly_prim__bottom = (x=>x.bottom);
const Web_Dom_prim__window = (()=>window);
const Web_Dom_prim__document = (()=>document);
const Web_Internal_DomPrim_EventListener_prim__toEventListener = (x=>(a)=>x(a)());
const Web_Internal_DomPrim_Event_prim__target = (x=>x.target);
const Web_Internal_DomPrim_Event_prim__stopPropagation = (x=>x.stopPropagation());
const Web_Internal_DomPrim_Element_prim__setScrollTop = ((x,v)=>{x.scrollTop = v});
const Web_Internal_DomPrim_InnerHTML_prim__setInnerHTML = ((x,v)=>{x.innerHTML = v});
const Web_Internal_DomPrim_Document_prim__setBody = ((x,v)=>{x.body = v});
const Web_Internal_DomPrim_Element_prim__setAttribute = ((x,a,b)=>x.setAttribute(a,b));
const Web_Internal_DomPrim_Element_prim__scrollTop = (x=>x.scrollTop);
const Web_Internal_DomPrim_Element_prim__scrollHeight = (x=>x.scrollHeight);
const Web_Internal_DomPrim_ParentNode_prim__replaceChildren = ((x,va)=>x.replaceChildren(...va()));
const Web_Internal_DomPrim_Element_prim__removeAttribute = ((x,a)=>x.removeAttribute(a));
const Web_Internal_DomPrim_Event_prim__preventDefault = (x=>x.preventDefault());
const Web_Internal_DomPrim_InnerHTML_prim__innerHTML = (x=>x.innerHTML);
const Web_Internal_DomPrim_NonElementParentNode_prim__getElementById = ((x,a)=>x.getElementById(a));
const Web_Internal_DomPrim_Document_prim__createElement = ((x,a,b)=>x.createElement(a,b));
const Web_Internal_DomPrim_Document_prim__createDocumentFragment = (x=>x.createDocumentFragment());
const Web_Internal_DomPrim_Element_prim__clientHeight = (x=>x.clientHeight);
const Web_Internal_DomPrim_Event_prim__cancelable = (x=>x.cancelable);
const Web_Internal_DomPrim_Event_prim__bubbles = (x=>x.bubbles);
const Web_Internal_DomPrim_Document_prim__body = (x=>x.body);
const Web_Internal_DomPrim_ParentNode_prim__append = ((x,va)=>x.append(...va()));
const Web_Internal_DomPrim_EventTarget_prim__addEventListener = ((x,a,b,c)=>x.addEventListener(a,b,c));
const Web_MVC_Event_prim__length = (x=>x.length);
const Web_MVC_Event_prim__item = ((x,y)=>x[y]);
const Web_MVC_Event_prim__input = (x=>x.target.value || x.target.innerHTML || '');
const Web_MVC_Event_prim__files = (x=>x.target.files || []);
const Web_MVC_Event_prim__checked = (x=>x.target.checked?1:0);
const Web_Internal_UIEventsPrim_MouseEvent_prim__shiftKey = (x=>x.shiftKey);
const Web_Internal_UIEventsPrim_KeyboardEvent_prim__shiftKey = (x=>x.shiftKey);
const Web_Internal_UIEventsPrim_MouseEvent_prim__screenY = (x=>x.screenY);
const Web_Internal_UIEventsPrim_MouseEvent_prim__screenX = (x=>x.screenX);
const Web_Internal_UIEventsPrim_MouseEvent_prim__pageY = (x=>x.pageY);
const Web_Internal_UIEventsPrim_MouseEvent_prim__pageX = (x=>x.pageX);
const Web_Internal_UIEventsPrim_MouseEvent_prim__offsetY = (x=>x.offsetY);
const Web_Internal_UIEventsPrim_MouseEvent_prim__offsetX = (x=>x.offsetX);
const Web_Internal_UIEventsPrim_MouseEvent_prim__metaKey = (x=>x.metaKey);
const Web_Internal_UIEventsPrim_KeyboardEvent_prim__metaKey = (x=>x.metaKey);
const Web_Internal_UIEventsPrim_KeyboardEvent_prim__location = (x=>x.location);
const Web_Internal_UIEventsPrim_KeyboardEvent_prim__key = (x=>x.key);
const Web_Internal_UIEventsPrim_KeyboardEvent_prim__isComposing = (x=>x.isComposing);
const Web_Internal_UIEventsPrim_WheelEvent_prim__deltaZ = (x=>x.deltaZ);
const Web_Internal_UIEventsPrim_WheelEvent_prim__deltaY = (x=>x.deltaY);
const Web_Internal_UIEventsPrim_WheelEvent_prim__deltaX = (x=>x.deltaX);
const Web_Internal_UIEventsPrim_WheelEvent_prim__deltaMode = (x=>x.deltaMode);
const Web_Internal_UIEventsPrim_MouseEvent_prim__ctrlKey = (x=>x.ctrlKey);
const Web_Internal_UIEventsPrim_KeyboardEvent_prim__ctrlKey = (x=>x.ctrlKey);
const Web_Internal_UIEventsPrim_KeyboardEvent_prim__code = (x=>x.code);
const Web_Internal_UIEventsPrim_MouseEvent_prim__clientY = (x=>x.clientY);
const Web_Internal_UIEventsPrim_MouseEvent_prim__clientX = (x=>x.clientX);
const Web_Internal_UIEventsPrim_MouseEvent_prim__buttons = (x=>x.buttons);
const Web_Internal_UIEventsPrim_MouseEvent_prim__button = (x=>x.button);
const Web_Internal_UIEventsPrim_MouseEvent_prim__altKey = (x=>x.altKey);
const Web_Internal_UIEventsPrim_KeyboardEvent_prim__altKey = (x=>x.altKey);
const EmKit_Frontend_SSE_prim__subscribeSSE = ( (url, onMsg) => (world) => { const es = new EventSource(url); es.onmessage = (ev) => { const act = onMsg(ev.data); if (typeof act === 'function') { act(world); } }; if (!window.__sse) window.__sse = {}; window.__sse[url] = es; return {h: 1, a1: undefined}; });
const EmKit_Frontend_SSE_prim__clientId = ( () => (world) => { const mk = () => 'c-' + Math.random().toString(36).slice(2); const id = (crypto && crypto.randomUUID) ? crypto.randomUUID() : mk(); return {h: 1, a1: id}; });
/* {$tcOpt:1} */
function x24tcOpt_1($0) {
 switch($0.a3.h) {
  case undefined: /* cons */ {
   switch($0.a3.a2.h) {
    case undefined: /* cons */ {
     switch($0.a4.h) {
      case undefined: /* cons */ return {h: 1 /* {TcContinue1:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2.a2, a4: $0.a4.a2, a5: $a => $0.a5({a1: $0.a4.a1, a2: $a})};
      default: return {h: 0 /* {TcDone:1} */, a1: {a1: $0.a4, a2: $0.a5({h: 0})}};
     }
    }
    default: return {h: 0 /* {TcDone:1} */, a1: {a1: $0.a4, a2: $0.a5({h: 0})}};
   }
  }
  default: return {h: 0 /* {TcDone:1} */, a1: {a1: $0.a4, a2: $0.a5({h: 0})}};
 }
}

/* Data.List.7787:8509:splitRec */
function Data_List_n__7787_8509_splitRec($0, $1, $2, $3, $4) {
 return __tailRec(x24tcOpt_1, {h: 1 /* {TcContinue1:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4});
}

/* {$tcOpt:2} */
function x24tcOpt_2($0) {
 switch($0.a4.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:2} */, a1: $4 => $0.a5};
  case undefined: /* cons */ {
   const $6 = Data_Array_Index_tryNatToFin($0.a3, $0.a4.a1.a1);
   switch($6.h) {
    case undefined: /* just */ {
     const $a = $b => {
      const $c = Data_Array_Core_prim__arraySet($0.a5, $6.a1, $0.a4.a1.a2, $b);
      return Data_Array_Indexed_n__5766_9221_go($0.a1, $0.a2, $0.a3, $0.a4.a2, $0.a5)(undefined);
     };
     return {h: 0 /* {TcDone:2} */, a1: $a};
    }
    case 0: /* nothing */ return {h: 1 /* {TcContinue2:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4.a2, a5: $0.a5};
   }
  }
 }
}

/* Data.Array.Indexed.5766:9221:go */
function Data_Array_Indexed_n__5766_9221_go($0, $1, $2, $3, $4) {
 return __tailRec(x24tcOpt_2, {h: 1 /* {TcContinue2:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4});
}

/* {$tcOpt:3} */
function x24tcOpt_3($0) {
 switch($0.a4.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:3} */, a1: $0.a5};
  case undefined: /* cons */ {
   const $5 = Text_ILex_Parser_prim__machineSet($0.a5, $0.a4.a1.a1, $0.a4.a1.a2, $0.a6);
   return {h: 1 /* {TcContinue3:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4.a2, a5: $0.a5, a6: undefined};
  }
 }
}

/* Text.ILex.Parser.10719:11251:fill */
function Text_ILex_Parser_n__10719_11251_fill($0, $1, $2, $3, $4, $5) {
 return __tailRec(x24tcOpt_3, {h: 1 /* {TcContinue3:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5});
}

/* {$tcOpt:4} */
function x24tcOpt_4($0) {
 switch($0.h) {
  case 1: /* {TcContinue4:1} */ {
   switch($0.a2.h) {
    case 0: /* nil */ {
     switch($0.a3.h) {
      case 0: /* nil */ return {h: 0 /* {TcDone:4} */, a1: 1};
      case undefined: /* cons */ return {h: 0 /* {TcDone:4} */, a1: 0};
     }
    }
    case undefined: /* cons */ {
     switch($0.a3.h) {
      case 0: /* nil */ return {h: 0 /* {TcDone:4} */, a1: 2};
      case undefined: /* cons */ return {h: 2 /* {TcContinue4:2} */, a1: $0.a1, a2: $0.a2.a1, a3: $0.a2.a2, a4: $0.a3.a1, a5: $0.a3.a2, a6: $0.a1.a2($0.a2.a1)($0.a3.a1)};
     }
    }
   }
  }
  case 2: /* {TcContinue4:2} */ {
   switch($0.a6) {
    case 1: return {h: 1 /* {TcContinue4:1} */, a1: $0.a1, a2: $0.a3, a3: $0.a5};
    default: return {h: 0 /* {TcDone:4} */, a1: $0.a6};
   }
  }
 }
}

/* Prelude.Types.compare */
function Prelude_Types_compare_Ord_x28Listx20x24ax29($0, $1, $2) {
 return __tailRec(x24tcOpt_4, {h: 1 /* {TcContinue4:1} */, a1: $0, a2: $1, a3: $2});
}

/* Prelude.Types.case block in compare */
function Prelude_Types_case__compare_6803($0, $1, $2, $3, $4, $5) {
 return __tailRec(x24tcOpt_4, {h: 2 /* {TcContinue4:2} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5});
}

/* {$tcOpt:5} */
function x24tcOpt_5($0) {
 switch($0.a2.h) {
  case 0: /* nil */ {
   switch($0.a3.h) {
    case 0: /* nil */ return {h: 0 /* {TcDone:5} */, a1: 1};
    default: return {h: 0 /* {TcDone:5} */, a1: 0};
   }
  }
  case undefined: /* cons */ {
   switch($0.a3.h) {
    case undefined: /* cons */ {
     switch($0.a1.a1($0.a2.a1)($0.a3.a1)) {
      case 1: return {h: 1 /* {TcContinue5:1} */, a1: $0.a1, a2: $0.a2.a2, a3: $0.a3.a2};
      case 0: return {h: 0 /* {TcDone:5} */, a1: 0};
     }
    }
    default: return {h: 0 /* {TcDone:5} */, a1: 0};
   }
  }
  default: return {h: 0 /* {TcDone:5} */, a1: 0};
 }
}

/* Prelude.Types.== */
function Prelude_Types_x3dx3d_Eq_x28Listx20x24ax29($0, $1, $2) {
 return __tailRec(x24tcOpt_5, {h: 1 /* {TcContinue5:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:6} */
function x24tcOpt_6($0) {
 switch($0.h) {
  case 1: /* {TcContinue6:1} */ {
   switch($0.a6.h) {
    case 0: /* nil */ return {h: 0 /* {TcDone:6} */, a1: undefined};
    case undefined: /* cons */ return {h: 2 /* {TcContinue6:2} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a5, a6: $0.a6.a1, a7: $0.a6.a2, a8: $0.a7, a9: Data_Array_Index_tryNatToFin($0.a1, $0.a6.a1)};
   }
  }
  case 2: /* {TcContinue6:2} */ {
   switch($0.a9.h) {
    case 0: /* nothing */ return {h: 1 /* {TcContinue6:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a5, a6: $0.a7, a7: $0.a8};
    case undefined: /* just */ {
     const $18 = Data_Array_Core_prim__arrayGet($0.a3, $0.a9.a1);
     switch($18) {
      case 1: return {h: 1 /* {TcContinue6:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a5, a6: $0.a7, a7: undefined};
      case 0: {
       const $24 = Data_Array_Core_prim__arraySet($0.a3, $0.a9.a1, 1, undefined);
       return {h: 3 /* {TcContinue6:3} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a5, a6: $0.a6, a7: $0.a7, a8: $0.a9.a1, a9: $24, a10: Data_Array_Core_prim__arrayGet($0.a4, $0.a9.a1)};
      }
     }
    }
   }
  }
  case 3: /* {TcContinue6:3} */ {
   switch($0.a10.h) {
    case 0: /* nothing */ return {h: 1 /* {TcContinue6:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a5, a6: $0.a7, a7: undefined};
    case undefined: /* just */ {
     const $3f = Data_Array_Core_prim__arraySet($0.a5, $0.a8, {a1: $0.a10.a1}, undefined);
     return {h: 1 /* {TcContinue6:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a5, a6: Prelude_Types_List_tailRecAppend($0.a2($0.a10.a1), $0.a7), a7: undefined};
    }
   }
  }
 }
}

/* Text.ILex.Internal.Types.visit : (a -> List Nat) -> MArray s sz Bool -> MArray s sz (Maybe a) -> MArray s sz (Maybe a) -> List Nat -> F1' s */
function Text_ILex_Internal_Types_visit($0, $1, $2, $3, $4, $5, $6) {
 return __tailRec(x24tcOpt_6, {h: 1 /* {TcContinue6:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6});
}

/* Text.ILex.Internal.Types.case block in visit */
function Text_ILex_Internal_Types_case__visit_9902($0, $1, $2, $3, $4, $5, $6, $7, $8) {
 return __tailRec(x24tcOpt_6, {h: 2 /* {TcContinue6:2} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8});
}

/* Text.ILex.Internal.Types.case block in case block in case block in case block in visit */
function Text_ILex_Internal_Types_case__casex20blockx20inx20casex20blockx20inx20casex20blockx20inx20visit_10061($0, $1, $2, $3, $4, $5, $6, $7, $8, $9) {
 return __tailRec(x24tcOpt_6, {h: 3 /* {TcContinue6:3} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8, a10: $9});
}

/* {$tcOpt:7} */
function x24tcOpt_7($0) {
 switch($0.a2.h) {
  case undefined: /* cons */ {
   switch($0.a3.h) {
    case undefined: /* cons */ {
     const $4 = {a1: $0.a2.a1, a2: $0.a2.a2};
     const $7 = {a1: $0.a3.a1, a2: $0.a3.a2};
     switch(Prelude_EqOrd_compare_Ord_Integer($0.a2.a1, $0.a3.a1)) {
      case 0: return {h: 1 /* {TcContinue7:1} */, a1: {a1: $0.a1, a2: $0.a2.a1}, a2: $0.a2.a2, a3: $7};
      case 2: return {h: 1 /* {TcContinue7:1} */, a1: {a1: $0.a1, a2: $0.a3.a1}, a2: $4, a3: $0.a3.a2};
      case 1: return {h: 1 /* {TcContinue7:1} */, a1: {a1: $0.a1, a2: $0.a2.a1}, a2: $0.a2.a2, a3: $0.a3.a2};
     }
    }
    default: return {h: 0 /* {TcDone:7} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, $0.a2)};
   }
  }
  case 0: /* nil */ return {h: 0 /* {TcDone:7} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, $0.a3)};
  default: return {h: 0 /* {TcDone:7} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, $0.a2)};
 }
}

/* Text.ILex.Internal.Types.union_ : SnocList Nat -> NSet -> NSet -> NSet */
function Text_ILex_Internal_Types_union_($0, $1, $2) {
 return __tailRec(x24tcOpt_7, {h: 1 /* {TcContinue7:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:8} */
function x24tcOpt_8($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:8} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, {h: 0})};
  case undefined: /* cons */ {
   const $7 = $0.a2($0.a3.a1)($0.a4);
   return {h: 1 /* {TcContinue8:1} */, a1: {a1: $0.a1, a2: $7}, a2: $0.a2, a3: $0.a3.a2, a4: undefined};
  }
 }
}

/* Data.Linear.Traverse1.traverse1List : SnocList b -> (a -> F1 s b) -> List a -> F1 s (List b) */
function Data_Linear_Traverse1_traverse1List($0, $1, $2, $3) {
 return __tailRec(x24tcOpt_8, {h: 1 /* {TcContinue8:1} */, a1: $0, a2: $1, a3: $2, a4: $3});
}

/* {$tcOpt:9} */
function x24tcOpt_9($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:9} */, a1: 0n};
  case undefined: /* cons */ {
   switch($0.a1.a1($0.a3.a1.a1)($0.a2)) {
    case 1: return {h: 0 /* {TcDone:9} */, a1: $0.a3.a1.a2};
    case 0: return {h: 1 /* {TcContinue9:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2};
   }
  }
 }
}

/* EmKit.Stream.Version.streamKnownVersion : Eq stream => stream -> List (stream, Nat) -> Nat */
function EmKit_Stream_Version_streamKnownVersion($0, $1, $2) {
 return __tailRec(x24tcOpt_9, {h: 1 /* {TcContinue9:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:10} */
function x24tcOpt_10($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:10} */, a1: {a1: $0.a1, a2: '}'}};
  case undefined: /* cons */ {
   const $6 = JSON_Parser_showPair({a1: $0.a1, a2: ','}, $0.a2.a1);
   return {h: 1 /* {TcContinue10:1} */, a1: $6, a2: $0.a2.a2};
  }
 }
}

/* JSON.Parser.showObject : SnocList String -> List (String, JSON) -> SnocList String */
function JSON_Parser_showObject($0, $1) {
 return __tailRec(x24tcOpt_10, {h: 1 /* {TcContinue10:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:11} */
function x24tcOpt_11($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:11} */, a1: {a1: $0.a1, a2: ']'}};
  case undefined: /* cons */ {
   const $6 = JSON_Parser_showValue({a1: $0.a1, a2: ','}, $0.a2.a1);
   return {h: 1 /* {TcContinue11:1} */, a1: $6, a2: $0.a2.a2};
  }
 }
}

/* JSON.Parser.showArray : SnocList String -> List JSON -> SnocList String */
function JSON_Parser_showArray($0, $1) {
 return __tailRec(x24tcOpt_11, {h: 1 /* {TcContinue11:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:12} */
function x24tcOpt_12($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:12} */, a1: $4 => Prelude_Types_SnocList_x3cx3ex3e($0.a2, {h: 0})};
  case undefined: /* cons */ {
   switch($0.a3.a1.a2.h) {
    case 0: /* nil */ return {h: 1 /* {TcContinue12:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2};
    case undefined: /* cons */ {
     switch($0.a3.a1.a2.a2.h) {
      case 0: /* nil */ return {h: 1 /* {TcContinue12:1} */, a1: $0.a1, a2: {a1: $0.a2, a2: {a1: $0.a3.a1.a1, a2: $0.a3.a1.a2.a1}}, a3: $0.a3.a2};
      default: {
       const $15 = $16 => {
        const $17 = Text_ILex_Internal_Types_lookupSet($0.a1, $0.a3.a1.a2, $16);
        switch($17.h) {
         case undefined: /* just */ return Text_ILex_Internal_DFA_process($0.a1, {a1: $0.a2, a2: {a1: $0.a3.a1.a1, a2: $17.a1}}, $0.a3.a2)(undefined);
         case 0: /* nothing */ {
          const $27 = Text_ILex_Internal_Types_addSet($0.a1, $0.a3.a1.a2, undefined);
          const $2c = Data_Linear_Traverse1_traverse1List({h: 0}, $30 => $31 => Text_ILex_Internal_Types_lookupDflt1($30, () => ({a1: $30, a2: {h: 0}, a3: {h: 0}}), $0.a1.a4, $31), $0.a3.a1.a2, undefined);
          const $3d = Text_ILex_Internal_Types_insert1($27, Prelude_Types_foldl_Foldable_List(csegen_606(), {a1: $27, a2: {h: 0}, a3: {h: 0}}, $2c), $0.a1.a4, undefined);
          const $4c = Text_ILex_Internal_DFA_discrete($0.a1, $27, undefined);
          return Text_ILex_Internal_DFA_process($0.a1, {a1: $0.a2, a2: {a1: $0.a3.a1.a1, a2: $27}}, $0.a3.a2)(undefined);
         }
        }
       };
       return {h: 0 /* {TcDone:12} */, a1: $15};
      }
     }
    }
    default: {
     const $5b = $5c => {
      const $5d = Text_ILex_Internal_Types_lookupSet($0.a1, $0.a3.a1.a2, $5c);
      switch($5d.h) {
       case undefined: /* just */ return Text_ILex_Internal_DFA_process($0.a1, {a1: $0.a2, a2: {a1: $0.a3.a1.a1, a2: $5d.a1}}, $0.a3.a2)(undefined);
       case 0: /* nothing */ {
        const $6d = Text_ILex_Internal_Types_addSet($0.a1, $0.a3.a1.a2, undefined);
        const $72 = Data_Linear_Traverse1_traverse1List({h: 0}, $76 => $77 => Text_ILex_Internal_Types_lookupDflt1($76, () => ({a1: $76, a2: {h: 0}, a3: {h: 0}}), $0.a1.a4, $77), $0.a3.a1.a2, undefined);
        const $83 = Text_ILex_Internal_Types_insert1($6d, Prelude_Types_foldl_Foldable_List(csegen_606(), {a1: $6d, a2: {h: 0}, a3: {h: 0}}, $72), $0.a1.a4, undefined);
        const $92 = Text_ILex_Internal_DFA_discrete($0.a1, $6d, undefined);
        return Text_ILex_Internal_DFA_process($0.a1, {a1: $0.a2, a2: {a1: $0.a3.a1.a1, a2: $6d}}, $0.a3.a2)(undefined);
       }
      }
     };
     return {h: 0 /* {TcDone:12} */, a1: $5b};
    }
   }
  }
 }
}

/* Text.ILex.Internal.DFA.process : DFAState s a => SnocList Edge -> NEdges -> F1 s Edges */
function Text_ILex_Internal_DFA_process($0, $1, $2) {
 return __tailRec(x24tcOpt_12, {h: 1 /* {TcContinue12:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:13} */
function x24tcOpt_13($0) {
 switch($0.a4) {
  case 0n: return {h: 0 /* {TcDone:13} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a3, {h: 0})};
  default: {
   const $7 = ($0.a4-1n);
   const $a = Data_Array_Core_prim__arrayGet($0.a2, $7);
   switch($a.h) {
    case undefined: /* just */ return {h: 1 /* {TcContinue13:1} */, a1: $0.a1, a2: $0.a2, a3: {a1: $0.a3, a2: {a1: $7, a2: $a.a1}}, a4: $7, a5: undefined};
    case 0: /* nothing */ return {h: 1 /* {TcContinue13:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $7, a5: undefined};
   }
  }
 }
}

/* Text.ILex.Internal.Types.9675:9656:go */
function Text_ILex_Internal_Types_n__9675_9656_go($0, $1, $2, $3, $4) {
 return __tailRec(x24tcOpt_13, {h: 1 /* {TcContinue13:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4});
}

/* {$tcOpt:14} */
function x24tcOpt_14($0) {
 switch($0.h) {
  case 1: /* {TcContinue14:1} */ {
   switch($0.a4.h) {
    case 0: /* nil */ return {h: 0 /* {TcDone:14} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a3, {h: 0})};
    case undefined: /* cons */ {
     switch($0.a4.a2.h) {
      case 0: /* nil */ {
       let $8;
       switch($0.a4.a1.h) {
        case 0: /* nil */ {
         $8 = 1;
         break;
        }
        default: $8 = 0;
       }
       switch($8) {
        case 1: return {h: 0 /* {TcDone:14} */, a1: {h: 0}};
        case 0: return {h: 0 /* {TcDone:14} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a3, {a1: $0.a4.a1, a2: {h: 0}})};
       }
      }
      case undefined: /* cons */ return {h: 2 /* {TcContinue14:2} */, a1: $0.a1, a2: $0.a2, a3: $0.a4.a1, a4: $0.a4.a2.a1, a5: $0.a4.a2.a2, a6: $0.a3, a7: Text_ILex_Char_Range_union($0.a1.a1, $0.a2, $0.a4.a1, $0.a4.a2.a1)};
     }
    }
   }
  }
  case 2: /* {TcContinue14:2} */ {
   switch($0.a7.h) {
    case 0: /* Left */ {
     let $1f;
     switch($0.a7.a1.h) {
      case 0: /* nil */ {
       $1f = 1;
       break;
      }
      default: $1f = 0;
     }
     switch($1f) {
      case 1: return {h: 1 /* {TcContinue14:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a6, a4: $0.a5};
      case 0: return {h: 1 /* {TcContinue14:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a6, a4: {a1: $0.a7.a1, a2: $0.a5}};
     }
    }
    case 1: /* Right */ return {h: 1 /* {TcContinue14:1} */, a1: $0.a1, a2: $0.a2, a3: {a1: $0.a6, a2: $0.a7.a1.a1}, a4: {a1: $0.a7.a1.a2, a2: $0.a5}};
   }
  }
 }
}

/* Text.ILex.Char.Set.normalise : WithBounds t => Neg t =>
SnocList (RangeOf t) -> Vect n (RangeOf t) -> List (RangeOf t) */
function Text_ILex_Char_Set_normalise($0, $1, $2, $3) {
 return __tailRec(x24tcOpt_14, {h: 1 /* {TcContinue14:1} */, a1: $0, a2: $1, a3: $2, a4: $3});
}

/* Text.ILex.Char.Set.case block in normalise */
function Text_ILex_Char_Set_case__normalise_14085($0, $1, $2, $3, $4, $5, $6) {
 return __tailRec(x24tcOpt_14, {h: 2 /* {TcContinue14:2} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6});
}

/* {$tcOpt:15} */
function x24tcOpt_15($0) {
 switch($0.a6.h) {
  case 0: /* nil */ {
   let $7;
   switch($0.a1.a1.a5($0.a5)($0.a1.a3)) {
    case 1: {
     $7 = {a1: $0.a5, a2: $0.a1.a3};
     break;
    }
    case 0: {
     $7 = {h: 0};
     break;
    }
   }
   const $6 = {a1: $7, a2: {h: 0}};
   const $3 = Prelude_Types_SnocList_x3cx3ex3e($0.a4, $6);
   return {h: 0 /* {TcDone:15} */, a1: $3};
  }
  case undefined: /* cons */ {
   let $14;
   switch($0.a6.a1.h) {
    case 0: /* nil */ {
     $14 = 1;
     break;
    }
    default: $14 = 0;
   }
   switch($14) {
    case 1: return {h: 1 /* {TcContinue15:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a5, a6: $0.a6.a2};
    case 0: {
     const $1c = Text_ILex_Char_Range_lowerBound($0.a1, $0.a6.a1);
     const $20 = Text_ILex_Char_Range_upperBound($0.a1, $0.a6.a1);
     let $24;
     switch($0.a1.a1.a4($1c)($0.a5)) {
      case 1: {
       let $2d;
       switch($0.a1.a1.a5($0.a5)($0.a2.a3($1c)($0.a2.a1.a3(1n)))) {
        case 1: {
         $2d = {a1: $0.a5, a2: $0.a2.a3($1c)($0.a2.a1.a3(1n))};
         break;
        }
        case 0: {
         $2d = {h: 0};
         break;
        }
       }
       $24 = {a1: $0.a4, a2: $2d};
       break;
      }
      case 0: {
       $24 = $0.a4;
       break;
      }
     }
     switch($0.a1.a1.a1.a1($20)($0.a1.a3)) {
      case 1: return {h: 0 /* {TcDone:15} */, a1: Prelude_Types_SnocList_x3cx3ex3e($24, {h: 0})};
      case 0: return {h: 1 /* {TcContinue15:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $24, a5: $0.a2.a1.a1($20)($0.a2.a1.a3(1n)), a6: $0.a6.a2};
     }
    }
   }
  }
 }
}

/* Text.ILex.Char.Set.7601:14384:go */
function Text_ILex_Char_Set_n__7601_14384_go($0, $1, $2, $3, $4, $5) {
 return __tailRec(x24tcOpt_15, {h: 1 /* {TcContinue15:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5});
}

/* {$tcOpt:16} */
function x24tcOpt_16($0) {
 switch($0.a3.h) {
  case undefined: /* cons */ {
   const $3 = $0.a2($0.a3.a1);
   switch($3.h) {
    case undefined: /* just */ return {h: 1 /* {TcContinue16:1} */, a1: {a1: $0.a1, a2: $3.a1}, a2: $0.a2, a3: $0.a3.a2};
    case 0: /* nothing */ return {h: 1 /* {TcContinue16:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2};
   }
  }
  case 0: /* nil */ return {h: 0 /* {TcDone:16} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, {h: 0})};
 }
}

/* Prelude.Types.List.mapMaybeAppend : SnocList b -> (a -> Maybe b) -> List a -> List b */
function Prelude_Types_List_mapMaybeAppend($0, $1, $2) {
 return __tailRec(x24tcOpt_16, {h: 1 /* {TcContinue16:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:17} */
function x24tcOpt_17($0) {
 switch($0.h) {
  case 1: /* {TcContinue17:1} */ {
   const $2 = ($0.a6.value);
   switch($2) {
    case 0: {
     const $7 = ($0.a6.value=1);
     const $c = ($0.a5.value);
     return {h: 2 /* {TcContinue17:2} */, a1: $0.a3, a2: $0.a4, a3: $0.a5, a4: $0.a6, a5: $0.a7, a6: $0.a8, a7: $0.a2, a8: $0.a1, a9: 0, a10: $c, a11: $0.a4($0.a8)($c), a12: $0.a9};
    }
    case 1: return {h: 0 /* {TcDone:17} */, a1: Data_IORef_modifyIORef(csegen_111()(), $0.a7, $28 => Data_Queue_enqueue($28, $0.a8))($0.a9)};
   }
  }
  case 2: /* {TcContinue17:2} */ {
   const $2e = ($0.a3.value=$0.a11.a1);
   const $33 = $0.a11.a2($37 => Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $3d => Web_MVC_n__6231_4025_handle($0.a8, $0.a7, $0.a1, $0.a2, $0.a3, $0.a4, $0.a5, $37, $3d)))($0.a12);
   let $49;
   switch($33.h) {
    case 0: /* Left */ {
     $49 = $0.a1($33.a1)($0.a12);
     break;
    }
    case 1: /* Right */ {
     $49 = undefined;
     break;
    }
   }
   const $4f = ($0.a4.value=0);
   const $54 = Prelude_IO_map_Functor_IO($57 => Data_Queue_dequeue($57), $5b => ($0.a5.value), $0.a12);
   switch($54.h) {
    case undefined: /* just */ {
     const $62 = ($0.a5.value=$54.a1.a2);
     return {h: 1 /* {TcContinue17:1} */, a1: $0.a8, a2: $0.a7, a3: $0.a1, a4: $0.a2, a5: $0.a3, a6: $0.a4, a7: $0.a5, a8: $54.a1.a1, a9: $0.a12};
    }
    case 0: /* nothing */ return {h: 0 /* {TcDone:17} */, a1: undefined};
   }
  }
 }
}

/* Web.MVC.6231:4025:handle */
function Web_MVC_n__6231_4025_handle($0, $1, $2, $3, $4, $5, $6, $7, $8) {
 return __tailRec(x24tcOpt_17, {h: 1 /* {TcContinue17:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8});
}

/* Web.MVC.case block in case block in runController,handle */
function Web_MVC_case__casex20blockx20inx20runControllerx2chandle_4097($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $a, $b) {
 return __tailRec(x24tcOpt_17, {h: 2 /* {TcContinue17:2} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8, a10: $9, a11: $a, a12: $b});
}

/* {$tcOpt:18} */
function x24tcOpt_18($0) {
 switch($0.a1) {
  case '': {
   switch($0.a2.h) {
    case 0: /* Nil */ return {h: 0 /* {TcDone:18} */, a1: ''};
    default: {
     const $6 = ($0.a2.a1+$0.a2.a2);
     switch(Prelude_Types_isSpace($0.a2.a1)) {
      case 1: return {h: 1 /* {TcContinue18:1} */, a1: $0.a2.a2, a2: $0.a2.a3()};
      case 0: return {h: 0 /* {TcDone:18} */, a1: $6};
     }
    }
   }
  }
  default: {
   const $11 = ($0.a2.a1+$0.a2.a2);
   switch(Prelude_Types_isSpace($0.a2.a1)) {
    case 1: return {h: 1 /* {TcContinue18:1} */, a1: $0.a2.a2, a2: $0.a2.a3()};
    case 0: return {h: 0 /* {TcDone:18} */, a1: $11};
   }
  }
 }
}

/* Data.String.with block in ltrim */
function Data_String_with__ltrim_9864($0, $1) {
 return __tailRec(x24tcOpt_18, {h: 1 /* {TcContinue18:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:19} */
function x24tcOpt_19($0) {
 switch($0.h) {
  case 1: /* {TcContinue19:1} */ {
   switch($0.a6) {
    case 0n: {
     const $3 = ($0.a4.value=csegen_536());
     return {h: 0 /* {TcDone:19} */, a1: $0.a2.a6($0.a5)($0.a1)(undefined)};
    }
    default: {
     const $11 = ($0.a6-1n);
     return {h: 2 /* {TcContinue19:2} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $11, a6: $0.a8, a7: $0.a7, a8: $0.a5, a9: Text_ILex_Parser_prim__machineGet($0.a2.a3, $0.a5)};
    }
   }
  }
  case 2: /* {TcContinue19:2} */ {
   const $22 = Data_Array_Core_prim__arrayGet($0.a9.a2, 0n);
   return {h: 3 /* {TcContinue19:3} */, a1: $0.a2, a2: $0.a3, a3: $0.a4, a4: $0.a5, a5: $0.a6, a6: $0.a7, a7: $0.a8, a8: $0.a9.a1, a9: $0.a1, a10: $0.a9.a2, a11: $22, a12: Data_Array_Core_prim__arrayGet($22, BigInt(Data_Buffer_Core_prim__getByte($0.a3, $0.a7)))};
  }
  case 3: /* {TcContinue19:3} */ {
   switch($0.a12.h) {
    case 1: /* Done */ {
     const $3a = $0.a12.a1($0.a9);
     return {h: 1 /* {TcContinue19:1} */, a1: $0.a9, a2: $0.a1, a3: $0.a2, a4: $0.a3, a5: $3a, a6: $0.a4, a7: ($0.a6+1n), a8: undefined};
    }
    case 3: /* Move */ return {h: 6 /* {TcContinue19:6} */, a1: $0.a9, a2: $0.a1, a3: $0.a2, a4: $0.a3, a5: $0.a7, a6: $0.a10, a7: Data_Array_Core_prim__arrayGet($0.a10, $0.a12.a1), a8: $0.a12.a2, a9: $0.a6, a10: $0.a4, a11: ($0.a6+1n), a12: $0.a5};
    case 4: /* MoveE */ return {h: 4 /* {TcContinue19:4} */, a1: $0.a9, a2: $0.a1, a3: $0.a2, a4: $0.a3, a5: $0.a7, a6: $0.a10, a7: Data_Array_Core_prim__arrayGet($0.a10, $0.a12.a1), a8: $0.a6, a9: $0.a4, a10: ($0.a6+1n), a11: $0.a5};
    case 2: /* DoneBS */ {
     const $69 = {a1: $0.a2, a2: 0n};
     const $6c = {a1: Prelude_Types_prim__integerToNat((($0.a6+1n)-$0.a6)), a2: Data_ByteVect_substringFromTill($0.a6, ($0.a6+1n), $69)};
     const $68 = ($0.a3.value=$6c);
     const $7f = $0.a12.a1($0.a9);
     return {h: 1 /* {TcContinue19:1} */, a1: $0.a9, a2: $0.a1, a3: $0.a2, a4: $0.a3, a5: $7f, a6: $0.a4, a7: ($0.a6+1n), a8: undefined};
    }
    default: {
     const $8d = {a1: $0.a2, a2: 0n};
     const $90 = {a1: Prelude_Types_prim__integerToNat((($0.a6+1n)-$0.a6)), a2: Data_ByteVect_substringFromTill($0.a6, ($0.a6+1n), $8d)};
     const $8c = ($0.a3.value=$90);
     return {h: 0 /* {TcDone:19} */, a1: Text_ILex_Parser_arrFail($0.a1.a5, $0.a7, $0.a9, undefined)};
    }
   }
  }
  case 4: /* {TcContinue19:4} */ {
   switch($0.a9) {
    case 0n: {
     const $ac = {a1: $0.a3, a2: 0n};
     const $af = {a1: Prelude_Types_prim__integerToNat(($0.a10-$0.a8)), a2: Data_ByteVect_substringFromTill($0.a8, $0.a10, $ac)};
     const $ab = ($0.a4.value=$af);
     return {h: 0 /* {TcDone:19} */, a1: Text_ILex_Parser_arrFail($0.a2.a5, $0.a5, $0.a1, undefined)};
    }
    default: {
     const $c5 = ($0.a9-1n);
     const $c8 = Data_Buffer_Core_prim__getByte($0.a3, $0.a10);
     return {h: 5 /* {TcContinue19:5} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $c5, a6: $0.a11, a7: $0.a10, a8: $0.a8, a9: $0.a7, a10: $0.a6, a11: $0.a5, a12: $c8, a13: Data_Array_Core_prim__arrayGet($0.a7, BigInt($c8))};
    }
   }
  }
  case 5: /* {TcContinue19:5} */ {
   switch($0.a13.h) {
    case 0: /* Keep */ return {h: 4 /* {TcContinue19:4} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a11, a6: $0.a10, a7: $0.a9, a8: $0.a8, a9: $0.a5, a10: ($0.a7+1n), a11: $0.a6};
    case 1: /* Done */ {
     const $eb = $0.a13.a1($0.a1);
     return {h: 1 /* {TcContinue19:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $eb, a6: $0.a5, a7: ($0.a7+1n), a8: undefined};
    }
    case 3: /* Move */ return {h: 6 /* {TcContinue19:6} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a11, a6: $0.a10, a7: Data_Array_Core_prim__arrayGet($0.a10, $0.a13.a1), a8: $0.a13.a2, a9: $0.a8, a10: $0.a5, a11: ($0.a7+1n), a12: $0.a6};
    case 4: /* MoveE */ return {h: 4 /* {TcContinue19:4} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a11, a6: $0.a10, a7: Data_Array_Core_prim__arrayGet($0.a10, $0.a13.a1), a8: $0.a8, a9: $0.a5, a10: ($0.a7+1n), a11: $0.a6};
    case 2: /* DoneBS */ {
     const $11a = {a1: $0.a3, a2: 0n};
     const $11d = {a1: Prelude_Types_prim__integerToNat((($0.a7+1n)-$0.a8)), a2: Data_ByteVect_substringFromTill($0.a8, ($0.a7+1n), $11a)};
     const $119 = ($0.a4.value=$11d);
     const $130 = $0.a13.a1($0.a1);
     return {h: 1 /* {TcContinue19:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $130, a6: $0.a5, a7: ($0.a7+1n), a8: undefined};
    }
    case 5: /* Bottom */ {
     const $13e = {a1: $0.a3, a2: 0n};
     const $141 = {a1: Prelude_Types_prim__integerToNat((($0.a7+1n)-$0.a8)), a2: Data_ByteVect_substringFromTill($0.a8, ($0.a7+1n), $13e)};
     const $13d = ($0.a4.value=$141);
     return {h: 0 /* {TcDone:19} */, a1: Text_ILex_Parser_arrFail($0.a2.a5, $0.a11, $0.a1, undefined)};
    }
   }
  }
  case 6: /* {TcContinue19:6} */ {
   switch($0.a10) {
    case 0n: {
     const $15d = {a1: $0.a3, a2: 0n};
     const $160 = {a1: Prelude_Types_prim__integerToNat(($0.a11-$0.a9)), a2: Data_ByteVect_substringFromTill($0.a9, $0.a11, $15d)};
     const $15c = ($0.a4.value=$160);
     return {h: 0 /* {TcDone:19} */, a1: Text_ILex_Parser_lastStep($0.a2, $0.a8, $0.a5, $0.a1, undefined)};
    }
    default: {
     const $176 = ($0.a10-1n);
     const $179 = Data_Buffer_Core_prim__getByte($0.a3, $0.a11);
     return {h: 7 /* {TcContinue19:7} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $176, a6: $0.a12, a7: $0.a11, a8: $0.a9, a9: $0.a8, a10: $0.a7, a11: $0.a6, a12: $0.a5, a13: $179, a14: Data_Array_Core_prim__arrayGet($0.a7, BigInt($179))};
    }
   }
  }
  case 7: /* {TcContinue19:7} */ {
   switch($0.a14.h) {
    case 0: /* Keep */ return {h: 6 /* {TcContinue19:6} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a12, a6: $0.a11, a7: $0.a10, a8: $0.a9, a9: $0.a8, a10: $0.a5, a11: ($0.a7+1n), a12: $0.a6};
    case 1: /* Done */ {
     const $19e = $0.a14.a1($0.a1);
     return {h: 1 /* {TcContinue19:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $19e, a6: $0.a5, a7: ($0.a7+1n), a8: undefined};
    }
    case 3: /* Move */ return {h: 6 /* {TcContinue19:6} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a12, a6: $0.a11, a7: Data_Array_Core_prim__arrayGet($0.a11, $0.a14.a1), a8: $0.a14.a2, a9: $0.a8, a10: $0.a5, a11: ($0.a7+1n), a12: $0.a6};
    case 4: /* MoveE */ return {h: 4 /* {TcContinue19:4} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a12, a6: $0.a11, a7: Data_Array_Core_prim__arrayGet($0.a11, $0.a14.a1), a8: $0.a8, a9: $0.a5, a10: ($0.a7+1n), a11: $0.a6};
    case 2: /* DoneBS */ {
     const $1cd = {a1: $0.a3, a2: 0n};
     const $1d0 = {a1: Prelude_Types_prim__integerToNat((($0.a7+1n)-$0.a8)), a2: Data_ByteVect_substringFromTill($0.a8, ($0.a7+1n), $1cd)};
     const $1cc = ($0.a4.value=$1d0);
     const $1e3 = $0.a14.a1($0.a1);
     return {h: 1 /* {TcContinue19:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $1e3, a6: $0.a5, a7: ($0.a7+1n), a8: undefined};
    }
    case 5: /* Bottom */ {
     const $1f1 = {a1: $0.a3, a2: 0n};
     const $1f4 = {a1: Prelude_Types_prim__integerToNat(($0.a7-$0.a8)), a2: Data_ByteVect_substringFromTill($0.a8, $0.a7, $1f1)};
     const $1f0 = ($0.a4.value=$1f4);
     const $203 = $0.a9($0.a1);
     return {h: 1 /* {TcContinue19:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $203, a6: ($0.a5+1n), a7: $0.a7, a8: undefined};
    }
   }
  }
 }
}

/* Text.ILex.Runner.loop : s q -> P1 q e r s a -> IBuffer n -> Ref q ByteString -> Index r -> (pos : Nat) ->
Ix pos n => F1 q (Either e a) */
function Text_ILex_Runner_loop($0, $1, $2, $3, $4, $5, $6, $7) {
 return __tailRec(x24tcOpt_19, {h: 1 /* {TcContinue19:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7});
}

/* Text.ILex.Runner.case block in loop */
function Text_ILex_Runner_case__loop_7379($0, $1, $2, $3, $4, $5, $6, $7, $8) {
 return __tailRec(x24tcOpt_19, {h: 2 /* {TcContinue19:2} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8});
}

/* Text.ILex.Runner.case block in case block in loop */
function Text_ILex_Runner_case__casex20blockx20inx20loop_7435($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $a, $b) {
 return __tailRec(x24tcOpt_19, {h: 3 /* {TcContinue19:3} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8, a10: $9, a11: $a, a12: $b});
}

/* Text.ILex.Runner.step : s q -> P1 q e r s a -> IBuffer n -> Ref q ByteString -> Index r -> Stepper k q r s -> ByteStep k q r s -> (from : Ix m n) ->
(pos : Nat) -> {auto x : Ix pos n} ->
{auto 0 _ : LTE (ixToNat from) (ixToNat x)} -> F1 q (Either e a) */
function Text_ILex_Runner_step($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $a) {
 return __tailRec(x24tcOpt_19, {h: 4 /* {TcContinue19:4} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8, a10: $9, a11: $a});
}

/* Text.ILex.Runner.case block in step */
function Text_ILex_Runner_case__step_8834($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $a, $b, $c) {
 return __tailRec(x24tcOpt_19, {h: 5 /* {TcContinue19:5} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8, a10: $9, a11: $a, a12: $b, a13: $c});
}

/* Text.ILex.Runner.succ : s q -> P1 q e r s a -> IBuffer n -> Ref q ByteString -> Index r -> Stepper k q r s -> ByteStep k q r s -> Step1 q r s -> (from : Ix m n) ->
(pos : Nat) -> {auto x : Ix pos n} ->
{auto 0 _ : LTE (ixToNat from) (ixToNat x)} -> F1 q (Either e a) */
function Text_ILex_Runner_succ($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $a, $b) {
 return __tailRec(x24tcOpt_19, {h: 6 /* {TcContinue19:6} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8, a10: $9, a11: $a, a12: $b});
}

/* Text.ILex.Runner.case block in succ */
function Text_ILex_Runner_case__succ_8029($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $a, $b, $c, $d) {
 return __tailRec(x24tcOpt_19, {h: 7 /* {TcContinue19:7} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8, a10: $9, a11: $a, a12: $b, a13: $c, a14: $d});
}

/* {$tcOpt:20} */
function x24tcOpt_20($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:20} */, a1: {h: 0}};
  case undefined: /* cons */ {
   switch($0.a1($0.a2)($0.a3.a1.a1)) {
    case 1: return {h: 0 /* {TcDone:20} */, a1: {a1: $0.a3.a1.a2}};
    case 0: return {h: 1 /* {TcContinue20:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a2};
   }
  }
 }
}

/* Data.List.lookupBy : (a -> b -> Bool) -> a -> List (b, v) -> Maybe v */
function Data_List_lookupBy($0, $1, $2) {
 return __tailRec(x24tcOpt_20, {h: 1 /* {TcContinue20:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:21} */
function x24tcOpt_21($0) {
 switch($0.a3.h) {
  case 0: /* Leaf */ {
   switch($0.a1.a1.a1($0.a2)($0.a3.a1)) {
    case 1: return {h: 0 /* {TcDone:21} */, a1: {a1: {a1: $0.a3.a1, a2: $0.a3.a2}}};
    case 0: return {h: 0 /* {TcDone:21} */, a1: {h: 0}};
   }
  }
  case 1: /* Branch2 */ {
   switch($0.a1.a5($0.a2)($0.a3.a2)) {
    case 1: return {h: 1 /* {TcContinue21:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a1};
    case 0: return {h: 1 /* {TcContinue21:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a3};
   }
  }
  case 2: /* Branch3 */ {
   switch($0.a1.a5($0.a2)($0.a3.a2)) {
    case 1: return {h: 1 /* {TcContinue21:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a1};
    case 0: {
     switch($0.a1.a5($0.a2)($0.a3.a4)) {
      case 1: return {h: 1 /* {TcContinue21:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a3};
      case 0: return {h: 1 /* {TcContinue21:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3.a5};
     }
    }
   }
  }
 }
}

/* Data.SortedMap.Dependent.treeLookup : Ord k => k -> Tree n k v o -> Maybe (y : k ** v y) */
function Data_SortedMap_Dependent_treeLookup($0, $1, $2) {
 return __tailRec(x24tcOpt_21, {h: 1 /* {TcContinue21:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:22} */
function x24tcOpt_22($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:22} */, a1: Prelude_Types_List_reverse($0.a2)};
  case undefined: /* cons */ return {h: 1 /* {TcContinue22:1} */, a1: $0.a1, a2: Prelude_Types_List_reverseOnto($0.a2, $0.a1($0.a3.a1)), a3: $0.a3.a2};
 }
}

/* Prelude.Types.listBindOnto : (a -> List b) -> List b -> List a -> List b */
function Prelude_Types_listBindOnto($0, $1, $2) {
 return __tailRec(x24tcOpt_22, {h: 1 /* {TcContinue22:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:23} */
function x24tcOpt_23($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:23} */, a1: $0.a1};
  case undefined: /* cons */ return {h: 1 /* {TcContinue23:1} */, a1: {a1: $0.a2.a1, a2: $0.a1}, a2: $0.a2.a2};
 }
}

/* Prelude.Types.List.reverseOnto : List a -> List a -> List a */
function Prelude_Types_List_reverseOnto($0, $1) {
 return __tailRec(x24tcOpt_23, {h: 1 /* {TcContinue23:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:24} */
function x24tcOpt_24($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:24} */, a1: $0.a1};
  case undefined: /* cons */ return {h: 1 /* {TcContinue24:1} */, a1: ($0.a1+1n), a2: $0.a2.a2};
 }
}

/* Prelude.Types.List.lengthPlus : Nat -> List a -> Nat */
function Prelude_Types_List_lengthPlus($0, $1) {
 return __tailRec(x24tcOpt_24, {h: 1 /* {TcContinue24:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:25} */
function x24tcOpt_25($0) {
 switch($0.h) {
  case 1: /* {TcContinue25:1} */ {
   switch($0.a7) {
    case 0n: return {h: 0 /* {TcDone:25} */, a1: {a1: $0.a5, a2: $0.a6}};
    default: {
     const $6 = ($0.a7-1n);
     return {h: 2 /* {TcContinue25:2} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $6, a6: $0.a8, a7: $0.a6, a8: $0.a5, a9: Data_Buffer_Core_prim__getByteOffset($0.a2.a1, $0.a8, $0.a2.a2)};
    }
   }
  }
  case 2: /* {TcContinue25:2} */ {
   switch($0.a9) {
    case 10: return {h: 1 /* {TcContinue25:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: ($0.a8+1n), a6: 0n, a7: $0.a5, a8: ($0.a6+1n)};
    default: {
     let $24;
     switch(Prelude_EqOrd_x3c_Ord_Bits8($0.a9, 128)) {
      case 1: {
       $24 = 1;
       break;
      }
      case 0: {
       $24 = Prelude_EqOrd_x3dx3d_Eq_Bits8(($0.a9&192), 96);
       break;
      }
     }
     switch($24) {
      case 1: return {h: 1 /* {TcContinue25:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a8, a6: ($0.a7+1n), a7: $0.a5, a8: ($0.a6+1n)};
      default: return {h: 1 /* {TcContinue25:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a8, a6: $0.a7, a7: $0.a5, a8: ($0.a6+1n)};
     }
    }
   }
  }
 }
}

/* Text.Bounds.9325:12498:go */
function Text_Bounds_n__9325_12498_go($0, $1, $2, $3, $4, $5, $6, $7) {
 return __tailRec(x24tcOpt_25, {h: 1 /* {TcContinue25:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7});
}

/* Text.Bounds.case block in incBytes,go */
function Text_Bounds_case__incBytesx2cgo_12524($0, $1, $2, $3, $4, $5, $6, $7, $8) {
 return __tailRec(x24tcOpt_25, {h: 2 /* {TcContinue25:2} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6, a8: $7, a9: $8});
}

/* {$tcOpt:26} */
function x24tcOpt_26($0) {
 switch($0.a1) {
  case 0n: {
   switch($0.a2.h) {
    case undefined: /* cons */ return {h: 0 /* {TcDone:26} */, a1: {a1: $0.a2.a1}};
    default: return {h: 0 /* {TcDone:26} */, a1: {h: 0}};
   }
  }
  default: {
   const $8 = ($0.a1-1n);
   switch($0.a2.h) {
    case undefined: /* cons */ return {h: 1 /* {TcContinue26:1} */, a1: $8, a2: $0.a2.a2};
    default: return {h: 0 /* {TcDone:26} */, a1: {h: 0}};
   }
  }
 }
}

/* Prelude.Types.getAt : Nat -> List a -> Maybe a */
function Prelude_Types_getAt($0, $1) {
 return __tailRec(x24tcOpt_26, {h: 1 /* {TcContinue26:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:27} */
function x24tcOpt_27($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:27} */, a1: $0.a1};
  case undefined: /* cons */ return {h: 1 /* {TcContinue27:1} */, a1: {a1: $0.a2.a1, a2: $0.a1}, a2: $0.a2.a2};
 }
}

/* Data.Vect.fromList' : Vect len elem -> (l : List elem) -> Vect (length l + len) elem */
function Data_Vect_fromListx27($0, $1) {
 return __tailRec(x24tcOpt_27, {h: 1 /* {TcContinue27:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:28} */
function x24tcOpt_28($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:28} */, a1: $0.a1};
  case undefined: /* cons */ return {h: 1 /* {TcContinue28:1} */, a1: {a1: $0.a2.a1, a2: $0.a1}, a2: $0.a2.a2};
 }
}

/* Data.Vect.reverseOnto : Vect n elem -> Vect m elem -> Vect (n + m) elem */
function Data_Vect_reverseOnto($0, $1) {
 return __tailRec(x24tcOpt_28, {h: 1 /* {TcContinue28:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:29} */
function x24tcOpt_29($0) {
 switch($0.a2.h) {
  case 0: /* Eps */ return {h: 0 /* {TcDone:29} */, a1: $0.a3};
  case 2: /* And */ {
   const $4 = Text_ILex_Internal_ENFA_enfa($0.a1, $0.a2.a2, $0.a3, $0.a4);
   return {h: 1 /* {TcContinue29:1} */, a1: $0.a1, a2: $0.a2.a1, a3: $4, a4: undefined};
  }
  case 1: /* Ch */ {
   const $e = Text_ILex_Internal_Types_inc($0.a1, $0.a4);
   const $12 = Text_ILex_Internal_Types_insert1($e, {a1: {h: 0}, a2: {h: 0}, a3: Prelude_Types_List_mapAppend({h: 0}, $1c => ({a1: $1c, a2: $0.a3}), $0.a2.a1)}, $0.a1.a3, undefined);
   return {h: 0 /* {TcDone:29} */, a1: $e};
  }
  case 3: /* Or */ {
   const $24 = Text_ILex_Internal_ENFA_enfa($0.a1, $0.a2.a1, $0.a3, $0.a4);
   const $2a = Text_ILex_Internal_ENFA_enfa($0.a1, $0.a2.a2, $0.a3, undefined);
   const $30 = Text_ILex_Internal_Types_inc($0.a1, undefined);
   const $34 = Text_ILex_Internal_Types_insert1($30, {a1: {h: 0}, a2: {a1: $24, a2: {a1: $2a, a2: {h: 0}}}, a3: {h: 0}}, $0.a1.a3, undefined);
   return {h: 0 /* {TcDone:29} */, a1: $30};
  }
  case 4: /* Star */ {
   const $43 = Text_ILex_Internal_Types_inc($0.a1, $0.a4);
   const $47 = Text_ILex_Internal_ENFA_enfa($0.a1, $0.a2.a1, $43, undefined);
   const $4d = Text_ILex_Internal_Types_insert1($43, {a1: {h: 0}, a2: {a1: $47, a2: {a1: $0.a3, a2: {h: 0}}}, a3: {h: 0}}, $0.a1.a3, undefined);
   return {h: 0 /* {TcDone:29} */, a1: $43};
  }
 }
}

/* Text.ILex.Internal.ENFA.enfa : DFAState s a => RExp8 b -> Nat -> F1 s Nat */
function Text_ILex_Internal_ENFA_enfa($0, $1, $2, $3) {
 return __tailRec(x24tcOpt_29, {h: 1 /* {TcContinue29:1} */, a1: $0, a2: $1, a3: $2, a4: $3});
}

/* {$tcOpt:30} */
function x24tcOpt_30($0) {
 switch($0.a3.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:30} */, a1: $0.a2};
  case undefined: /* cons */ return {h: 1 /* {TcContinue30:1} */, a1: $0.a1, a2: $0.a1($0.a2)($0.a3.a1), a3: $0.a3.a2};
 }
}

/* Prelude.Types.foldl */
function Prelude_Types_foldl_Foldable_List($0, $1, $2) {
 return __tailRec(x24tcOpt_30, {h: 1 /* {TcContinue30:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:31} */
function x24tcOpt_31($0) {
 switch($0.h) {
  case 1: /* {TcContinue31:1} */ return {h: 2 /* {TcContinue31:2} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $0.a4, a5: $0.a6, a6: $0.a5, a7: Data_Array_Index_tryNatToFin($0.a4, $0.a3)};
  case 2: /* {TcContinue31:2} */ {
   switch($0.a7.h) {
    case undefined: /* just */ {
     const $d = Data_Array_Core_prim__arraySet($0.a6, $0.a7.a1, {a1: $0.a1}, $0.a5);
     return {h: 0 /* {TcDone:31} */, a1: ($0.a2.value={a1: $0.a4, a2: $0.a6})};
    }
    case 0: /* nothing */ {
     const $1b = Data_Array_Mutable_mgrow($0.a4, $0.a6, $0.a4, {h: 0}, $0.a5);
     return {h: 1 /* {TcContinue31:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: ($0.a4+$0.a4), a5: $1b, a6: undefined};
    }
   }
  }
 }
}

/* Text.ILex.Internal.Types.9368:9393:go */
function Text_ILex_Internal_Types_n__9368_9393_go($0, $1, $2, $3, $4, $5) {
 return __tailRec(x24tcOpt_31, {h: 1 /* {TcContinue31:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5});
}

/* Text.ILex.Internal.Types.case block in insert1,go */
function Text_ILex_Internal_Types_case__insert1x2cgo_9410($0, $1, $2, $3, $4, $5, $6) {
 return __tailRec(x24tcOpt_31, {h: 2 /* {TcContinue31:2} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4, a6: $5, a7: $6});
}

/* {$tcOpt:32} */
function x24tcOpt_32($0) {
 switch($0.a4.h) {
  case undefined: /* cons */ {
   switch($0.a5.h) {
    case undefined: /* cons */ {
     const $4 = Text_ILex_Char_Set_appendNonEmpty($0.a1, $0.a2, $0.a3, Text_ILex_Char_Range_intersection($0.a1.a1, $0.a4.a1, $0.a5.a1));
     const $f = {a1: $0.a4.a1, a2: $0.a4.a2};
     const $12 = {a1: $0.a5.a1, a2: $0.a5.a2};
     switch($0.a1.a1.a3(Text_ILex_Char_Range_upperBound($0.a1, $0.a4.a1))(Text_ILex_Char_Range_upperBound($0.a1, $0.a5.a1))) {
      case 1: return {h: 1 /* {TcContinue32:1} */, a1: $0.a1, a2: $0.a2, a3: $4, a4: $0.a4.a2, a5: $12};
      case 0: return {h: 1 /* {TcContinue32:1} */, a1: $0.a1, a2: $0.a2, a3: $4, a4: $f, a5: $0.a5.a2};
     }
    }
    default: return {h: 0 /* {TcDone:32} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a3, {h: 0})};
   }
  }
  default: return {h: 0 /* {TcDone:32} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a3, {h: 0})};
 }
}

/* Text.ILex.Char.Set.inters : WithBounds t => Neg t =>
SnocList (RangeOf t) -> List (RangeOf t) -> List (RangeOf t) -> List (RangeOf t) */
function Text_ILex_Char_Set_inters($0, $1, $2, $3, $4) {
 return __tailRec(x24tcOpt_32, {h: 1 /* {TcContinue32:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4});
}

/* {$tcOpt:33} */
function x24tcOpt_33($0) {
 switch($0.a3) {
  case 0n: return {h: 0 /* {TcDone:33} */, a1: $0.a2};
  default: {
   const $4 = ($0.a3-1n);
   return {h: 1 /* {TcContinue33:1} */, a1: $0.a1, a2: (($0.a2*10n)+(BigInt(Data_Buffer_Core_prim__getByteOffset($0.a1.a1, $0.a4, $0.a1.a2))-48n)), a3: $4, a4: ($0.a4+1n)};
  }
 }
}

/* Text.ILex.Util.decimalBV : ByteVect n -> Integer -> (k : Nat) -> Ix k n => Integer */
function Text_ILex_Util_decimalBV($0, $1, $2, $3) {
 return __tailRec(x24tcOpt_33, {h: 1 /* {TcContinue33:1} */, a1: $0, a2: $1, a3: $2, a4: $3});
}

/* {$tcOpt:34} */
function x24tcOpt_34($0) {
 switch($0.a2.h) {
  case 0: /* Here */ return {h: 0 /* {TcDone:34} */, a1: $0.a1(undefined)($0.a2.a1)};
  case 1: /* There */ return {h: 1 /* {TcContinue34:1} */, a1: $9 => $0.a1(undefined), a2: $0.a2.a1};
 }
}

/* Data.List.Quantifiers.Extra.Any.collapse : (f v -> x) -> Any f ks -> x */
function Data_List_Quantifiers_Extra_Any_collapse($0, $1) {
 return __tailRec(x24tcOpt_34, {h: 1 /* {TcContinue34:1} */, a1: $0, a2: $1});
}

/* {$tcOpt:35} */
function x24tcOpt_35($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:35} */, a1: undefined};
  case undefined: /* cons */ {
   const $4 = $0.a1($0.a2.a1)($0.a3);
   return {h: 1 /* {TcContinue35:1} */, a1: $0.a1, a2: $0.a2.a2, a3: undefined};
  }
 }
}

/* Data.Linear.Traverse1.traverse1_List : (a -> F1' s) -> List a -> F1' s */
function Data_Linear_Traverse1_traverse1_List($0, $1, $2) {
 return __tailRec(x24tcOpt_35, {h: 1 /* {TcContinue35:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:36} */
function x24tcOpt_36($0) {
 switch($0.a3.h) {
  case undefined: /* cons */ return {h: 1 /* {TcContinue36:1} */, a1: {a1: $0.a1, a2: $0.a2($0.a3.a1)}, a2: $0.a2, a3: $0.a3.a2};
  case 0: /* nil */ return {h: 0 /* {TcDone:36} */, a1: Prelude_Types_SnocList_x3cx3ex3e($0.a1, {h: 0})};
 }
}

/* Prelude.Types.List.mapAppend : SnocList b -> (a -> b) -> List a -> List b */
function Prelude_Types_List_mapAppend($0, $1, $2) {
 return __tailRec(x24tcOpt_36, {h: 1 /* {TcContinue36:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:37} */
function x24tcOpt_37($0) {
 switch($0.a4) {
  case 0n: return {h: 0 /* {TcDone:37} */, a1: 0};
  default: {
   const $4 = ($0.a4-1n);
   switch($0.a3(Data_Buffer_Core_prim__getByteOffset($0.a2.a1, $0.a5, $0.a2.a2))) {
    case 1: return {h: 0 /* {TcDone:37} */, a1: 1};
    case 0: return {h: 1 /* {TcContinue37:1} */, a1: $0.a1, a2: $0.a2, a3: $0.a3, a4: $4, a5: ($0.a5+1n)};
   }
  }
 }
}

/* Data.ByteVect.6150:2653:go */
function Data_ByteVect_n__6150_2653_go($0, $1, $2, $3, $4) {
 return __tailRec(x24tcOpt_37, {h: 1 /* {TcContinue37:1} */, a1: $0, a2: $1, a3: $2, a4: $3, a5: $4});
}

/* {$tcOpt:38} */
function x24tcOpt_38($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:38} */, a1: {h: 1 /* Right */, a1: undefined}};
  case undefined: /* cons */ {
   const $5 = $0.a1($0.a2.a1)($0.a3);
   switch($5.h) {
    case 1: /* Right */ return {h: 1 /* {TcContinue38:1} */, a1: $0.a1, a2: $0.a2.a2, a3: undefined};
    case 0: /* Left */ return {h: 0 /* {TcDone:38} */, a1: {h: 0 /* Left */, a1: $5.a1}};
   }
  }
 }
}

/* Control.Monad.Either.Extra.implList_ : (t -> EitherT e IO ()) -> List t -> PrimIO (Either e ()) */
function Control_Monad_Either_Extra_implList_($0, $1, $2) {
 return __tailRec(x24tcOpt_38, {h: 1 /* {TcContinue38:1} */, a1: $0, a2: $1, a3: $2});
}

/* {$tcOpt:39} */
function x24tcOpt_39($0) {
 switch($0.a1.h) {
  case 0: /* nil */ return {h: 0 /* {TcDone:39} */, a1: $0.a2};
  case undefined: /* cons */ return {h: 1 /* {TcContinue39:1} */, a1: $0.a1.a1, a2: {a1: $0.a1.a2, a2: $0.a2}};
 }
}

/* Prelude.Types.SnocList.(<>>) : SnocList a -> List a -> List a */
function Prelude_Types_SnocList_x3cx3ex3e($0, $1) {
 return __tailRec(x24tcOpt_39, {h: 1 /* {TcContinue39:1} */, a1: $0, a2: $1});
}

/* {__mainExpression:0} */
function __mainExpression_0() {
 return PrimIO_unsafePerformIO($2 => FrontendMain_main($2));
}

/* {csegen:0} */
const csegen_0 = __lazy(function () {
 return {a1: $1 => FrontendMain_requestResync($1), a2: {h: 0}};
});

/* {csegen:12} */
const csegen_12 = __lazy(function () {
 return {a1: {h: 1 /* Str */, a1: 'style', a2: 'display:flex; gap:10px; flex-wrap:wrap; margin:18px 0;'}, a2: {h: 0}};
});

/* {csegen:32} */
const csegen_32 = __lazy(function () {
 return () => b => a => func => $0 => $1 => Prelude_IO_map_Functor_IO(func, $0, $1);
});

/* {csegen:36} */
const csegen_36 = __lazy(function () {
 return () => {
  const $6 = b => a => $7 => $8 => $9 => {
   const $a = $7($9);
   const $d = $8($9);
   return $a($d);
  };
  return {a1: csegen_32()(), a2: a => $4 => $5 => $4, a3: $6};
 };
});

/* {csegen:37} */
const csegen_37 = __lazy(function () {
 return () => Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), undefined);
});

/* {csegen:45} */
const csegen_45 = __lazy(function () {
 return () => {
  const $3 = b => a => $4 => $5 => $6 => {
   const $7 = $4($6);
   return $5($7)($6);
  };
  const $e = a => $f => $10 => {
   const $11 = $f($10);
   return $11($10);
  };
  return {a1: csegen_36()(), a2: $3, a3: $e};
 };
});

/* {csegen:56} */
const csegen_56 = __lazy(function () {
 return () => ({a1: b => a => func => $1 => Control_Monad_Error_Either_map_Functor_x28x28EitherTx20x24ex29x20x24mx29(csegen_32()(), func, $1), a2: a => $9 => Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $9), a3: b => a => $10 => $11 => Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $10, $11)});
});

/* {csegen:74} */
const csegen_74 = __lazy(function () {
 return $0 => $1 => ({a1: $0, a2: $1});
});

/* {csegen:111} */
const csegen_111 = __lazy(function () {
 return () => ({a1: csegen_45()(), a2: a => $4 => $4});
});

/* {csegen:114} */
const csegen_114 = __lazy(function () {
 return {a1: $1 => $2 => ($1+$2), a2: ''};
});

/* {csegen:115} */
const csegen_115 = __lazy(function () {
 return $0 => $1 => {
  switch($0.h) {
   case 0: /* Left */ return {h: 0 /* Left */, a1: $0.a1};
   case 1: /* Right */ {
    switch($1.h) {
     case 1: /* Right */ return {h: 1 /* Right */, a1: $0.a1($1.a1)};
     case 0: /* Left */ return {h: 0 /* Left */, a1: $1.a1};
    }
   }
  }
 };
});

/* {csegen:119} */
const csegen_119 = __lazy(function () {
 return {a1: $1 => $1, a2: {a1: $4 => $4, a2: {h: 0}}};
});

/* {csegen:155} */
const csegen_155 = __lazy(function () {
 return {a1: {a1: $2 => $3 => Prelude_EqOrd_x3dx3d_Eq_Bits32($2, $3), a2: $8 => $9 => Prelude_EqOrd_x2fx3d_Eq_Bits32($8, $9)}, a2: $e => $f => Prelude_EqOrd_compare_Ord_Bits32($e, $f), a3: $14 => $15 => Prelude_EqOrd_x3c_Ord_Bits32($14, $15), a4: $1a => $1b => Prelude_EqOrd_x3e_Ord_Bits32($1a, $1b), a5: $20 => $21 => Prelude_EqOrd_x3cx3d_Ord_Bits32($20, $21), a6: $26 => $27 => Prelude_EqOrd_x3ex3d_Ord_Bits32($26, $27), a7: $2c => $2d => Prelude_EqOrd_max_Ord_Bits32($2c, $2d), a8: $32 => $33 => Prelude_EqOrd_min_Ord_Bits32($32, $33)};
});

/* {csegen:156} */
const csegen_156 = __lazy(function () {
 return {a1: csegen_155(), a2: 0, a3: 4294967295};
});

/* {csegen:159} */
const csegen_159 = __lazy(function () {
 return {a1: $1 => $2 => _add32u($1, $2), a2: $6 => $7 => _mul32u($6, $7), a3: $b => Number(_truncUBigInt32($b))};
});

/* {csegen:161} */
const csegen_161 = __lazy(function () {
 return {a1: csegen_159(), a2: $3 => _sub32u(0, $3), a3: $7 => $8 => _sub32u($7, $8)};
});

/* {csegen:166} */
const csegen_166 = __lazy(function () {
 return Text_ILex_RExp_oneof(csegen_156(), csegen_161(), {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32(' '.codePointAt(0)))}, a2: {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('\u{9}'.codePointAt(0)))}, a2: {h: 0}}});
});

/* {csegen:168} */
const csegen_168 = __lazy(function () {
 return {h: 2 /* And */, a1: csegen_166(), a2: {h: 4 /* Star */, a1: csegen_166()}};
});

/* {csegen:175} */
const csegen_175 = __lazy(function () {
 return {a1: $1 => $2 => $2.a1, a2: $5 => $6 => $6.a2, a3: $9 => $a => $a.a3};
});

/* {csegen:177} */
const csegen_177 = __lazy(function () {
 return $0 => $1 => $1.a8;
});

/* {csegen:181} */
const csegen_181 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('\n'.codePointAt(0)))};
});

/* {csegen:182} */
const csegen_182 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('\r'.codePointAt(0)))};
});

/* {csegen:185} */
const csegen_185 = __lazy(function () {
 return Text_ILex_RExp_x3cx7cx3e(csegen_156(), csegen_161(), csegen_181(), Text_ILex_RExp_x3cx7cx3e(csegen_156(), csegen_161(), csegen_182(), {h: 2 /* And */, a1: csegen_182(), a2: csegen_181()}));
});

/* {csegen:191} */
const csegen_191 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('n'.codePointAt(0)))};
});

/* {csegen:192} */
const csegen_192 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('u'.codePointAt(0)))};
});

/* {csegen:193} */
const csegen_193 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('l'.codePointAt(0)))};
});

/* {csegen:200} */
const csegen_200 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('t'.codePointAt(0)))};
});

/* {csegen:201} */
const csegen_201 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('r'.codePointAt(0)))};
});

/* {csegen:202} */
const csegen_202 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('e'.codePointAt(0)))};
});

/* {csegen:209} */
const csegen_209 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('f'.codePointAt(0)))};
});

/* {csegen:219} */
const csegen_219 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('-'.codePointAt(0)))};
});

/* {csegen:221} */
const csegen_221 = __lazy(function () {
 return {h: 2 /* And */, a1: {h: 3 /* Or */, a1: csegen_219(), a2: {h: 0 /* Eps */}}, a2: Text_ILex_RExp_decimal()};
});

/* {csegen:236} */
const csegen_236 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('\"'.codePointAt(0)))};
});

/* {csegen:240} */
const csegen_240 = __lazy(function () {
 const $4 = $5 => {
  const $9 = ($5.a1.value);
  const $e = ($5.a2.value);
  const $8 = {a1: $9, a2: $e};
  const $15 = ($5.a3.value);
  const $7 = ($5.a3.value={a1: $15, a2: $8});
  const $21 = $5.a2;
  const $23 = ($21.value);
  const $6 = ($21.value=($23+1n));
  return JSON_Parser_JStr();
 };
 const $3 = {h: 0 /* Go */, a1: $4};
 const $0 = {a1: csegen_236(), a2: $3};
 return {a1: $0, a2: {h: 0}};
});

/* {csegen:247} */
const csegen_247 = __lazy(function () {
 const $d = $e => {
  const $10 = $e.a2;
  const $12 = ($10.value);
  const $f = ($10.value=($12+4n));
  const $1c = ($e.a4.value);
  switch($1c.h) {
   case 0: /* PA */ {
    const $22 = ($e.a4.value={h: 0 /* PA */, a1: $1c.a1, a2: {a1: $1c.a2, a2: {h: 0 /* JNull */}}});
    return JSON_Parser_AVal();
   }
   case 2: /* PL */ {
    const $2d = ($e.a4.value={h: 1 /* PO */, a1: $1c.a1, a2: {a1: $1c.a2, a2: {a1: $1c.a3, a2: {h: 0 /* JNull */}}}});
    return JSON_Parser_OVal();
   }
   case 4: /* PV */ {
    const $3a = ($e.a4.value={h: 4 /* PV */, a1: {a1: $1c.a1, a2: {h: 0 /* JNull */}}});
    return JSON_Parser_JIni();
   }
   default: {
    const $44 = ($e.a4.value={h: 5 /* PF */, a1: {h: 0 /* JNull */}});
    return JSON_Parser_JDone();
   }
  }
 };
 const $c = {h: 0 /* Go */, a1: $d};
 const $0 = {a1: {h: 2 /* And */, a1: csegen_191(), a2: {h: 2 /* And */, a1: csegen_192(), a2: {h: 2 /* And */, a1: csegen_193(), a2: csegen_193()}}}, a2: $c};
 const $5a = $5b => {
  const $5d = $5b.a2;
  const $5f = ($5d.value);
  const $5c = ($5d.value=($5f+4n));
  const $69 = ($5b.a4.value);
  switch($69.h) {
   case 0: /* PA */ {
    const $6f = ($5b.a4.value={h: 0 /* PA */, a1: $69.a1, a2: {a1: $69.a2, a2: {h: 3 /* JBool */, a1: 1}}});
    return JSON_Parser_AVal();
   }
   case 2: /* PL */ {
    const $7b = ($5b.a4.value={h: 1 /* PO */, a1: $69.a1, a2: {a1: $69.a2, a2: {a1: $69.a3, a2: {h: 3 /* JBool */, a1: 1}}}});
    return JSON_Parser_OVal();
   }
   case 4: /* PV */ {
    const $89 = ($5b.a4.value={h: 4 /* PV */, a1: {a1: $69.a1, a2: {h: 3 /* JBool */, a1: 1}}});
    return JSON_Parser_JIni();
   }
   default: {
    const $94 = ($5b.a4.value={h: 5 /* PF */, a1: {h: 3 /* JBool */, a1: 1}});
    return JSON_Parser_JDone();
   }
  }
 };
 const $59 = {h: 0 /* Go */, a1: $5a};
 const $4d = {a1: {h: 2 /* And */, a1: csegen_200(), a2: {h: 2 /* And */, a1: csegen_201(), a2: {h: 2 /* And */, a1: csegen_192(), a2: csegen_202()}}}, a2: $59};
 const $b4 = $b5 => {
  const $b7 = $b5.a2;
  const $b9 = ($b7.value);
  const $b6 = ($b7.value=($b9+5n));
  const $c3 = ($b5.a4.value);
  switch($c3.h) {
   case 0: /* PA */ {
    const $c9 = ($b5.a4.value={h: 0 /* PA */, a1: $c3.a1, a2: {a1: $c3.a2, a2: {h: 3 /* JBool */, a1: 0}}});
    return JSON_Parser_AVal();
   }
   case 2: /* PL */ {
    const $d5 = ($b5.a4.value={h: 1 /* PO */, a1: $c3.a1, a2: {a1: $c3.a2, a2: {a1: $c3.a3, a2: {h: 3 /* JBool */, a1: 0}}}});
    return JSON_Parser_OVal();
   }
   case 4: /* PV */ {
    const $e3 = ($b5.a4.value={h: 4 /* PV */, a1: {a1: $c3.a1, a2: {h: 3 /* JBool */, a1: 0}}});
    return JSON_Parser_JIni();
   }
   default: {
    const $ee = ($b5.a4.value={h: 5 /* PF */, a1: {h: 3 /* JBool */, a1: 0}});
    return JSON_Parser_JDone();
   }
  }
 };
 const $b3 = {h: 0 /* Go */, a1: $b4};
 const $9e = {a1: {h: 2 /* And */, a1: csegen_209(), a2: {h: 2 /* And */, a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('a'.codePointAt(0)))}, a2: {h: 2 /* And */, a1: csegen_193(), a2: {h: 2 /* And */, a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('s'.codePointAt(0)))}, a2: csegen_202()}}}}, a2: $b3};
 const $fc = $fd => {
  const $fe = ($fd.a8.value);
  const $104 = ($fd.a4.value);
  let $103;
  switch($104.h) {
   case 0: /* PA */ {
    const $10a = ($fd.a4.value={h: 0 /* PA */, a1: $104.a1, a2: {a1: $104.a2, a2: {h: 1 /* JInteger */, a1: Text_ILex_Util_integerBV($fe.a2, $fe.a1, 0n)}}});
    $103 = JSON_Parser_AVal();
    break;
   }
   case 2: /* PL */ {
    const $11b = ($fd.a4.value={h: 1 /* PO */, a1: $104.a1, a2: {a1: $104.a2, a2: {a1: $104.a3, a2: {h: 1 /* JInteger */, a1: Text_ILex_Util_integerBV($fe.a2, $fe.a1, 0n)}}}});
    $103 = JSON_Parser_OVal();
    break;
   }
   case 4: /* PV */ {
    const $12e = ($fd.a4.value={h: 4 /* PV */, a1: {a1: $104.a1, a2: {h: 1 /* JInteger */, a1: Text_ILex_Util_integerBV($fe.a2, $fe.a1, 0n)}}});
    $103 = JSON_Parser_JIni();
    break;
   }
   default: {
    const $13e = ($fd.a4.value={h: 5 /* PF */, a1: {h: 1 /* JInteger */, a1: Text_ILex_Util_integerBV($fe.a2, $fe.a1, 0n)}});
    $103 = JSON_Parser_JDone();
   }
  }
  const $14d = $fd.a2;
  const $14f = ($14d.value);
  const $14c = ($14d.value=($fe.a1+$14f));
  return $103;
 };
 const $fb = {h: 1 /* Rd */, a1: $fc};
 const $f8 = {a1: csegen_221(), a2: $fb};
 const $15f = $160 => {
  const $161 = ($160.a8.value);
  const $166 = Data_ByteString_toString($161);
  const $16a = ($160.a4.value);
  let $169;
  switch($16a.h) {
   case 0: /* PA */ {
    const $170 = ($160.a4.value={h: 0 /* PA */, a1: $16a.a1, a2: {a1: $16a.a2, a2: {h: 2 /* JDouble */, a1: JSON_Parser_jdouble($166)}}});
    $169 = JSON_Parser_AVal();
    break;
   }
   case 2: /* PL */ {
    const $17e = ($160.a4.value={h: 1 /* PO */, a1: $16a.a1, a2: {a1: $16a.a2, a2: {a1: $16a.a3, a2: {h: 2 /* JDouble */, a1: JSON_Parser_jdouble($166)}}}});
    $169 = JSON_Parser_OVal();
    break;
   }
   case 4: /* PV */ {
    const $18e = ($160.a4.value={h: 4 /* PV */, a1: {a1: $16a.a1, a2: {h: 2 /* JDouble */, a1: JSON_Parser_jdouble($166)}}});
    $169 = JSON_Parser_JIni();
    break;
   }
   default: {
    const $19b = ($160.a4.value={h: 5 /* PF */, a1: {h: 2 /* JDouble */, a1: JSON_Parser_jdouble($166)}});
    $169 = JSON_Parser_JDone();
   }
  }
  const $1a7 = $160.a2;
  const $1a9 = ($1a7.value);
  const $1a6 = ($1a7.value=(Prelude_Types_String_length($166)+$1a9));
  return $169;
 };
 const $15e = {h: 1 /* Rd */, a1: $15f};
 const $15b = {a1: JSON_Parser_jsonDouble(), a2: $15e};
 const $1bd = $1be => {
  const $1c2 = ($1be.a1.value);
  const $1c7 = ($1be.a2.value);
  const $1c1 = {a1: $1c2, a2: $1c7};
  const $1ce = ($1be.a3.value);
  const $1c0 = ($1be.a3.value={a1: $1ce, a2: $1c1});
  const $1da = $1be.a2;
  const $1dc = ($1da.value);
  const $1bf = ($1da.value=($1dc+1n));
  const $1e6 = ($1be.a4.value);
  const $1eb = ($1be.a4.value={h: 1 /* PO */, a1: $1e6, a2: {h: 0}});
  return JSON_Parser_ONew();
 };
 const $1bc = {h: 0 /* Go */, a1: $1bd};
 const $1b6 = {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('{'.codePointAt(0)))}, a2: $1bc};
 const $1fc = $1fd => {
  const $201 = ($1fd.a1.value);
  const $206 = ($1fd.a2.value);
  const $200 = {a1: $201, a2: $206};
  const $20d = ($1fd.a3.value);
  const $1ff = ($1fd.a3.value={a1: $20d, a2: $200});
  const $219 = $1fd.a2;
  const $21b = ($219.value);
  const $1fe = ($219.value=($21b+1n));
  const $225 = ($1fd.a4.value);
  const $22a = ($1fd.a4.value={h: 0 /* PA */, a1: $225, a2: {h: 0}});
  return JSON_Parser_ANew();
 };
 const $1fb = {h: 0 /* Go */, a1: $1fc};
 const $1f5 = {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('['.codePointAt(0)))}, a2: $1fb};
 const $1f4 = {a1: $1f5, a2: csegen_240()};
 const $1b5 = {a1: $1b6, a2: $1f4};
 const $15a = {a1: $15b, a2: $1b5};
 const $f7 = {a1: $f8, a2: $15a};
 const $9d = {a1: $9e, a2: $f7};
 const $4c = {a1: $4d, a2: $9d};
 return {a1: $0, a2: $4c};
});

/* {csegen:248} */
const csegen_248 = __lazy(function () {
 return Prelude_Types_List_tailRecAppend(csegen_247(), {h: 0});
});

/* {csegen:273} */
const csegen_273 = __lazy(function () {
 const $0 = $1 => {
  const $4 = $1.a2;
  const $6 = ($4.value);
  const $3 = ($4.value=($6+1n));
  const $10 = ($1.a3.value);
  let $2;
  switch($10.h) {
   case undefined: /* cons */ {
    $2 = ($1.a3.value=$10.a1);
    break;
   }
   default: $2 = undefined;
  }
  const $1b = ($1.a4.value);
  switch($1b.h) {
   case 1: /* PO */ {
    switch($1b.a1.h) {
     case 0: /* PA */ {
      const $22 = ($1.a4.value={h: 0 /* PA */, a1: $1b.a1.a1, a2: {a1: $1b.a1.a2, a2: {h: 6 /* JObject */, a1: Prelude_Types_SnocList_x3cx3ex3e($1b.a2, {h: 0})}}});
      return JSON_Parser_AVal();
     }
     case 2: /* PL */ {
      const $31 = ($1.a4.value={h: 1 /* PO */, a1: $1b.a1.a1, a2: {a1: $1b.a1.a2, a2: {a1: $1b.a1.a3, a2: {h: 6 /* JObject */, a1: Prelude_Types_SnocList_x3cx3ex3e($1b.a2, {h: 0})}}}});
      return JSON_Parser_OVal();
     }
     case 4: /* PV */ {
      const $42 = ($1.a4.value={h: 4 /* PV */, a1: {a1: $1b.a1.a1, a2: {h: 6 /* JObject */, a1: Prelude_Types_SnocList_x3cx3ex3e($1b.a2, {h: 0})}}});
      return JSON_Parser_JIni();
     }
     default: {
      const $50 = ($1.a4.value={h: 5 /* PF */, a1: {h: 6 /* JObject */, a1: Prelude_Types_SnocList_x3cx3ex3e($1b.a2, {h: 0})}});
      return JSON_Parser_JDone();
     }
    }
   }
   case 0: /* PA */ {
    switch($1b.a1.h) {
     case 0: /* PA */ {
      const $5d = ($1.a4.value={h: 0 /* PA */, a1: $1b.a1.a1, a2: {a1: $1b.a1.a2, a2: {h: 5 /* JArray */, a1: Prelude_Types_SnocList_x3cx3ex3e($1b.a2, {h: 0})}}});
      return JSON_Parser_AVal();
     }
     case 2: /* PL */ {
      const $6c = ($1.a4.value={h: 1 /* PO */, a1: $1b.a1.a1, a2: {a1: $1b.a1.a2, a2: {a1: $1b.a1.a3, a2: {h: 5 /* JArray */, a1: Prelude_Types_SnocList_x3cx3ex3e($1b.a2, {h: 0})}}}});
      return JSON_Parser_OVal();
     }
     case 4: /* PV */ {
      const $7d = ($1.a4.value={h: 4 /* PV */, a1: {a1: $1b.a1.a1, a2: {h: 5 /* JArray */, a1: Prelude_Types_SnocList_x3cx3ex3e($1b.a2, {h: 0})}}});
      return JSON_Parser_JIni();
     }
     default: {
      const $8b = ($1.a4.value={h: 5 /* PF */, a1: {h: 5 /* JArray */, a1: Prelude_Types_SnocList_x3cx3ex3e($1b.a2, {h: 0})}});
      return JSON_Parser_JDone();
     }
    }
   }
   default: return JSON_Parser_JDone();
  }
 };
 return {h: 0 /* Go */, a1: $0};
});

/* {csegen:275} */
const csegen_275 = __lazy(function () {
 return {a1: {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32(']'.codePointAt(0)))}, a2: csegen_273()}, a2: {h: 0}};
});

/* {csegen:299} */
const csegen_299 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32(','.codePointAt(0)))};
});

/* {csegen:316} */
const csegen_316 = __lazy(function () {
 return {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('}'.codePointAt(0)))}, a2: csegen_273()};
});

/* {csegen:382} */
const csegen_382 = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('\u{5c}'.codePointAt(0)))};
});

/* {csegen:446} */
const csegen_446 = __lazy(function () {
 return $0 => $1 => $1.a7;
});

/* {csegen:448} */
const csegen_448 = __lazy(function () {
 return $0 => $1 => Text_ILex_Interfaces_unclosedIfEOI(csegen_446(), csegen_175(), csegen_177(), '[', {h: 0}, $0, $1);
});

/* {csegen:479} */
const csegen_479 = __lazy(function () {
 return {h: 2 /* And */, a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_digit()}, a2: {h: 4 /* Star */, a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_digit()}}};
});

/* {csegen:512} */
const csegen_512 = __lazy(function () {
 let $1;
 switch(Prelude_EqOrd_x3cx3d_Ord_Bits32(_truncUInt32('0'.codePointAt(0)), _truncUInt32('9'.codePointAt(0)))) {
  case 1: {
   $1 = {a1: _truncUInt32('0'.codePointAt(0)), a2: _truncUInt32('9'.codePointAt(0))};
   break;
  }
  case 0: {
   $1 = {h: 0};
   break;
  }
 }
 return Text_ILex_Char_Set_range($1);
});

/* {csegen:536} */
const csegen_536 = __lazy(function () {
 return {a1: Prelude_Types_prim__integerToNat(BigInt(Data_Buffer_stringByteLength(''))), a2: Data_ByteVect_fromString('')};
});

/* {csegen:539} */
const csegen_539 = __lazy(function () {
 return {a1: $1 => $2 => (($1===$2)?1:0), a2: $6 => $7 => Prelude_Types_x2fx3d_Eq_Nat($6, $7)};
});

/* {csegen:547} */
const csegen_547 = __lazy(function () {
 return {a1: csegen_539(), a2: $3 => $4 => Prelude_EqOrd_compare_Ord_Integer($3, $4), a3: $9 => $a => Prelude_Types_x3c_Ord_Nat($9, $a), a4: $f => $10 => Prelude_Types_x3e_Ord_Nat($f, $10), a5: $15 => $16 => Prelude_Types_x3cx3d_Ord_Nat($15, $16), a6: $1b => $1c => Prelude_Types_x3ex3d_Ord_Nat($1b, $1c), a7: $21 => $22 => Prelude_Types_max_Ord_Nat($21, $22), a8: $27 => $28 => Prelude_Types_min_Ord_Nat($27, $28)};
});

/* {csegen:553} */
const csegen_553 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_EqOrd_x3dx3d_Eq_Bits8($1, $2), a2: $7 => $8 => Prelude_EqOrd_x2fx3d_Eq_Bits8($7, $8)};
});

/* {csegen:561} */
const csegen_561 = __lazy(function () {
 return {a1: csegen_553(), a2: $3 => $4 => Prelude_EqOrd_compare_Ord_Bits8($3, $4), a3: $9 => $a => Prelude_EqOrd_x3c_Ord_Bits8($9, $a), a4: $f => $10 => Prelude_EqOrd_x3e_Ord_Bits8($f, $10), a5: $15 => $16 => Prelude_EqOrd_x3cx3d_Ord_Bits8($15, $16), a6: $1b => $1c => Prelude_EqOrd_x3ex3d_Ord_Bits8($1b, $1c), a7: $21 => $22 => Prelude_EqOrd_max_Ord_Bits8($21, $22), a8: $27 => $28 => Prelude_EqOrd_min_Ord_Bits8($27, $28)};
});

/* {csegen:562} */
const csegen_562 = __lazy(function () {
 return {a1: csegen_561(), a2: 0, a3: 255};
});

/* {csegen:565} */
const csegen_565 = __lazy(function () {
 return {a1: $1 => $2 => _add8u($1, $2), a2: $6 => $7 => _mul8u($6, $7), a3: $b => Number(_truncUBigInt8($b))};
});

/* {csegen:570} */
const csegen_570 = __lazy(function () {
 return {a1: csegen_565(), a2: $3 => _sub8u(0, $3), a3: $7 => $8 => _sub8u($7, $8)};
});

/* {csegen:573} */
const csegen_573 = __lazy(function () {
 return $0 => $0.a2;
});

/* {csegen:606} */
const csegen_606 = __lazy(function () {
 return $0 => $1 => Text_ILex_Internal_NFA_joinNNode($0, $1);
});

/* {csegen:611} */
const csegen_611 = __lazy(function () {
 const $a = a => b => {
  switch(Text_ILex_Char_Range_eqRangeOf(csegen_553(), a, b)) {
   case 1: return 0;
   case 0: return 1;
  }
 };
 const $1 = {a1: $3 => $4 => Text_ILex_Char_Range_eqRangeOf(csegen_553(), $3, $4), a2: $a};
 return Language_Reflection_Derive_mkOrd($1, $12 => $13 => Text_ILex_Char_Range_ordRangeOf(csegen_561(), $12, $13));
});

/* {csegen:615} */
const csegen_615 = __lazy(function () {
 return Text_ILex_Char_UTF8_bytes(Text_ILex_Char_UTF8_MinAddByte(), Text_ILex_Char_UTF8_MaxAddByte());
});

/* {csegen:616} */
const csegen_616 = __lazy(function () {
 return $0 => Prelude_EqOrd_x3dx3d_Eq_Bits8(10, $0);
});

/* {csegen:626} */
const csegen_626 = __lazy(function () {
 return $0 => {
  switch($0.h) {
   case 6: /* JObject */ return {a1: $0.a1};
   default: return {h: 0};
  }
 };
});

/* {csegen:627} */
const csegen_627 = __lazy(function () {
 return $0 => {
  switch($0.h) {
   case 4: /* JString */ return {a1: $0.a1};
   default: return {h: 0};
  }
 };
});

/* {csegen:631} */
const csegen_631 = __lazy(function () {
 return {a1: $1 => $2 => Prelude_EqOrd_x3dx3d_Eq_String($1, $2), a2: $7 => $8 => Prelude_EqOrd_x2fx3d_Eq_String($7, $8)};
});

/* {csegen:634} */
const csegen_634 = __lazy(function () {
 return $0 => $1 => Web_Internal_DomTypes_safeCast_SafeCast_Element($1);
});

/* {csegen:635} */
const csegen_635 = __lazy(function () {
 return $0 => $1 => Web_Internal_DomTypes_safeCast_SafeCast_Event($1);
});

/* {csegen:636} */
const csegen_636 = __lazy(function () {
 return $0 => $1 => Web_Internal_UIEventsTypes_safeCast_SafeCast_MouseEvent($1);
});

/* {csegen:637} */
const csegen_637 = __lazy(function () {
 return $0 => $1 => Web_Internal_UIEventsTypes_safeCast_SafeCast_KeyboardEvent($1);
});

/* {csegen:645} */
const csegen_645 = __lazy(function () {
 return $0 => $1 => $2 => $3 => $4 => Prelude_IO_map_Functor_IO($2, $3, $4);
});

/* {csegen:652} */
const csegen_652 = __lazy(function () {
 return $0 => JS_Union_toFFI_ToFFI_x28HSumx20x28x28x3ax3ax20x24ax29x20x28x28x3ax3ax20x24bx29x20Nilx29x29x29_x28x28Union2x20x24mx29x20x24nx29(csegen_119(), $0);
});

/* {csegen:660} */
const csegen_660 = __lazy(function () {
 return () => Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), {a1: 0.0, a2: 0, a3: 0});
});

/* prim__sub_Integer : Integer -> Integer -> Integer */
function prim__sub_Integer($0, $1) {
 return ($0-$1);
}

/* FrontendMain.case block in controller */
function FrontendMain_case__controller_3443($0, $1, $2) {
 switch($2.h) {
  case 0: /* Left */ {
   const $4 = {a1: $1.a1, a2: $1.a2, a3: 'Live decode failed. Resyncing stream...', a4: 1, a5: $1.a5};
   return {a1: $4, a2: $d => $e => Web_MVC_Cmd_batch({a1: $12 => FrontendMain_updateView($4, $12), a2: csegen_0()}, $d, $e)};
  }
  case 1: /* Right */ {
   const $1a = Domain_applyDetailEvent($2.a1.a1, $2.a1.a2, $1.a1);
   switch($1a.h) {
    case 0: /* Left */ {
     const $22 = {a1: $1.a1, a2: $1.a2, a3: ($1a.a1+' Resyncing stream...'), a4: 1, a5: $1.a5};
     return {a1: $22, a2: $2d => $2e => Web_MVC_Cmd_batch({a1: $32 => FrontendMain_updateView($22, $32), a2: csegen_0()}, $2d, $2e)};
    }
    case 1: /* Right */ {
     const $3a = {a1: $1a.a1, a2: $1.a2, a3: 'Live update applied.', a4: 0, a5: $1.a5};
     return {a1: $3a, a2: $43 => FrontendMain_updateView($3a, $43)};
    }
   }
  }
 }
}

/* FrontendMain.13631:2606:matches */
function FrontendMain_n__13631_2606_matches($0, $1, $2) {
 switch($1) {
  case 0: {
   switch($2) {
    case 0: return 1;
    default: return 0;
   }
  }
  case 1: {
   switch($2) {
    case 1: return 1;
    default: return 0;
   }
  }
  case 2: {
   switch($2) {
    case 2: return 1;
    default: return 0;
   }
  }
  default: return 0;
 }
}

/* FrontendMain.13794:2761:historyRow */
function FrontendMain_n__13794_2761_historyRow($0, $1, $2) {
 return {h: 0 /* El */, a1: 'li', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'margin-bottom:6px;'}, a2: {h: 0}}, a3: {a1: {h: 2 /* Text */, a1: ('v'+(Prelude_Show_show_Show_Nat($1)+(' '+FrontendMain_renderHistoryEvent($2))))}, a2: {h: 0}}};
}

/* FrontendMain.13794:2760:feedStatus */
function FrontendMain_n__13794_2760_feedStatus($0, $1) {
 switch($1.h) {
  case 0: /* nothing */ return ' \u{b7} disconnected';
  case undefined: /* just */ return ' \u{b7} connected';
 }
}

/* FrontendMain.viewNode : State -> Node Msg */
function FrontendMain_viewNode($0) {
 const $1 = FrontendMain_currentModel($0);
 const $4 = FrontendMain_hasAction(0, $0);
 const $8 = FrontendMain_hasAction(1, $0);
 const $c = FrontendMain_hasAction(2, $0);
 const $10 = Data_List_zipWith_Zippable_List($13 => $14 => FrontendMain_n__13794_2761_historyRow($0, $13, $14), Prelude_Types_rangeFromTo_Range_Nat(1n, Prelude_Types_List_lengthTR($0.a1.a3)), $0.a1.a3);
 let $94;
 switch($4) {
  case 1: {
   $94 = {h: 0 /* El */, a1: 'div', a2: csegen_12(), a3: {a1: {h: 0 /* El */, a1: 'input', a2: {a1: Text_HTML_Attribute_onInput($a0 => ({h: 4 /* CreateNameChanged */, a1: $a0})), a2: {a1: {h: 1 /* Str */, a1: 'value', a2: $0.a2}, a2: {a1: {h: 1 /* Str */, a1: 'placeholder', a2: 'counter name'}, a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'padding:10px; border:1px solid #98aaba; border-radius:10px; min-width:240px;'}, a2: {h: 0}}}}}, a3: {h: 0}}, a2: {a1: FrontendMain_actionButton($0.a4, 0), a2: {h: 0}}}};
   break;
  }
  case 0: {
   let $bd;
   switch($8) {
    case 1: {
     $bd = {a1: FrontendMain_actionButton($0.a4, 1), a2: {h: 0}};
     break;
    }
    case 0: {
     $bd = {h: 0};
     break;
    }
   }
   let $c5;
   switch($c) {
    case 1: {
     $c5 = {a1: FrontendMain_actionButton($0.a4, 2), a2: {h: 0}};
     break;
    }
    case 0: {
     $c5 = {h: 0};
     break;
    }
   }
   const $bb = Prelude_Types_List_tailRecAppend($bd, $c5);
   $94 = {h: 0 /* El */, a1: 'div', a2: csegen_12(), a3: $bb};
   break;
  }
 }
 let $da;
 switch(Prelude_Types_null_Foldable_List($10)) {
  case 1: {
   $da = {h: 2 /* Text */, a1: 'No events yet.'};
   break;
  }
  case 0: {
   $da = {h: 0 /* El */, a1: 'ul', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'margin:0; padding-left:20px;'}, a2: {h: 0}}, a3: $10};
   break;
  }
 }
 const $d9 = {a1: $da, a2: {h: 0}};
 const $cd = {a1: {h: 0 /* El */, a1: 'h2', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'margin:0 0 8px 0;'}, a2: {h: 0}}, a3: {a1: {h: 2 /* Text */, a1: 'Event History'}, a2: {h: 0}}}, a2: $d9};
 const $93 = {a1: $94, a2: $cd};
 const $86 = {a1: {h: 0 /* El */, a1: 'div', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'font-size:28px; letter-spacing:1px; margin-top:6px; color:#406657; min-height:34px;'}, a2: {h: 0}}, a3: {a1: {h: 2 /* Text */, a1: $1.a4}, a2: {h: 0}}}, a2: $93};
 const $77 = {a1: {h: 0 /* El */, a1: 'div', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'font-size:84px; font-weight:700; line-height:0.9; color:#1b4f3e;'}, a2: {h: 0}}, a3: {a1: {h: 2 /* Text */, a1: Prelude_Show_show_Show_Nat($1.a3)}, a2: {h: 0}}}, a2: $86};
 const $6a = {a1: {h: 0 /* El */, a1: 'h1', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'margin:8px 0 6px 0; font-size:30px;'}, a2: {h: 0}}, a3: {a1: {h: 2 /* Text */, a1: $1.a2}, a2: {h: 0}}}, a2: $77};
 const $5e = {a1: {h: 0 /* El */, a1: 'div', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'font-size:12px; opacity:0.65; text-transform:uppercase; letter-spacing:1px;'}, a2: {h: 0}}, a3: {a1: {h: 2 /* Text */, a1: 'ClientProjectionOnly'}, a2: {h: 0}}}, a2: $6a};
 const $57 = {h: 0 /* El */, a1: 'div', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'background:#ffffffd9; border:1px solid #ced8e2; border-radius:18px; padding:18px;'}, a2: {h: 0}}, a3: $5e};
 const $56 = {a1: $57, a2: {h: 0}};
 const $32 = {a1: {h: 0 /* El */, a1: 'div', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'background:#ffffffd9; border:1px solid #ced8e2; border-radius:14px; padding:12px 14px; margin-bottom:18px; display:flex; gap:12px; flex-wrap:wrap;'}, a2: {h: 0}}, a3: {a1: {h: 2 /* Text */, a1: ('Status: '+FrontendMain_statusText($0))}, a2: {a1: {h: 0 /* El */, a1: 'div', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'margin-left:auto; font-size:12px; opacity:0.72;'}, a2: {h: 0}}, a3: {a1: {h: 2 /* Text */, a1: ('Stream: '+('counter-main'+FrontendMain_n__13794_2760_feedStatus($0, $0.a5)))}, a2: {h: 0}}}, a2: {h: 0}}}}, a2: $56};
 const $2b = {h: 0 /* El */, a1: 'div', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'max-width:860px; margin:0 auto;'}, a2: {h: 0}}, a3: $32};
 const $2a = {a1: $2b, a2: {h: 0}};
 return {h: 0 /* El */, a1: 'div', a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'min-height:100vh; padding:24px; background:linear-gradient(135deg,#f1eee8 0%, #e5eef7 55%, #dde7d8 100%); font-family:Georgia,serif; color:#20303b;'}, a2: {h: 0}}, a3: $2a};
}

/* FrontendMain.updateView : State -> Cmd Msg */
function FrontendMain_updateView($0, $1) {
 return Web_MVC_View_setupNodes($4 => $5 => Web_Raw_Dom_ParentNode_replaceChildren($4, Web_MVC_Util_nodeList($5)), {h: 2 /* Body */}, {a1: FrontendMain_viewNode($0), a2: {h: 0}}, $1);
}

/* FrontendMain.subscribeLive : String -> Cmd Msg */
function FrontendMain_subscribeLive($0, $1) {
 return EmKit_Frontend_Stream_subscribeStream($4 => $5 => FrontendMain_eventsUrl($4, $5), 'counter-main', $0, $c => ({h: 3 /* LiveEventReceived */, a1: $c}), $1);
}

/* FrontendMain.statusText : State -> String */
function FrontendMain_statusText($0) {
 switch($0.a4) {
  case 1: return ('Working: '+$0.a3);
  case 0: return $0.a3;
 }
}

/* FrontendMain.resyncUrl : String -> String */
function FrontendMain_resyncUrl($0) {
 return '/api/counter/resync';
}

/* FrontendMain.requestResync : Cmd Msg */
function FrontendMain_requestResync($0) {
 return EmKit_Frontend_Execute_getResync($3 => EmKit_Wire_JSON_Simple_fromJsonResyncPayload($6 => Domain_JSON_Simple_fromJsonCounterEvent($6), $3), $b => FrontendMain_resyncUrl($b), $f => $10 => ({h: 2 /* ResyncFinished */, a1: $10}), 'counter-main', $0);
}

/* FrontendMain.renderHistoryEvent : CounterEvent -> String */
function FrontendMain_renderHistoryEvent($0) {
 switch($0.h) {
  case 0: /* Created */ return ('Created ('+($0.a1+')'));
  case 1: /* Incremented */ return 'Incremented';
  case 2: /* Decremented */ return 'Decremented';
 }
}

/* FrontendMain.postIncrement : Nat -> Cmd Msg */
function FrontendMain_postIncrement($0, $1) {
 return EmKit_Frontend_Execute_postExecuteSingle($4 => Domain_JSON_Simple_toJsonCommand($4), $8 => FrontendMain_executeUrl($8), $c => ({h: 8 /* IncrementFinished */, a1: $c}), 'counter-main', $0, {h: 1 /* Increment */}, $1);
}

/* FrontendMain.postDecrement : Nat -> Cmd Msg */
function FrontendMain_postDecrement($0, $1) {
 return EmKit_Frontend_Execute_postExecuteSingle($4 => Domain_JSON_Simple_toJsonCommand($4), $8 => FrontendMain_executeUrl($8), $c => ({h: 10 /* DecrementFinished */, a1: $c}), 'counter-main', $0, {h: 2 /* Decrement */}, $1);
}

/* FrontendMain.postCreate : Nat -> String -> Cmd Msg */
function FrontendMain_postCreate($0, $1, $2) {
 return EmKit_Frontend_Execute_postExecuteSingle($5 => Domain_JSON_Simple_toJsonCommand($5), $9 => FrontendMain_executeUrl($9), $d => ({h: 6 /* CreateFinished */, a1: $d}), 'counter-main', $0, {h: 0 /* Create */, a1: $1}, $2);
}

/* FrontendMain.onError : JSErr -> IO () */
function FrontendMain_onError($0, $1) {
 return Prelude_IO_prim__putStr((JS_Util_dispErr($0)+'\n'), $1);
}

/* FrontendMain.msgForAction : Action -> Msg */
function FrontendMain_msgForAction($0) {
 switch($0) {
  case 0: return {h: 5 /* CreateClicked */};
  case 1: return {h: 7 /* IncrementClicked */};
  case 2: return {h: 9 /* DecrementClicked */};
 }
}

/* FrontendMain.main : IO () */
function FrontendMain_main($0) {
 return Web_MVC_runController($3 => $4 => FrontendMain_controller($3, $4), $9 => $a => FrontendMain_onError($9, $a), {h: 0 /* Initialized */}, FrontendMain_initialState(), $0);
}

/* FrontendMain.initialState : State */
const FrontendMain_initialState = __lazy(function () {
 return {a1: Domain_emptyDetail(), a2: 'Kitchen', a3: 'Connecting live feed...', a4: 1, a5: {h: 0}};
});

/* FrontendMain.httpErrorMessage : HTTPError -> String */
function FrontendMain_httpErrorMessage($0) {
 switch($0.h) {
  case 0: /* Timeout */ return 'Request timed out.';
  case 1: /* NetworkError */ return 'Network error. Run ./scripts/run.sh and open /static/index.html on the configured port.';
  case 2: /* BadStatus */ return ('Server returned status '+(Prelude_Show_show_Show_Bits16($0.a1)+'.'));
  case 3: /* JSONError */ return 'Failed to decode JSON response.';
 }
}

/* FrontendMain.hasAction : Action -> State -> Bool */
function FrontendMain_hasAction($0, $1) {
 return Prelude_Types_foldMap_Foldable_List({a1: $5 => $6 => Prelude_Interfaces_Bool_Semigroup_x3cx2bx3e_Semigroup_AnyBool($5, $6), a2: 0}, $c => FrontendMain_n__13631_2606_matches($1, $0, $c), FrontendMain_availableActions($1));
}

/* FrontendMain.executeUrl : String -> String */
function FrontendMain_executeUrl($0) {
 return '/api/counter/execute';
}

/* FrontendMain.eventsUrl : String -> String -> String */
function FrontendMain_eventsUrl($0, $1) {
 return ('/api/counter/events/'+$1);
}

/* FrontendMain.currentModel : State -> CounterModel */
function FrontendMain_currentModel($0) {
 return $0.a1.a2;
}

/* FrontendMain.controller : Msg -> State -> (State, Cmd Msg) */
function FrontendMain_controller($0, $1) {
 switch($0.h) {
  case 0: /* Initialized */ {
   const $3 = {a1: $1.a1, a2: $1.a2, a3: 'Connecting live feed...', a4: 1, a5: $1.a5};
   return {a1: $3, a2: $c => $d => Web_MVC_Cmd_batch({a1: $11 => FrontendMain_updateView($3, $11), a2: {a1: $17 => EmKit_Frontend_SSE_requestClientId($1a => ({h: 1 /* ClientIdReady */, a1: $1a}), $17), a2: {h: 0}}}, $c, $d)};
  }
  case 1: /* ClientIdReady */ {
   const $20 = {a1: $1.a1, a2: $1.a2, a3: 'Syncing stream...', a4: 1, a5: {a1: $0.a1}};
   return {a1: $20, a2: $2a => $2b => Web_MVC_Cmd_batch({a1: $2f => FrontendMain_updateView($20, $2f), a2: {a1: $35 => FrontendMain_subscribeLive($0.a1, $35), a2: csegen_0()}}, $2a, $2b)};
  }
  case 2: /* ResyncFinished */ {
   switch($0.a1.h) {
    case 0: /* Left */ {
     const $3e = {a1: $1.a1, a2: $1.a2, a3: FrontendMain_httpErrorMessage($0.a1.a1), a4: 0, a5: $1.a5};
     return {a1: $3e, a2: $49 => FrontendMain_updateView($3e, $49)};
    }
    case 1: /* Right */ {
     const $4d = Domain_detailFromEvents($0.a1.a1.a1, $0.a1.a1.a2);
     const $53 = {a1: $4d, a2: $1.a2, a3: 'Stream synced.', a4: 0, a5: $1.a5};
     return {a1: $53, a2: $5c => FrontendMain_updateView($53, $5c)};
    }
   }
  }
  case 3: /* LiveEventReceived */ {
   const $6f = Text_ILex_Runner_runFrom(Prelude_Types_prim__integerToNat(BigInt(Data_Buffer_stringByteLength($0.a1))), $78 => JSON_Parser_json(), Prelude_Types_prim__integerToNat(BigInt(Data_Buffer_stringByteLength($0.a1))), 0n, Data_Buffer_Core_fromString($0.a1));
   let $6e;
   switch($6f.h) {
    case 0: /* Left */ {
     $6e = {h: 0 /* Left */, a1: Text_ParseError_toParseError({h: 0}, Data_Buffer_Core_toString(Data_Buffer_Core_fromString($0.a1), 0n, Prelude_Types_prim__integerToNat(BigInt(Data_Buffer_stringByteLength($0.a1)))), $6f.a1)};
     break;
    }
    case 1: /* Right */ {
     $6e = {h: 1 /* Right */, a1: $6f.a1};
     break;
    }
   }
   const $63 = JSON_Simple_FromJSON_case__decode_14999($66 => EmKit_Wire_JSON_Simple_fromJsonStreamEvent($69 => Domain_JSON_Simple_fromJsonCounterEvent($69), $66), $0.a1, $6e);
   return FrontendMain_case__controller_3443($0.a1, $1, $63);
  }
  case 4: /* CreateNameChanged */ return {a1: {a1: $1.a1, a2: $0.a1, a3: $1.a3, a4: $1.a4, a5: $1.a5}, a2: $9d => csegen_37()()};
  case 5: /* CreateClicked */ {
   const $a0 = Data_String_trim($1.a2);
   const $a4 = $1.a1.a1;
   switch(Prelude_EqOrd_x3dx3d_Eq_String($a0, '')) {
    case 1: {
     const $ab = {a1: $1.a1, a2: $1.a2, a3: 'Counter name is required.', a4: 0, a5: $1.a5};
     return {a1: $ab, a2: $b4 => FrontendMain_updateView($ab, $b4)};
    }
    case 0: {
     const $b8 = {a1: $1.a1, a2: $1.a2, a3: 'Creating counter...', a4: 1, a5: $1.a5};
     return {a1: $b8, a2: $c1 => $c2 => Web_MVC_Cmd_batch({a1: $c6 => FrontendMain_updateView($b8, $c6), a2: {a1: $cc => FrontendMain_postCreate($a4, $a0, $cc), a2: {h: 0}}}, $c1, $c2)};
    }
   }
  }
  case 6: /* CreateFinished */ {
   switch($0.a1.h) {
    case 0: /* Left */ {
     const $d5 = {a1: $1.a1, a2: $1.a2, a3: FrontendMain_httpErrorMessage($0.a1.a1), a4: 0, a5: $1.a5};
     return {a1: $d5, a2: $e0 => FrontendMain_updateView($d5, $e0)};
    }
    case 1: /* Right */ {
     const $e4 = {a1: $1.a1, a2: '', a3: 'Create accepted. Waiting for live update...', a4: 0, a5: $1.a5};
     return {a1: $e4, a2: $ed => FrontendMain_updateView($e4, $ed)};
    }
   }
  }
  case 7: /* IncrementClicked */ {
   const $f1 = {a1: $1.a1, a2: $1.a2, a3: 'Incrementing counter...', a4: 1, a5: $1.a5};
   return {a1: $f1, a2: $fa => $fb => Web_MVC_Cmd_batch({a1: $ff => FrontendMain_updateView($f1, $ff), a2: {a1: $105 => FrontendMain_postIncrement($1.a1.a1, $105), a2: {h: 0}}}, $fa, $fb)};
  }
  case 8: /* IncrementFinished */ {
   switch($0.a1.h) {
    case 0: /* Left */ {
     const $10f = {a1: $1.a1, a2: $1.a2, a3: FrontendMain_httpErrorMessage($0.a1.a1), a4: 0, a5: $1.a5};
     return {a1: $10f, a2: $11a => FrontendMain_updateView($10f, $11a)};
    }
    case 1: /* Right */ {
     const $11e = {a1: $1.a1, a2: $1.a2, a3: 'Increment accepted. Waiting for live update...', a4: 0, a5: $1.a5};
     return {a1: $11e, a2: $127 => FrontendMain_updateView($11e, $127)};
    }
   }
  }
  case 9: /* DecrementClicked */ {
   const $12b = {a1: $1.a1, a2: $1.a2, a3: 'Decrementing counter...', a4: 1, a5: $1.a5};
   return {a1: $12b, a2: $134 => $135 => Web_MVC_Cmd_batch({a1: $139 => FrontendMain_updateView($12b, $139), a2: {a1: $13f => FrontendMain_postDecrement($1.a1.a1, $13f), a2: {h: 0}}}, $134, $135)};
  }
  case 10: /* DecrementFinished */ {
   switch($0.a1.h) {
    case 0: /* Left */ {
     const $149 = {a1: $1.a1, a2: $1.a2, a3: FrontendMain_httpErrorMessage($0.a1.a1), a4: 0, a5: $1.a5};
     return {a1: $149, a2: $154 => FrontendMain_updateView($149, $154)};
    }
    case 1: /* Right */ {
     const $158 = {a1: $1.a1, a2: $1.a2, a3: 'Decrement accepted. Waiting for live update...', a4: 0, a5: $1.a5};
     return {a1: $158, a2: $161 => FrontendMain_updateView($158, $161)};
    }
   }
  }
 }
}

/* FrontendMain.availableActions : State -> List Action */
function FrontendMain_availableActions($0) {
 return Domain_availableActionsForModel(FrontendMain_currentModel($0));
}

/* FrontendMain.actionButton : Bool -> Action -> Node Msg */
function FrontendMain_actionButton($0, $1) {
 return {h: 0 /* El */, a1: 'button', a2: {a1: {h: 3 /* Event_ */, a1: 0, a2: 0, a3: {h: 0 /* Click */, a1: $9 => ({a1: FrontendMain_msgForAction($1)})}}, a2: {a1: {h: 2 /* Bool */, a1: 'disabled', a2: $0}, a2: {a1: {h: 1 /* Str */, a1: 'style', a2: 'padding:9px 12px; border:1px solid #3b5d7e; border-radius:10px; background:#eef5fb;'}, a2: {h: 0}}}}, a3: {a1: {h: 2 /* Text */, a1: Domain_renderAction($1)}, a2: {h: 0}}};
}

/* Web.MVC.Http.xsend : RequestBody -> XMLHttpRequest -> JSIO () */
function Web_MVC_Http_xsend($0, $1) {
 switch($0.h) {
  case 0: /* Empty */ return Web_Raw_Xhr_XMLHttpRequest_send($1);
  case 1: /* StringBody */ return Web_Raw_Xhr_XMLHttpRequest_sendx27($1, {a1: {a1: Data_List_Quantifiers_Extra_inject(15n, $0.a2)}});
  case 2: /* JSONBody */ return Web_Raw_Xhr_XMLHttpRequest_sendx27($1, {a1: {a1: Data_List_Quantifiers_Extra_inject(15n, JSON_Parser_showImpl($0.a1($0.a2)))}});
  case 3: /* FormBody */ return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Xhr_FormData_new$(), fd => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $25 => Control_Monad_Either_Extra_traverseList_($28 => Web_MVC_Http_append(fd, $28), $0.a1, $25), $2f => Web_Raw_Xhr_XMLHttpRequest_sendx27($1, {a1: {a1: Data_List_Quantifiers_Extra_inject(13n, fd)}})));
 }
}

/* Web.MVC.Http.showPrecMethod : Prec -> Method -> String */
function Web_MVC_Http_showPrecMethod($0, $1) {
 switch($1) {
  case 0: return 'GET';
  case 1: return 'POST';
 }
}

/* Web.MVC.Http.request : Method -> List Header -> String -> RequestBody -> Expect r -> Maybe Bits32 -> Cmd r */
function Web_MVC_Http_request($0, $1, $2, $3, $4, $5, $6) {
 const $d = x => {
  const $20 = $21 => {
   const $34 = $35 => {
    const $48 = $49 => {
     const $52 = Language_Reflection_Derive_mkShowPrec($55 => $56 => Web_MVC_Http_showPrecMethod($55, $56));
     const $51 = $52.a1($0);
     const $4e = Web_Raw_Xhr_XMLHttpRequest_open_(x, $51, $2);
     const $5d = $5e => {
      const $60 = Prelude_Types_List_tailRecAppend(Web_MVC_Http_bodyHeaders($3), $1);
      const $5f = () => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $6b => Control_Monad_Either_Extra_traverseList_($6e => Web_Raw_Xhr_XMLHttpRequest_setRequestHeader(x, $6e.a1, $6e.a2), $60, $6b), $77 => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Prelude_Interfaces_traverse_(csegen_56()(), {a1: acc => elem => func => init => input => Prelude_Types_foldr_Foldable_Maybe(func, init, input), a2: elem => acc => func => init => input => Prelude_Types_foldl_Foldable_Maybe(func, init, input), a3: elem => $8e => Prelude_Types_null_Foldable_Maybe($8e), a4: elem => acc => m => $92 => funcM => init => input => Prelude_Types_foldlM_Foldable_Maybe($92, funcM, init, input), a5: elem => $99 => Prelude_Types_toList_Foldable_Maybe($99), a6: a => m => $9d => f => $9e => Prelude_Types_foldMap_Foldable_Maybe($9d, f, $9e)}, $a4 => JS_Attribute_set(Web_Raw_Xhr_XMLHttpRequest_timeout(x), $a4))($5), $ac => Web_MVC_Http_xsend($3, x)));
      return $5f();
     };
     return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $4e, $5d);
    };
    return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), JS_Attribute_x3fx3e($3d => Web_Html_callback_Callback_EventHandlerNonNull_x28x25pix20RigWx20Explicitx20Nothingx20Eventx20x28JSIOx20x28x7cUnitx2cMkUnitx7cx29x29x29($3d), Web_Raw_Xhr_XMLHttpRequestEventTarget_ontimeout(x), Web_MVC_Http_onerror($6, $4, {h: 0 /* Timeout */})), $48);
   };
   return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), JS_Attribute_x3fx3e($29 => Web_Html_callback_Callback_EventHandlerNonNull_x28x25pix20RigWx20Explicitx20Nothingx20Eventx20x28JSIOx20x28x7cUnitx2cMkUnitx7cx29x29x29($29), Web_Raw_Xhr_XMLHttpRequestEventTarget_onload(x), Web_MVC_Http_onload($6, $4, x)), $34);
  };
  return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), JS_Attribute_x3fx3e($15 => Web_Html_callback_Callback_EventHandlerNonNull_x28x25pix20RigWx20Explicitx20Nothingx20Eventx20x28JSIOx20x28x7cUnitx2cMkUnitx7cx29x29x29($15), Web_Raw_Xhr_XMLHttpRequestEventTarget_onerror(x), Web_MVC_Http_onerror($6, $4, {h: 1 /* NetworkError */})), $20);
 };
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Xhr_XMLHttpRequest_new$(), $d);
}

/* Web.MVC.Http.onsuccess : (r -> JSIO ()) -> Expect r -> XMLHttpRequest -> JSIO () */
function Web_MVC_Http_onsuccess($0, $1, $2) {
 switch($1.h) {
  case 1: /* ExpectString */ return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Xhr_XMLHttpRequest_responseText($2), $c => $0($1.a1({h: 1 /* Right */, a1: $c})));
  case 2: /* ExpectAny */ return $0($1.a1({h: 1 /* Right */, a1: undefined}));
  case 0: /* ExpectJSON */ {
   const $1e = s => {
    const $28 = Text_ILex_Runner_runFrom(Prelude_Types_prim__integerToNat(BigInt(Data_Buffer_stringByteLength(s))), $31 => JSON_Parser_json(), Prelude_Types_prim__integerToNat(BigInt(Data_Buffer_stringByteLength(s))), 0n, Data_Buffer_Core_fromString(s));
    let $27;
    switch($28.h) {
     case 0: /* Left */ {
      $27 = {h: 0 /* Left */, a1: Text_ParseError_toParseError({h: 0}, Data_Buffer_Core_toString(Data_Buffer_Core_fromString(s), 0n, Prelude_Types_prim__integerToNat(BigInt(Data_Buffer_stringByteLength(s)))), $28.a1)};
      break;
     }
     case 1: /* Right */ {
      $27 = {h: 1 /* Right */, a1: $28.a1};
      break;
     }
    }
    const $23 = JSON_Simple_FromJSON_case__decode_14999($1.a1, s, $27);
    let $22;
    switch($23.h) {
     case 0: /* Left */ {
      $22 = {h: 0 /* Left */, a1: {h: 3 /* JSONError */, a1: s, a2: $23.a1}};
      break;
     }
     case 1: /* Right */ {
      $22 = {h: 1 /* Right */, a1: $23.a1};
      break;
     }
    }
    const $20 = $1.a2($22);
    return $0($20);
   };
   return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Xhr_XMLHttpRequest_responseText($2), $1e);
  }
 }
}

/* Web.MVC.Http.onload : (r -> JSIO ()) -> Expect r -> XMLHttpRequest -> JSIO () */
function Web_MVC_Http_onload($0, $1, $2) {
 const $a = st => {
  let $b;
  switch(Prelude_EqOrd_x3ex3d_Ord_Bits16(st, 200)) {
   case 1: {
    $b = Prelude_EqOrd_x3c_Ord_Bits16(st, 300);
    break;
   }
   case 0: {
    $b = 0;
    break;
   }
  }
  switch($b) {
   case 0: return Web_MVC_Http_onerror($0, $1, {h: 2 /* BadStatus */, a1: st});
   case 1: return Web_MVC_Http_onsuccess($0, $1, $2);
  }
 };
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Xhr_XMLHttpRequest_status($2), $a);
}

/* Web.MVC.Http.onerror : (r -> JSIO ()) -> Expect r -> HTTPError -> JSIO () */
function Web_MVC_Http_onerror($0, $1, $2) {
 switch($1.h) {
  case 0: /* ExpectJSON */ return $0($1.a2({h: 0 /* Left */, a1: $2}));
  case 1: /* ExpectString */ return $0($1.a1({h: 0 /* Left */, a1: $2}));
  case 2: /* ExpectAny */ return $0($1.a1({h: 0 /* Left */, a1: $2}));
 }
}

/* Web.MVC.Http.bodyHeaders : RequestBody -> List Header */
function Web_MVC_Http_bodyHeaders($0) {
 switch($0.h) {
  case 0: /* Empty */ return {h: 0};
  case 1: /* StringBody */ return {a1: {a1: 'Content-Type', a2: $0.a1}, a2: {h: 0}};
  case 2: /* JSONBody */ return {a1: {a1: 'Content-Type', a2: 'application/json'}, a2: {h: 0}};
  case 3: /* FormBody */ return {h: 0};
 }
}

/* Web.MVC.Http.append : FormData -> Part -> JSIO () */
function Web_MVC_Http_append($0, $1) {
 switch($1.h) {
  case 0: /* StringPart */ return Web_Raw_Xhr_FormData_append($0, $1.a1, $1.a2);
  case 1: /* FilePart */ return Web_Raw_Xhr_FormData_append1($0, $1.a1, $1.a2);
 }
}

/* Web.MVC.Cmd.batch : List (Cmd e) -> Cmd e */
function Web_MVC_Cmd_batch($0, $1, $2) {
 return Control_Monad_Either_Extra_traverseList_($5 => $5($1), $0, $2);
}

/* Prelude.Uninhabited.void : (0 _ : Void) -> a */
const Prelude_Uninhabited_void$ = __lazy(function () {
 _crashExp('No clauses in Prelude.Uninhabited.void');
});

/* Prelude.Basics.uncurry : (a -> b -> c) -> (a, b) -> c */
function Prelude_Basics_uncurry($0, $1) {
 return $0($1.a1)($1.a2);
}

/* Prelude.Basics.flip : (a -> b -> c) -> b -> a -> c */
function Prelude_Basics_flip($0, $1, $2) {
 return $0($2)($1);
}

/* Builtin.swap : (a, b) -> (b, a) */
function Builtin_swap($0) {
 return {a1: $0.a2, a2: $0.a1};
}

/* Builtin.snd : (a, b) -> b */
function Builtin_snd($0) {
 return $0.a2;
}

/* Builtin.fst : (a, b) -> a */
function Builtin_fst($0) {
 return $0.a1;
}

/* Prelude.Types.traverse */
function Prelude_Types_traverse_Traversable_List($0, $1, $2) {
 switch($2.h) {
  case 0: /* nil */ return $0.a2(undefined)({h: 0});
  case undefined: /* cons */ return $0.a3(undefined)(undefined)($0.a3(undefined)(undefined)($0.a2(undefined)(csegen_74()))($1($2.a1)))(Prelude_Types_traverse_Traversable_List($0, $1, $2.a2));
 }
}

/* Prelude.Types.toList */
function Prelude_Types_toList_Foldable_Maybe($0) {
 return Prelude_Types_foldr_Foldable_Maybe(csegen_74(), {h: 0}, $0);
}

/* Prelude.Types.rangeFromTo */
function Prelude_Types_rangeFromTo_Range_Nat($0, $1) {
 switch(Prelude_EqOrd_compare_Ord_Integer($0, $1)) {
  case 0: return Prelude_Types_takeUntil($8 => Prelude_Types_x3ex3d_Ord_Nat($8, $1), Prelude_Types_countFrom($0, $10 => ($10+1n)));
  case 1: return Prelude_Types_pure_Applicative_List($0);
  case 2: return Prelude_Types_takeUntil($17 => Prelude_Types_x3cx3d_Ord_Nat($17, $1), Prelude_Types_countFrom($0, n => Prelude_Types_prim__integerToNat((n-1n))));
 }
}

/* Prelude.Types.rangeFromTo */
function Prelude_Types_rangeFromTo_Range_x24a($0, $1, $2) {
 const $4 = Builtin_fst(Builtin_snd($0));
 const $3 = $4.a2($1)($2);
 switch($3) {
  case 0: {
   const $e = $f => {
    const $10 = Builtin_fst(Builtin_snd($0));
    return $10.a6($f)($2);
   };
   const $1c = $1d => {
    const $1e = Builtin_snd(Builtin_snd($0));
    const $28 = Builtin_snd(Builtin_snd($0));
    const $27 = $28.a1.a3(1n);
    return $1e.a1.a1($1d)($27);
   };
   const $19 = Prelude_Types_countFrom($1, $1c);
   return Prelude_Types_takeUntil($e, $19);
  }
  case 1: return Prelude_Types_pure_Applicative_List($1);
  case 2: {
   const $33 = $34 => {
    const $35 = Builtin_fst(Builtin_snd($0));
    return $35.a5($34)($2);
   };
   const $41 = x => {
    const $42 = Builtin_snd(Builtin_snd($0));
    const $4b = Builtin_snd(Builtin_snd($0));
    const $4a = $4b.a1.a3(1n);
    return $42.a3(x)($4a);
   };
   const $3e = Prelude_Types_countFrom($1, $41);
   return Prelude_Types_takeUntil($33, $3e);
  }
 }
}

/* Prelude.Types.pure */
function Prelude_Types_pure_Applicative_List($0) {
 return {a1: $0, a2: {h: 0}};
}

/* Prelude.Types.null */
function Prelude_Types_null_Foldable_Maybe($0) {
 switch($0.h) {
  case 0: /* nothing */ return 1;
  case undefined: /* just */ return 0;
 }
}

/* Prelude.Types.null */
function Prelude_Types_null_Foldable_List($0) {
 switch($0.h) {
  case 0: /* nil */ return 1;
  case undefined: /* cons */ return 0;
 }
}

/* Prelude.Types.min */
function Prelude_Types_min_Ord_Nat($0, $1) {
 switch(Prelude_Types_x3c_Ord_Nat($0, $1)) {
  case 1: return $0;
  case 0: return $1;
 }
}

/* Prelude.Types.min */
function Prelude_Types_min_Ord_x28Listx20x24ax29($0, $1, $2) {
 switch(Prelude_Types_x3c_Ord_x28Listx20x24ax29($0, $1, $2)) {
  case 1: return $1;
  case 0: return $2;
 }
}

/* Prelude.Types.max */
function Prelude_Types_max_Ord_Nat($0, $1) {
 switch(Prelude_Types_x3e_Ord_Nat($0, $1)) {
  case 1: return $0;
  case 0: return $1;
 }
}

/* Prelude.Types.max */
function Prelude_Types_max_Ord_x28Listx20x24ax29($0, $1, $2) {
 switch(Prelude_Types_x3e_Ord_x28Listx20x24ax29($0, $1, $2)) {
  case 1: return $1;
  case 0: return $2;
 }
}

/* Prelude.Types.map */
function Prelude_Types_map_Functor_Maybe($0, $1) {
 switch($1.h) {
  case undefined: /* just */ return {a1: $0($1.a1)};
  case 0: /* nothing */ return {h: 0};
 }
}

/* Prelude.Types.foldr */
function Prelude_Types_foldr_Foldable_Maybe($0, $1, $2) {
 switch($2.h) {
  case 0: /* nothing */ return $1;
  case undefined: /* just */ return $0($2.a1)($1);
 }
}

/* Prelude.Types.foldr */
function Prelude_Types_foldr_Foldable_List($0, $1, $2) {
 switch($2.h) {
  case 0: /* nil */ return $1;
  case undefined: /* cons */ return $0($2.a1)(Prelude_Types_foldr_Foldable_List($0, $1, $2.a2));
 }
}

/* Prelude.Types.foldl */
function Prelude_Types_foldl_Foldable_Maybe($0, $1, $2) {
 return Prelude_Types_foldr_Foldable_Maybe($6 => $7 => Prelude_Basics_flip($a => $b => $c => $a($b($c)), $12 => Prelude_Basics_flip($0, $6, $12), $7), $19 => $19, $2)($1);
}

/* Prelude.Types.foldlM */
function Prelude_Types_foldlM_Foldable_Maybe($0, $1, $2, $3) {
 return Prelude_Types_foldl_Foldable_Maybe(ma => b => $0.a2(undefined)(undefined)(ma)($f => Prelude_Basics_flip($1, b, $f)), $0.a1.a2(undefined)($2), $3);
}

/* Prelude.Types.foldlM */
function Prelude_Types_foldlM_Foldable_List($0, $1, $2, $3) {
 return Prelude_Types_foldl_Foldable_List(ma => b => $0.a2(undefined)(undefined)(ma)($f => Prelude_Basics_flip($1, b, $f)), $0.a1.a2(undefined)($2), $3);
}

/* Prelude.Types.foldMap */
function Prelude_Types_foldMap_Foldable_Maybe($0, $1, $2) {
 return Prelude_Types_foldr_Foldable_Maybe($5 => $0.a1($1($5)), $0.a2, $2);
}

/* Prelude.Types.foldMap */
function Prelude_Types_foldMap_Foldable_List($0, $1, $2) {
 return Prelude_Types_foldl_Foldable_List(acc => elem => $0.a1(acc)($1(elem)), $0.a2, $2);
}

/* Prelude.Types.> */
function Prelude_Types_x3e_Ord_Nat($0, $1) {
 return Prelude_EqOrd_x3dx3d_Eq_Ordering(Prelude_EqOrd_compare_Ord_Integer($0, $1), 2);
}

/* Prelude.Types.> */
function Prelude_Types_x3e_Ord_x28Listx20x24ax29($0, $1, $2) {
 return Prelude_EqOrd_x3dx3d_Eq_Ordering(Prelude_Types_compare_Ord_x28Listx20x24ax29($0, $1, $2), 2);
}

/* Prelude.Types.>>= */
function Prelude_Types_x3ex3ex3d_Monad_Maybe($0, $1) {
 switch($0.h) {
  case 0: /* nothing */ return {h: 0};
  case undefined: /* just */ return $1($0.a1);
 }
}

/* Prelude.Types.>>= */
function Prelude_Types_x3ex3ex3d_Monad_x28Eitherx20x24ex29($0, $1) {
 switch($0.h) {
  case 0: /* Left */ return {h: 0 /* Left */, a1: $0.a1};
  case 1: /* Right */ return $1($0.a1);
 }
}

/* Prelude.Types.>= */
function Prelude_Types_x3ex3d_Ord_Nat($0, $1) {
 return Prelude_EqOrd_x2fx3d_Eq_Ordering(Prelude_EqOrd_compare_Ord_Integer($0, $1), 0);
}

/* Prelude.Types.>= */
function Prelude_Types_x3ex3d_Ord_x28Listx20x24ax29($0, $1, $2) {
 return Prelude_EqOrd_x2fx3d_Eq_Ordering(Prelude_Types_compare_Ord_x28Listx20x24ax29($0, $1, $2), 0);
}

/* Prelude.Types.< */
function Prelude_Types_x3c_Ord_Nat($0, $1) {
 return Prelude_EqOrd_x3dx3d_Eq_Ordering(Prelude_EqOrd_compare_Ord_Integer($0, $1), 0);
}

/* Prelude.Types.< */
function Prelude_Types_x3c_Ord_x28Listx20x24ax29($0, $1, $2) {
 return Prelude_EqOrd_x3dx3d_Eq_Ordering(Prelude_Types_compare_Ord_x28Listx20x24ax29($0, $1, $2), 0);
}

/* Prelude.Types.<= */
function Prelude_Types_x3cx3d_Ord_Nat($0, $1) {
 return Prelude_EqOrd_x2fx3d_Eq_Ordering(Prelude_EqOrd_compare_Ord_Integer($0, $1), 2);
}

/* Prelude.Types.<= */
function Prelude_Types_x3cx3d_Ord_x28Listx20x24ax29($0, $1, $2) {
 return Prelude_EqOrd_x2fx3d_Eq_Ordering(Prelude_Types_compare_Ord_x28Listx20x24ax29($0, $1, $2), 2);
}

/* Prelude.Types./= */
function Prelude_Types_x2fx3d_Eq_Nat($0, $1) {
 switch((($0===$1)?1:0)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.Types./= */
function Prelude_Types_x2fx3d_Eq_x28Listx20x24ax29($0, $1, $2) {
 switch(Prelude_Types_x3dx3d_Eq_x28Listx20x24ax29($0, $1, $2)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.Types.takeUntil : (n -> Bool) -> Stream n -> List n */
function Prelude_Types_takeUntil($0, $1) {
 switch($0($1.a1)) {
  case 1: return {a1: $1.a1, a2: {h: 0}};
  case 0: return {a1: $1.a1, a2: Prelude_Types_takeUntil($0, $1.a2())};
 }
}

/* Prelude.Types.List.tailRecAppend : List a -> List a -> List a */
function Prelude_Types_List_tailRecAppend($0, $1) {
 return Prelude_Types_List_reverseOnto($1, Prelude_Types_List_reverse($0));
}

/* Prelude.Types.List.reverse : List a -> List a */
function Prelude_Types_List_reverse($0) {
 return Prelude_Types_List_reverseOnto({h: 0}, $0);
}

/* Prelude.Types.prim__integerToNat : Integer -> Nat */
function Prelude_Types_prim__integerToNat($0) {
 switch(((0n<=$0)?1:0)) {
  case 0: return 0n;
  default: return $0;
 }
}

/* Prelude.Types.maybe : Lazy b -> Lazy (a -> b) -> Maybe a -> b */
function Prelude_Types_maybe($0, $1, $2) {
 switch($2.h) {
  case 0: /* nothing */ return $0();
  case undefined: /* just */ return $1()($2.a1);
 }
}

/* Prelude.Types.listBind : List a -> (a -> List b) -> List b */
function Prelude_Types_listBind($0, $1) {
 return Prelude_Types_listBindOnto($1, {h: 0}, $0);
}

/* Prelude.Types.List.lengthTR : List a -> Nat */
function Prelude_Types_List_lengthTR($0) {
 return Prelude_Types_List_lengthPlus(0n, $0);
}

/* Prelude.Types.String.length : String -> Nat */
function Prelude_Types_String_length($0) {
 return Prelude_Types_prim__integerToNat(BigInt($0.length));
}

/* Prelude.Types.isSpace : Char -> Bool */
function Prelude_Types_isSpace($0) {
 switch($0) {
  case ' ': return 1;
  case '\u{9}': return 1;
  case '\r': return 1;
  case '\n': return 1;
  case '\u{c}': return 1;
  case '\u{b}': return 1;
  case '\u{a0}': return 1;
  default: return 0;
 }
}

/* Prelude.Types.isDigit : Char -> Bool */
function Prelude_Types_isDigit($0) {
 switch(Prelude_EqOrd_x3ex3d_Ord_Char($0, '0')) {
  case 1: return Prelude_EqOrd_x3cx3d_Ord_Char($0, '9');
  case 0: return 0;
 }
}

/* Prelude.Types.isControl : Char -> Bool */
function Prelude_Types_isControl($0) {
 let $1;
 switch(Prelude_EqOrd_x3ex3d_Ord_Char($0, '\0')) {
  case 1: {
   $1 = Prelude_EqOrd_x3cx3d_Ord_Char($0, '\u{1f}');
   break;
  }
  case 0: {
   $1 = 0;
   break;
  }
 }
 switch($1) {
  case 1: return 1;
  case 0: {
   switch(Prelude_EqOrd_x3ex3d_Ord_Char($0, '\u{7f}')) {
    case 1: return Prelude_EqOrd_x3cx3d_Ord_Char($0, '\u{9f}');
    case 0: return 0;
   }
  }
 }
}

/* Prelude.Types.either : Lazy (a -> c) -> Lazy (b -> c) -> Either a b -> c */
function Prelude_Types_either($0, $1, $2) {
 switch($2.h) {
  case 0: /* Left */ return $0()($2.a1);
  case 1: /* Right */ return $1()($2.a1);
 }
}

/* Prelude.Types.countFrom : n -> (n -> n) -> Stream n */
function Prelude_Types_countFrom($0, $1) {
 return {a1: $0, a2: () => Prelude_Types_countFrom($1($0), $1)};
}

/* Prelude.Num.mod */
function Prelude_Num_mod_Integral_Bits8($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Bits8($1, 0)) {
  case 0: return ($0%$1);
  default: return _crashExp('Unhandled input for Prelude.Num.case block in mod at Prelude.Num:271:3--273:42');
 }
}

/* Prelude.Num.mod */
function Prelude_Num_mod_Integral_Bits32($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Bits32($1, 0)) {
  case 0: return ($0%$1);
  default: return _crashExp('Unhandled input for Prelude.Num.case block in mod at Prelude.Num:327:3--329:43');
 }
}

/* Prelude.Num.div */
function Prelude_Num_div_Integral_Bits8($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Bits8($1, 0)) {
  case 0: return _div8u($0, $1);
  default: return _crashExp('Unhandled input for Prelude.Num.case block in div at Prelude.Num:268:3--270:42');
 }
}

/* Prelude.Num.div */
function Prelude_Num_div_Integral_Bits32($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Bits32($1, 0)) {
  case 0: return _div32u($0, $1);
  default: return _crashExp('Unhandled input for Prelude.Num.case block in div at Prelude.Num:324:3--326:43');
 }
}

/* Prelude.EqOrd.min */
function Prelude_EqOrd_min_Ord_Bits8($0, $1) {
 switch(Prelude_EqOrd_x3c_Ord_Bits8($0, $1)) {
  case 1: return $0;
  case 0: return $1;
 }
}

/* Prelude.EqOrd.min */
function Prelude_EqOrd_min_Ord_Bits32($0, $1) {
 switch(Prelude_EqOrd_x3c_Ord_Bits32($0, $1)) {
  case 1: return $0;
  case 0: return $1;
 }
}

/* Prelude.EqOrd.max */
function Prelude_EqOrd_max_Ord_Bits8($0, $1) {
 switch(Prelude_EqOrd_x3e_Ord_Bits8($0, $1)) {
  case 1: return $0;
  case 0: return $1;
 }
}

/* Prelude.EqOrd.max */
function Prelude_EqOrd_max_Ord_Bits32($0, $1) {
 switch(Prelude_EqOrd_x3e_Ord_Bits32($0, $1)) {
  case 1: return $0;
  case 0: return $1;
 }
}

/* Prelude.EqOrd.compare */
function Prelude_EqOrd_compare_Ord_Integer($0, $1) {
 switch(Prelude_EqOrd_x3c_Ord_Integer($0, $1)) {
  case 1: return 0;
  case 0: {
   switch(Prelude_EqOrd_x3dx3d_Eq_Integer($0, $1)) {
    case 1: return 1;
    case 0: return 2;
   }
  }
 }
}

/* Prelude.EqOrd.compare */
function Prelude_EqOrd_compare_Ord_Bits8($0, $1) {
 switch(Prelude_EqOrd_x3c_Ord_Bits8($0, $1)) {
  case 1: return 0;
  case 0: {
   switch(Prelude_EqOrd_x3dx3d_Eq_Bits8($0, $1)) {
    case 1: return 1;
    case 0: return 2;
   }
  }
 }
}

/* Prelude.EqOrd.compare */
function Prelude_EqOrd_compare_Ord_Bits32($0, $1) {
 switch(Prelude_EqOrd_x3c_Ord_Bits32($0, $1)) {
  case 1: return 0;
  case 0: {
   switch(Prelude_EqOrd_x3dx3d_Eq_Bits32($0, $1)) {
    case 1: return 1;
    case 0: return 2;
   }
  }
 }
}

/* Prelude.EqOrd.> */
function Prelude_EqOrd_x3e_Ord_Char($0, $1) {
 switch((($0>$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.> */
function Prelude_EqOrd_x3e_Ord_Bits8($0, $1) {
 switch((($0>$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.> */
function Prelude_EqOrd_x3e_Ord_Bits32($0, $1) {
 switch((($0>$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.>= */
function Prelude_EqOrd_x3ex3d_Ord_Integer($0, $1) {
 switch((($0>=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.>= */
function Prelude_EqOrd_x3ex3d_Ord_Char($0, $1) {
 switch((($0>=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.>= */
function Prelude_EqOrd_x3ex3d_Ord_Bits8($0, $1) {
 switch((($0>=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.>= */
function Prelude_EqOrd_x3ex3d_Ord_Bits32($0, $1) {
 switch((($0>=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.>= */
function Prelude_EqOrd_x3ex3d_Ord_Bits16($0, $1) {
 switch((($0>=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_String($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Ordering($0, $1) {
 switch($0) {
  case 0: {
   switch($1) {
    case 0: return 1;
    default: return 0;
   }
  }
  case 1: {
   switch($1) {
    case 1: return 1;
    default: return 0;
   }
  }
  case 2: {
   switch($1) {
    case 2: return 1;
    default: return 0;
   }
  }
  default: return 0;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Integer($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Double($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Char($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Bits8($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.== */
function Prelude_EqOrd_x3dx3d_Eq_Bits32($0, $1) {
 switch((($0===$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.< */
function Prelude_EqOrd_x3c_Ord_Integer($0, $1) {
 switch((($0<$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.< */
function Prelude_EqOrd_x3c_Ord_Bits8($0, $1) {
 switch((($0<$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.< */
function Prelude_EqOrd_x3c_Ord_Bits32($0, $1) {
 switch((($0<$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.< */
function Prelude_EqOrd_x3c_Ord_Bits16($0, $1) {
 switch((($0<$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.<= */
function Prelude_EqOrd_x3cx3d_Ord_Char($0, $1) {
 switch((($0<=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.<= */
function Prelude_EqOrd_x3cx3d_Ord_Bits8($0, $1) {
 switch((($0<=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd.<= */
function Prelude_EqOrd_x3cx3d_Ord_Bits32($0, $1) {
 switch((($0<=$1)?1:0)) {
  case 0: return 0;
  default: return 1;
 }
}

/* Prelude.EqOrd./= */
function Prelude_EqOrd_x2fx3d_Eq_String($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_String($0, $1)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.EqOrd./= */
function Prelude_EqOrd_x2fx3d_Eq_Ordering($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Ordering($0, $1)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.EqOrd./= */
function Prelude_EqOrd_x2fx3d_Eq_Bits8($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Bits8($0, $1)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.EqOrd./= */
function Prelude_EqOrd_x2fx3d_Eq_Bits32($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Bits32($0, $1)) {
  case 1: return 0;
  case 0: return 1;
 }
}

/* Prelude.EqOrd.compareInteger : Integer -> Integer -> Ordering */
function Prelude_EqOrd_compareInteger($0, $1) {
 return Prelude_EqOrd_compare_Ord_Integer($0, $1);
}

/* Prelude.Interfaces.Bool.Semigroup.<+> */
function Prelude_Interfaces_Bool_Semigroup_x3cx2bx3e_Semigroup_AnyBool($0, $1) {
 switch($0) {
  case 1: return 1;
  case 0: return $1;
 }
}

/* Prelude.Interfaces.when : Applicative f => Bool -> Lazy (f ()) -> f () */
function Prelude_Interfaces_when($0, $1, $2) {
 switch($1) {
  case 1: return $2();
  case 0: return $0.a2(undefined)(undefined);
 }
}

/* Prelude.Interfaces.traverse_ : Applicative f => Foldable t => (a -> f b) -> t a -> f () */
function Prelude_Interfaces_traverse_($0, $1, $2) {
 return $1.a1(undefined)(undefined)($b => $c => Prelude_Interfaces_x2ax3e($0, $2($b), $c))($0.a2(undefined)(undefined));
}

/* Prelude.Interfaces.(*>) : Applicative f => f a -> f b -> f b */
function Prelude_Interfaces_x2ax3e($0, $1, $2) {
 const $d = $0.a1;
 const $c = $d(undefined)(undefined);
 const $b = $c($14 => $15 => $15);
 const $a = $b($1);
 const $4 = $0.a3(undefined)(undefined)($a);
 return $4($2);
}

/* Prelude.Show.2434:11880:asciiTab */
function Prelude_Show_n__2434_11880_asciiTab($0) {
 return {a1: 'NUL', a2: {a1: 'SOH', a2: {a1: 'STX', a2: {a1: 'ETX', a2: {a1: 'EOT', a2: {a1: 'ENQ', a2: {a1: 'ACK', a2: {a1: 'BEL', a2: {a1: 'BS', a2: {a1: 'HT', a2: {a1: 'LF', a2: {a1: 'VT', a2: {a1: 'FF', a2: {a1: 'CR', a2: {a1: 'SO', a2: {a1: 'SI', a2: {a1: 'DLE', a2: {a1: 'DC1', a2: {a1: 'DC2', a2: {a1: 'DC3', a2: {a1: 'DC4', a2: {a1: 'NAK', a2: {a1: 'SYN', a2: {a1: 'ETB', a2: {a1: 'CAN', a2: {a1: 'EM', a2: {a1: 'SUB', a2: {a1: 'ESC', a2: {a1: 'FS', a2: {a1: 'GS', a2: {a1: 'RS', a2: {a1: 'US', a2: {h: 0}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}};
}

/* Prelude.Show.show */
function Prelude_Show_show_Show_String($0) {
 return ('\"'+Prelude_Show_showLitString(Prelude_Types_fastUnpack($0))('\"'));
}

/* Prelude.Show.show */
function Prelude_Show_show_Show_Nat($0) {
 return Prelude_Show_show_Show_Integer($0);
}

/* Prelude.Show.show */
function Prelude_Show_show_Show_Integer($0) {
 return Prelude_Show_showPrec_Show_Integer({h: 0 /* Open */}, $0);
}

/* Prelude.Show.show */
function Prelude_Show_show_Show_Int($0) {
 return Prelude_Show_showPrec_Show_Int({h: 0 /* Open */}, $0);
}

/* Prelude.Show.show */
function Prelude_Show_show_Show_Double($0) {
 return Prelude_Show_showPrec_Show_Double({h: 0 /* Open */}, $0);
}

/* Prelude.Show.show */
function Prelude_Show_show_Show_Bits16($0) {
 return Prelude_Show_showPrec_Show_Bits16({h: 0 /* Open */}, $0);
}

/* Prelude.Show.showPrec */
function Prelude_Show_showPrec_Show_Integer($0, $1) {
 return Prelude_Show_primNumShow($4 => (''+$4), $0, $1);
}

/* Prelude.Show.showPrec */
function Prelude_Show_showPrec_Show_Int($0, $1) {
 return Prelude_Show_primNumShow($4 => (''+$4), $0, $1);
}

/* Prelude.Show.showPrec */
function Prelude_Show_showPrec_Show_Double($0, $1) {
 return Prelude_Show_primNumShow($4 => (''+$4), $0, $1);
}

/* Prelude.Show.showPrec */
function Prelude_Show_showPrec_Show_Bits16($0, $1) {
 return Prelude_Show_primNumShow($4 => (''+$4), $0, $1);
}

/* Prelude.Show.compare */
function Prelude_Show_compare_Ord_Prec($0, $1) {
 switch($0.h) {
  case 4: /* User */ {
   switch($1.h) {
    case 4: /* User */ return Prelude_EqOrd_compare_Ord_Integer($0.a1, $1.a1);
    default: return Prelude_EqOrd_compare_Ord_Integer(Prelude_Show_precCon($0), Prelude_Show_precCon($1));
   }
  }
  default: return Prelude_EqOrd_compare_Ord_Integer(Prelude_Show_precCon($0), Prelude_Show_precCon($1));
 }
}

/* Prelude.Show.>= */
function Prelude_Show_x3ex3d_Ord_Prec($0, $1) {
 return Prelude_EqOrd_x2fx3d_Eq_Ordering(Prelude_Show_compare_Ord_Prec($0, $1), 0);
}

/* Prelude.Show.showParens : Bool -> String -> String */
function Prelude_Show_showParens($0, $1) {
 switch($0) {
  case 0: return $1;
  case 1: return ('('+($1+')'));
 }
}

/* Prelude.Show.showLitString : List Char -> String -> String */
function Prelude_Show_showLitString($0) {
 return $1 => {
  switch($0.h) {
   case 0: /* nil */ return $1;
   case undefined: /* cons */ {
    switch($0.a1) {
     case '\"': return ('\u{5c}\"'+Prelude_Show_showLitString($0.a2)($1));
     default: return Prelude_Show_showLitChar($0.a1)(Prelude_Show_showLitString($0.a2)($1));
    }
   }
  }
 };
}

/* Prelude.Show.showLitChar : Char -> String -> String */
function Prelude_Show_showLitChar($0) {
 switch($0) {
  case '\u{7}': return $2 => ('\u{5c}a'+$2);
  case '\u{8}': return $5 => ('\u{5c}b'+$5);
  case '\u{c}': return $8 => ('\u{5c}f'+$8);
  case '\n': return $b => ('\u{5c}n'+$b);
  case '\r': return $e => ('\u{5c}r'+$e);
  case '\u{9}': return $11 => ('\u{5c}t'+$11);
  case '\u{b}': return $14 => ('\u{5c}v'+$14);
  case '\u{e}': return $17 => Prelude_Show_protectEsc($1a => Prelude_EqOrd_x3dx3d_Eq_Char($1a, 'H'), '\u{5c}SO', $17);
  case '\u{7f}': return $20 => ('\u{5c}DEL'+$20);
  case '\u{5c}': return $23 => ('\u{5c}\u{5c}'+$23);
  default: {
   return $26 => {
    const $27 = Prelude_Types_getAt(Prelude_Types_prim__integerToNat(BigInt($0.codePointAt(0))), Prelude_Show_n__2434_11880_asciiTab($0));
    switch($27.h) {
     case undefined: /* just */ return ('\u{5c}'+($27.a1+$26));
     case 0: /* nothing */ {
      switch(Prelude_EqOrd_x3e_Ord_Char($0, '\u{7f}')) {
       case 1: return ('\u{5c}'+Prelude_Show_protectEsc($3c => Prelude_Types_isDigit($3c), Prelude_Show_show_Show_Int(_truncInt32($0.codePointAt(0))), $26));
       case 0: return ($0+$26);
      }
     }
    }
   };
  }
 }
}

/* Prelude.Show.protectEsc : (Char -> Bool) -> String -> String -> String */
function Prelude_Show_protectEsc($0, $1, $2) {
 let $5;
 switch(Prelude_Show_firstCharIs($0, $2)) {
  case 1: {
   $5 = '\u{5c}&';
   break;
  }
  case 0: {
   $5 = '';
   break;
  }
 }
 const $4 = ($5+$2);
 return ($1+$4);
}

/* Prelude.Show.primNumShow : (a -> String) -> Prec -> a -> String */
function Prelude_Show_primNumShow($0, $1, $2) {
 const $3 = $0($2);
 let $7;
 switch(Prelude_Show_x3ex3d_Ord_Prec($1, {h: 5 /* PrefixMinus */})) {
  case 1: {
   $7 = Prelude_Show_firstCharIs($e => Prelude_EqOrd_x3dx3d_Eq_Char($e, '-'), $3);
   break;
  }
  case 0: {
   $7 = 0;
   break;
  }
 }
 return Prelude_Show_showParens($7, $3);
}

/* Prelude.Show.precCon : Prec -> Integer */
function Prelude_Show_precCon($0) {
 switch($0.h) {
  case 0: /* Open */ return 0n;
  case 1: /* Equal */ return 1n;
  case 2: /* Dollar */ return 2n;
  case 3: /* Backtick */ return 3n;
  case 4: /* User */ return 4n;
  case 5: /* PrefixMinus */ return 5n;
  case 6: /* App */ return 6n;
 }
}

/* Prelude.Show.firstCharIs : (Char -> Bool) -> String -> Bool */
function Prelude_Show_firstCharIs($0, $1) {
 switch($1) {
  case '': return 0;
  default: return $0(($1.charAt(0)));
 }
}

/* Prelude.IO.map */
function Prelude_IO_map_Functor_IO($0, $1, $2) {
 const $3 = $1($2);
 return $0($3);
}

/* PrimIO.unsafePerformIO : IO a -> a */
function PrimIO_unsafePerformIO($0) {
 return PrimIO_unsafeCreateWorld(w => $0(w));
}

/* PrimIO.unsafeCreateWorld : (1 _ : ((1 _ : %World) -> a)) -> a */
function PrimIO_unsafeCreateWorld($0) {
 return $0(_idrisworld);
}

/* JS.Util.unMaybe : String -> JSIO (Maybe a) -> JSIO a */
function JS_Util_unMaybe($0, $1) {
 const $7 = $8 => {
  switch($8.h) {
   case undefined: /* just */ return Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $8.a1);
   case 0: /* nothing */ return Control_Monad_Error_Interface_throwError_MonadError_x24e_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), {h: 2 /* IsNothing */, a1: $0});
  }
 };
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $1, $7);
}

/* JS.Util.runJSWith : Lazy (JSErr -> IO a) -> JSIO a -> IO a */
function JS_Util_runJSWith($0, $1, $2) {
 const $3 = $1($2);
 return Prelude_Types_either(() => $0(), () => $b => $c => $b, $3)($2);
}

/* JS.Util.runJS : JSIO () -> IO () */
function JS_Util_runJS($0, $1) {
 return JS_Util_runJSWith(() => $4 => JS_Util_consoleLog(csegen_111()(), JS_Util_dispErr($4)), $0, $1);
}

/* JS.Util.dispErr : JSErr -> String */
function JS_Util_dispErr($0) {
 switch($0.h) {
  case 1: /* CastErr */ return Prelude_Types_foldMap_Foldable_List(csegen_114(), $6 => $6, {a1: 'Error when casting a Javascript value in function ', a2: {a1: $0.a1, a2: {a1: '.\n  The value was: ', a2: {a1: JS_Util_prim__show($0.a2), a2: {a1: '.\n  The value\'s type was ', a2: {a1: JS_Util_prim__typeOf($0.a2), a2: {a1: '.', a2: {h: 0}}}}}}}});
  case 2: /* IsNothing */ return Prelude_Types_foldMap_Foldable_List(csegen_114(), $1e => $1e, {a1: 'Trying to extract a value from Nothing at ', a2: {a1: $0.a1, a2: {h: 0}}});
  case 0: /* Caught */ return $0.a1;
 }
}

/* JS.Util.consoleLog : HasIO io => String -> io () */
function JS_Util_consoleLog($0, $1) {
 return $0.a2(undefined)($7 => JS_Util_prim__consoleLog($1, $7));
}

/* Data.Maybe.fromMaybe : Lazy a -> Maybe a -> a */
function Data_Maybe_fromMaybe($0, $1) {
 switch($1.h) {
  case 0: /* nothing */ return $0();
  case undefined: /* just */ return $1.a1;
 }
}

/* Control.Monad.Error.Interface.throwError */
function Control_Monad_Error_Interface_throwError_MonadError_x24e_x28x28EitherTx20x24ex29x20x24mx29($0, $1) {
 return $0.a1.a2(undefined)({h: 0 /* Left */, a1: $1});
}

/* Data.Vect.map */
function Data_Vect_map_Functor_x28Vectx20x24nx29($0, $1) {
 switch($1.h) {
  case 0: /* nil */ return {h: 0};
  case undefined: /* cons */ return {a1: $0($1.a1), a2: Data_Vect_map_Functor_x28Vectx20x24nx29($0, $1.a2)};
 }
}

/* Data.Vect.reverse : Vect len elem -> Vect len elem */
function Data_Vect_reverse($0) {
 return Data_Vect_reverseOnto({h: 0}, $0);
}

/* Data.Vect.fromList : (xs : List elem) -> Vect (length xs) elem */
function Data_Vect_fromList($0) {
 return Data_Vect_reverse(Data_Vect_fromListx27({h: 0}, $0));
}

/* Data.List.7787:8508:split */
function Data_List_n__7787_8508_split($0, $1, $2) {
 return Data_List_n__7787_8509_splitRec($0, $1, $2, $2, $9 => $9);
}

/* Data.List.zipWith */
function Data_List_zipWith_Zippable_List($0, $1, $2) {
 switch($1.h) {
  case 0: /* nil */ return {h: 0};
  default: {
   switch($2.h) {
    case 0: /* nil */ return {h: 0};
    default: return {a1: $0($1.a1)($2.a1), a2: Data_List_zipWith_Zippable_List($0, $1.a2, $2.a2)};
   }
  }
 }
}

/* Data.List.sortBy : (a -> a -> Ordering) -> List a -> List a */
function Data_List_sortBy($0, $1) {
 switch($1.h) {
  case 0: /* nil */ return {h: 0};
  case undefined: /* cons */ {
   switch($1.a2.h) {
    case 0: /* nil */ return {a1: $1.a1, a2: {h: 0}};
    default: {
     const $6 = Data_List_n__7787_8508_split($1, $0, $1);
     return Data_List_mergeBy($0, Data_List_sortBy($0, $6.a1), Data_List_sortBy($0, $6.a2));
    }
   }
  }
  default: {
   const $15 = Data_List_n__7787_8508_split($1, $0, $1);
   return Data_List_mergeBy($0, Data_List_sortBy($0, $15.a1), Data_List_sortBy($0, $15.a2));
  }
 }
}

/* Data.List.sort : Ord a => List a -> List a */
function Data_List_sort($0, $1) {
 return Data_List_sortBy($0.a2, $1);
}

/* Data.List.mergeBy : (a -> a -> Ordering) -> List a -> List a -> List a */
function Data_List_mergeBy($0, $1, $2) {
 switch($1.h) {
  case 0: /* nil */ return $2;
  default: {
   switch($2.h) {
    case 0: /* nil */ return $1;
    default: {
     switch($0($1.a1)($2.a1)) {
      case 0: return {a1: $1.a1, a2: Data_List_mergeBy($0, $1.a2, {a1: $2.a1, a2: $2.a2})};
      default: return {a1: $2.a1, a2: Data_List_mergeBy($0, {a1: $1.a1, a2: $1.a2}, $2.a2)};
     }
    }
   }
  }
 }
}

/* Data.List.lookup : Eq a => a -> List (a, b) -> Maybe b */
function Data_List_lookup($0, $1, $2) {
 return Data_List_lookupBy($0.a1, $1, $2);
}

/* Data.List.appendNilRightNeutral : (l : List a) -> l ++ [] = l */
function Data_List_appendNilRightNeutral($0) {
 switch($0.h) {
  case 0: /* nil */ return undefined;
  case undefined: /* cons */ return undefined;
 }
}

/* Data.List.appendAssociative : (l : List a) -> (c : List a) -> (r : List a) -> l ++ (c ++ r) = (l ++ c) ++ r */
function Data_List_appendAssociative($0, $1, $2) {
 switch($0.h) {
  case 0: /* nil */ return undefined;
  case undefined: /* cons */ return undefined;
 }
}

/* Control.Monad.Error.Either.pure */
function Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29($0, $1) {
 return $0.a2(undefined)({h: 1 /* Right */, a1: $1});
}

/* Control.Monad.Error.Either.map */
function Control_Monad_Error_Either_map_Functor_x28x28EitherTx20x24ex29x20x24mx29($0, $1, $2) {
 const $9 = $a => {
  switch($a.h) {
   case 0: /* Left */ return {h: 0 /* Left */, a1: $a.a1};
   case 1: /* Right */ return {h: 1 /* Right */, a1: $1($a.a1)};
  }
 };
 const $3 = $0(undefined)(undefined)($9);
 return $3($2);
}

/* Control.Monad.Error.Either.liftIO */
function Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29($0, $1) {
 const $6 = $7 => {
  const $8 = $1($7);
  return {h: 1 /* Right */, a1: $8};
 };
 return $0.a2(undefined)($6);
}

/* Control.Monad.Error.Either.>>= */
function Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29($0, $1, $2) {
 return $0.a2(undefined)(undefined)($1)($c => Prelude_Types_either(() => $f => $0.a1.a2(undefined)({h: 0 /* Left */, a1: $f}), () => $18 => $2($18), $c));
}

/* Control.Monad.Error.Either.<*> */
function Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29($0, $1, $2) {
 return $0.a3(undefined)(undefined)($0.a3(undefined)(undefined)($0.a2(undefined)(csegen_115()))($1))($2);
}

/* JS.Union.toFFI */
function JS_Union_toFFI_ToFFI_x28HSumx20x28x28x3ax3ax20x24ax29x20x28x28x3ax3ax20x24bx29x20Nilx29x29x29_x28x28Union2x20x24mx29x20x24nx29($0, $1) {
 return JS_Union_toUnion2(JS_Union_appToFFI($0, $1));
}

/* JS.Union.toFFI */
function JS_Union_toFFI_ToFFI_x28HSumx20x28x28x3ax3ax20x24ax29x20x28x28x3ax3ax20x24bx29x20x28x28x3ax3ax20x24cx29x20x28x28x3ax3ax20x24dx29x20x28x28x3ax3ax20x24ex29x20x28x28x3ax3ax20x24fx29x20x28x28x3ax3ax20x24gx29x20x28x28x3ax3ax20x24hx29x20x28x28x3ax3ax20x24ix29x20x28x28x3ax3ax20x24jx29x20x28x28x3ax3ax20x24kx29x20x28x28x3ax3ax20x24lx29x20x28x28x3ax3ax20x24a1x29x20x28x28x3ax3ax20x24a2x29x20x28x28x3ax3ax20x24a3x29x20x28x28x3ax3ax20x24a4x29x20Nilx29x29x29x29x29x29x29x29x29x29x29x29x29x29x29x29x29_x28x28x28x28x28x28x28x28x28x28x28x28x28x28x28x28Union16x20x24mx29x20x24nx29x20x24ox29x20x24px29x20x24qx29x20x24rx29x20x24sx29x20x24tx29x20x24ux29x20x24vx29x20x24wx29x20x24xx29x20x24yx29x20x24zx29x20x24z1x29x20x24z2x29($0, $1) {
 return JS_Union_toUnion16(JS_Union_appToFFI($0, $1));
}

/* JS.Union.toUnion2 : HSum [a, b] -> Union2 a b */
function JS_Union_toUnion2($0) {
 return Data_List_Quantifiers_Extra_Any_collapse($3 => $4 => $4, Data_List_Quantifiers_Any_mapProperty($8 => $9 => $9, $0));
}

/* JS.Union.toUnion16 : HSum [a,
      b,
      c,
      d,
      e,
      f,
      g,
      h,
      i,
      j,
      k,
      l,
      a1,
      a2,
      a3,
      a4] -> Union16 a b c d e f g h i j k l a1 a2 a3 a4 */
function JS_Union_toUnion16($0) {
 return Data_List_Quantifiers_Extra_Any_collapse($3 => $4 => $4, Data_List_Quantifiers_Any_mapProperty($8 => $9 => $9, $0));
}

/* JS.Union.appToFFI : NPP ToFFI ps1 ps2 -> HSum ps1 -> HSum ps2 */
function JS_Union_appToFFI($0, $1) {
 switch($0.h) {
  case undefined: /* cons */ {
   switch($1.h) {
    case 0: /* Here */ return {h: 0 /* Here */, a1: $0.a1($1.a1)};
    case 1: /* There */ return {h: 1 /* There */, a1: JS_Union_appToFFI($0.a2, $1.a1)};
   }
  }
  case 0: /* nil */ return Prelude_Uninhabited_void$();
 }
}

/* JS.Marshall.fromFFI */
function JS_Marshall_fromFFI_FromFFI_String_String($0) {
 return {a1: $0};
}

/* JS.Marshall.fromFFI */
function JS_Marshall_fromFFI_FromFFI_Double_Double($0) {
 return {a1: $0};
}

/* JS.Marshall.fromFFI */
function JS_Marshall_fromFFI_FromFFI_Bits32_Bits32($0) {
 return {a1: $0};
}

/* JS.Marshall.tryJS : FromFFI a ffiRepr => Lazy String -> PrimIO ffiRepr -> JSIO a */
function JS_Marshall_tryJS($0, $1, $2) {
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $2), $e => JS_Marshall_tryFromFFI($0, $1, $e));
}

/* JS.Marshall.tryFromFFI : FromFFI a ffiRepr => Lazy String -> ffiRepr -> JSIO a */
function JS_Marshall_tryFromFFI($0, $1, $2) {
 const $3 = $0($2);
 switch($3.h) {
  case 0: /* nothing */ return Control_Monad_Error_Interface_throwError_MonadError_x24e_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), {h: 1 /* CastErr */, a1: $1(), a2: $2});
  case undefined: /* just */ return Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $3.a1);
 }
}

/* JS.Inheritance.unsafeCastOnPrototypeName : String -> a -> Maybe b */
function JS_Inheritance_unsafeCastOnPrototypeName($0, $1) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Double(JS_Inheritance_prim__hasProtoName($0, $1), 1.0)) {
  case 1: return {a1: $1};
  case 0: return {h: 0};
 }
}

/* JS.Inheritance.tryCast_ : (0 a : Type) -> SafeCast a => Lazy String -> x -> JSIO a */
function JS_Inheritance_tryCast_($0, $1, $2) {
 return JS_Inheritance_tryCast($0, $1, $2);
}

/* JS.Inheritance.tryCast : SafeCast a => Lazy String -> x -> JSIO a */
function JS_Inheritance_tryCast($0, $1, $2) {
 const $3 = $0(undefined)($2);
 switch($3.h) {
  case undefined: /* just */ return Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $3.a1);
  case 0: /* nothing */ return Control_Monad_Error_Interface_throwError_MonadError_x24e_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), {h: 1 /* CastErr */, a1: $1(), a2: $2});
 }
}

/* Data.String.with block in asList */
function Data_String_with__asList_9840($0, $1) {
 switch($0) {
  case '': {
   switch($1.h) {
    case 0: /* nil */ return {h: 0 /* Nil */};
    default: return {h: 1 /* :: */, a1: $1.a1, a2: $1.a2, a3: () => Data_String_asList($1.a2)};
   }
  }
  default: return {h: 1 /* :: */, a1: $1.a1, a2: $1.a2, a3: () => Data_String_asList($1.a2)};
 }
}

/* Data.String.trim : String -> String */
function Data_String_trim($0) {
 return Data_String_ltrim(Data_String_rtrim($0));
}

/* Data.String.strM : (x : String) -> StrM x */
function Data_String_strM($0) {
 switch($0) {
  case '': return {h: 0};
  default: return {a1: ($0.charAt(0)), a2: ($0.slice(1))};
 }
}

/* Data.String.singleton : Char -> String */
function Data_String_singleton($0) {
 return ($0+'');
}

/* Data.String.rtrim : String -> String */
function Data_String_rtrim($0) {
 return _strReverse(Data_String_ltrim(_strReverse($0)));
}

/* Data.String.ltrim : String -> String */
function Data_String_ltrim($0) {
 return Data_String_with__ltrim_9864($0, Data_String_asList($0));
}

/* Data.String.asList : (str : String) -> AsList str */
function Data_String_asList($0) {
 return Data_String_with__asList_9840($0, Data_String_strM($0));
}

/* Data.List.Quantifiers.Extra.inject : Has t ts => f t -> Any f ts */
function Data_List_Quantifiers_Extra_inject($0, $1) {
 switch($0) {
  case 0n: return {h: 0 /* Here */, a1: $1};
  default: {
   const $4 = ($0-1n);
   return {h: 1 /* There */, a1: Data_List_Quantifiers_Extra_inject($4, $1)};
  }
 }
}

/* Data.List.Quantifiers.Any.mapProperty : ((x `p`) -> q x) -> Any p l -> Any q l */
function Data_List_Quantifiers_Any_mapProperty($0, $1) {
 switch($1.h) {
  case 0: /* Here */ return {h: 0 /* Here */, a1: $0(undefined)($1.a1)};
  case 1: /* There */ return {h: 1 /* There */, a1: Data_List_Quantifiers_Any_mapProperty($b => $0(undefined), $1.a1)};
 }
}

/* JS.Undefined.toFFI */
function JS_Undefined_toFFI_ToFFI_x28Optionalx20x24ax29_x28UndefOrx20x24bx29($0, $1) {
 return JS_Undefined_optionalToUndefOr(JS_Undefined_map_Functor_Optional($0, $1));
}

/* JS.Undefined.map */
function JS_Undefined_map_Functor_Optional($0, $1) {
 switch($1.h) {
  case 0: /* nothing */ return {h: 0};
  case undefined: /* just */ return {a1: $0($1.a1)};
 }
}

/* JS.Undefined.undef : UndefOr a */
const JS_Undefined_undef = __lazy(function () {
 return JS_Undefined_undefined();
});

/* JS.Undefined.optionalToUndefOr : Optional a -> UndefOr a */
function JS_Undefined_optionalToUndefOr($0) {
 return JS_Undefined_optional(() => JS_Undefined_undef(), $5 => $5, $0);
}

/* JS.Undefined.optional : Lazy b -> (a -> b) -> Optional a -> b */
function JS_Undefined_optional($0, $1, $2) {
 switch($2.h) {
  case 0: /* nothing */ return $0();
  case undefined: /* just */ return $1($2.a1);
 }
}

/* JS.Nullable.toFFI */
function JS_Nullable_toFFI_ToFFI_x28Maybex20x24ax29_x28Nullablex20x24bx29($0, $1) {
 return JS_Nullable_maybeToNullable(Prelude_Types_map_Functor_Maybe($0, $1));
}

/* JS.Nullable.fromFFI */
function JS_Nullable_fromFFI_FromFFI_x28Maybex20x24ax29_x28Nullablex20x24bx29($0, $1) {
 const $2 = JS_Nullable_nullableToMaybe($1);
 switch($2.h) {
  case 0: /* nothing */ return {a1: {h: 0}};
  case undefined: /* just */ return Prelude_Types_map_Functor_Maybe($8 => ({a1: $8}), $0($2.a1));
 }
}

/* JS.Nullable.nullableToMaybe : Nullable a -> Maybe a */
function JS_Nullable_nullableToMaybe($0) {
 switch(JS_Nullable_isNull($0)) {
  case 1: return {h: 0};
  case 0: return {a1: $0};
 }
}

/* JS.Nullable.null : Nullable a */
const JS_Nullable_null$ = __lazy(function () {
 return JS_Nullable_prim__null();
});

/* JS.Nullable.maybeToNullable : Maybe a -> Nullable a */
function JS_Nullable_maybeToNullable($0) {
 return Prelude_Types_maybe(() => JS_Nullable_null$(), () => $5 => $5, $0);
}

/* JS.Nullable.isNull : a -> Bool */
function JS_Nullable_isNull($0) {
 return JS_Util_prim__eqv(JS_Nullable_prim__null(), $0);
}

/* JS.Boolean.fromFFI */
function JS_Boolean_fromFFI_FromFFI_Bool_Boolean($0) {
 switch(JS_Util_prim__eqv($0, JS_Boolean_true$())) {
  case 1: return {a1: 1};
  case 0: {
   switch(JS_Util_prim__eqv($0, JS_Boolean_false$())) {
    case 1: return {a1: 0};
    case 0: return {h: 0};
   }
  }
 }
}

/* JS.Array.5323:8128:fill */
function JS_Array_n__5323_8128_fill($0, $1, $2, $3, $4) {
 switch($3.h) {
  case 0: /* nil */ return $0.a1.a1.a2(undefined)($4);
  case undefined: /* cons */ return $0.a1.a2(undefined)(undefined)(JS_Array_writeIO($0, $4, $2, $3.a1))($1c => JS_Array_n__5323_8128_fill($0, $1, _add32u($2, 1), $3.a2, $4));
 }
}

/* JS.Array.toFFI */
function JS_Array_toFFI_ToFFI_x28Listx20x24ax29_x28IOx20x28Arrayx20x24bx29x29($0, $1) {
 return JS_Array_fromListIO(csegen_111()(), Prelude_Types_List_mapAppend({h: 0}, $0, $1));
}

/* JS.Array.writeIO : HasIO io => Array a -> Bits32 -> a -> io () */
function JS_Array_writeIO($0, $1, $2, $3) {
 return $0.a2(undefined)($9 => JS_Array_prim__writeIO(undefined, $1, $2, $3, $9));
}

/* JS.Array.newArrayIO : HasIO io => Bits32 -> io (Array a) */
function JS_Array_newArrayIO($0, $1) {
 return $0.a2(undefined)($7 => JS_Array_prim__newArrayIO(undefined, $1, $7));
}

/* JS.Array.fromListIO : HasIO io => List a -> io (Array a) */
function JS_Array_fromListIO($0, $1) {
 const $2 = Number(_truncUBigInt32(Prelude_Types_List_lengthTR($1)));
 return $0.a1.a2(undefined)(undefined)(JS_Array_newArrayIO($0, $2))($13 => JS_Array_n__5323_8128_fill($0, $1, 0, $1, $13));
}

/* JS.Attribute.to : (obj -> Attribute b f a) -> obj -> JSIO (f a) */
function JS_Attribute_to($0, $1) {
 return Prelude_Basics_flip($4 => $5 => JS_Attribute_get($4, $5), $0, $1);
}

/* JS.Attribute.set : Attribute b f a -> a -> JSIO () */
function JS_Attribute_set($0, $1) {
 switch($0.h) {
  case 0: /* Attr */ return $0.a2($1);
  case 1: /* NullableAttr */ return $0.a2({a1: $1});
  case 2: /* OptionalAttr */ return $0.a2({a1: $1});
  case 3: /* OptionalAttrNoDefault */ return $0.a2({a1: $1});
 }
}

/* JS.Attribute.get : obj -> (obj -> Attribute b f a) -> JSIO (f a) */
function JS_Attribute_get($0, $1) {
 const $2 = $1($0);
 switch($2.h) {
  case 0: /* Attr */ return $2.a1;
  case 1: /* NullableAttr */ return $2.a1;
  case 2: /* OptionalAttr */ return $2.a1;
  case 3: /* OptionalAttrNoDefault */ return $2.a1;
 }
}

/* JS.Attribute.fromPrim : ToFFI a b => FromFFI a b =>
String -> (obj -> PrimIO b) -> (obj -> b -> PrimIO ()) -> obj -> Attribute True id a */
function JS_Attribute_fromPrim($0, $1, $2, $3, $4, $5) {
 return {h: 0 /* Attr */, a1: JS_Marshall_tryJS($1, () => $2, $3($5)), a2: a => Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $4($5)($0(a)))};
}

/* JS.Attribute.fromNullablePrim : ToFFI a b => FromFFI a b =>
String -> (obj -> PrimIO (Nullable b)) -> (obj -> Nullable b -> PrimIO ()) -> obj -> Attribute False Maybe a */
function JS_Attribute_fromNullablePrim($0, $1, $2, $3, $4, $5) {
 return {h: 1 /* NullableAttr */, a1: JS_Marshall_tryJS($9 => JS_Nullable_fromFFI_FromFFI_x28Maybex20x24ax29_x28Nullablex20x24bx29($1, $9), () => $2, $3($5)), a2: a => Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $4($5)(JS_Nullable_toFFI_ToFFI_x28Maybex20x24ax29_x28Nullablex20x24bx29($0, a)))};
}

/* JS.Attribute.(?>) : Callback a (x -> y) => Attribute b f a -> y -> JSIO () */
function JS_Attribute_x3fx3e($0, $1, $2) {
 return JS_Attribute_x21x3e($0, $1, $7 => $2);
}

/* JS.Attribute.(.=) : Attribute b f a -> a -> JSIO () */
function JS_Attribute_x2ex3d($0, $1) {
 return JS_Attribute_set($0, $1);
}

/* JS.Attribute.(!>) : Callback a fun => Attribute b f a -> fun -> JSIO () */
function JS_Attribute_x21x3e($0, $1, $2) {
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $0($2), $b => JS_Attribute_set($1, $b));
}

/* Control.Monad.Either.Extra.traverseList_ : (t -> EitherT e IO ()) -> List t -> EitherT e IO () */
function Control_Monad_Either_Extra_traverseList_($0, $1, $2) {
 return Control_Monad_Either_Extra_implList_($0, $1, $2);
}

/* Web.Raw.Xhr.XMLHttpRequest.timeout : XMLHttpRequest -> Attribute True id Bits32 */
function Web_Raw_Xhr_XMLHttpRequest_timeout($0) {
 return JS_Attribute_fromPrim($3 => $3, $5 => JS_Marshall_fromFFI_FromFFI_Bits32_Bits32($5), 'XMLHttpRequest.gettimeout', $a => $b => Web_Internal_XhrPrim_XMLHttpRequest_prim__timeout($a, $b), $10 => $11 => $12 => Web_Internal_XhrPrim_XMLHttpRequest_prim__setTimeout($10, $11, $12), $0);
}

/* Web.Raw.Xhr.XMLHttpRequest.status : XMLHttpRequest -> JSIO Bits16 */
function Web_Raw_Xhr_XMLHttpRequest_status($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_XhrPrim_XMLHttpRequest_prim__status($0, $6));
}

/* Web.Raw.Xhr.XMLHttpRequest.setRequestHeader : XMLHttpRequest -> ByteString -> ByteString -> JSIO () */
function Web_Raw_Xhr_XMLHttpRequest_setRequestHeader($0, $1, $2) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $8 => Web_Internal_XhrPrim_XMLHttpRequest_prim__setRequestHeader($0, $1, $2, $8));
}

/* Web.Raw.Xhr.XMLHttpRequest.send' : XMLHttpRequest -> Optional (Maybe (HSum [Document,
                                         Blob,
                                         Int8Array,
                                         Int16Array,
                                         Int32Array,
                                         UInt8Array,
                                         UInt8Array,
                                         UInt8Array,
                                         UInt8ClampedArray,
                                         Float32Array,
                                         Float64Array,
                                         DataView,
                                         ArrayBuffer,
                                         FormData,
                                         URLSearchParams,
                                         String])) -> JSIO () */
function Web_Raw_Xhr_XMLHttpRequest_sendx27($0, $1) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $7 => Web_Internal_XhrPrim_XMLHttpRequest_prim__send($0, JS_Undefined_toFFI_ToFFI_x28Optionalx20x24ax29_x28UndefOrx20x24bx29($d => JS_Nullable_toFFI_ToFFI_x28Maybex20x24ax29_x28Nullablex20x24bx29($10 => JS_Union_toFFI_ToFFI_x28HSumx20x28x28x3ax3ax20x24ax29x20x28x28x3ax3ax20x24bx29x20x28x28x3ax3ax20x24cx29x20x28x28x3ax3ax20x24dx29x20x28x28x3ax3ax20x24ex29x20x28x28x3ax3ax20x24fx29x20x28x28x3ax3ax20x24gx29x20x28x28x3ax3ax20x24hx29x20x28x28x3ax3ax20x24ix29x20x28x28x3ax3ax20x24jx29x20x28x28x3ax3ax20x24kx29x20x28x28x3ax3ax20x24lx29x20x28x28x3ax3ax20x24a1x29x20x28x28x3ax3ax20x24a2x29x20x28x28x3ax3ax20x24a3x29x20x28x28x3ax3ax20x24a4x29x20Nilx29x29x29x29x29x29x29x29x29x29x29x29x29x29x29x29x29_x28x28x28x28x28x28x28x28x28x28x28x28x28x28x28x28Union16x20x24mx29x20x24nx29x20x24ox29x20x24px29x20x24qx29x20x24rx29x20x24sx29x20x24tx29x20x24ux29x20x24vx29x20x24wx29x20x24xx29x20x24yx29x20x24zx29x20x24z1x29x20x24z2x29({a1: $14 => $14, a2: {a1: $17 => $17, a2: {a1: $1a => $1a, a2: {a1: $1d => $1d, a2: {a1: $20 => $20, a2: {a1: $23 => $23, a2: {a1: $26 => $26, a2: {a1: $29 => $29, a2: {a1: $2c => $2c, a2: {a1: $2f => $2f, a2: {a1: $32 => $32, a2: {a1: $35 => $35, a2: {a1: $38 => $38, a2: {a1: $3b => $3b, a2: csegen_119()}}}}}}}}}}}}}}, $10), $d), $1), $7));
}

/* Web.Raw.Xhr.XMLHttpRequest.send : XMLHttpRequest -> JSIO () */
function Web_Raw_Xhr_XMLHttpRequest_send($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_XhrPrim_XMLHttpRequest_prim__send($0, JS_Undefined_undef(), $6));
}

/* Web.Raw.Xhr.XMLHttpRequest.responseText : XMLHttpRequest -> JSIO String */
function Web_Raw_Xhr_XMLHttpRequest_responseText($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_XhrPrim_XMLHttpRequest_prim__responseText($0, $6));
}

/* Web.Raw.Xhr.XMLHttpRequest.open_ : XMLHttpRequest -> ByteString -> String -> JSIO () */
function Web_Raw_Xhr_XMLHttpRequest_open_($0, $1, $2) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $8 => Web_Internal_XhrPrim_XMLHttpRequest_prim__open($0, $1, $2, $8));
}

/* Web.Raw.Xhr.XMLHttpRequestEventTarget.ontimeout : {auto 0 conArg : JSType t} ->
{auto 0 _ : Elem XMLHttpRequestEventTarget (Types t)} ->
t -> Attribute False Maybe EventHandlerNonNull */
function Web_Raw_Xhr_XMLHttpRequestEventTarget_ontimeout($0) {
 return JS_Attribute_fromNullablePrim($3 => $3, $5 => Web_Internal_HtmlTypes_fromFFI_FromFFI_EventHandlerNonNull_EventHandlerNonNull($5), 'XMLHttpRequestEventTarget.getontimeout', $a => $b => Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__ontimeout($a, $b), $10 => $11 => $12 => Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__setOntimeout($10, $11, $12), $0);
}

/* Web.Raw.Xhr.XMLHttpRequestEventTarget.onload : {auto 0 conArg : JSType t} ->
{auto 0 _ : Elem XMLHttpRequestEventTarget (Types t)} ->
t -> Attribute False Maybe EventHandlerNonNull */
function Web_Raw_Xhr_XMLHttpRequestEventTarget_onload($0) {
 return JS_Attribute_fromNullablePrim($3 => $3, $5 => Web_Internal_HtmlTypes_fromFFI_FromFFI_EventHandlerNonNull_EventHandlerNonNull($5), 'XMLHttpRequestEventTarget.getonload', $a => $b => Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__onload($a, $b), $10 => $11 => $12 => Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__setOnload($10, $11, $12), $0);
}

/* Web.Raw.Xhr.XMLHttpRequestEventTarget.onerror : {auto 0 conArg : JSType t} ->
{auto 0 _ : Elem XMLHttpRequestEventTarget (Types t)} ->
t -> Attribute False Maybe EventHandlerNonNull */
function Web_Raw_Xhr_XMLHttpRequestEventTarget_onerror($0) {
 return JS_Attribute_fromNullablePrim($3 => $3, $5 => Web_Internal_HtmlTypes_fromFFI_FromFFI_EventHandlerNonNull_EventHandlerNonNull($5), 'XMLHttpRequestEventTarget.getonerror', $a => $b => Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__onerror($a, $b), $10 => $11 => $12 => Web_Internal_XhrPrim_XMLHttpRequestEventTarget_prim__setOnerror($10, $11, $12), $0);
}

/* Web.Raw.Xhr.XMLHttpRequest.new : JSIO XMLHttpRequest */
const Web_Raw_Xhr_XMLHttpRequest_new$ = __lazy(function () {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $5 => Web_Internal_XhrPrim_XMLHttpRequest_prim__new($5));
});

/* Web.Raw.Xhr.FormData.new : JSIO FormData */
const Web_Raw_Xhr_FormData_new$ = __lazy(function () {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $5 => Web_Internal_XhrPrim_FormData_prim__new(JS_Undefined_undef(), $5));
});

/* Web.Raw.Xhr.FormData.append1 : {auto 0 conArg : JSType t3} -> {auto 0 _ : Elem Blob (Types t3)} ->
FormData -> String -> t3 -> JSIO () */
function Web_Raw_Xhr_FormData_append1($0, $1, $2) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $8 => Web_Internal_XhrPrim_FormData_prim__append1($0, $1, $2, JS_Undefined_undef(), $8));
}

/* Web.Raw.Xhr.FormData.append : FormData -> String -> String -> JSIO () */
function Web_Raw_Xhr_FormData_append($0, $1, $2) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $8 => Web_Internal_XhrPrim_FormData_prim__append($0, $1, $2, $8));
}

/* Web.Internal.UIEventsTypes.safeCast */
function Web_Internal_UIEventsTypes_safeCast_SafeCast_WheelEvent($0) {
 return JS_Inheritance_unsafeCastOnPrototypeName('WheelEvent', $0);
}

/* Web.Internal.UIEventsTypes.safeCast */
function Web_Internal_UIEventsTypes_safeCast_SafeCast_MouseEvent($0) {
 return JS_Inheritance_unsafeCastOnPrototypeName('MouseEvent', $0);
}

/* Web.Internal.UIEventsTypes.safeCast */
function Web_Internal_UIEventsTypes_safeCast_SafeCast_KeyboardEvent($0) {
 return JS_Inheritance_unsafeCastOnPrototypeName('KeyboardEvent', $0);
}

/* Web.Internal.HtmlTypes.safeCast */
function Web_Internal_HtmlTypes_safeCast_SafeCast_HTMLTemplateElement($0) {
 return JS_Inheritance_unsafeCastOnPrototypeName('HTMLTemplateElement', $0);
}

/* Web.Internal.HtmlTypes.fromFFI */
function Web_Internal_HtmlTypes_fromFFI_FromFFI_HTMLElement_HTMLElement($0) {
 return {a1: $0};
}

/* Web.Internal.HtmlTypes.fromFFI */
function Web_Internal_HtmlTypes_fromFFI_FromFFI_EventHandlerNonNull_EventHandlerNonNull($0) {
 return {a1: $0};
}

/* Web.Internal.DomTypes.safeCast */
function Web_Internal_DomTypes_safeCast_SafeCast_Event($0) {
 return JS_Inheritance_unsafeCastOnPrototypeName('Event', $0);
}

/* Web.Internal.DomTypes.safeCast */
function Web_Internal_DomTypes_safeCast_SafeCast_Element($0) {
 return JS_Inheritance_unsafeCastOnPrototypeName('Element', $0);
}

/* Web.Internal.DomTypes.fromFFI */
function Web_Internal_DomTypes_fromFFI_FromFFI_EventTarget_EventTarget($0) {
 return {a1: $0};
}

/* Web.Internal.DomTypes.fromFFI */
function Web_Internal_DomTypes_fromFFI_FromFFI_Element_Element($0) {
 return {a1: $0};
}

/* Web.Html.callback */
function Web_Html_callback_Callback_EventHandlerNonNull_x28x25pix20RigWx20Explicitx20Nothingx20Eventx20x28JSIOx20x28x7cUnitx2cMkUnitx7cx29x29x29($0) {
 return Web_Raw_Html_EventHandlerNonNull_toEventHandlerNonNull($3 => $4 => Prelude_IO_map_Functor_IO($7 => $7, $9 => JS_Util_runJS($0($3), $9), $4));
}

/* Web.Raw.Html.EventHandlerNonNull.toEventHandlerNonNull : (Event -> IO AnyPtr) -> JSIO EventHandlerNonNull */
function Web_Raw_Html_EventHandlerNonNull_toEventHandlerNonNull($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_HtmlPrim_EventHandlerNonNull_prim__toEventHandlerNonNull($0, $6));
}

/* Web.Raw.Html.HTMLTemplateElement.content : HTMLTemplateElement -> JSIO DocumentFragment */
function Web_Raw_Html_HTMLTemplateElement_content($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_HtmlPrim_HTMLTemplateElement_prim__content($0, $6));
}

/* JSON.Simple.ToJSON.taggedObject : String -> String -> String -> JSON -> JSON */
function JSON_Simple_ToJSON_taggedObject($0, $1, $2, $3) {
 return {h: 6 /* JObject */, a1: {a1: {a1: $0, a2: {h: 4 /* JString */, a1: $2}}, a2: {a1: {a1: $1, a2: $3}, a2: {h: 0}}}};
}

/* Language.Reflection.Derive.mkShowPrec : (Prec -> a -> String) -> Show a */
function Language_Reflection_Derive_mkShowPrec($0) {
 return {a1: $0({h: 0 /* Open */}), a2: $0};
}

/* Language.Reflection.Derive.mkOrd : Eq a => (a -> a -> Ordering) -> Ord a */
function Language_Reflection_Derive_mkOrd($0, $1) {
 const $24 = a => b => {
  switch(Prelude_EqOrd_x3dx3d_Eq_Ordering($1(a)(b), 2)) {
   case 1: return a;
   case 0: return b;
  }
 };
 const $2d = a => b => {
  switch(Prelude_EqOrd_x3dx3d_Eq_Ordering($1(a)(b), 0)) {
   case 1: return a;
   case 0: return b;
  }
 };
 return {a1: $0, a2: $1, a3: a => b => Prelude_EqOrd_x3dx3d_Eq_Ordering($1(a)(b), 0), a4: a => b => Prelude_EqOrd_x3dx3d_Eq_Ordering($1(a)(b), 2), a5: a => b => Prelude_EqOrd_x2fx3d_Eq_Ordering($1(a)(b), 2), a6: a => b => Prelude_EqOrd_x2fx3d_Eq_Ordering($1(a)(b), 0), a7: $24, a8: $2d};
}

/* JSON.Parser.showValue : SnocList String -> JSON -> SnocList String */
function JSON_Parser_showValue($0, $1) {
 switch($1.h) {
  case 0: /* JNull */ return {a1: $0, a2: 'null'};
  case 1: /* JInteger */ return {a1: $0, a2: Prelude_Show_show_Show_Integer($1.a1)};
  case 2: /* JDouble */ return {a1: $0, a2: Prelude_Show_show_Show_Double($1.a1)};
  case 3: /* JBool */ {
   switch($1.a1) {
    case 1: return {a1: $0, a2: 'true'};
    case 0: return {a1: $0, a2: 'false'};
   }
  }
  case 4: /* JString */ return {a1: $0, a2: JSON_Parser_encode($1.a1)};
  case 5: /* JArray */ {
   switch($1.a1.h) {
    case 0: /* nil */ return {a1: $0, a2: '[]'};
    case undefined: /* cons */ {
     const $19 = JSON_Parser_showValue({a1: $0, a2: '['}, $1.a1.a1);
     return JSON_Parser_showArray($19, $1.a1.a2);
    }
   }
  }
  case 6: /* JObject */ {
   switch($1.a1.h) {
    case 0: /* nil */ return {a1: $0, a2: '{}'};
    case undefined: /* cons */ {
     const $25 = JSON_Parser_showPair({a1: $0, a2: '{'}, $1.a1.a1);
     return JSON_Parser_showObject($25, $1.a1.a2);
    }
   }
  }
 }
}

/* JSON.Parser.showPair : SnocList String -> (String, JSON) -> SnocList String */
function JSON_Parser_showPair($0, $1) {
 return JSON_Parser_showValue({a1: {a1: $0, a2: JSON_Parser_encode($1.a1)}, a2: ':'}, $1.a2);
}

/* JSON.Parser.showImpl : JSON -> String */
function JSON_Parser_showImpl($0) {
 return Prelude_Types_fastConcat(Prelude_Types_SnocList_x3cx3ex3e(JSON_Parser_showValue({h: 0}, $0), {h: 0}));
}

/* JSON.Parser.jsonTrans : Lex1 q JSz SK */
const JSON_Parser_jsonTrans = __lazy(function () {
 const $2a = $2b => {
  const $2d = ($2b.a1.value);
  const $32 = ($2b.a1.value=($2d+1n));
  const $2c = ($2b.a2.value=0n);
  return JSON_Parser_JIni();
 };
 const $29 = {h: 0 /* Go */, a1: $2a};
 const $26 = {a1: csegen_185(), a2: $29};
 const $25 = {a1: $26, a2: {h: 0}};
 const $d = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $13 => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $1c => $1c, JSON_Parser_JIni(), $13, ($13.a8.value))}}, a2: $25};
 const $b = Prelude_Types_List_tailRecAppend($d, csegen_248());
 const $9 = Text_ILex_Lexer_dfa($b);
 const $6 = {a1: JSON_Parser_JIni(), a2: $9};
 const $68 = $69 => {
  const $6b = ($69.a1.value);
  const $70 = ($69.a1.value=($6b+1n));
  const $6a = ($69.a2.value=0n);
  return JSON_Parser_JDone();
 };
 const $67 = {h: 0 /* Go */, a1: $68};
 const $64 = {a1: csegen_185(), a2: $67};
 const $63 = {a1: $64, a2: {h: 0}};
 const $4b = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $51 => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $5a => $5a, JSON_Parser_JDone(), $51, ($51.a8.value))}}, a2: $63};
 const $49 = Prelude_Types_List_tailRecAppend($4b, {h: 0});
 const $47 = Text_ILex_Lexer_dfa($49);
 const $44 = {a1: JSON_Parser_JDone(), a2: $47};
 const $a5 = $a6 => {
  const $a8 = ($a6.a1.value);
  const $ad = ($a6.a1.value=($a8+1n));
  const $a7 = ($a6.a2.value=0n);
  return JSON_Parser_ANew();
 };
 const $a4 = {h: 0 /* Go */, a1: $a5};
 const $a1 = {a1: csegen_185(), a2: $a4};
 const $a0 = {a1: $a1, a2: {h: 0}};
 const $88 = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $8e => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $97 => $97, JSON_Parser_ANew(), $8e, ($8e.a8.value))}}, a2: $a0};
 const $86 = Prelude_Types_List_tailRecAppend($88, Prelude_Types_List_tailRecAppend(csegen_247(), csegen_275()));
 const $84 = Text_ILex_Lexer_dfa($86);
 const $81 = {a1: JSON_Parser_ANew(), a2: $84};
 const $e7 = $e8 => {
  const $ea = ($e8.a1.value);
  const $ef = ($e8.a1.value=($ea+1n));
  const $e9 = ($e8.a2.value=0n);
  return JSON_Parser_ACom();
 };
 const $e6 = {h: 0 /* Go */, a1: $e7};
 const $e3 = {a1: csegen_185(), a2: $e6};
 const $e2 = {a1: $e3, a2: {h: 0}};
 const $ca = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $d0 => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $d9 => $d9, JSON_Parser_ACom(), $d0, ($d0.a8.value))}}, a2: $e2};
 const $c8 = Prelude_Types_List_tailRecAppend($ca, csegen_248());
 const $c6 = Text_ILex_Lexer_dfa($c8);
 const $c3 = {a1: JSON_Parser_ACom(), a2: $c6};
 const $125 = $126 => {
  const $128 = ($126.a1.value);
  const $12d = ($126.a1.value=($128+1n));
  const $127 = ($126.a2.value=0n);
  return JSON_Parser_AVal();
 };
 const $124 = {h: 0 /* Go */, a1: $125};
 const $121 = {a1: csegen_185(), a2: $124};
 const $120 = {a1: $121, a2: {h: 0}};
 const $108 = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $10e => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $117 => $117, JSON_Parser_AVal(), $10e, ($10e.a8.value))}}, a2: $120};
 const $141 = $142 => {
  const $144 = $142.a2;
  const $146 = ($144.value);
  const $143 = ($144.value=($146+1n));
  return JSON_Parser_ACom();
 };
 const $140 = {h: 0 /* Go */, a1: $141};
 const $13d = {a1: csegen_299(), a2: $140};
 const $13c = {a1: $13d, a2: csegen_275()};
 const $106 = Prelude_Types_List_tailRecAppend($108, $13c);
 const $104 = Text_ILex_Lexer_dfa($106);
 const $101 = {a1: JSON_Parser_AVal(), a2: $104};
 const $178 = $179 => {
  const $17b = ($179.a1.value);
  const $180 = ($179.a1.value=($17b+1n));
  const $17a = ($179.a2.value=0n);
  return JSON_Parser_ONew();
 };
 const $177 = {h: 0 /* Go */, a1: $178};
 const $174 = {a1: csegen_185(), a2: $177};
 const $173 = {a1: $174, a2: {h: 0}};
 const $15b = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $161 => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $16a => $16a, JSON_Parser_ONew(), $161, ($161.a8.value))}}, a2: $173};
 const $159 = Prelude_Types_List_tailRecAppend($15b, {a1: csegen_316(), a2: csegen_240()});
 const $157 = Text_ILex_Lexer_dfa($159);
 const $154 = {a1: JSON_Parser_ONew(), a2: $157};
 const $1b9 = $1ba => {
  const $1bc = ($1ba.a1.value);
  const $1c1 = ($1ba.a1.value=($1bc+1n));
  const $1bb = ($1ba.a2.value=0n);
  return JSON_Parser_OVal();
 };
 const $1b8 = {h: 0 /* Go */, a1: $1b9};
 const $1b5 = {a1: csegen_185(), a2: $1b8};
 const $1b4 = {a1: $1b5, a2: {h: 0}};
 const $19c = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $1a2 => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $1ab => $1ab, JSON_Parser_OVal(), $1a2, ($1a2.a8.value))}}, a2: $1b4};
 const $1d8 = $1d9 => {
  const $1db = $1d9.a2;
  const $1dd = ($1db.value);
  const $1da = ($1db.value=($1dd+1n));
  return JSON_Parser_OCom();
 };
 const $1d7 = {h: 0 /* Go */, a1: $1d8};
 const $1d4 = {a1: csegen_299(), a2: $1d7};
 const $1d3 = {a1: $1d4, a2: {h: 0}};
 const $1d0 = {a1: csegen_316(), a2: $1d3};
 const $19a = Prelude_Types_List_tailRecAppend($19c, $1d0);
 const $198 = Text_ILex_Lexer_dfa($19a);
 const $195 = {a1: JSON_Parser_OVal(), a2: $198};
 const $20e = $20f => {
  const $211 = ($20f.a1.value);
  const $216 = ($20f.a1.value=($211+1n));
  const $210 = ($20f.a2.value=0n);
  return JSON_Parser_OCom();
 };
 const $20d = {h: 0 /* Go */, a1: $20e};
 const $20a = {a1: csegen_185(), a2: $20d};
 const $209 = {a1: $20a, a2: {h: 0}};
 const $1f1 = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $1f7 => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $200 => $200, JSON_Parser_OCom(), $1f7, ($1f7.a8.value))}}, a2: $209};
 const $1ef = Prelude_Types_List_tailRecAppend($1f1, csegen_240());
 const $1ed = Text_ILex_Lexer_dfa($1ef);
 const $1ea = {a1: JSON_Parser_OCom(), a2: $1ed};
 const $24c = $24d => {
  const $24f = ($24d.a1.value);
  const $254 = ($24d.a1.value=($24f+1n));
  const $24e = ($24d.a2.value=0n);
  return JSON_Parser_OLbl();
 };
 const $24b = {h: 0 /* Go */, a1: $24c};
 const $248 = {a1: csegen_185(), a2: $24b};
 const $247 = {a1: $248, a2: {h: 0}};
 const $22f = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $235 => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $23e => $23e, JSON_Parser_OLbl(), $235, ($235.a8.value))}}, a2: $247};
 const $26b = $26c => {
  const $26e = $26c.a2;
  const $270 = ($26e.value);
  const $26d = ($26e.value=($270+1n));
  return JSON_Parser_OCol();
 };
 const $26a = {h: 0 /* Go */, a1: $26b};
 const $264 = {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32(':'.codePointAt(0)))}, a2: $26a};
 const $263 = {a1: $264, a2: {h: 0}};
 const $22d = Prelude_Types_List_tailRecAppend($22f, $263);
 const $22b = Text_ILex_Lexer_dfa($22d);
 const $228 = {a1: JSON_Parser_OLbl(), a2: $22b};
 const $2a1 = $2a2 => {
  const $2a4 = ($2a2.a1.value);
  const $2a9 = ($2a2.a1.value=($2a4+1n));
  const $2a3 = ($2a2.a2.value=0n);
  return JSON_Parser_OCol();
 };
 const $2a0 = {h: 0 /* Go */, a1: $2a1};
 const $29d = {a1: csegen_185(), a2: $2a0};
 const $29c = {a1: $29d, a2: {h: 0}};
 const $284 = {a1: {a1: csegen_168(), a2: {h: 1 /* Rd */, a1: $28a => Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874(csegen_168(), csegen_175(), csegen_177(), $293 => $293, JSON_Parser_OCol(), $28a, ($28a.a8.value))}}, a2: $29c};
 const $282 = Prelude_Types_List_tailRecAppend($284, csegen_248());
 const $280 = Text_ILex_Lexer_dfa($282);
 const $27d = {a1: JSON_Parser_OCol(), a2: $280};
 const $2c5 = $2c6 => {
  const $2c9 = $2c6.a2;
  const $2cb = ($2c9.value);
  const $2c8 = ($2c9.value=($2cb+1n));
  const $2d5 = ($2c6.a3.value);
  let $2c7;
  switch($2d5.h) {
   case undefined: /* cons */ {
    $2c7 = ($2c6.a3.value=$2d5.a1);
    break;
   }
   default: $2c7 = undefined;
  }
  const $2e2 = ($2c6.a6.value);
  const $2e7 = ($2c6.a6.value={h: 0});
  const $2e1 = $2e2;
  const $2e0 = Text_ILex_Util_snocPack($2e1);
  const $2ef = ($2c6.a4.value);
  switch($2ef.h) {
   case 1: /* PO */ {
    const $2f5 = ($2c6.a4.value={h: 2 /* PL */, a1: $2ef.a1, a2: $2ef.a2, a3: $2e0});
    return JSON_Parser_OLbl();
   }
   default: {
    switch($2ef.h) {
     case 0: /* PA */ {
      const $300 = ($2c6.a4.value={h: 0 /* PA */, a1: $2ef.a1, a2: {a1: $2ef.a2, a2: {h: 4 /* JString */, a1: $2e0}}});
      return JSON_Parser_AVal();
     }
     case 2: /* PL */ {
      const $30c = ($2c6.a4.value={h: 1 /* PO */, a1: $2ef.a1, a2: {a1: $2ef.a2, a2: {a1: $2ef.a3, a2: {h: 4 /* JString */, a1: $2e0}}}});
      return JSON_Parser_OVal();
     }
     case 4: /* PV */ {
      const $31a = ($2c6.a4.value={h: 4 /* PV */, a1: {a1: $2ef.a1, a2: {h: 4 /* JString */, a1: $2e0}}});
      return JSON_Parser_JIni();
     }
     default: {
      const $325 = ($2c6.a4.value={h: 5 /* PF */, a1: {h: 4 /* JString */, a1: $2e0}});
      return JSON_Parser_JDone();
     }
    }
   }
  }
 };
 const $2c4 = {h: 0 /* Go */, a1: $2c5};
 const $2c1 = {a1: csegen_236(), a2: $2c4};
 const $337 = $338 => {
  const $339 = ($338.a8.value);
  const $33e = Data_ByteString_toString($339);
  const $343 = ($338.a6.value);
  const $342 = ($338.a6.value={a1: $343, a2: $33e});
  const $341 = JSON_Parser_JStr();
  const $351 = $338.a2;
  const $353 = ($351.value);
  const $350 = ($351.value=(Prelude_Types_String_length($33e)+$353));
  return $341;
 };
 const $336 = {h: 1 /* Rd */, a1: $337};
 const $32f = {a1: {h: 2 /* And */, a1: JSON_Parser_jchar(), a2: {h: 4 /* Star */, a1: JSON_Parser_jchar()}}, a2: $336};
 const $367 = $368 => {
  const $36a = $368.a2;
  const $36c = ($36a.value);
  const $369 = ($36a.value=($36c+2n));
  const $377 = ($368.a6.value);
  const $376 = ($368.a6.value={a1: $377, a2: '\"'});
  return JSON_Parser_JStr();
 };
 const $366 = {h: 0 /* Go */, a1: $367};
 const $360 = {a1: {h: 2 /* And */, a1: csegen_382(), a2: csegen_236()}, a2: $366};
 const $38c = $38d => {
  const $38f = $38d.a2;
  const $391 = ($38f.value);
  const $38e = ($38f.value=($391+2n));
  const $39c = ($38d.a6.value);
  const $39b = ($38d.a6.value={a1: $39c, a2: '\n'});
  return JSON_Parser_JStr();
 };
 const $38b = {h: 0 /* Go */, a1: $38c};
 const $385 = {a1: {h: 2 /* And */, a1: csegen_382(), a2: csegen_191()}, a2: $38b};
 const $3b1 = $3b2 => {
  const $3b4 = $3b2.a2;
  const $3b6 = ($3b4.value);
  const $3b3 = ($3b4.value=($3b6+2n));
  const $3c1 = ($3b2.a6.value);
  const $3c0 = ($3b2.a6.value={a1: $3c1, a2: '\u{c}'});
  return JSON_Parser_JStr();
 };
 const $3b0 = {h: 0 /* Go */, a1: $3b1};
 const $3aa = {a1: {h: 2 /* And */, a1: csegen_382(), a2: csegen_209()}, a2: $3b0};
 const $3d9 = $3da => {
  const $3dc = $3da.a2;
  const $3de = ($3dc.value);
  const $3db = ($3dc.value=($3de+2n));
  const $3e9 = ($3da.a6.value);
  const $3e8 = ($3da.a6.value={a1: $3e9, a2: '\u{8}'});
  return JSON_Parser_JStr();
 };
 const $3d8 = {h: 0 /* Go */, a1: $3d9};
 const $3cf = {a1: {h: 2 /* And */, a1: csegen_382(), a2: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('b'.codePointAt(0)))}}, a2: $3d8};
 const $3fe = $3ff => {
  const $401 = $3ff.a2;
  const $403 = ($401.value);
  const $400 = ($401.value=($403+2n));
  const $40e = ($3ff.a6.value);
  const $40d = ($3ff.a6.value={a1: $40e, a2: '\r'});
  return JSON_Parser_JStr();
 };
 const $3fd = {h: 0 /* Go */, a1: $3fe};
 const $3f7 = {a1: {h: 2 /* And */, a1: csegen_382(), a2: csegen_201()}, a2: $3fd};
 const $423 = $424 => {
  const $426 = $424.a2;
  const $428 = ($426.value);
  const $425 = ($426.value=($428+2n));
  const $433 = ($424.a6.value);
  const $432 = ($424.a6.value={a1: $433, a2: '\u{9}'});
  return JSON_Parser_JStr();
 };
 const $422 = {h: 0 /* Go */, a1: $423};
 const $41c = {a1: {h: 2 /* And */, a1: csegen_382(), a2: csegen_200()}, a2: $422};
 const $448 = $449 => {
  const $44b = $449.a2;
  const $44d = ($44b.value);
  const $44a = ($44b.value=($44d+2n));
  const $458 = ($449.a6.value);
  const $457 = ($449.a6.value={a1: $458, a2: '\u{5c}'});
  return JSON_Parser_JStr();
 };
 const $447 = {h: 0 /* Go */, a1: $448};
 const $441 = {a1: {h: 2 /* And */, a1: csegen_382(), a2: csegen_382()}, a2: $447};
 const $470 = $471 => {
  const $473 = $471.a2;
  const $475 = ($473.value);
  const $472 = ($473.value=($475+2n));
  const $480 = ($471.a6.value);
  const $47f = ($471.a6.value={a1: $480, a2: '/'});
  return JSON_Parser_JStr();
 };
 const $46f = {h: 0 /* Go */, a1: $470};
 const $466 = {a1: {h: 2 /* And */, a1: csegen_382(), a2: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('/'.codePointAt(0)))}}, a2: $46f};
 const $492 = $493 => {
  const $494 = ($493.a8.value);
  const $49b = ($493.a6.value);
  const $49a = ($493.a6.value={a1: $49b, a2: JSON_Parser_decode($494)});
  const $499 = JSON_Parser_JStr();
  const $4ab = $493.a2;
  const $4ad = ($4ab.value);
  const $4aa = ($4ab.value=($494.a1+$4ad));
  return $499;
 };
 const $491 = {h: 1 /* Rd */, a1: $492};
 const $48e = {a1: JSON_Parser_codepoint(), a2: $491};
 const $48d = {a1: $48e, a2: {h: 0}};
 const $465 = {a1: $466, a2: $48d};
 const $440 = {a1: $441, a2: $465};
 const $41b = {a1: $41c, a2: $440};
 const $3f6 = {a1: $3f7, a2: $41b};
 const $3ce = {a1: $3cf, a2: $3f6};
 const $3a9 = {a1: $3aa, a2: $3ce};
 const $384 = {a1: $385, a2: $3a9};
 const $35f = {a1: $360, a2: $384};
 const $32e = {a1: $32f, a2: $35f};
 const $2c0 = {a1: $2c1, a2: $32e};
 const $2be = Text_ILex_Lexer_dfa($2c0);
 const $2bb = {a1: JSON_Parser_JStr(), a2: $2be};
 const $2ba = {a1: $2bb, a2: {h: 0}};
 const $27c = {a1: $27d, a2: $2ba};
 const $227 = {a1: $228, a2: $27c};
 const $1e9 = {a1: $1ea, a2: $227};
 const $194 = {a1: $195, a2: $1e9};
 const $153 = {a1: $154, a2: $194};
 const $100 = {a1: $101, a2: $153};
 const $c2 = {a1: $c3, a2: $100};
 const $80 = {a1: $81, a2: $c2};
 const $43 = {a1: $44, a2: $80};
 const $5 = {a1: $6, a2: $43};
 return Text_ILex_Parser_arr32(11, Text_ILex_Lexer_dfa({h: 0}), $5);
});

/* JSON.Parser.jsonErr : Arr32 JSz (SK q -> F1 q (BoundedErr Void)) */
const JSON_Parser_jsonErr = __lazy(function () {
 return Text_ILex_Parser_arr32(11, $3 => $4 => Text_ILex_Interfaces_unexpected(csegen_446(), csegen_175(), csegen_177(), {h: 0}, $3, $4), {a1: {a1: JSON_Parser_ANew(), a2: csegen_448()}, a2: {a1: {a1: JSON_Parser_AVal(), a2: $1a => $1b => Text_ILex_Interfaces_unclosedIfEOI(csegen_446(), csegen_175(), csegen_177(), '[', {a1: ',', a2: {a1: ']', a2: {h: 0}}}, $1a, $1b)}, a2: {a1: {a1: JSON_Parser_ACom(), a2: csegen_448()}, a2: {a1: {a1: JSON_Parser_ONew(), a2: $36 => $37 => Text_ILex_Interfaces_unclosedIfEOI(csegen_446(), csegen_175(), csegen_177(), '{', {a1: '\"', a2: {a1: '}', a2: {h: 0}}}, $36, $37)}, a2: {a1: {a1: JSON_Parser_OVal(), a2: $4c => $4d => Text_ILex_Interfaces_unclosedIfEOI(csegen_446(), csegen_175(), csegen_177(), '{', {a1: ',', a2: {a1: '}', a2: {h: 0}}}, $4c, $4d)}, a2: {a1: {a1: JSON_Parser_OCom(), a2: $62 => $63 => Text_ILex_Interfaces_unclosedIfEOI(csegen_446(), csegen_175(), csegen_177(), '{', {a1: '\"', a2: {h: 0}}, $62, $63)}, a2: {a1: {a1: JSON_Parser_OLbl(), a2: $76 => $77 => Text_ILex_Interfaces_unclosedIfEOI(csegen_446(), csegen_175(), csegen_177(), '{', {a1: ':', a2: {h: 0}}, $76, $77)}, a2: {a1: {a1: JSON_Parser_OCol(), a2: $8a => $8b => Text_ILex_Interfaces_unclosedIfEOI(csegen_446(), csegen_175(), csegen_177(), '{', {h: 0}, $8a, $8b)}, a2: {a1: {a1: JSON_Parser_JStr(), a2: $9c => $9d => Text_ILex_Interfaces_unclosedIfNLorEOI(csegen_446(), csegen_175(), csegen_177(), '\"', {h: 0}, $9c, $9d)}, a2: {h: 0}}}}}}}}}});
});

/* JSON.Parser.jsonEOI : JST -> SK q -> F1 q (Either (BoundedErr Void) JSON) */
function JSON_Parser_jsonEOI($0, $1, $2) {
 switch(Prelude_EqOrd_x3dx3d_Eq_Bits32($0, JSON_Parser_JDone())) {
  case 0: return Text_ILex_Parser_arrFail(JSON_Parser_jsonErr(), $0, $1, $2);
  case 1: {
   const $e = ($1.a4.value);
   switch($e.h) {
    case 5: /* PF */ return {h: 1 /* Right */, a1: $e.a1};
    default: return {h: 1 /* Right */, a1: {h: 0 /* JNull */}};
   }
  }
 }
}

/* JSON.Parser.jsonDouble : RExp True */
const JSON_Parser_jsonDouble = __lazy(function () {
 const $0 = {h: 2 /* And */, a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('.'.codePointAt(0)))}, a2: csegen_479()};
 const $8 = {h: 2 /* And */, a1: {h: 2 /* And */, a1: Text_ILex_RExp_oneof(csegen_156(), csegen_161(), {a1: csegen_202(), a2: {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('E'.codePointAt(0)))}, a2: {h: 0}}}), a2: {h: 3 /* Or */, a1: Text_ILex_RExp_oneof(csegen_156(), csegen_161(), {a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('+'.codePointAt(0)))}, a2: {a1: csegen_219(), a2: {h: 0}}}), a2: {h: 0 /* Eps */}}}, a2: csegen_479()};
 return {h: 2 /* And */, a1: {h: 2 /* And */, a1: csegen_221(), a2: {h: 3 /* Or */, a1: $0, a2: {h: 0 /* Eps */}}}, a2: {h: 3 /* Or */, a1: $8, a2: {h: 0 /* Eps */}}};
});

/* JSON.Parser.json : P1 q (BoundedErr Void) JSz SK JSON */
const JSON_Parser_json = __lazy(function () {
 return {a1: JSON_Parser_JIni(), a2: $3 => Text_ILex_Stack_init({h: 3 /* PI */}, $3), a3: JSON_Parser_jsonTrans(), a4: x => $a => ({h: 0}), a5: JSON_Parser_jsonErr(), a6: $e => $f => $10 => JSON_Parser_jsonEOI($e, $f, $10), a7: csegen_177()};
});

/* JSON.Parser.jchar : RExp True */
const JSON_Parser_jchar = __lazy(function () {
 let $9;
 switch(Prelude_EqOrd_x3cx3d_Ord_Bits32(32, 1114111)) {
  case 1: {
   $9 = {a1: 32, a2: 1114111};
   break;
  }
  case 0: {
   $9 = {h: 0};
   break;
  }
 }
 const $7 = Text_ILex_Char_Set_range($9);
 const $0 = Text_ILex_Char_Set_inters(csegen_156(), csegen_161(), {h: 0}, $7, Text_ILex_Char_Set_inters(csegen_156(), csegen_161(), {h: 0}, Text_ILex_Char_Set_negation(csegen_156(), csegen_161(), Text_ILex_Char_Set_singleton(_truncUInt32('\"'.codePointAt(0)))), Text_ILex_Char_Set_negation(csegen_156(), csegen_161(), Text_ILex_Char_Set_singleton(_truncUInt32('\u{5c}'.codePointAt(0))))));
 return {h: 1 /* Ch */, a1: $0};
});

/* JSON.Parser.escape : SnocList Char -> Char -> SnocList Char */
function JSON_Parser_escape($0, $1) {
 switch($1) {
  case '\"': return {a1: {a1: $0, a2: '\u{5c}'}, a2: '\"'};
  case '\n': return {a1: {a1: $0, a2: '\u{5c}'}, a2: 'n'};
  case '\u{c}': return {a1: {a1: $0, a2: '\u{5c}'}, a2: 'f'};
  case '\u{8}': return {a1: {a1: $0, a2: '\u{5c}'}, a2: 'b'};
  case '\r': return {a1: {a1: $0, a2: '\u{5c}'}, a2: 'r'};
  case '\u{9}': return {a1: {a1: $0, a2: '\u{5c}'}, a2: 't'};
  case '\u{5c}': return {a1: {a1: $0, a2: '\u{5c}'}, a2: '\u{5c}'};
  case '/': return {a1: {a1: $0, a2: '\u{5c}'}, a2: '/'};
  default: {
   switch(Prelude_Types_isControl($1)) {
    case 1: {
     const $26 = BigInt($1.codePointAt(0));
     const $28 = Text_ParseError_hexChar(Number(_truncUBigInt8((($26>>12n)&15n))));
     const $30 = Text_ParseError_hexChar(Number(_truncUBigInt8((($26>>8n)&15n))));
     const $38 = Text_ParseError_hexChar(Number(_truncUBigInt8((($26>>4n)&15n))));
     const $40 = Text_ParseError_hexChar(Number(_truncUBigInt8(($26&15n))));
     return {a1: {a1: {a1: {a1: {a1: {a1: $0, a2: '\u{5c}'}, a2: 'u'}, a2: $28}, a2: $30}, a2: $38}, a2: $40};
    }
    case 0: return {a1: $0, a2: $1};
   }
  }
 }
}

/* JSON.Parser.encode : String -> String */
function JSON_Parser_encode($0) {
 return Prelude_Types_fastPack(Prelude_Types_SnocList_x3cx3ex3e(Prelude_Types_foldl_Foldable_List($7 => $8 => JSON_Parser_escape($7, $8), {a1: {h: 0}, a2: '\"'}, Prelude_Types_fastUnpack($0)), {a1: '\"', a2: {h: 0}}));
}

/* JSON.Parser.decode : ByteString -> String */
function JSON_Parser_decode($0) {
 switch($0.h) {
  case undefined: /* cons */ {
   switch($0.a1) {
    case 0n: return '';
    default: {
     const $3 = ($0.a1-1n);
     switch($3) {
      case 0n: return '';
      default: {
       const $7 = ($3-1n);
       switch($7) {
        case 0n: return '';
        default: {
         const $b = ($7-1n);
         switch($b) {
          case 0n: return '';
          default: {
           const $f = ($b-1n);
           switch($f) {
            case 0n: return '';
            default: {
             const $13 = ($f-1n);
             switch($13) {
              case 0n: return '';
              default: {
               const $17 = ($13-1n);
               switch($17) {
                case 0n: return Data_String_singleton(_truncToChar(Number(((((Text_ILex_Util_hexdigit(Data_Buffer_Core_prim__getByteOffset($0.a2.a1, 2n, $0.a2.a2))*4096n)+(Text_ILex_Util_hexdigit(Data_Buffer_Core_prim__getByteOffset($0.a2.a1, 3n, $0.a2.a2))*256n))+(Text_ILex_Util_hexdigit(Data_Buffer_Core_prim__getByteOffset($0.a2.a1, 4n, $0.a2.a2))*16n))+Text_ILex_Util_hexdigit(Data_Buffer_Core_prim__getByteOffset($0.a2.a1, 5n, $0.a2.a2))))));
                default: return '';
               }
              }
             }
            }
           }
          }
         }
        }
       }
      }
     }
    }
   }
  }
  default: return '';
 }
}

/* JSON.Parser.codepoint : RExp True */
const JSON_Parser_codepoint = __lazy(function () {
 return {h: 2 /* And */, a1: {h: 2 /* And */, a1: {h: 2 /* And */, a1: {h: 2 /* And */, a1: {h: 2 /* And */, a1: csegen_382(), a2: csegen_192()}, a2: Text_ILex_RExp_hexdigit()}, a2: Text_ILex_RExp_hexdigit()}, a2: Text_ILex_RExp_hexdigit()}, a2: Text_ILex_RExp_hexdigit()};
});

/* JSON.Parser.OVal : JST */
const JSON_Parser_OVal = __lazy(function () {
 return 5;
});

/* JSON.Parser.ONew : JST */
const JSON_Parser_ONew = __lazy(function () {
 return 4;
});

/* JSON.Parser.OLbl : JST */
const JSON_Parser_OLbl = __lazy(function () {
 return 7;
});

/* JSON.Parser.OCom : JST */
const JSON_Parser_OCom = __lazy(function () {
 return 6;
});

/* JSON.Parser.OCol : JST */
const JSON_Parser_OCol = __lazy(function () {
 return 8;
});

/* JSON.Parser.JStr : JST */
const JSON_Parser_JStr = __lazy(function () {
 return 9;
});

/* JSON.Parser.JIni : JST */
const JSON_Parser_JIni = __lazy(function () {
 return 0;
});

/* JSON.Parser.JDone : JST */
const JSON_Parser_JDone = __lazy(function () {
 return 10;
});

/* JSON.Parser.AVal : JST */
const JSON_Parser_AVal = __lazy(function () {
 return 2;
});

/* JSON.Parser.ANew : JST */
const JSON_Parser_ANew = __lazy(function () {
 return 1;
});

/* JSON.Parser.ACom : JST */
const JSON_Parser_ACom = __lazy(function () {
 return 3;
});

/* Text.ILex.Util.case block in integerBV */
function Text_ILex_Util_case__integerBV_11515($0, $1, $2, $3) {
 switch($3) {
  case 45: return (0n-Text_ILex_Util_decimalBV($0, 0n, $1, ($2+1n)));
  case 43: return Text_ILex_Util_decimalBV($0, 0n, $1, ($2+1n));
  default: return Text_ILex_Util_decimalBV($0, (BigInt($3)-48n), $1, ($2+1n));
 }
}

/* Text.ILex.Util.snocPack : SnocList String -> String */
function Text_ILex_Util_snocPack($0) {
 switch($0.h) {
  case 0: /* nil */ return '';
  case undefined: /* cons */ {
   switch($0.a1.h) {
    case 0: /* nil */ return $0.a2;
    default: return Prelude_Types_fastConcat(Prelude_Types_SnocList_x3cx3ex3e($0, {h: 0}));
   }
  }
  default: return Prelude_Types_fastConcat(Prelude_Types_SnocList_x3cx3ex3e($0, {h: 0}));
 }
}

/* Text.ILex.Util.integerBV : ByteVect n -> (k : Nat) -> Ix k n => Integer */
function Text_ILex_Util_integerBV($0, $1, $2) {
 switch($1) {
  case 0n: return 0n;
  default: {
   const $4 = ($1-1n);
   return Text_ILex_Util_case__integerBV_11515($0, $4, $2, Data_Buffer_Core_prim__getByteOffset($0.a1, $2, $0.a2));
  }
 }
}

/* Text.ILex.Util.hexdigit : Bits8 -> Integer */
function Text_ILex_Util_hexdigit($0) {
 switch(Prelude_EqOrd_x3cx3d_Ord_Bits8($0, 57)) {
  case 1: return (BigInt($0)-48n);
  case 0: {
   switch(Prelude_EqOrd_x3cx3d_Ord_Bits8($0, 70)) {
    case 1: return ((BigInt($0)+10n)-65n);
    case 0: return ((BigInt($0)+10n)-97n);
   }
  }
 }
}

/* Text.ILex.RExp.posdigit : RExp True */
const Text_ILex_RExp_posdigit = __lazy(function () {
 return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_posdigit()};
});

/* Text.ILex.RExp.oneof : WithBounds t => Neg t => (rs : List (RExpOf True t)) ->
{auto 0 _ : NonEmpty rs} -> RExpOf True t */
function Text_ILex_RExp_oneof($0, $1, $2) {
 switch($2.a2.h) {
  case 0: /* nil */ return $2.a1;
  case undefined: /* cons */ return Text_ILex_RExp_x3cx7cx3e($0, $1, $2.a1, Text_ILex_RExp_oneof($0, $1, $2.a2));
 }
}

/* Text.ILex.RExp.hexdigit : RExp True */
const Text_ILex_RExp_hexdigit = __lazy(function () {
 let $11;
 switch(Prelude_EqOrd_x3cx3d_Ord_Bits32(_truncUInt32('a'.codePointAt(0)), _truncUInt32('f'.codePointAt(0)))) {
  case 1: {
   $11 = {a1: _truncUInt32('a'.codePointAt(0)), a2: _truncUInt32('f'.codePointAt(0))};
   break;
  }
  case 0: {
   $11 = {h: 0};
   break;
  }
 }
 const $f = Text_ILex_Char_Set_range($11);
 const $e = {h: 1 /* Ch */, a1: $f};
 let $1f;
 switch(Prelude_EqOrd_x3cx3d_Ord_Bits32(_truncUInt32('A'.codePointAt(0)), _truncUInt32('F'.codePointAt(0)))) {
  case 1: {
   $1f = {a1: _truncUInt32('A'.codePointAt(0)), a2: _truncUInt32('F'.codePointAt(0))};
   break;
  }
  case 0: {
   $1f = {h: 0};
   break;
  }
 }
 const $1d = Text_ILex_Char_Set_range($1f);
 const $1c = {h: 1 /* Ch */, a1: $1d};
 const $8 = Text_ILex_RExp_x3cx7cx3e(csegen_156(), csegen_161(), $e, $1c);
 return Text_ILex_RExp_x3cx7cx3e(csegen_156(), csegen_161(), {h: 1 /* Ch */, a1: csegen_512()}, $8);
});

/* Text.ILex.RExp.decimal : RExp True */
const Text_ILex_RExp_decimal = __lazy(function () {
 return Text_ILex_RExp_x3cx7cx3e(csegen_156(), csegen_161(), {h: 1 /* Ch */, a1: Text_ILex_Char_Set_singleton(_truncUInt32('0'.codePointAt(0)))}, {h: 2 /* And */, a1: Text_ILex_RExp_posdigit(), a2: {h: 4 /* Star */, a1: {h: 1 /* Ch */, a1: Text_ILex_Char_Set_digit()}}});
});

/* Text.ILex.RExp.adjRanges : (SetOf t -> RExpOf True s) -> RExpOf b t -> RExpOf b s */
function Text_ILex_RExp_adjRanges($0, $1) {
 switch($1.h) {
  case 0: /* Eps */ return {h: 0 /* Eps */};
  case 1: /* Ch */ return $0($1.a1);
  case 2: /* And */ return {h: 2 /* And */, a1: Text_ILex_RExp_adjRanges($0, $1.a1), a2: Text_ILex_RExp_adjRanges($0, $1.a2)};
  case 3: /* Or */ return {h: 3 /* Or */, a1: Text_ILex_RExp_adjRanges($0, $1.a1), a2: Text_ILex_RExp_adjRanges($0, $1.a2)};
  case 4: /* Star */ return {h: 4 /* Star */, a1: Text_ILex_RExp_adjRanges($0, $1.a1)};
 }
}

/* Text.ILex.RExp.(<|>) : WithBounds t => Neg t => RExpOf b1 t -> RExpOf b2 t -> RExpOf (b1 && Delay b2) t */
function Text_ILex_RExp_x3cx7cx3e($0, $1, $2, $3) {
 switch($2.h) {
  case 1: /* Ch */ {
   switch($3.h) {
    case 1: /* Ch */ return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_union($0, $1, $2.a1, $3.a1)};
    default: return {h: 3 /* Or */, a1: $2, a2: $3};
   }
  }
  default: return {h: 3 /* Or */, a1: $2, a2: $3};
 }
}

/* Text.ILex.Char.Set.union : WithBounds t => Neg t => SetOf t -> SetOf t -> SetOf t */
function Text_ILex_Char_Set_union($0, $1, $2, $3) {
 return Text_ILex_Char_Set_rangeSet($0, $1, Prelude_Types_List_tailRecAppend($2, $3));
}

/* Text.ILex.Char.Set.unicode : Set32 */
const Text_ILex_Char_Set_unicode = __lazy(function () {
 return Text_ILex_Char_Set_difference(csegen_156(), csegen_161(), Text_ILex_Char_Set_range(Text_ILex_Char_Range_codepoint()), Text_ILex_Char_Set_range(Text_ILex_Char_Range_surrogate()));
});

/* Text.ILex.Char.Set.singleton : t -> SetOf t */
function Text_ILex_Char_Set_singleton($0) {
 return {a1: {a1: $0, a2: $0}, a2: {h: 0}};
}

/* Text.ILex.Char.Set.rangeSet : WithBounds t => Neg t => List (RangeOf t) -> SetOf t */
function Text_ILex_Char_Set_rangeSet($0, $1, $2) {
 const $17 = a => b => {
  switch(Text_ILex_Char_Range_eqRangeOf($0.a1.a1, a, b)) {
   case 1: return 0;
   case 0: return 1;
  }
 };
 const $d = {a1: $f => $10 => Text_ILex_Char_Range_eqRangeOf($0.a1.a1, $f, $10), a2: $17};
 const $b = Language_Reflection_Derive_mkOrd($d, $20 => $21 => Text_ILex_Char_Range_ordRangeOf($0.a1, $20, $21));
 const $9 = Data_List_sort($b, $2);
 const $7 = Data_Vect_fromList($9);
 return Text_ILex_Char_Set_normalise($0, $1, {h: 0}, $7);
}

/* Text.ILex.Char.Set.range : RangeOf t -> SetOf t */
function Text_ILex_Char_Set_range($0) {
 let $1;
 switch($0.h) {
  case 0: /* nil */ {
   $1 = 1;
   break;
  }
  default: $1 = 0;
 }
 switch($1) {
  case 1: return Text_ILex_Char_Set_empty();
  case 0: return {a1: $0, a2: {h: 0}};
 }
}

/* Text.ILex.Char.Set.posdigit : Set32 */
const Text_ILex_Char_Set_posdigit = __lazy(function () {
 let $1;
 switch(Prelude_EqOrd_x3cx3d_Ord_Bits32(_truncUInt32('1'.codePointAt(0)), _truncUInt32('9'.codePointAt(0)))) {
  case 1: {
   $1 = {a1: _truncUInt32('1'.codePointAt(0)), a2: _truncUInt32('9'.codePointAt(0))};
   break;
  }
  case 0: {
   $1 = {h: 0};
   break;
  }
 }
 return Text_ILex_Char_Set_range($1);
});

/* Text.ILex.Char.Set.negation : WithBounds t => Neg t => SetOf t -> SetOf t */
function Text_ILex_Char_Set_negation($0, $1, $2) {
 return Text_ILex_Char_Set_n__7601_14384_go($0, $1, $2, {h: 0}, $1.a1.a3(0n), $2);
}

/* Text.ILex.Char.Set.empty : SetOf t */
const Text_ILex_Char_Set_empty = __lazy(function () {
 return {h: 0};
});

/* Text.ILex.Char.Set.digit : Set32 */
const Text_ILex_Char_Set_digit = __lazy(function () {
 return csegen_512();
});

/* Text.ILex.Char.Set.difference : WithBounds t => Neg t => SetOf t -> SetOf t -> SetOf t */
function Text_ILex_Char_Set_difference($0, $1, $2, $3) {
 const $4 = Text_ILex_Char_Set_negation($0, $1, $3);
 return Text_ILex_Char_Set_inters($0, $1, {h: 0}, $2, $4);
}

/* Text.ILex.Char.Set.appendNonEmpty : WithBounds t => Neg t =>
SnocList (RangeOf t) -> RangeOf t -> SnocList (RangeOf t) */
function Text_ILex_Char_Set_appendNonEmpty($0, $1, $2, $3) {
 let $4;
 switch($3.h) {
  case 0: /* nil */ {
   $4 = 1;
   break;
  }
  default: $4 = 0;
 }
 switch($4) {
  case 1: return $2;
  case 0: return {a1: $2, a2: $3};
 }
}

/* Text.ILex.Char.Range.case block in case block in case block in difference */
function Text_ILex_Char_Range_case__casex20blockx20inx20casex20blockx20inx20difference_13378($0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $a, $b) {
 switch($b.h) {
  case undefined: /* cons */ {
   const $1a = a => b => {
    switch(Text_ILex_Char_Range_eqRangeOf($0.a1, a, b)) {
     case 1: return 0;
     case 0: return 1;
    }
   };
   const $11 = {a1: $13 => $14 => Text_ILex_Char_Range_eqRangeOf($0.a1, $13, $14), a2: $1a};
   const $f = Language_Reflection_Derive_mkOrd($11, $22 => $23 => Text_ILex_Char_Range_ordRangeOf($0, $22, $23));
   const $e = $f.a8($a)($b);
   const $38 = a => b => {
    switch(Text_ILex_Char_Range_eqRangeOf($0.a1, a, b)) {
     case 1: return 0;
     case 0: return 1;
    }
   };
   const $2f = {a1: $31 => $32 => Text_ILex_Char_Range_eqRangeOf($0.a1, $31, $32), a2: $38};
   const $2d = Language_Reflection_Derive_mkOrd($2f, $40 => $41 => Text_ILex_Char_Range_ordRangeOf($0, $40, $41));
   const $2c = $2d.a7($a)($b);
   const $d = {a1: $e, a2: $2c};
   return {h: 1 /* Right */, a1: $d};
  }
  case 0: /* nil */ return {h: 0 /* Left */, a1: $a};
 }
}

/* Text.ILex.Char.Range.case block in case block in difference */
function Text_ILex_Char_Range_case__casex20blockx20inx20difference_13342($0, $1, $2, $3, $4, $5, $6, $7, $8) {
 switch($8.h) {
  case undefined: /* cons */ {
   const $a = {a1: $8.a1, a2: $8.a2};
   return Text_ILex_Char_Range_case__casex20blockx20inx20casex20blockx20inx20difference_13378($0, $1, $2, $3, $8.a2, $8.a1, $7, $6, $5, $4, $a, Text_ILex_Char_Range_afterTo($0, $1, $4, $6));
  }
  case 0: /* nil */ return {h: 0 /* Left */, a1: Text_ILex_Char_Range_afterTo($0, $1, $4, $6)};
 }
}

/* Text.ILex.Char.Range.case block in ordRangeOf */
function Text_ILex_Char_Range_case__ordRangeOf_12656($0, $1, $2, $3, $4, $5) {
 switch($5) {
  case 1: return $0.a2($2)($4);
  default: return $5;
 }
}

/* Text.ILex.Char.Range.upperBound : WithBounds t => RangeOf t -> t */
function Text_ILex_Char_Range_upperBound($0, $1) {
 switch($1.h) {
  case undefined: /* cons */ return $1.a2;
  case 0: /* nil */ return $0.a2;
 }
}

/* Text.ILex.Char.Range.union : Ord t => Neg t => RangeOf t -> RangeOf t -> Either (RangeOf t) (RangeOf t,
RangeOf t) */
function Text_ILex_Char_Range_union($0, $1, $2, $3) {
 switch($2.h) {
  case undefined: /* cons */ {
   switch($3.h) {
    case undefined: /* cons */ {
     const $6 = {a1: $2.a1, a2: $2.a2};
     const $9 = {a1: $3.a1, a2: $3.a2};
     let $c;
     switch(Text_ILex_Char_Range_overlap($0, $6, $9)) {
      case 1: {
       $c = 1;
       break;
      }
      case 0: {
       $c = Text_ILex_Char_Range_adjacent($0, $1, $6, $9);
       break;
      }
     }
     switch($c) {
      case 1: return {h: 0 /* Left */, a1: Text_ILex_Char_Range_span($0, $6, $9)};
      case 0: {
       const $29 = a => b => {
        switch(Text_ILex_Char_Range_eqRangeOf($0.a1, a, b)) {
         case 1: return 0;
         case 0: return 1;
        }
       };
       const $20 = {a1: $22 => $23 => Text_ILex_Char_Range_eqRangeOf($0.a1, $22, $23), a2: $29};
       const $1e = Language_Reflection_Derive_mkOrd($20, $31 => $32 => Text_ILex_Char_Range_ordRangeOf($0, $31, $32));
       const $1d = $1e.a8($6)($9);
       const $47 = a => b => {
        switch(Text_ILex_Char_Range_eqRangeOf($0.a1, a, b)) {
         case 1: return 0;
         case 0: return 1;
        }
       };
       const $3e = {a1: $40 => $41 => Text_ILex_Char_Range_eqRangeOf($0.a1, $40, $41), a2: $47};
       const $3c = Language_Reflection_Derive_mkOrd($3e, $4f => $50 => Text_ILex_Char_Range_ordRangeOf($0, $4f, $50));
       const $3b = $3c.a7($6)($9);
       const $1c = {a1: $1d, a2: $3b};
       return {h: 1 /* Right */, a1: $1c};
      }
     }
    }
    default: return {h: 0 /* Left */, a1: $2};
   }
  }
  case 0: /* nil */ return {h: 0 /* Left */, a1: $3};
  default: return {h: 0 /* Left */, a1: $2};
 }
}

/* Text.ILex.Char.Range.surrogate : Range32 */
const Text_ILex_Char_Range_surrogate = __lazy(function () {
 return {a1: 55296, a2: 57343};
});

/* Text.ILex.Char.Range.span : Ord t => RangeOf t -> RangeOf t -> RangeOf t */
function Text_ILex_Char_Range_span($0, $1, $2) {
 switch($1.h) {
  case undefined: /* cons */ {
   switch($2.h) {
    case undefined: /* cons */ return {a1: $0.a8($1.a1)($2.a1), a2: $0.a7($1.a2)($2.a2)};
    default: return $1;
   }
  }
  case 0: /* nil */ return $2;
  default: return $1;
 }
}

/* Text.ILex.Char.Range.overlap : Ord t => RangeOf t -> RangeOf t -> Bool */
function Text_ILex_Char_Range_overlap($0, $1, $2) {
 switch($1.h) {
  case undefined: /* cons */ {
   switch($2.h) {
    case undefined: /* cons */ {
     switch(Text_ILex_Char_Range_has($0, $1, $2.a1)) {
      case 1: return 1;
      case 0: return Text_ILex_Char_Range_has($0, $2, $1.a1);
     }
    }
    default: return 0;
   }
  }
  default: return 0;
 }
}

/* Text.ILex.Char.Range.ordRangeOf : Ord t => RangeOf t -> RangeOf t -> Ordering */
function Text_ILex_Char_Range_ordRangeOf($0, $1, $2) {
 switch($1.h) {
  case 0: /* nil */ {
   switch($2.h) {
    case 0: /* nil */ return 1;
    default: return Prelude_EqOrd_compare_Ord_Bits8(Text_ILex_Char_Range_conIndexRangeOf($1), Text_ILex_Char_Range_conIndexRangeOf($2));
   }
  }
  case undefined: /* cons */ {
   switch($2.h) {
    case undefined: /* cons */ return Text_ILex_Char_Range_case__ordRangeOf_12656($0, $1.a1, $1.a2, $2.a1, $2.a2, $0.a2($1.a1)($2.a1));
    default: return Prelude_EqOrd_compare_Ord_Bits8(Text_ILex_Char_Range_conIndexRangeOf($1), Text_ILex_Char_Range_conIndexRangeOf($2));
   }
  }
  default: return Prelude_EqOrd_compare_Ord_Bits8(Text_ILex_Char_Range_conIndexRangeOf($1), Text_ILex_Char_Range_conIndexRangeOf($2));
 }
}

/* Text.ILex.Char.Range.lowerBound : WithBounds t => RangeOf t -> t */
function Text_ILex_Char_Range_lowerBound($0, $1) {
 switch($1.h) {
  case undefined: /* cons */ return $1.a1;
  case 0: /* nil */ return $0.a3;
 }
}

/* Text.ILex.Char.Range.intersection : Ord t => RangeOf t -> RangeOf t -> RangeOf t */
function Text_ILex_Char_Range_intersection($0, $1, $2) {
 switch($1.h) {
  case undefined: /* cons */ {
   switch($2.h) {
    case undefined: /* cons */ {
     switch($0.a5($1.a1)($2.a1)) {
      case 1: {
       switch($0.a5($2.a1)($0.a8($1.a2)($2.a2))) {
        case 1: return {a1: $2.a1, a2: $0.a8($1.a2)($2.a2)};
        case 0: return {h: 0};
       }
      }
      case 0: {
       switch($0.a5($1.a1)($0.a8($2.a2)($1.a2))) {
        case 1: return {a1: $1.a1, a2: $0.a8($2.a2)($1.a2)};
        case 0: return {h: 0};
       }
      }
     }
    }
    default: return {h: 0};
   }
  }
  default: return {h: 0};
 }
}

/* Text.ILex.Char.Range.has : Ord t => RangeOf t -> t -> Bool */
function Text_ILex_Char_Range_has($0, $1, $2) {
 switch($1.h) {
  case 0: /* nil */ return 0;
  case undefined: /* cons */ {
   switch($0.a5($1.a1)($2)) {
    case 1: return $0.a5($2)($1.a2);
    case 0: return 0;
   }
  }
 }
}

/* Text.ILex.Char.Range.fromTill : Ord t => Neg t => t -> t -> RangeOf t */
function Text_ILex_Char_Range_fromTill($0, $1, $2, $3) {
 switch($0.a3($2)($3)) {
  case 1: {
   switch($0.a5($2)($1.a3($3)($1.a1.a3(1n)))) {
    case 1: return {a1: $2, a2: $1.a3($3)($1.a1.a3(1n))};
    case 0: return {h: 0};
   }
  }
  case 0: return {h: 0};
 }
}

/* Text.ILex.Char.Range.eqRangeOf : Eq t => RangeOf t -> RangeOf t -> Bool */
function Text_ILex_Char_Range_eqRangeOf($0, $1, $2) {
 switch($1.h) {
  case 0: /* nil */ {
   switch($2.h) {
    case 0: /* nil */ return 1;
    default: return 0;
   }
  }
  case undefined: /* cons */ {
   switch($2.h) {
    case undefined: /* cons */ {
     switch($0.a1($1.a1)($2.a1)) {
      case 1: return $0.a1($1.a2)($2.a2);
      case 0: return 0;
     }
    }
    default: return 0;
   }
  }
  default: return 0;
 }
}

/* Text.ILex.Char.Range.difference : Ord t => Neg t => RangeOf t -> RangeOf t -> Either (RangeOf t) (RangeOf t,
RangeOf t) */
function Text_ILex_Char_Range_difference($0, $1, $2, $3) {
 switch($2.h) {
  case undefined: /* cons */ {
   switch($3.h) {
    case undefined: /* cons */ {
     const $6 = {a1: $2.a1, a2: $2.a2};
     const $9 = {a1: $3.a1, a2: $3.a2};
     switch(Text_ILex_Char_Range_overlap($0, $6, $9)) {
      case 1: return Text_ILex_Char_Range_case__casex20blockx20inx20difference_13342($0, $1, $6, $9, $3.a2, $3.a1, $2.a2, $2.a1, Text_ILex_Char_Range_fromTill($0, $1, $2.a1, $3.a1));
      case 0: return {h: 0 /* Left */, a1: $6};
     }
    }
    default: return {h: 0 /* Left */, a1: $2};
   }
  }
  case 0: /* nil */ return {h: 0 /* Left */, a1: {h: 0}};
  default: return {h: 0 /* Left */, a1: $2};
 }
}

/* Text.ILex.Char.Range.conIndexRangeOf : RangeOf t -> Bits8 */
function Text_ILex_Char_Range_conIndexRangeOf($0) {
 switch($0.h) {
  case 0: /* nil */ return 0;
  case undefined: /* cons */ return 1;
 }
}

/* Text.ILex.Char.Range.codepoint : Range32 */
const Text_ILex_Char_Range_codepoint = __lazy(function () {
 return {a1: 0, a2: 1114111};
});

/* Text.ILex.Char.Range.afterTo : Ord t => Neg t => t -> t -> RangeOf t */
function Text_ILex_Char_Range_afterTo($0, $1, $2, $3) {
 switch($0.a3($2)($3)) {
  case 1: {
   switch($0.a5($1.a1.a1($2)($1.a1.a3(1n)))($3)) {
    case 1: return {a1: $1.a1.a1($2)($1.a1.a3(1n)), a2: $3};
    case 0: return {h: 0};
   }
  }
  case 0: return {h: 0};
 }
}

/* Text.ILex.Char.Range.adjacent : Ord t => Neg t => RangeOf t -> RangeOf t -> Bool */
function Text_ILex_Char_Range_adjacent($0, $1, $2, $3) {
 switch($2.h) {
  case undefined: /* cons */ {
   switch($3.h) {
    case undefined: /* cons */ {
     let $6;
     switch($0.a3($2.a2)($3.a1)) {
      case 1: {
       $6 = $0.a1.a1($1.a1.a1($2.a2)($1.a1.a3(1n)))($3.a1);
       break;
      }
      case 0: {
       $6 = 0;
       break;
      }
     }
     switch($6) {
      case 1: return 1;
      case 0: {
       switch($0.a3($3.a2)($2.a1)) {
        case 1: return $0.a1.a1($1.a1.a1($3.a2)($1.a1.a3(1n)))($2.a1);
        case 0: return 0;
       }
      }
     }
    }
    default: return 0;
   }
  }
  default: return 0;
 }
}

/* Data.ByteString.toString : ByteString -> String */
function Data_ByteString_toString($0) {
 return Data_ByteVect_toString($0.a1, $0.a2);
}

/* Data.ByteVect.toString : ByteVect n -> String */
function Data_ByteVect_toString($0, $1) {
 return Data_Buffer_Core_toString($1.a1, $1.a2, $0);
}

/* Data.ByteVect.substringFromTill : (from : Nat) -> (till : Nat) -> {auto 0 _ : LTE from till} ->
{auto 0 _ : LTE till n} -> ByteVect n -> ByteVect (minus till from) */
function Data_ByteVect_substringFromTill($0, $1, $2) {
 return {a1: $2.a1, a2: ($2.a2+$0)};
}

/* Data.ByteVect.fromString : (s : String) -> ByteVect (cast (stringByteLength s)) */
function Data_ByteVect_fromString($0) {
 return {a1: Data_Buffer_Core_fromString($0), a2: 0n};
}

/* Data.ByteVect.empty : ByteVect 0 */
const Data_ByteVect_empty = __lazy(function () {
 return {a1: Data_Buffer_Indexed_empty(), a2: 0n};
});

/* Data.ByteVect.any : (Bits8 -> Bool) -> ByteVect n -> Bool */
function Data_ByteVect_any($0, $1, $2) {
 return Data_ByteVect_n__6150_2653_go($0, $2, $1, $0, 0n);
}

/* Data.Buffer.Indexed.empty : IBuffer 0 */
const Data_Buffer_Indexed_empty = __lazy(function () {
 return Data_Buffer_Core_alloc(0n, $3 => $4 => $5 => $4);
});

/* Data.Linear.Token.run1 : F1 s a -> a */
function Data_Linear_Token_run1($0) {
 return $0(undefined)(_idrisworld);
}

/* Data.Buffer.Core.toString : IBuffer n -> (off : Nat) -> (len : Nat) -> {auto 0 _ : LTE (off + len) n} ->
String */
function Data_Buffer_Core_toString($0, $1, $2) {
 return Data_Buffer_Core_prim__getString($0, $1, $2);
}

/* Data.Buffer.Core.fromString : (s : String) -> IBuffer (cast (stringByteLength s)) */
function Data_Buffer_Core_fromString($0) {
 return Data_Buffer_Core_prim__fromString($0);
}

/* Data.Buffer.Core.alloc : (n : Nat) -> WithMBuffer n a -> a */
function Data_Buffer_Core_alloc($0, $1) {
 const $3 = $4 => t => {
  const $5 = Data_Buffer_Core_prim__newBuf($0, _idrisworld);
  return $1(undefined)($5)(undefined);
 };
 return Data_Linear_Token_run1($3);
}

/* Data.Array.Index.with block in tryNatToFin */
function Data_Array_Index_with__tryNatToFin_1744($0, $1, $2, $3) {
 switch($2) {
  case 1: return {a1: $1};
  case 0: return {h: 0};
 }
}

/* Data.Array.Index.tryNatToFin : Nat -> Maybe (Fin k) */
function Data_Array_Index_tryNatToFin($0, $1) {
 return Data_Array_Index_with__tryNatToFin_1744($0, $1, Prelude_Types_x3c_Ord_Nat($1, $0), undefined);
}

/* Data.Array.Indexed.fromPairs : (n : Nat) -> a -> List (Nat, a) -> IArray n a */
function Data_Array_Indexed_fromPairs($0, $1, $2) {
 return Data_Array_Core_alloc($0, $1, $7 => $8 => Data_Array_Indexed_n__5766_9221_go($1, $2, $0, $2, $8));
}

/* Data.Linear.Traverse1.pairIx : Ref s Nat -> a -> F1 s (Nat, a) */
function Data_Linear_Traverse1_pairIx($0, $1, $2) {
 return {a1: Data_Linear_Ref1_readAndMod1($0, $7 => ($7+1n), $2), a2: $1};
}

/* Data.Linear.Ref1.case block in readAndMod1 */
function Data_Linear_Ref1_case__readAndMod1_1633($0, $1, $2) {
 const $3 = ($1.value=$0($2));
 return $2;
}

/* Data.Linear.Ref1.withRef1 : a -> WithRef1 a b -> b */
function Data_Linear_Ref1_withRef1($0, $1) {
 const $3 = $4 => t => {
  const $5 = ({value:$0});
  return $1(undefined)($5)(undefined);
 };
 return Data_Linear_Token_run1($3);
}

/* Data.Linear.Ref1.readAndMod1 : Ref s a -> (a -> a) -> F1 s a */
function Data_Linear_Ref1_readAndMod1($0, $1, $2) {
 return Data_Linear_Ref1_case__readAndMod1_1633($1, $0, ($0.value));
}

/* Data.Array.Mutable.case block in mgrow */
function Data_Array_Mutable_case__mgrow_8883($0, $1, $2, $3, $4) {
 const $5 = Data_Array_Core_copy($1, 0n, 0n, $0, $4, undefined);
 return $4;
}

/* Data.Array.Mutable.mgrow : MArray s n a -> (m : Nat) -> a -> F1 s (MArray s (m + n) a) */
function Data_Array_Mutable_mgrow($0, $1, $2, $3, $4) {
 return Data_Array_Mutable_case__mgrow_8883($0, $1, $3, $2, Data_Array_Core_prim__newArray(($2+$0), $3, $4));
}

/* Data.Array.Core.copy : MArray s m a -> (srcOffset : Nat) -> (dstOffset : Nat) -> (len : Nat) ->
{auto 0 _ : LTE (srcOffset + len) m} -> {auto 0 _ : LTE (dstOffset + len) n} ->
MArray s n a -> F1' s */
function Data_Array_Core_copy($0, $1, $2, $3, $4, $5) {
 return Data_Array_Core_prim__copyArray($0, $1, $3, $4, $2, $5);
}

/* Data.Array.Core.alloc : (n : Nat) -> a -> WithMArray n a b -> b */
function Data_Array_Core_alloc($0, $1, $2) {
 const $4 = $5 => t => {
  const $6 = Data_Array_Core_prim__newArray($0, $1, t);
  return $2(undefined)($6)(undefined);
 };
 return Data_Linear_Token_run1($4);
}

/* Text.ILex.Parser.lastStep : P1 q e r s a -> Step1 q r s -> Index r -> s q -> F1 q (Either e a) */
function Text_ILex_Parser_lastStep($0, $1, $2, $3, $4) {
 const $5 = $1($3);
 const $c = $0.a7;
 const $b = $c(undefined);
 const $a = $b($3);
 const $8 = ($a.value=csegen_536());
 return $0.a6($5)($3)(undefined);
}

/* Text.ILex.Parser.arrFail : (0 s : (Type -> Type)) ->
Arr32 r (s q -> F1 q e) -> Index r -> s q -> F1 q (Either e x) */
function Text_ILex_Parser_arrFail($0, $1, $2, $3) {
 const $4 = Text_ILex_Parser_prim__machineGet($0, $1);
 const $8 = $4($2)($3);
 return {h: 0 /* Left */, a1: $8};
}

/* Text.ILex.Parser.arr32 : (n : Bits32) -> a -> List (Entry n a) -> Arr32 n a */
function Text_ILex_Parser_arr32($0, $1, $2) {
 const $4 = $5 => t => {
  const $6 = Text_ILex_Parser_prim__newMachine($0, $1, t);
  return Text_ILex_Parser_n__10719_11251_fill($1, $0, $2, $2, $6, undefined);
 };
 return Data_Linear_Token_run1($4);
}

/* Text.ILex.Lexer.case block in case block in byteDFA */
function Text_ILex_Lexer_case__casex20blockx20inx20byteDFA_3342($0, $1, $2, $3, $4, $5) {
 switch($5) {
  case 0n: return Text_ILex_Lexer_emptyDFA();
  default: {
   const $8 = ($5-1n);
   const $b = Text_ILex_Lexer_index($8, $4);
   const $f = Data_Array_Indexed_fromPairs(($8+1n), Text_ILex_Lexer_emptyRow(), Prelude_Types_List_mapAppend({h: 0}, $1a => Text_ILex_Lexer_node($3, $b, $1a), $4));
   return {a1: $8, a2: $f};
  }
 }
}

/* Text.ILex.Lexer.case block in byteDFA */
function Text_ILex_Lexer_case__byteDFA_3282($0, $1) {
 const $3 = Data_SortedMap_fromList(csegen_547(), Prelude_Types_List_mapMaybeAppend({h: 0}, $b => Text_ILex_Lexer_terminals($1.a1, Builtin_snd($b)), $1.a2));
 const $12 = Data_Linear_Ref1_withRef1(0n, $16 => r => $17 => Data_Linear_Traverse1_traverse1List({h: 0}, $1b => $1c => Data_Linear_Traverse1_pairIx(r, $1b, $1c), Prelude_Types_List_mapMaybeAppend({h: 0}, $25 => Text_ILex_Lexer_nonFinal($3, Builtin_snd($25)), $1.a2), $17));
 return Text_ILex_Lexer_case__casex20blockx20inx20byteDFA_3342($0, $1.a2, $1.a1, $3, $12, Prelude_Types_List_lengthTR($12));
}

/* Text.ILex.Lexer.11909:2677:pair */
function Text_ILex_Lexer_n__11909_2677_pair($0, $1, $2, $3, $4, $5, $6) {
 const $8 = Data_SortedMap_lookup($6.a2, $5);
 switch($8.h) {
  case 0: /* nothing */ {
   switch((($6.a2===$3)?1:0)) {
    case 1: return {a1: {a1: Prelude_Types_prim__integerToNat(BigInt($6.a1)), a2: {h: 0 /* Keep */}}};
    case 0: return Prelude_Types_map_Functor_Maybe($17 => ({a1: Prelude_Types_prim__integerToNat(BigInt($6.a1)), a2: {h: 4 /* MoveE */, a1: $17}}), Data_SortedMap_lookup($6.a2, $4));
   }
  }
  case undefined: /* just */ {
   switch($8.a1.h) {
    case 0: /* Left */ {
     switch($8.a1.a1.h) {
      case 0: /* Go */ return {a1: {a1: Prelude_Types_prim__integerToNat(BigInt($6.a1)), a2: {h: 1 /* Done */, a1: $8.a1.a1.a1}}};
      case 1: /* Rd */ return {a1: {a1: Prelude_Types_prim__integerToNat(BigInt($6.a1)), a2: {h: 2 /* DoneBS */, a1: $8.a1.a1.a1}}};
     }
    }
    case 1: /* Right */ {
     switch($8.a1.a1.h) {
      case 0: /* Go */ {
       switch((($6.a2===$3)?1:0)) {
        case 1: return {a1: {a1: Prelude_Types_prim__integerToNat(BigInt($6.a1)), a2: {h: 0 /* Keep */}}};
        case 0: return Prelude_Types_map_Functor_Maybe($3e => ({a1: Prelude_Types_prim__integerToNat(BigInt($6.a1)), a2: {h: 3 /* Move */, a1: $3e, a2: $8.a1.a1.a1}}), Data_SortedMap_lookup($6.a2, $4));
       }
      }
      case 1: /* Rd */ {
       switch((($6.a2===$3)?1:0)) {
        case 1: return {a1: {a1: Prelude_Types_prim__integerToNat(BigInt($6.a1)), a2: {h: 0 /* Keep */}}};
        case 0: return Prelude_Types_map_Functor_Maybe($55 => ({a1: Prelude_Types_prim__integerToNat(BigInt($6.a1)), a2: {h: 3 /* Move */, a1: $55, a2: $8.a1.a1.a1}}), Data_SortedMap_lookup($6.a2, $4));
       }
      }
     }
    }
   }
  }
 }
}

/* Text.ILex.Lexer.terminals : SortedMap Nat a -> Node -> Maybe (Nat, Either a a) */
function Text_ILex_Lexer_terminals($0, $1) {
 switch($1.h) {
  case undefined: /* record */ {
   switch($1.a2.h) {
    case undefined: /* cons */ {
     switch($1.a3.h) {
      case 0: /* nil */ return Prelude_Types_map_Functor_Maybe($7 => ({a1: $1.a1, a2: {h: 0 /* Left */, a1: $7}}), Data_SortedMap_lookup($1.a2.a1, $0));
      default: return Prelude_Types_map_Functor_Maybe($11 => ({a1: $1.a1, a2: {h: 1 /* Right */, a1: $11}}), Data_SortedMap_lookup($1.a2.a1, $0));
     }
    }
    default: return {h: 0};
   }
  }
  default: return {h: 0};
 }
}

/* Text.ILex.Lexer.nonFinal : SortedMap Nat (Either a a) -> Node -> Maybe Node */
function Text_ILex_Lexer_nonFinal($0, $1) {
 const $2 = Data_SortedMap_lookup($1.a1, $0);
 switch($2.h) {
  case undefined: /* just */ {
   switch($2.a1.h) {
    case 0: /* Left */ return {h: 0};
    default: return {a1: $1};
   }
  }
  default: return {a1: $1};
 }
}

/* Text.ILex.Lexer.node : SortedMap Nat (Either (Step q r s) (Step q r s)) -> SortedMap Nat (Fin (S n)) -> (Nat,
Node) -> (Nat, ByteStep n q r s) */
function Text_ILex_Lexer_node($0, $1, $2) {
 return {a1: $2.a1, a2: Data_Array_Indexed_fromPairs(256n, {h: 5 /* Bottom */}, Prelude_Types_List_mapMaybeAppend({h: 0}, $e => Text_ILex_Lexer_n__11909_2677_pair($2.a2.a2, $2.a1, $2.a2.a3, $2.a2.a1, $1, $0, $e), Prelude_Types_listBind($2.a2.a3, $1b => Text_ILex_Internal_Types_transitions($1b))))};
}

/* Text.ILex.Lexer.index : List (Nat, Node) -> SortedMap Nat (Fin (S n)) */
function Text_ILex_Lexer_index($0, $1) {
 return Data_SortedMap_fromList(csegen_547(), Prelude_Types_List_mapMaybeAppend({h: 0}, $9 => Prelude_Types_map_Functor_Maybe($d => ({a1: $9.a2.a1, a2: $d}), Data_Array_Index_tryNatToFin(($0+1n), $9.a1)), $1));
}

/* Text.ILex.Lexer.emptyRow : ByteStep n q r s */
const Text_ILex_Lexer_emptyRow = __lazy(function () {
 return Data_Array_Core_alloc(256n, {h: 5 /* Bottom */}, $4 => $5 => $6 => $5);
});

/* Text.ILex.Lexer.emptyDFA : DFA q r s */
const Text_ILex_Lexer_emptyDFA = __lazy(function () {
 return {a1: 0n, a2: Data_Array_Core_alloc(1n, Text_ILex_Lexer_emptyRow(), $7 => $8 => $9 => $8)};
});

/* Text.ILex.Lexer.dfa : Steps q r s -> DFA q r s */
function Text_ILex_Lexer_dfa($0) {
 return Text_ILex_Lexer_byteDFA(Prelude_Types_List_mapAppend({h: 0}, $6 => Text_ILex_Char_UTF8_toUTF8($6), $0));
}

/* Text.ILex.Lexer.byteDFA : TokenMap8 (Step q r s) -> DFA q r s */
function Text_ILex_Lexer_byteDFA($0) {
 return Text_ILex_Lexer_case__byteDFA_3282($0, Text_ILex_Internal_Types_machine($6 => $7 => $8 => Text_ILex_Internal_DFA_toDFA($7, $0, $8)));
}

/* Text.ILex.Internal.Types.11747:11880:translate */
function Text_ILex_Internal_Types_n__11747_11880_translate($0, $1, $2, $3) {
 const $6 = Text_ILex_Internal_Types_lookupDflt1($2.a1, () => 0n, $1, $3);
 const $f = $10 => $11 => {
  const $13 = Text_ILex_Internal_Types_lookupDflt1($10.a2, () => 0n, $1, $11);
  return {a1: $10.a1, a2: $13};
 };
 const $c = Data_Linear_Traverse1_traverse1List({h: 0}, $f, $2.a2.a3, undefined);
 return {a1: $6, a2: {a1: $6, a2: $2.a2.a2, a3: $c}};
}

/* Text.ILex.Internal.Types.transitions : Edge -> List (Bits8, Nat) */
function Text_ILex_Internal_Types_transitions($0) {
 const $2 = Text_ILex_Char_Range_lowerBound(csegen_562(), $0.a1);
 const $7 = Text_ILex_Char_Range_upperBound(csegen_562(), $0.a1);
 switch(Prelude_EqOrd_compare_Ord_Bits8($2, $7)) {
  case 0: return Prelude_Types_List_mapAppend({h: 0}, $13 => ({a1: $13, a2: $0.a2}), Prelude_Types_rangeFromTo_Range_x24a({a1: {a1: csegen_565(), a2: $1d => $1e => Prelude_Num_div_Integral_Bits8($1d, $1e), a3: $23 => $24 => Prelude_Num_mod_Integral_Bits8($23, $24)}, a2: {a1: csegen_561(), a2: csegen_570()}}, $2, $7));
  case 1: return {a1: {a1: $2, a2: $0.a2}, a2: {h: 0}};
  case 2: return {h: 0};
 }
}

/* Text.ILex.Internal.Types.pairs1 : NatMap1 s a -> F1 s (List (Nat, a)) */
function Text_ILex_Internal_Types_pairs1($0, $1) {
 const $2 = ($0.value);
 return Text_ILex_Internal_Types_n__9675_9656_go($0, $2.a2, {h: 0}, $2.a1, undefined);
}

/* Text.ILex.Internal.Types.normalizeGraph : DFAState s a => F1' s */
function Text_ILex_Internal_Types_normalizeGraph($0, $1) {
 const $2 = Text_ILex_Internal_Types_pairs1($0.a5, $1);
 const $7 = Text_ILex_Internal_Types_fromList1(Prelude_Types_List_mapAppend({h: 0}, $d => Builtin_swap($d), Data_Linear_Ref1_withRef1(0n, $14 => r => $15 => Data_Linear_Traverse1_traverse1List({h: 0}, $19 => $1a => Data_Linear_Traverse1_pairIx(r, $19, $1a), Prelude_Types_List_mapAppend({h: 0}, $23 => Builtin_fst($23), $2), $15))), undefined);
 const $29 = Data_Linear_Traverse1_traverse1List({h: 0}, $2d => $2e => Text_ILex_Internal_Types_n__11747_11880_translate($0, $7, $2d, $2e), $2, undefined);
 const $36 = Text_ILex_Internal_Types_fromList1($29, undefined);
 const $3a = ($36.value);
 return ($0.a5.value=$3a);
}

/* Text.ILex.Internal.Types.nchildren : NNode -> List Nat */
function Text_ILex_Internal_Types_nchildren($0) {
 return Prelude_Types_listBind($0.a3, csegen_573());
}

/* Text.ILex.Internal.Types.machine : (DFAState s a => F1 s b) -> Machine a b */
function Text_ILex_Internal_Types_machine($0) {
 const $2 = $3 => $4 => {
  const $5 = Text_ILex_Internal_Types_init($4);
  const $8 = $0(undefined)($5)(undefined);
  const $f = Text_ILex_Internal_Types_pairs1($5.a1, undefined);
  return {a1: Data_SortedMap_fromList(csegen_547(), $f), a2: $8};
 };
 return Data_Linear_Token_run1($2);
}

/* Text.ILex.Internal.Types.lookupSet : DFAState s a => NSet -> F1 s (Maybe Nat) */
function Text_ILex_Internal_Types_lookupSet($0, $1, $2) {
 const $3 = ($0.a2.value);
 return Data_SortedMap_lookup($1, $3);
}

/* Text.ILex.Internal.Types.lookupDflt1 : Nat -> Lazy a -> NatMap1 s a -> F1 s a */
function Text_ILex_Internal_Types_lookupDflt1($0, $1, $2, $3) {
 const $4 = ($2.value);
 const $9 = Data_Array_Index_tryNatToFin($4.a1, $0);
 switch($9.h) {
  case undefined: /* just */ {
   const $d = Data_Array_Core_prim__arrayGet($4.a2, $9.a1);
   return Data_Maybe_fromMaybe($1, $d);
  }
  case 0: /* nothing */ return $1();
 }
}

/* Text.ILex.Internal.Types.lookup1 : Nat -> NatMap1 s a -> F1 s (Maybe a) */
function Text_ILex_Internal_Types_lookup1($0, $1, $2) {
 const $3 = ($1.value);
 const $8 = Data_Array_Index_tryNatToFin($3.a1, $0);
 switch($8.h) {
  case undefined: /* just */ return Data_Array_Core_prim__arrayGet($3.a2, $8.a1);
  case 0: /* nothing */ return {h: 0};
 }
}

/* Text.ILex.Internal.Types.insertTerminal : DFAState s a => (Nat, (t, a)) -> F1' s */
function Text_ILex_Internal_Types_insertTerminal($0, $1, $2) {
 const $6 = Text_ILex_Internal_Types_insert1($1.a1, {a1: {a1: $1.a1, a2: {h: 0}}, a2: {h: 0}, a3: {h: 0}}, $0.a3, $2);
 const $5 = $1.a1;
 return Text_ILex_Internal_Types_insert1($1.a1, $1.a2.a2, $0.a1, undefined);
}

/* Text.ILex.Internal.Types.insert1 : Nat -> a -> NatMap1 s a -> F1' s */
function Text_ILex_Internal_Types_insert1($0, $1, $2, $3) {
 const $4 = ($2.value);
 return Text_ILex_Internal_Types_n__9368_9393_go($1, $2, $0, $4.a1, $4.a2, undefined);
}

/* Text.ILex.Internal.Types.init : F1 s (DFAState s a) */
function Text_ILex_Internal_Types_init($0) {
 const $1 = Text_ILex_Internal_Types_empty(256n, $0);
 const $5 = ({value:Data_SortedMap_empty({a1: {a1: $c => $d => Prelude_Types_x3dx3d_Eq_x28Listx20x24ax29(csegen_539(), $c, $d), a2: $14 => $15 => Prelude_Types_x2fx3d_Eq_x28Listx20x24ax29(csegen_539(), $14, $15)}, a2: $1c => $1d => Prelude_Types_compare_Ord_x28Listx20x24ax29(csegen_547(), $1c, $1d), a3: $24 => $25 => Prelude_Types_x3c_Ord_x28Listx20x24ax29(csegen_547(), $24, $25), a4: $2c => $2d => Prelude_Types_x3e_Ord_x28Listx20x24ax29(csegen_547(), $2c, $2d), a5: $34 => $35 => Prelude_Types_x3cx3d_Ord_x28Listx20x24ax29(csegen_547(), $34, $35), a6: $3c => $3d => Prelude_Types_x3ex3d_Ord_x28Listx20x24ax29(csegen_547(), $3c, $3d), a7: $44 => $45 => Prelude_Types_max_Ord_x28Listx20x24ax29(csegen_547(), $44, $45), a8: $4c => $4d => Prelude_Types_min_Ord_x28Listx20x24ax29(csegen_547(), $4c, $4d)})});
 const $54 = Text_ILex_Internal_Types_empty(256n, undefined);
 const $58 = Text_ILex_Internal_Types_empty(256n, undefined);
 const $5c = Text_ILex_Internal_Types_empty(256n, undefined);
 const $60 = ({value:1n});
 return {a1: $1, a2: $5, a3: $54, a4: $58, a5: $5c, a6: $60};
}

/* Text.ILex.Internal.Types.inc : DFAState s a => F1 s Nat */
function Text_ILex_Internal_Types_inc($0, $1) {
 const $2 = ($0.a6.value);
 const $7 = ($0.a6.value=($2+1n));
 return $2;
}

/* Text.ILex.Internal.Types.fromList1 : List (Nat, a) -> F1 s (NatMap1 s a) */
function Text_ILex_Internal_Types_fromList1($0, $1) {
 const $2 = Text_ILex_Internal_Types_empty(256n, $1);
 const $6 = Data_Linear_Traverse1_traverse1_List($9 => $a => Text_ILex_Internal_Types_insert1($9.a1, $9.a2, $2, $a), $0, undefined);
 return $2;
}

/* Text.ILex.Internal.Types.empty : {default 256 size : Nat} -> {auto 0 _ : IsSucc size} -> F1 s (NatMap1 s a) */
function Text_ILex_Internal_Types_empty($0, $1) {
 const $2 = Data_Array_Core_prim__newArray($0, {h: 0}, $1);
 return ({value:{a1: $0, a2: $2}});
}

/* Text.ILex.Internal.Types.connectedComponent : (a -> List Nat) -> Nat -> NatMap1 s a -> F1' s */
function Text_ILex_Internal_Types_connectedComponent($0, $1, $2, $3) {
 const $4 = ($2.value);
 const $9 = Data_Array_Core_prim__newArray($4.a1, 0, undefined);
 const $e = Data_Array_Core_prim__newArray($4.a1, {h: 0}, undefined);
 const $13 = Text_ILex_Internal_Types_visit($4.a1, $0, $9, $4.a2, $e, {a1: $1, a2: {h: 0}}, undefined);
 return ($2.value={a1: $4.a1, a2: $e});
}

/* Text.ILex.Internal.Types.children : Node -> List Nat */
function Text_ILex_Internal_Types_children($0) {
 return Prelude_Types_List_mapAppend({h: 0}, csegen_573(), $0.a3);
}

/* Text.ILex.Internal.Types.addSet : DFAState s a => NSet -> F1 s Nat */
function Text_ILex_Internal_Types_addSet($0, $1, $2) {
 const $3 = Text_ILex_Internal_Types_inc($0, $2);
 const $8 = ($0.a2.value);
 const $7 = ($0.a2.value=Data_SortedMap_insert($1, $3, $8));
 return $3;
}

/* Data.SortedMap.lookup : k -> SortedMap k v -> Maybe v */
function Data_SortedMap_lookup($0, $1) {
 return Prelude_Types_map_Functor_Maybe($4 => $4.a2, Data_SortedMap_Dependent_lookup($0, $1));
}

/* Data.SortedMap.insertFrom : Foldable f => f (k, v) -> SortedMap k v -> SortedMap k v */
function Data_SortedMap_insertFrom($0, $1, $2) {
 return Prelude_Basics_flip($0.a2(undefined)(undefined)($c => $d => Prelude_Basics_flip($10 => Prelude_Basics_uncurry($13 => $14 => $15 => Data_SortedMap_insert($13, $14, $15), $10), $c, $d)), $1, $2);
}

/* Data.SortedMap.insert : k -> v -> SortedMap k v -> SortedMap k v */
function Data_SortedMap_insert($0, $1, $2) {
 return Data_SortedMap_Dependent_insert($0, $1, $2);
}

/* Data.SortedMap.fromList : Ord k => List (k, v) -> SortedMap k v */
function Data_SortedMap_fromList($0, $1) {
 return Prelude_Basics_flip($4 => $5 => Data_SortedMap_insertFrom({a1: acc => elem => func => init => input => Prelude_Types_foldr_Foldable_List(func, init, input), a2: elem => acc => func => init => input => Prelude_Types_foldl_Foldable_List(func, init, input), a3: elem => $13 => Prelude_Types_null_Foldable_List($13), a4: elem => acc => m => $17 => funcM => init => input => Prelude_Types_foldlM_Foldable_List($17, funcM, init, input), a5: elem => $1e => $1e, a6: a => m => $20 => f => $21 => Prelude_Types_foldMap_Foldable_List($20, f, $21)}, $4, $5), Data_SortedMap_empty($0), $1);
}

/* Data.SortedMap.empty : Ord k => SortedMap k v */
function Data_SortedMap_empty($0) {
 return Data_SortedMap_Dependent_empty($0);
}

/* Data.SortedMap.Dependent.treeInsert' : Ord k => (x : k) -> v x -> Tree n k v o -> Either (Tree n k v o) (Tree n k v o,
(k, Tree n k v o)) */
function Data_SortedMap_Dependent_treeInsertx27($0, $1, $2, $3) {
 switch($3.h) {
  case 0: /* Leaf */ {
   switch($0.a2($1)($3.a1)) {
    case 0: return {h: 1 /* Right */, a1: {a1: {h: 0 /* Leaf */, a1: $1, a2: $2}, a2: {a1: $1, a2: {h: 0 /* Leaf */, a1: $3.a1, a2: $3.a2}}}};
    case 1: return {h: 0 /* Left */, a1: {h: 0 /* Leaf */, a1: $1, a2: $2}};
    case 2: return {h: 1 /* Right */, a1: {a1: {h: 0 /* Leaf */, a1: $3.a1, a2: $3.a2}, a2: {a1: $3.a1, a2: {h: 0 /* Leaf */, a1: $1, a2: $2}}}};
   }
  }
  case 1: /* Branch2 */ {
   switch($0.a5($1)($3.a2)) {
    case 1: {
     const $26 = Data_SortedMap_Dependent_treeInsertx27($0, $1, $2, $3.a1);
     switch($26.h) {
      case 0: /* Left */ return {h: 0 /* Left */, a1: {h: 1 /* Branch2 */, a1: $26.a1, a2: $3.a2, a3: $3.a3}};
      case 1: /* Right */ return {h: 0 /* Left */, a1: {h: 2 /* Branch3 */, a1: $26.a1.a1, a2: $26.a1.a2.a1, a3: $26.a1.a2.a2, a4: $3.a2, a5: $3.a3}};
     }
    }
    case 0: {
     const $38 = Data_SortedMap_Dependent_treeInsertx27($0, $1, $2, $3.a3);
     switch($38.h) {
      case 0: /* Left */ return {h: 0 /* Left */, a1: {h: 1 /* Branch2 */, a1: $3.a1, a2: $3.a2, a3: $38.a1}};
      case 1: /* Right */ return {h: 0 /* Left */, a1: {h: 2 /* Branch3 */, a1: $3.a1, a2: $3.a2, a3: $38.a1.a1, a4: $38.a1.a2.a1, a5: $38.a1.a2.a2}};
     }
    }
   }
  }
  case 2: /* Branch3 */ {
   switch($0.a5($1)($3.a2)) {
    case 1: {
     const $50 = Data_SortedMap_Dependent_treeInsertx27($0, $1, $2, $3.a1);
     switch($50.h) {
      case 0: /* Left */ return {h: 0 /* Left */, a1: {h: 2 /* Branch3 */, a1: $50.a1, a2: $3.a2, a3: $3.a3, a4: $3.a4, a5: $3.a5}};
      case 1: /* Right */ return {h: 1 /* Right */, a1: {a1: {h: 1 /* Branch2 */, a1: $50.a1.a1, a2: $50.a1.a2.a1, a3: $50.a1.a2.a2}, a2: {a1: $3.a2, a2: {h: 1 /* Branch2 */, a1: $3.a3, a2: $3.a4, a3: $3.a5}}}};
     }
    }
    case 0: {
     switch($0.a5($1)($3.a4)) {
      case 1: {
       const $6f = Data_SortedMap_Dependent_treeInsertx27($0, $1, $2, $3.a3);
       switch($6f.h) {
        case 0: /* Left */ return {h: 0 /* Left */, a1: {h: 2 /* Branch3 */, a1: $3.a1, a2: $3.a2, a3: $6f.a1, a4: $3.a4, a5: $3.a5}};
        case 1: /* Right */ return {h: 1 /* Right */, a1: {a1: {h: 1 /* Branch2 */, a1: $3.a1, a2: $3.a2, a3: $6f.a1.a1}, a2: {a1: $6f.a1.a2.a1, a2: {h: 1 /* Branch2 */, a1: $6f.a1.a2.a2, a2: $3.a4, a3: $3.a5}}}};
       }
      }
      case 0: {
       const $88 = Data_SortedMap_Dependent_treeInsertx27($0, $1, $2, $3.a5);
       switch($88.h) {
        case 0: /* Left */ return {h: 0 /* Left */, a1: {h: 2 /* Branch3 */, a1: $3.a1, a2: $3.a2, a3: $3.a3, a4: $3.a4, a5: $88.a1}};
        case 1: /* Right */ return {h: 1 /* Right */, a1: {a1: {h: 1 /* Branch2 */, a1: $3.a1, a2: $3.a2, a3: $3.a3}, a2: {a1: $3.a4, a2: {h: 1 /* Branch2 */, a1: $88.a1.a1, a2: $88.a1.a2.a1, a3: $88.a1.a2.a2}}}};
       }
      }
     }
    }
   }
  }
 }
}

/* Data.SortedMap.Dependent.treeInsert : Ord k => (x : k) ->
v x -> Tree n k v o -> Either (Tree n k v o) (Tree (S n) k v o) */
function Data_SortedMap_Dependent_treeInsert($0, $1, $2, $3) {
 const $4 = Data_SortedMap_Dependent_treeInsertx27($0, $1, $2, $3);
 switch($4.h) {
  case 0: /* Left */ return {h: 0 /* Left */, a1: $4.a1};
  case 1: /* Right */ return {h: 1 /* Right */, a1: {h: 1 /* Branch2 */, a1: $4.a1.a1, a2: $4.a1.a2.a1, a3: $4.a1.a2.a2}};
 }
}

/* Data.SortedMap.Dependent.lookup : k -> SortedDMap k v -> Maybe (y : k ** v y) */
function Data_SortedMap_Dependent_lookup($0, $1) {
 switch($1.h) {
  case 0: /* Empty */ return {h: 0};
  case 1: /* M */ return Data_SortedMap_Dependent_treeLookup($1.a1, $0, $1.a3);
 }
}

/* Data.SortedMap.Dependent.insert : (x : k) -> v x -> SortedDMap k v -> SortedDMap k v */
function Data_SortedMap_Dependent_insert($0, $1, $2) {
 switch($2.h) {
  case 0: /* Empty */ return {h: 1 /* M */, a1: $2.a1, a2: 0n, a3: {h: 0 /* Leaf */, a1: $0, a2: $1}};
  case 1: /* M */ {
   const $9 = Data_SortedMap_Dependent_treeInsert($2.a1, $0, $1, $2.a3);
   switch($9.h) {
    case 0: /* Left */ return {h: 1 /* M */, a1: $2.a1, a2: $2.a2, a3: $9.a1};
    case 1: /* Right */ return {h: 1 /* M */, a1: $2.a1, a2: ($2.a2+1n), a3: $9.a1};
   }
  }
 }
}

/* Data.SortedMap.Dependent.empty : Ord k => SortedDMap k v */
function Data_SortedMap_Dependent_empty($0) {
 return {h: 0 /* Empty */, a1: $0};
}

/* Text.ILex.Internal.DFA.toDFA : DFAState s a => TokenMap8 a -> F1 s (List (Nat, Node)) */
function Text_ILex_Internal_DFA_toDFA($0, $1, $2) {
 const $3 = Text_ILex_Internal_NFA_toNFA($0, $1, $2);
 const $8 = Text_ILex_Internal_DFA_nodes($0, undefined);
 const $c = Text_ILex_Internal_Types_connectedComponent($f => Text_ILex_Internal_Types_children($f), 0n, $0.a5, undefined);
 const $16 = Text_ILex_Internal_Types_normalizeGraph($0, undefined);
 return Text_ILex_Internal_Types_pairs1($0.a5, undefined);
}

/* Text.ILex.Internal.DFA.nodes : DFAState s a => F1' s */
function Text_ILex_Internal_DFA_nodes($0, $1) {
 const $3 = Text_ILex_Internal_Types_pairs1($0.a4, $1);
 const $2 = Prelude_Types_List_mapAppend({h: 0}, $b => Builtin_fst($b), $3);
 return Data_Linear_Traverse1_traverse1_List($11 => $12 => Text_ILex_Internal_DFA_discrete($0, $11, $12), $2, undefined);
}

/* Text.ILex.Internal.DFA.discrete : DFAState s a => Nat -> F1' s */
function Text_ILex_Internal_DFA_discrete($0, $1, $2) {
 const $3 = Text_ILex_Internal_Types_lookup1($1, $0.a5, $2);
 switch($3.h) {
  case 0: /* nothing */ {
   const $a = Text_ILex_Internal_Types_lookupDflt1($1, () => ({a1: $1, a2: {h: 0}, a3: {h: 0}}), $0.a4, undefined);
   const $14 = Text_ILex_Internal_DFA_process($0, {h: 0}, $a.a3)(undefined);
   const $1c = {a1: $a.a1, a2: $a.a2, a3: $14};
   return Text_ILex_Internal_Types_insert1($1, $1c, $0.a5, undefined);
  }
  case undefined: /* just */ return undefined;
 }
}

/* Text.ILex.Internal.NFA.case block in case block in split */
function Text_ILex_Internal_NFA_case__casex20blockx20inx20split_13738($0, $1, $2, $3, $4, $5) {
 switch($5.h) {
  case 0: /* Left */ {
   const $8 = csegen_611();
   const $7 = $8.a3($4)($5.a1);
   switch($7) {
    case 1: return {a1: {a1: $4, a2: $1.a2}, a2: {a1: $3, a2: {a1: $5.a1, a2: $0.a2}}};
    case 0: return {a1: {a1: $5.a1, a2: $0.a2}, a2: {a1: $3, a2: {a1: $4, a2: $1.a2}}};
   }
  }
  case 1: /* Right */ return {a1: {a1: $5.a1.a1, a2: $0.a2}, a2: {a1: $3, a2: {a1: $5.a1.a2, a2: $0.a2}}};
 }
}

/* Text.ILex.Internal.NFA.toNFA : DFAState s a => TokenMap8 a -> F1' s */
function Text_ILex_Internal_NFA_toNFA($0, $1, $2) {
 const $3 = Text_ILex_Internal_ENFA_toENFA($0, $1, $2);
 const $8 = Text_ILex_Internal_NFA_closures($0, undefined);
 return Text_ILex_Internal_Types_connectedComponent($e => Text_ILex_Internal_Types_nchildren($e), 0n, $0.a4, undefined);
}

/* Text.ILex.Internal.NFA.split : NEdge -> NEdge -> (NEdge, (NEdge, NEdge)) */
function Text_ILex_Internal_NFA_split($0, $1) {
 const $2 = Text_ILex_Char_Range_intersection(csegen_561(), $0.a1, $1.a1);
 const $a = {a1: $2, a2: Text_ILex_Internal_Types_union_({h: 0}, $0.a2, $1.a2)};
 const $13 = Text_ILex_Char_Range_difference(csegen_561(), csegen_570(), $0.a1, $2);
 switch($13.h) {
  case 0: /* Left */ return Text_ILex_Internal_NFA_case__casex20blockx20inx20split_13738($1, $0, $2, $a, $13.a1, Text_ILex_Char_Range_difference(csegen_561(), csegen_570(), $1.a1, $2));
  case 1: /* Right */ return {a1: {a1: $13.a1.a1, a2: $0.a2}, a2: {a1: $a, a2: {a1: $13.a1.a2, a2: $0.a2}}};
 }
}

/* Text.ILex.Internal.NFA.prep : NEdge -> NEdges -> NEdges */
function Text_ILex_Internal_NFA_prep($0, $1) {
 let $2;
 switch($0.a1.h) {
  case 0: /* nil */ {
   $2 = 1;
   break;
  }
  default: $2 = 0;
 }
 switch($2) {
  case 1: return $1;
  case 0: return {a1: $0, a2: $1};
 }
}

/* Text.ILex.Internal.NFA.outUnion : NEdges -> NEdges -> NEdges */
function Text_ILex_Internal_NFA_outUnion($0, $1) {
 return Prelude_Types_foldl_Foldable_List($4 => $5 => Text_ILex_Internal_NFA_insertEdge($4, $5), $1, $0);
}

/* Text.ILex.Internal.NFA.joinNNode : NNode -> NNode -> NNode */
function Text_ILex_Internal_NFA_joinNNode($0, $1) {
 return {a1: $0.a1, a2: Text_ILex_Internal_Types_union_({h: 0}, $0.a2, $1.a2), a3: Text_ILex_Internal_NFA_outUnion($0.a3, $1.a3)};
}

/* Text.ILex.Internal.NFA.insertEdge : NEdges -> NEdge -> NEdges */
function Text_ILex_Internal_NFA_insertEdge($0, $1) {
 switch($0.h) {
  case 0: /* nil */ {
   let $3;
   switch($1.a1.h) {
    case 0: /* nil */ {
     $3 = 1;
     break;
    }
    default: $3 = 0;
   }
   switch($3) {
    case 1: return {h: 0};
    case 0: return {a1: $1, a2: {h: 0}};
   }
  }
  case undefined: /* cons */ {
   const $8 = {a1: $0.a1, a2: $0.a2};
   let $b;
   switch($1.a1.h) {
    case 0: /* nil */ {
     $b = 1;
     break;
    }
    default: $b = 0;
   }
   switch($b) {
    case 1: return $8;
    case 0: {
     switch(Prelude_Types_x3dx3d_Eq_x28Listx20x24ax29(csegen_539(), $1.a2, $0.a1.a2)) {
      case 0: {
       switch(Text_ILex_Char_Range_overlap(csegen_561(), $1.a1, $0.a1.a1)) {
        case 0: {
         const $1f = csegen_611();
         const $1e = $1f.a3($1.a1)($0.a1.a1);
         switch($1e) {
          case 1: return Text_ILex_Internal_NFA_prep($1, $8);
          case 0: return {a1: $0.a1, a2: Text_ILex_Internal_NFA_insertEdge($0.a2, $1)};
         }
        }
        case 1: {
         const $2f = Text_ILex_Internal_NFA_split($1, $0.a1);
         return Text_ILex_Internal_NFA_prep($2f.a1, Text_ILex_Internal_NFA_prep($2f.a2.a1, Text_ILex_Internal_NFA_insertEdge($0.a2, $2f.a2.a2)));
        }
       }
      }
      case 1: {
       let $3d;
       switch(Text_ILex_Char_Range_overlap(csegen_561(), $1.a1, $0.a1.a1)) {
        case 1: {
         $3d = 1;
         break;
        }
        case 0: {
         $3d = Text_ILex_Char_Range_adjacent(csegen_561(), csegen_570(), $1.a1, $0.a1.a1);
         break;
        }
       }
       switch($3d) {
        case 0: {
         const $50 = csegen_611();
         const $4f = $50.a3($1.a1)($0.a1.a1);
         switch($4f) {
          case 1: return Text_ILex_Internal_NFA_prep($1, $8);
          case 0: return {a1: $0.a1, a2: Text_ILex_Internal_NFA_insertEdge($0.a2, $1)};
         }
        }
        case 1: return {a1: {a1: Text_ILex_Char_Range_span(csegen_561(), $1.a1, $0.a1.a1), a2: $1.a2}, a2: $0.a2};
       }
      }
     }
    }
   }
  }
 }
}

/* Text.ILex.Internal.NFA.fromEdge : Edge -> NEdge */
function Text_ILex_Internal_NFA_fromEdge($0) {
 return {a1: $0.a1, a2: {a1: $0.a2, a2: {h: 0}}};
}

/* Text.ILex.Internal.NFA.fromENode : Nat -> ENode -> NNode */
function Text_ILex_Internal_NFA_fromENode($0, $1) {
 return {a1: $0, a2: $1.a1, a3: Prelude_Types_List_mapAppend({h: 0}, $9 => Text_ILex_Internal_NFA_fromEdge($9), $1.a3)};
}

/* Text.ILex.Internal.NFA.eclosure : DFAState s a => Nat -> F1 s NNode */
function Text_ILex_Internal_NFA_eclosure($0, $1, $2) {
 const $3 = Text_ILex_Internal_Types_lookup1($1, $0.a4, $2);
 switch($3.h) {
  case 0: /* nothing */ {
   const $a = Text_ILex_Internal_Types_lookupDflt1($1, () => ({a1: {h: 0}, a2: {h: 0}, a3: {h: 0}}), $0.a3, undefined);
   const $14 = Data_Linear_Traverse1_traverse1List({h: 0}, $18 => $19 => Text_ILex_Internal_NFA_eclosure($0, $18, $19), $a.a2, undefined);
   const $21 = Prelude_Types_foldl_Foldable_List(csegen_606(), Text_ILex_Internal_NFA_fromENode($1, $a), $14);
   const $2a = Text_ILex_Internal_Types_insert1($1, $21, $0.a4, undefined);
   return $21;
  }
  case undefined: /* just */ return $3.a1;
 }
}

/* Text.ILex.Internal.NFA.closures : DFAState s a => F1' s */
function Text_ILex_Internal_NFA_closures($0, $1) {
 const $3 = Text_ILex_Internal_Types_pairs1($0.a3, $1);
 const $2 = Prelude_Types_List_mapAppend({h: 0}, $b => Builtin_fst($b), $3);
 const $10 = $11 => $12 => {
  const $13 = Text_ILex_Internal_NFA_eclosure($0, $11, $12);
  return undefined;
 };
 return Data_Linear_Traverse1_traverse1_List($10, $2, undefined);
}

/* Text.ILex.Internal.ENFA.toENFA : DFAState s a => TokenMap8 a -> F1' s */
function Text_ILex_Internal_ENFA_toENFA($0, $1, $2) {
 const $6 = x => $7 => {
  const $8 = Text_ILex_Internal_Types_inc($0, $7);
  return {a1: $8, a2: x};
 };
 const $3 = Data_Linear_Traverse1_traverse1List({h: 0}, $6, $1, $2);
 const $10 = Data_Linear_Traverse1_traverse1_List($13 => $14 => Text_ILex_Internal_Types_insertTerminal($0, $13, $14), $3, undefined);
 const $1b = Data_Linear_Traverse1_traverse1List({h: 0}, $1f => $22 => Text_ILex_Internal_ENFA_enfa($0, $1f.a2.a1, $1f.a1, $22), $3, undefined);
 const $2b = Text_ILex_Internal_Types_insert1(0n, {a1: {h: 0}, a2: $1b, a3: {h: 0}}, $0.a3, undefined);
 const $2a = 0n;
 return undefined;
}

/* Text.ILex.Char.UTF8.8539:17871:go */
function Text_ILex_Char_UTF8_n__8539_17871_go($0, $1, $2, $3) {
 switch($2.a2.h) {
  case 0: /* nil */ return Text_ILex_Char_UTF8_bytes($2.a1, $3.a1);
  case undefined: /* cons */ {
   const $d = {a1: $2.a2.a1, a2: $2.a2.a2};
   const $10 = {a1: $3.a2.a1, a2: $3.a2.a2};
   switch(Prelude_EqOrd_x3dx3d_Eq_Bits8($2.a1, $3.a1)) {
    case 1: return {h: 2 /* And */, a1: Text_ILex_Char_UTF8_bytes($2.a1, $2.a1), a2: Text_ILex_Char_UTF8_n__8539_17871_go($0, $1, $d, $10)};
    case 0: {
     const $21 = {h: 2 /* And */, a1: Text_ILex_Char_UTF8_bytes($2.a1, $2.a1), a2: Text_ILex_Char_UTF8_n__8539_17871_go($0, $1, $d, Data_Vect_map_Functor_x28Vectx20x24nx29($2e => Text_ILex_Char_UTF8_MaxAddByte(), $10))};
     const $31 = {h: 2 /* And */, a1: Text_ILex_Char_UTF8_bytes($3.a1, $3.a1), a2: Text_ILex_Char_UTF8_n__8539_17871_go($0, $1, Data_Vect_map_Functor_x28Vectx20x24nx29($3d => Text_ILex_Char_UTF8_MinAddByte(), $d), $10)};
     switch(Prelude_EqOrd_x3c_Ord_Bits8(_add8u($2.a1, 1), $3.a1)) {
      case 0: return Text_ILex_RExp_x3cx7cx3e(csegen_562(), csegen_570(), $21, $31);
      case 1: return Text_ILex_RExp_x3cx7cx3e(csegen_562(), csegen_570(), $21, Text_ILex_RExp_x3cx7cx3e(csegen_562(), csegen_570(), $31, {h: 2 /* And */, a1: Text_ILex_Char_UTF8_bytes(_add8u($2.a1, 1), _sub8u($3.a1, 1)), a2: Text_ILex_Char_UTF8_anyBytes($d)}));
     }
    }
   }
  }
 }
}

/* Text.ILex.Char.UTF8.toUTF8 : (RExp b, a) -> (RExp8 b, a) */
function Text_ILex_Char_UTF8_toUTF8($0) {
 return {a1: Text_ILex_RExp_adjRanges($5 => Text_ILex_Char_UTF8_toByteRanges($5), $0.a1), a2: $0.a2};
}

/* Text.ILex.Char.UTF8.toByteRanges : Set32 -> RExp8 True */
function Text_ILex_Char_UTF8_toByteRanges($0) {
 return Text_ILex_Char_UTF8_convert(Text_ILex_Char_Set_inters(csegen_156(), csegen_161(), {h: 0}, Text_ILex_Char_Set_unicode(), $0));
}

/* Text.ILex.Char.UTF8.spans : Vect m Bits8 -> Vect n Bits8 -> List Span */
function Text_ILex_Char_UTF8_spans($0, $1) {
 switch($0.h) {
  case undefined: /* cons */ {
   switch($0.a2.h) {
    case 0: /* nil */ {
     switch($1.h) {
      case undefined: /* cons */ {
       switch($1.a2.h) {
        case 0: /* nil */ return {a1: {a1: $0, a2: $1}, a2: {h: 0}};
        default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(127)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(128), $1)};
       }
      }
      default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(127)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(128), $1)};
     }
    }
    case undefined: /* cons */ {
     switch($0.a2.a2.h) {
      case 0: /* nil */ {
       switch($1.h) {
        case undefined: /* cons */ {
         switch($1.a2.h) {
          case undefined: /* cons */ {
           switch($1.a2.a2.h) {
            case 0: /* nil */ return {a1: {a1: $0, a2: $1}, a2: {h: 0}};
            default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(2047)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(2048), $1)};
           }
          }
          default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(2047)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(2048), $1)};
         }
        }
        default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(2047)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(2048), $1)};
       }
      }
      case undefined: /* cons */ {
       switch($0.a2.a2.a2.h) {
        case 0: /* nil */ {
         switch($1.h) {
          case undefined: /* cons */ {
           switch($1.a2.h) {
            case undefined: /* cons */ {
             switch($1.a2.a2.h) {
              case undefined: /* cons */ {
               switch($1.a2.a2.a2.h) {
                case 0: /* nil */ return {a1: {a1: $0, a2: $1}, a2: {h: 0}};
                default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(65535)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(65536), $1)};
               }
              }
              default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(65535)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(65536), $1)};
             }
            }
            default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(65535)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(65536), $1)};
           }
          }
          default: return {a1: {a1: $0, a2: Text_ILex_Char_UTF8_encodeSP(65535)}, a2: Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(65536), $1)};
         }
        }
        case undefined: /* cons */ {
         switch($0.a2.a2.a2.a2.h) {
          case 0: /* nil */ {
           switch($1.h) {
            case undefined: /* cons */ {
             switch($1.a2.h) {
              case undefined: /* cons */ {
               switch($1.a2.a2.h) {
                case undefined: /* cons */ {
                 switch($1.a2.a2.a2.h) {
                  case undefined: /* cons */ {
                   switch($1.a2.a2.a2.a2.h) {
                    case 0: /* nil */ return {a1: {a1: $0, a2: $1}, a2: {h: 0}};
                    default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
                   }
                  }
                  default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
                 }
                }
                default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
               }
              }
              default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
             }
            }
            default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
           }
          }
          default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
         }
        }
        default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
       }
      }
      default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
     }
    }
    default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
   }
  }
  default: return _crashExp('Unhandled input for Text.ILex.Char.UTF8.spans at Text.ILex.Char.UTF8:56:1--56:41');
 }
}

/* Text.ILex.Char.UTF8.go : Bits8 -> (n : Nat) -> Bits32 -> Vect n Bits8 */
function Text_ILex_Char_UTF8_go($0, $1, $2) {
 switch($1) {
  case 0n: return {h: 0};
  default: {
   const $4 = ($1-1n);
   return {a1: _add8u($0, _truncUInt8(_and32u(_shr32u($2, _mul32u(Number(_truncUBigInt32($4)), 6)), 63))), a2: Text_ILex_Char_UTF8_go(128, $4, $2)};
  }
 }
}

/* Text.ILex.Char.UTF8.fromSpan : Span -> RExp8 True */
function Text_ILex_Char_UTF8_fromSpan($0) {
 return Text_ILex_Char_UTF8_n__8539_17871_go($0.a2, $0.a1, $0.a1, $0.a2);
}

/* Text.ILex.Char.UTF8.fromRange : Range32 -> RExp8 True */
function Text_ILex_Char_UTF8_fromRange($0) {
 let $1;
 switch($0.h) {
  case 0: /* nil */ {
   $1 = 1;
   break;
  }
  default: $1 = 0;
 }
 switch($1) {
  case 1: return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_empty()};
  case 0: {
   const $5 = Text_ILex_Char_UTF8_spans(Text_ILex_Char_UTF8_encodeSP(Text_ILex_Char_Range_lowerBound(csegen_156(), $0)), Text_ILex_Char_UTF8_encodeSP(Text_ILex_Char_Range_upperBound(csegen_156(), $0)));
   switch($5.h) {
    case 0: /* nil */ return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_empty()};
    case undefined: /* cons */ return Prelude_Types_foldr_Foldable_List(x => y => Text_ILex_RExp_x3cx7cx3e(csegen_562(), csegen_570(), Text_ILex_Char_UTF8_fromSpan(x), y), Text_ILex_Char_UTF8_fromSpan($5.a1), $5.a2);
   }
  }
 }
}

/* Text.ILex.Char.UTF8.encodeSP : (n : Bits32) -> Vect (S (len (encode n))) Bits8 */
function Text_ILex_Char_UTF8_encodeSP($0) {
 return Text_ILex_Char_UTF8_encode($0);
}

/* Text.ILex.Char.UTF8.encode : Bits32 -> Codepoint */
function Text_ILex_Char_UTF8_encode($0) {
 switch(Prelude_EqOrd_x3c_Ord_Bits32($0, 128)) {
  case 1: return {a1: _truncUInt8($0), a2: {h: 0}};
  case 0: {
   switch(Prelude_EqOrd_x3c_Ord_Bits32($0, 2048)) {
    case 1: return Text_ILex_Char_UTF8_go(192, 2n, $0);
    case 0: {
     switch(Prelude_EqOrd_x3c_Ord_Bits32($0, 65536)) {
      case 1: return Text_ILex_Char_UTF8_go(224, 3n, $0);
      case 0: return Text_ILex_Char_UTF8_go(240, 4n, $0);
     }
    }
   }
  }
 }
}

/* Text.ILex.Char.UTF8.convert : List Range32 -> RExp8 True */
function Text_ILex_Char_UTF8_convert($0) {
 switch($0.h) {
  case 0: /* nil */ return {h: 1 /* Ch */, a1: Text_ILex_Char_Set_empty()};
  case undefined: /* cons */ return Prelude_Types_foldr_Foldable_List(r => y => Text_ILex_RExp_x3cx7cx3e(csegen_562(), csegen_570(), Text_ILex_Char_UTF8_fromRange(r), y), Text_ILex_Char_UTF8_fromRange($0.a1), $0.a2);
 }
}

/* Text.ILex.Char.UTF8.bytes : Bits8 -> Bits8 -> RExp8 True */
function Text_ILex_Char_UTF8_bytes($0, $1) {
 let $4;
 switch(Prelude_EqOrd_x3cx3d_Ord_Bits8($0, $1)) {
  case 1: {
   $4 = {a1: $0, a2: $1};
   break;
  }
  case 0: {
   $4 = {h: 0};
   break;
  }
 }
 const $2 = Text_ILex_Char_Set_range($4);
 return {h: 1 /* Ch */, a1: $2};
}

/* Text.ILex.Char.UTF8.anyBytes : Vect (S n) Bits8 -> RExp8 True */
function Text_ILex_Char_UTF8_anyBytes($0) {
 switch($0.a2.h) {
  case 0: /* nil */ return csegen_615();
  case undefined: /* cons */ return {h: 2 /* And */, a1: csegen_615(), a2: Text_ILex_Char_UTF8_anyBytes($0.a2)};
 }
}

/* Text.ILex.Char.UTF8.MinAddByte : Bits8 */
const Text_ILex_Char_UTF8_MinAddByte = __lazy(function () {
 return 128;
});

/* Text.ILex.Char.UTF8.MaxAddByte : Bits8 */
const Text_ILex_Char_UTF8_MaxAddByte = __lazy(function () {
 return 191;
});

/* Text.ParseError.toParseError : Origin -> String -> Bounded (InnerError e) -> ParseError e */
function Text_ParseError_toParseError($0, $1, $2) {
 return {a1: $0, a2: $2.a2, a3: $2.a2, a4: {a1: $1}, a5: $2.a1};
}

/* Text.ParseError.hexChar : Bits8 -> Char */
function Text_ParseError_hexChar($0) {
 switch($0) {
  case 0: return '0';
  case 1: return '1';
  case 2: return '2';
  case 3: return '3';
  case 4: return '4';
  case 5: return '5';
  case 6: return '6';
  case 7: return '7';
  case 8: return '8';
  case 9: return '9';
  case 10: return 'a';
  case 11: return 'b';
  case 12: return 'c';
  case 13: return 'd';
  case 14: return 'e';
  default: return 'f';
 }
}

/* Text.Bounds.incBytes : ByteString -> Position -> Position */
function Text_Bounds_incBytes($0, $1) {
 return Text_Bounds_n__9325_12498_go($0.a1, $0.a2, $1.a2, $1.a1, $1.a1, $1.a2, $0.a1, 0n);
}

/* Text.ILex.Stack.init : {auto 0 _ : 0 < r} -> a -> F1 q (Stack e a r q) */
function Text_ILex_Stack_init($0, $1) {
 const $2 = ({value:0n});
 const $6 = ({value:0n});
 const $a = ({value:{h: 0}});
 const $e = ({value:$0});
 const $12 = ({value:0});
 const $16 = ({value:{h: 0}});
 const $1a = ({value:{h: 0}});
 const $1e = ({value:{a1: 0n, a2: Data_ByteVect_empty()}});
 return {a1: $2, a2: $6, a3: $a, a4: $e, a5: $12, a6: $16, a7: $1a, a8: $1e};
}

/* Text.ILex.Interfaces.case block in case block in conv' */
function Text_ILex_Interfaces_case__casex20blockx20inx20convx27_15874($0, $1, $2, $3, $4, $5, $6) {
 const $8 = $1.a2(undefined)($5);
 const $e = ($8.value);
 const $7 = ($8.value=($6.a1+$e));
 return $3($4);
}

/* Text.ILex.Interfaces.unexpected : HasError s e => HasPosition s => HasBytes s =>
List String -> s q -> F1 q (BoundedErr e) */
function Text_ILex_Interfaces_unexpected($0, $1, $2, $3, $4, $5) {
 const $6 = ($0(undefined)($4).value);
 switch($6.h) {
  case undefined: /* just */ return $6.a1;
  case 0: /* nothing */ {
   const $f = ($2(undefined)($4).value);
   const $18 = ($1.a1(undefined)($4).value);
   const $21 = ($1.a2(undefined)($4).value);
   const $17 = {a1: $18, a2: $21};
   const $2c = {a1: $17, a2: {a1: $17.a1, a2: ($17.a2+1n)}};
   switch($f.h) {
    case undefined: /* cons */ {
     switch($f.a1) {
      case 0n: return {a1: {h: 1 /* EOI */}, a2: $2c};
      default: {
       const $38 = ($f.a1-1n);
       switch($38) {
        case 0n: {
         const $3c = Data_Buffer_Core_prim__getByteOffset($f.a2.a1, 0n, $f.a2.a2);
         const $42 = Data_String_singleton(_truncToChar($3c));
         switch(Prelude_EqOrd_x3c_Ord_Bits8($3c, 128)) {
          case 1: return {a1: {h: 2 /* Expected */, a1: $3, a2: $42}, a2: $2c};
          case 0: return {a1: {h: 10 /* InvalidByte */, a1: $3c}, a2: $2c};
         }
        }
        default: {
         const $51 = Data_ByteString_toString($f);
         const $54 = {a1: $17, a2: Text_Bounds_incBytes($f, $17)};
         return {a1: {h: 2 /* Expected */, a1: $3, a2: $51}, a2: $54};
        }
       }
      }
     }
    }
    default: {
     const $5e = Data_ByteString_toString($f);
     const $61 = {a1: $17, a2: Text_Bounds_incBytes($f, $17)};
     return {a1: {h: 2 /* Expected */, a1: $3, a2: $5e}, a2: $61};
    }
   }
  }
 }
}

/* Text.ILex.Interfaces.unclosedIfNLorEOI : HasError s e => HasPosition s => HasBytes s =>
String -> List String -> s q -> F1 q (BoundedErr e) */
function Text_ILex_Interfaces_unclosedIfNLorEOI($0, $1, $2, $3, $4, $5, $6) {
 const $7 = ($2(undefined)($5).value);
 switch($7.h) {
  case undefined: /* cons */ {
   switch($7.a1) {
    case 0n: return Text_ILex_Interfaces_unclosed($0, $1, $2, $3, $5, undefined);
    default: {
     switch(Data_ByteVect_any($7.a1, csegen_616(), $7.a2)) {
      case 1: return Text_ILex_Interfaces_unclosed($0, $1, $2, $3, $5, undefined);
      case 0: return Text_ILex_Interfaces_unexpected($0, $1, $2, $4, $5, undefined);
     }
    }
   }
  }
  default: {
   switch(Data_ByteVect_any($7.a1, csegen_616(), $7.a2)) {
    case 1: return Text_ILex_Interfaces_unclosed($0, $1, $2, $3, $5, undefined);
    case 0: return Text_ILex_Interfaces_unexpected($0, $1, $2, $4, $5, undefined);
   }
  }
 }
}

/* Text.ILex.Interfaces.unclosedIfEOI : HasError s e => HasPosition s => HasBytes s =>
String -> List String -> s q -> F1 q (BoundedErr e) */
function Text_ILex_Interfaces_unclosedIfEOI($0, $1, $2, $3, $4, $5, $6) {
 const $7 = ($2(undefined)($5).value);
 switch($7.h) {
  case undefined: /* cons */ {
   switch($7.a1) {
    case 0n: return Text_ILex_Interfaces_unclosed($0, $1, $2, $3, $5, undefined);
    default: return Text_ILex_Interfaces_unexpected($0, $1, $2, $4, $5, undefined);
   }
  }
  default: return Text_ILex_Interfaces_unexpected($0, $1, $2, $4, $5, undefined);
 }
}

/* Text.ILex.Interfaces.unclosed : HasError s e => HasPosition s => HasBytes s =>
String -> s q -> F1 q (BoundedErr e) */
function Text_ILex_Interfaces_unclosed($0, $1, $2, $3, $4, $5) {
 const $6 = Text_ILex_Interfaces_popAndGetBounds($4, $1, Prelude_Types_String_length($3), $5);
 return {a1: {h: 8 /* Unclosed */, a1: $3}, a2: $6};
}

/* Text.ILex.Interfaces.popAndGetBounds : s q => HasPosition s => Nat -> F1 q Bounds */
function Text_ILex_Interfaces_popAndGetBounds($0, $1, $2, $3) {
 const $4 = ($1.a3(undefined)($0).value);
 switch($4.h) {
  case undefined: /* cons */ {
   const $e = ($1.a3(undefined)($0).value=$4.a1);
   return {a1: $4.a2, a2: {a1: $4.a2.a1, a2: ($4.a2.a2+$2)}};
  }
  case 0: /* nil */ return {h: 0};
 }
}

/* Text.ILex.Runner.case block in runFrom,go */
function Text_ILex_Runner_case__runFromx2cgo_9494($0, $1, $2, $3, $4, $5, $6) {
 return Text_ILex_Runner_loop($6, $5, $1, $5.a7(undefined)($6), $5.a1, $2, $3, undefined);
}

/* Text.ILex.Runner.7436:9476:go */
function Text_ILex_Runner_n__7436_9476_go($0, $1, $2, $3, $4, $5, $6) {
 return Text_ILex_Runner_case__runFromx2cgo_9494($0, $1, $2, $3, $4, $5, $5.a2($6));
}

/* Text.ILex.Runner.runFrom : Parser1 e r s a -> (pos : Nat) -> Ix pos n => IBuffer n -> Either e a */
function Text_ILex_Runner_runFrom($0, $1, $2, $3, $4) {
 return Data_Linear_Token_run1($7 => $8 => Text_ILex_Runner_n__7436_9476_go($0, $4, $2, $3, $1, $1(undefined), $8));
}

/* JSON.Simple.FromJSON.case block in decode */
function JSON_Simple_FromJSON_case__decode_14999($0, $1, $2) {
 switch($2.h) {
  case 1: /* Right */ {
   const $4 = $0($2.a1);
   switch($4.h) {
    case 1: /* Right */ return {h: 1 /* Right */, a1: $4.a1};
    case 0: /* Left */ return {h: 0 /* Left */, a1: {h: 0 /* JErr */, a1: $4.a1}};
   }
  }
  case 0: /* Left */ return {h: 0 /* Left */, a1: {h: 1 /* JParseErr */, a1: $2.a1}};
 }
}

/* JSON.Simple.FromJSON.fromJSON */
function JSON_Simple_FromJSON_fromJSON_FromJSON_Nat($0) {
 const $3 = n => {
  switch(Prelude_EqOrd_x3ex3d_Ord_Integer(n, 0n)) {
   case 1: return {h: 1 /* Right */, a1: Prelude_Types_prim__integerToNat(n)};
   case 0: return {h: 0 /* Left */, a1: {a1: {h: 0}, a2: Prelude_Types_foldMap_Foldable_List(csegen_114(), $12 => $12, {a1: 'not a natural number: ', a2: {a1: Prelude_Show_show_Show_Integer(n), a2: {h: 0}}})}};
  }
 };
 return JSON_Simple_FromJSON_withInteger(() => 'Nat', $3, $0);
}

/* JSON.Simple.FromJSON.fromJSON */
function JSON_Simple_FromJSON_fromJSON_FromJSON_x28Listx20x24ax29($0, $1) {
 const $4 = $5 => {
  const $8 = b => a => func => $9 => {
   switch($9.h) {
    case 0: /* Left */ return {h: 0 /* Left */, a1: $9.a1};
    case 1: /* Right */ return {h: 1 /* Right */, a1: func($9.a1)};
   }
  };
  const $7 = {a1: $8, a2: a => $10 => ({h: 1 /* Right */, a1: $10}), a3: b => a => csegen_115()};
  return Prelude_Types_traverse_Traversable_List($7, $0, $5);
 };
 return JSON_Simple_FromJSON_withArray(() => 'List', $4, $1);
}

/* JSON.Simple.FromJSON.withValue : String -> (JSON -> Maybe t) -> Lazy String -> Parser t a -> Parser JSON a */
function JSON_Simple_FromJSON_withValue($0, $1, $2, $3, $4) {
 const $5 = $1($4);
 switch($5.h) {
  case undefined: /* just */ return $3($5.a1);
  case 0: /* nothing */ {
   const $a = JSON_Simple_FromJSON_typeMismatch($0, $4);
   switch($a.h) {
    case 0: /* Left */ return {h: 0 /* Left */, a1: {a1: $a.a1.a1, a2: (Prelude_Types_foldMap_Foldable_List(csegen_114(), $17 => $17, {a1: 'parsing ', a2: {a1: $2(), a2: {a1: ' failed, ', a2: {h: 0}}}})+$a.a1.a2)}};
    case 1: /* Right */ return {h: 1 /* Right */, a1: $a.a1};
   }
  }
 }
}

/* JSON.Simple.FromJSON.withInteger : Lazy String -> Parser Integer a -> Parser JSON a */
function JSON_Simple_FromJSON_withInteger($0, $1, $2) {
 const $5 = $6 => {
  switch($6.h) {
   case 1: /* JInteger */ return {a1: $6.a1};
   default: return {h: 0};
  }
 };
 return JSON_Simple_FromJSON_withValue('Integer', $5, $0, $1, $2);
}

/* JSON.Simple.FromJSON.withArray : Lazy String -> Parser (List JSON) a -> Parser JSON a */
function JSON_Simple_FromJSON_withArray($0, $1, $2) {
 const $5 = $6 => {
  switch($6.h) {
   case 5: /* JArray */ return {a1: $6.a1};
   default: return {h: 0};
  }
 };
 return JSON_Simple_FromJSON_withValue('Array', $5, $0, $1, $2);
}

/* JSON.Simple.FromJSON.typeOf : JSON -> String */
function JSON_Simple_FromJSON_typeOf($0) {
 switch($0.h) {
  case 0: /* JNull */ return 'Null';
  case 3: /* JBool */ return 'Boolean';
  case 2: /* JDouble */ return 'Double';
  case 1: /* JInteger */ return 'Integer';
  case 4: /* JString */ return 'String';
  case 5: /* JArray */ return 'Array';
  case 6: /* JObject */ return 'Object';
 }
}

/* JSON.Simple.FromJSON.typeMismatch : String -> Parser JSON a */
function JSON_Simple_FromJSON_typeMismatch($0, $1) {
 return {h: 0 /* Left */, a1: {a1: {h: 0}, a2: Prelude_Types_foldMap_Foldable_List(csegen_114(), $9 => $9, {a1: 'expected ', a2: {a1: $0, a2: {a1: ', but encountered ', a2: {a1: JSON_Simple_FromJSON_typeOf($1), a2: {h: 0}}}}})}};
}

/* JSON.Simple.FromJSON.orElse : Either a b -> Lazy (Either a b) -> Either a b */
function JSON_Simple_FromJSON_orElse($0, $1) {
 switch($0.h) {
  case 1: /* Right */ return $0;
  default: return $1();
 }
}

/* JSON.Simple.FromJSON.fromTaggedObject : Lazy String -> String -> String -> Parser (String, JSON) a -> Parser JSON a */
function JSON_Simple_FromJSON_fromTaggedObject($0, $1, $2, $3, $4) {
 return JSON_Simple_FromJSON_withValue('Object', csegen_626(), $0, o => Prelude_Types_x3ex3ex3d_Monad_x28Eitherx20x24ex29(JSON_Simple_FromJSON_explicitParseField($f => JSON_Simple_FromJSON_withValue('String', csegen_627(), () => 'String', $16 => ({h: 1 /* Right */, a1: $16}), $f), o, $1), s => Prelude_Types_x3ex3ex3d_Monad_x28Eitherx20x24ex29(JSON_Simple_FromJSON_explicitParseField($20 => ({h: 1 /* Right */, a1: $20}), o, $2), v => $3({a1: s, a2: v}))), $4);
}

/* JSON.Simple.FromJSON.explicitParseField : Parser JSON a -> List (String, JSON) -> Parser String a */
function JSON_Simple_FromJSON_explicitParseField($0, $1, $2) {
 const $3 = Data_List_lookup(csegen_631(), $2, $1);
 switch($3.h) {
  case 0: /* nothing */ return {h: 0 /* Left */, a1: {a1: {h: 0}, a2: Prelude_Types_foldMap_Foldable_List(csegen_114(), $10 => $10, {a1: 'key ', a2: {a1: Prelude_Show_show_Show_String($2), a2: {a1: ' not found', a2: {h: 0}}}})}};
  case undefined: /* just */ {
   const $1a = $0($3.a1);
   switch($1a.h) {
    case 0: /* Left */ return {h: 0 /* Left */, a1: {a1: {a1: {h: 0 /* Key */, a1: $2}, a2: $1a.a1.a1}, a2: $1a.a1.a2}};
    case 1: /* Right */ return {h: 1 /* Right */, a1: $1a.a1};
   }
  }
 }
}

/* JSON.Simple.FromJSON.(<|>) : Parser v a -> Parser v a -> Parser v a */
function JSON_Simple_FromJSON_x3cx7cx3e($0, $1, $2) {
 return JSON_Simple_FromJSON_orElse($0($2), () => $1($2));
}

/* Web.MVC.runController : (e -> s -> (s, Cmd e)) -> (JSErr -> IO ()) -> e -> s -> IO () */
function Web_MVC_runController($0, $1, $2, $3, $4) {
 const $5 = Data_IORef_newIORef(csegen_111()(), $3)($4);
 const $d = Data_IORef_newIORef(csegen_111()(), 0)($4);
 const $15 = Data_IORef_newIORef(csegen_111()(), {a1: {h: 0}, a2: {h: 0}})($4);
 return Web_MVC_n__6231_4025_handle($2, $3, $1, $0, $5, $d, $15, $2, $4);
}

/* Text.HTML.Attribute.onInput : (String -> ev) -> Attribute t ev */
function Text_HTML_Attribute_onInput($0) {
 return {h: 3 /* Event_ */, a1: 0, a2: 0, a3: {h: 14 /* Input */, a1: $5 => ({a1: $0($5.a1)})}};
}

/* Web.MVC.View.21642:9785:onresize */
function Web_MVC_View_n__21642_9785_onresize($0, $1, $2, $3, $4, $5) {
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), JS_Inheritance_tryCast_(csegen_634(), () => 'Web.MVC.View.onresize', $1), va => Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $16 => Web_MVC_View_prim__observeResize(va, r => $1a => JS_Util_runJS(Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_MVC_Util_toRect(r), rect => Prelude_Types_maybe(() => csegen_37()(), () => $4, $5(rect))), $1a), $16)));
}

/* Web.MVC.View.21642:9784:inst */
function Web_MVC_View_n__21642_9784_inst($0, $1, $2, $3, $4, $5, $6, $7, $8) {
 const $f = e => {
  const $17 = canc => {
   const $1f = bubl => {
    let $29;
    switch(canc) {
     case 1: {
      $29 = $3;
      break;
     }
     case 0: {
      $29 = 0;
      break;
     }
    }
    const $24 = Prelude_Interfaces_when(csegen_56()(), $29, () => Web_Raw_Dom_Event_preventDefault(e));
    const $2e = $2f => {
     let $39;
     switch(bubl) {
      case 1: {
       $39 = $2;
       break;
      }
      case 0: {
       $39 = 0;
       break;
      }
     }
     const $34 = Prelude_Interfaces_when(csegen_56()(), $39, () => Web_Raw_Dom_Event_stopPropagation(e));
     return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $34, $3f => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), JS_Inheritance_tryCast_($5, () => 'Web.MVC.View.inst', e), va => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $7(va), $52 => Prelude_Types_maybe(() => csegen_37()(), () => $4, $8($52)))));
    };
    return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $24, $2e);
   };
   return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Dom_Event_bubbles(e), $1f);
  };
  return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Dom_Event_cancelable(e), $17);
 };
 const $d = Web_Dom_callback_Callback_EventListener_x28x25pix20RigWx20Explicitx20Nothingx20Eventx20x28JSIOx20x28x7cUnitx2cMkUnitx7cx29x29x29($f);
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $d, c => Web_Raw_Dom_EventTarget_addEventListener($1, $6, {a1: c}));
}

/* Web.MVC.View.setupNodes : (Element -> DocumentFragment -> JSIO ()) -> Ref t -> List (Node e) -> Cmd e */
function Web_MVC_View_setupNodes($0, $1, $2, $3) {
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Dom_document(), doc => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_MVC_Util_castElementByRef(csegen_634(), $1), elem => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Dom_Document_createDocumentFragment(doc), df => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $22 => Web_MVC_View_addNodes($3, doc, df, $2, $22), $2a => $0(elem)(df)))));
}

/* Web.MVC.View.setAttribute : (e -> JSIO ()) -> Element -> Attribute t e -> JSIO () */
function Web_MVC_View_setAttribute($0, $1, $2) {
 switch($2.h) {
  case 0: /* Id */ return Web_Raw_Dom_Element_setAttribute($1, 'id', $2.a1.a2);
  case 1: /* Str */ return Web_Raw_Dom_Element_setAttribute($1, $2.a1, $2.a2);
  case 2: /* Bool */ {
   switch($2.a2) {
    case 1: return Web_Raw_Dom_Element_setAttribute($1, $2.a1, '');
    case 0: return Web_Raw_Dom_Element_removeAttribute($1, $2.a1);
   }
  }
  case 3: /* Event_ */ return Web_MVC_View_registerDOMEvent($0, $2.a1, $2.a2, $1, $2.a3);
  case 4: /* Empty */ return csegen_37()();
 }
}

/* Web.MVC.View.registerDOMEvent : (e -> JSIO ()) -> Bool -> Bool -> EventTarget -> DOMEvent e -> JSIO () */
function Web_MVC_View_registerDOMEvent($0, $1, $2, $3, $4) {
 switch($4.h) {
  case 14: /* Input */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_635(), 'input', $10 => Web_MVC_Event_changeInfo($10), $4.a1);
  case 13: /* Change */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_635(), 'change', $1e => Web_MVC_Event_changeInfo($1e), $4.a1);
  case 0: /* Click */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'click', $2c => Web_MVC_Event_mouseInfo($2c), $4.a1);
  case 1: /* DblClick */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'dblclick', $3a => Web_MVC_Event_mouseInfo($3a), $4.a1);
  case 11: /* KeyDown */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_637(), 'keydown', $48 => Web_MVC_Event_keyInfo($48), $4.a1);
  case 12: /* KeyUp */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_637(), 'keyup', $56 => Web_MVC_Event_keyInfo($56), $4.a1);
  case 9: /* Blur */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_635(), 'blur', $64 => Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $4.a1), $6b => ({a1: $6b}));
  case 10: /* Focus */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_635(), 'focus', $77 => Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $4.a1), $7e => ({a1: $7e}));
  case 2: /* MouseDown */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'mousedown', $8a => Web_MVC_Event_mouseInfo($8a), $4.a1);
  case 3: /* MouseUp */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'mouseup', $98 => Web_MVC_Event_mouseInfo($98), $4.a1);
  case 4: /* MouseEnter */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'mouseenter', $a6 => Web_MVC_Event_mouseInfo($a6), $4.a1);
  case 5: /* MouseLeave */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'mouseleave', $b4 => Web_MVC_Event_mouseInfo($b4), $4.a1);
  case 6: /* MouseOver */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'mouseover', $c2 => Web_MVC_Event_mouseInfo($c2), $4.a1);
  case 7: /* MouseOut */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'mouseout', $d0 => Web_MVC_Event_mouseInfo($d0), $4.a1);
  case 8: /* MouseMove */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_636(), 'mousemove', $de => Web_MVC_Event_mouseInfo($de), $4.a1);
  case 15: /* HashChange */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_635(), 'hashchange', $ec => Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $4.a1), $f3 => ({a1: $f3}));
  case 16: /* Scroll */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, csegen_635(), 'scroll', $ff => Web_MVC_Event_scrollInfo($ff), $4.a1);
  case 17: /* Wheel */ return Web_MVC_View_n__21642_9784_inst($4, $3, $2, $1, $0, $10a => $10b => Web_Internal_UIEventsTypes_safeCast_SafeCast_WheelEvent($10b), 'wheel', $110 => Web_MVC_Event_wheelInfo($110), $4.a1);
  case 18: /* Resize */ return Web_MVC_View_n__21642_9785_onresize($4, $3, $2, $1, $0, $4.a1);
 }
}

/* Web.MVC.View.addNodes : {auto 0 conArg : JSType t} -> {auto 0 _ : Elem ParentNode (Types t)} ->
(e -> JSIO ()) -> Document -> t -> List (Node e) -> JSIO () */
function Web_MVC_View_addNodes($0, $1, $2, $3, $4) {
 return Control_Monad_Either_Extra_traverseList_($7 => Web_MVC_View_addNode($0, $1, $2, $7), $3, $4);
}

/* Web.MVC.View.addNode : {auto 0 conArg : JSType t} -> {auto 0 _ : Elem ParentNode (Types t)} ->
(e -> JSIO ()) -> Document -> t -> Node e -> JSIO () */
function Web_MVC_View_addNode($0, $1, $2, $3) {
 switch($3.h) {
  case 0: /* El */ return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Dom_Document_createElement($1, $3.a1), n => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Dom_ParentNode_append($2, {a1: Data_List_Quantifiers_Extra_inject(0n, n), a2: {h: 0}}), $1c => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $22 => Web_MVC_View_addNodes($0, $1, n, $3.a3, $22), $2a => $2b => Control_Monad_Either_Extra_traverseList_($2e => Web_MVC_View_setAttribute($0, n, $2e), $3.a2, $2b))));
  case 1: /* Raw */ {
   const $3d = el => {
    const $4a = $4b => {
     switch($4b.h) {
      case undefined: /* just */ return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), JS_Attribute_x2ex3d(Web_Raw_Dom_InnerHTML_innerHTML($4b.a1), $3.a1), $58 => Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Html_HTMLTemplateElement_content($4b.a1), c => Web_Raw_Dom_ParentNode_append($2, {a1: Data_List_Quantifiers_Extra_inject(0n, c), a2: {h: 0}})));
      case 0: /* nothing */ return csegen_37()();
     }
    };
    return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Web_Internal_HtmlTypes_safeCast_SafeCast_HTMLTemplateElement(el)), $4a);
   };
   return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Dom_Document_createElement($1, 'template'), $3d);
  }
  case 2: /* Text */ return Web_Raw_Dom_ParentNode_append($2, {a1: Data_List_Quantifiers_Extra_inject(1n, $3.a1), a2: {h: 0}});
  case 3: /* Empty */ return csegen_37()();
 }
}

/* Web.MVC.Util.toRect : DOMRect -> JSIO Rect */
function Web_MVC_Util_toRect($0) {
 return Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $2e => $2f => $30 => $31 => $32 => $33 => $34 => $35 => ({a1: $2e, a2: $2f, a3: $30, a4: $31, a5: $32, a6: $33, a7: $34, a8: $35})), Web_Raw_Geometry_DOMRectReadOnly_x($0)), Web_Raw_Geometry_DOMRectReadOnly_y($0)), Web_Raw_Geometry_DOMRectReadOnly_height($0)), Web_Raw_Geometry_DOMRectReadOnly_width($0)), Web_Raw_Geometry_DOMRectReadOnly_top($0)), Web_Raw_Geometry_DOMRectReadOnly_bottom($0)), Web_Raw_Geometry_DOMRectReadOnly_left($0)), Web_Raw_Geometry_DOMRectReadOnly_right($0));
}

/* Web.MVC.Util.strictGetElementById : SafeCast t => Maybe String -> String -> JSIO t */
function Web_MVC_Util_strictGetElementById($0, $1, $2) {
 const $b = $c => {
  switch($c.h) {
   case 0: /* nothing */ {
    const $13 = Data_Maybe_fromMaybe(() => 'element', $1);
    const $12 = {h: 0 /* Caught */, a1: Prelude_Types_foldMap_Foldable_List(csegen_114(), $1c => $1c, {a1: 'Web.MVC.Output.strictGetElementById: Could not find ', a2: {a1: $13, a2: {a1: ' with id ', a2: {a1: $2, a2: {h: 0}}}}})};
    return Control_Monad_Error_Interface_throwError_MonadError_x24e_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), $12);
   }
   case undefined: /* just */ return Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $c.a1);
  }
 };
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Dom_castElementById_($0, $2), $b);
}

/* Web.MVC.Util.nodeList : DocumentFragment -> List (HSum [Node, String]) */
function Web_MVC_Util_nodeList($0) {
 return {a1: Data_List_Quantifiers_Extra_inject(0n, $0), a2: {h: 0}};
}

/* Web.MVC.Util.err : String */
const Web_MVC_Util_err = __lazy(function () {
 return 'Web.MVC.Output.castElementByRef';
});

/* Web.MVC.Util.castElementByRef : SafeCast t => Ref x -> JSIO t */
function Web_MVC_Util_castElementByRef($0, $1) {
 switch($1.h) {
  case 0: /* Id */ return Web_MVC_Util_strictGetElementById($0, {a1: $1.a1}, $1.a2);
  case 1: /* Elem */ return Web_MVC_Util_strictGetElementById($0, {h: 0}, $1.a1);
  case 2: /* Body */ return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Dom_body(), $13 => JS_Inheritance_tryCast($0, () => Web_MVC_Util_err(), $13));
  case 3: /* Document */ return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Dom_document(), $20 => JS_Inheritance_tryCast($0, () => Web_MVC_Util_err(), $20));
  case 4: /* Window */ return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Dom_window(), $2d => JS_Inheritance_tryCast($0, () => Web_MVC_Util_err(), $2d));
 }
}

/* Web.Raw.Geometry.DOMRectReadOnly.y : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem DOMRectReadOnly (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_Geometry_DOMRectReadOnly_y($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_GeometryPrim_DOMRectReadOnly_prim__y($0, $6));
}

/* Web.Raw.Geometry.DOMRectReadOnly.x : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem DOMRectReadOnly (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_Geometry_DOMRectReadOnly_x($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_GeometryPrim_DOMRectReadOnly_prim__x($0, $6));
}

/* Web.Raw.Geometry.DOMRectReadOnly.width : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem DOMRectReadOnly (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_Geometry_DOMRectReadOnly_width($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_GeometryPrim_DOMRectReadOnly_prim__width($0, $6));
}

/* Web.Raw.Geometry.DOMRectReadOnly.top : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem DOMRectReadOnly (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_Geometry_DOMRectReadOnly_top($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_GeometryPrim_DOMRectReadOnly_prim__top($0, $6));
}

/* Web.Raw.Geometry.DOMRectReadOnly.right : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem DOMRectReadOnly (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_Geometry_DOMRectReadOnly_right($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_GeometryPrim_DOMRectReadOnly_prim__right($0, $6));
}

/* Web.Raw.Geometry.DOMRectReadOnly.left : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem DOMRectReadOnly (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_Geometry_DOMRectReadOnly_left($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_GeometryPrim_DOMRectReadOnly_prim__left($0, $6));
}

/* Web.Raw.Geometry.DOMRectReadOnly.height : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem DOMRectReadOnly (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_Geometry_DOMRectReadOnly_height($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_GeometryPrim_DOMRectReadOnly_prim__height($0, $6));
}

/* Web.Raw.Geometry.DOMRectReadOnly.bottom : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem DOMRectReadOnly (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_Geometry_DOMRectReadOnly_bottom($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_GeometryPrim_DOMRectReadOnly_prim__bottom($0, $6));
}

/* Web.Dom.callback */
function Web_Dom_callback_Callback_EventListener_x28x25pix20RigWx20Explicitx20Nothingx20Eventx20x28JSIOx20x28x7cUnitx2cMkUnitx7cx29x29x29($0) {
 return Web_Raw_Dom_EventListener_toEventListener($3 => $4 => JS_Util_runJS($0($3), $4));
}

/* Web.Dom.window : JSIO Window */
const Web_Dom_window = __lazy(function () {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $5 => Web_Dom_prim__window($5));
});

/* Web.Dom.getElementById : String -> JSIO (Maybe Element) */
function Web_Dom_getElementById($0) {
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Dom_document(), $8 => Web_Raw_Dom_NonElementParentNode_getElementById($8, $0));
}

/* Web.Dom.document : JSIO Document */
const Web_Dom_document = __lazy(function () {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $5 => Web_Dom_prim__document($5));
});

/* Web.Dom.castElementById_ : SafeCast a => String -> JSIO (Maybe a) */
function Web_Dom_castElementById_($0, $1) {
 return Control_Monad_Error_Either_map_Functor_x28x28EitherTx20x24ex29x20x24mx29(csegen_645(), $6 => Prelude_Types_x3ex3ex3d_Monad_Maybe($6, $0(undefined)), Web_Dom_getElementById($1));
}

/* Web.Dom.body : JSIO HTMLElement */
const Web_Dom_body = __lazy(function () {
 return JS_Util_unMaybe('Web.Dom.body', Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Dom_document(), $a => JS_Attribute_to($d => Web_Raw_Dom_Document_body($d), $a)));
});

/* Web.Raw.Dom.EventListener.toEventListener : (Event -> IO ()) -> JSIO EventListener */
function Web_Raw_Dom_EventListener_toEventListener($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_DomPrim_EventListener_prim__toEventListener($0, $6));
}

/* Web.Raw.Dom.Event.target : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Event (Types t1)} ->
t1 -> JSIO (Maybe EventTarget) */
function Web_Raw_Dom_Event_target($0) {
 return JS_Marshall_tryJS($3 => JS_Nullable_fromFFI_FromFFI_x28Maybex20x24ax29_x28Nullablex20x24bx29($6 => Web_Internal_DomTypes_fromFFI_FromFFI_EventTarget_EventTarget($6), $3), () => 'Event.target', $c => Web_Internal_DomPrim_Event_prim__target($0, $c));
}

/* Web.Raw.Dom.Event.stopPropagation : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Event (Types t1)} ->
t1 -> JSIO () */
function Web_Raw_Dom_Event_stopPropagation($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_DomPrim_Event_prim__stopPropagation($0, $6));
}

/* Web.Raw.Dom.Element.setAttribute : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Element (Types t1)} ->
t1 -> String -> String -> JSIO () */
function Web_Raw_Dom_Element_setAttribute($0, $1, $2) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $8 => Web_Internal_DomPrim_Element_prim__setAttribute($0, $1, $2, $8));
}

/* Web.Raw.Dom.Element.scrollTop : {auto 0 conArg : JSType t} -> {auto 0 _ : Elem Element (Types t)} ->
t -> Attribute True id Double */
function Web_Raw_Dom_Element_scrollTop($0) {
 return JS_Attribute_fromPrim($3 => $3, $5 => JS_Marshall_fromFFI_FromFFI_Double_Double($5), 'Element.getscrollTop', $a => $b => Web_Internal_DomPrim_Element_prim__scrollTop($a, $b), $10 => $11 => $12 => Web_Internal_DomPrim_Element_prim__setScrollTop($10, $11, $12), $0);
}

/* Web.Raw.Dom.Element.scrollHeight : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Element (Types t1)} ->
t1 -> JSIO Int32 */
function Web_Raw_Dom_Element_scrollHeight($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_DomPrim_Element_prim__scrollHeight($0, $6));
}

/* Web.Raw.Dom.ParentNode.replaceChildren : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem ParentNode (Types t1)} ->
t1 -> List (HSum [Node, String]) -> JSIO () */
function Web_Raw_Dom_ParentNode_replaceChildren($0, $1) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $7 => Web_Internal_DomPrim_ParentNode_prim__replaceChildren($0, JS_Array_toFFI_ToFFI_x28Listx20x24ax29_x28IOx20x28Arrayx20x24bx29x29(csegen_652(), $1), $7));
}

/* Web.Raw.Dom.Element.removeAttribute : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Element (Types t1)} ->
t1 -> String -> JSIO () */
function Web_Raw_Dom_Element_removeAttribute($0, $1) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $7 => Web_Internal_DomPrim_Element_prim__removeAttribute($0, $1, $7));
}

/* Web.Raw.Dom.Event.preventDefault : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Event (Types t1)} ->
t1 -> JSIO () */
function Web_Raw_Dom_Event_preventDefault($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_DomPrim_Event_prim__preventDefault($0, $6));
}

/* Web.Raw.Dom.InnerHTML.innerHTML : {auto 0 conArg : JSType t} -> {auto 0 _ : Elem InnerHTML (Types t)} ->
t -> Attribute True id String */
function Web_Raw_Dom_InnerHTML_innerHTML($0) {
 return JS_Attribute_fromPrim($3 => $3, $5 => JS_Marshall_fromFFI_FromFFI_String_String($5), 'InnerHTML.getinnerHTML', $a => $b => Web_Internal_DomPrim_InnerHTML_prim__innerHTML($a, $b), $10 => $11 => $12 => Web_Internal_DomPrim_InnerHTML_prim__setInnerHTML($10, $11, $12), $0);
}

/* Web.Raw.Dom.NonElementParentNode.getElementById : {auto 0 conArg : JSType t1} ->
{auto 0 _ : Elem NonElementParentNode (Types t1)} ->
t1 -> String -> JSIO (Maybe Element) */
function Web_Raw_Dom_NonElementParentNode_getElementById($0, $1) {
 return JS_Marshall_tryJS($4 => JS_Nullable_fromFFI_FromFFI_x28Maybex20x24ax29_x28Nullablex20x24bx29($7 => Web_Internal_DomTypes_fromFFI_FromFFI_Element_Element($7), $4), () => 'NonElementParentNode.getElementById', $d => Web_Internal_DomPrim_NonElementParentNode_prim__getElementById($0, $1, $d));
}

/* Web.Raw.Dom.Document.createElement : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Document (Types t1)} ->
t1 -> String -> JSIO Element */
function Web_Raw_Dom_Document_createElement($0, $1) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $7 => Web_Internal_DomPrim_Document_prim__createElement($0, $1, JS_Undefined_undef(), $7));
}

/* Web.Raw.Dom.Document.createDocumentFragment : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Document (Types t1)} ->
t1 -> JSIO DocumentFragment */
function Web_Raw_Dom_Document_createDocumentFragment($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_DomPrim_Document_prim__createDocumentFragment($0, $6));
}

/* Web.Raw.Dom.Element.clientHeight : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Element (Types t1)} ->
t1 -> JSIO Int32 */
function Web_Raw_Dom_Element_clientHeight($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_DomPrim_Element_prim__clientHeight($0, $6));
}

/* Web.Raw.Dom.Event.cancelable : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Event (Types t1)} ->
t1 -> JSIO Bool */
function Web_Raw_Dom_Event_cancelable($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'Event.cancelable', $8 => Web_Internal_DomPrim_Event_prim__cancelable($0, $8));
}

/* Web.Raw.Dom.Event.bubbles : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem Event (Types t1)} ->
t1 -> JSIO Bool */
function Web_Raw_Dom_Event_bubbles($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'Event.bubbles', $8 => Web_Internal_DomPrim_Event_prim__bubbles($0, $8));
}

/* Web.Raw.Dom.Document.body : {auto 0 conArg : JSType t} -> {auto 0 _ : Elem Document (Types t)} ->
t -> Attribute False Maybe HTMLElement */
function Web_Raw_Dom_Document_body($0) {
 return JS_Attribute_fromNullablePrim($3 => $3, $5 => Web_Internal_HtmlTypes_fromFFI_FromFFI_HTMLElement_HTMLElement($5), 'Document.getbody', $a => $b => Web_Internal_DomPrim_Document_prim__body($a, $b), $10 => $11 => $12 => Web_Internal_DomPrim_Document_prim__setBody($10, $11, $12), $0);
}

/* Web.Raw.Dom.ParentNode.append : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem ParentNode (Types t1)} ->
t1 -> List (HSum [Node, String]) -> JSIO () */
function Web_Raw_Dom_ParentNode_append($0, $1) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $7 => Web_Internal_DomPrim_ParentNode_prim__append($0, JS_Array_toFFI_ToFFI_x28Listx20x24ax29_x28IOx20x28Arrayx20x24bx29x29(csegen_652(), $1), $7));
}

/* Web.Raw.Dom.EventTarget.addEventListener : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem EventTarget (Types t1)} ->
t1 -> String -> Maybe EventListener -> JSIO () */
function Web_Raw_Dom_EventTarget_addEventListener($0, $1, $2) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $8 => Web_Internal_DomPrim_EventTarget_prim__addEventListener($0, $1, JS_Nullable_toFFI_ToFFI_x28Maybex20x24ax29_x28Nullablex20x24bx29($f => $f, $2), JS_Undefined_undef(), $8));
}

/* Web.MVC.Event.wheelInfo : WheelEvent -> JSIO WheelInfo */
function Web_MVC_Event_wheelInfo($0) {
 return Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $1a => $1b => $1c => $1d => ({a1: $1a, a2: $1b, a3: $1c, a4: $1d})), Web_Raw_UIEvents_WheelEvent_deltaMode($0)), Web_Raw_UIEvents_WheelEvent_deltaX($0)), Web_Raw_UIEvents_WheelEvent_deltaY($0)), Web_Raw_UIEvents_WheelEvent_deltaZ($0));
}

/* Web.MVC.Event.scrollInfo : Event -> JSIO ScrollInfo */
function Web_MVC_Event_scrollInfo($0) {
 const $8 = $9 => {
  switch($9.h) {
   case undefined: /* just */ return Prelude_Types_maybe(() => csegen_660()(), () => $10 => Web_MVC_Event_elemScrollInfo($10), Web_Internal_DomTypes_safeCast_SafeCast_Element($9.a1));
   case 0: /* nothing */ return csegen_660()();
  }
 };
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Web_Raw_Dom_Event_target($0), $8);
}

/* Web.MVC.Event.mouseInfo : MouseEvent -> JSIO MouseInfo */
function Web_MVC_Event_mouseInfo($0) {
 return Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $4c => $4d => $4e => $4f => $50 => $51 => $52 => $53 => $54 => $55 => $56 => $57 => $58 => $59 => ({a1: $4c, a2: $4d, a3: $4e, a4: $4f, a5: $50, a6: $51, a7: $52, a8: $53, a9: $54, a10: $55, a11: $56, a12: $57, a13: $58, a14: $59})), Web_Raw_UIEvents_MouseEvent_button($0)), Web_Raw_UIEvents_MouseEvent_buttons($0)), Web_Raw_UIEvents_MouseEvent_clientX($0)), Web_Raw_UIEvents_MouseEvent_clientY($0)), Web_Raw_UIEvents_MouseEvent_offsetX($0)), Web_Raw_UIEvents_MouseEvent_offsetY($0)), Web_Raw_UIEvents_MouseEvent_pageX($0)), Web_Raw_UIEvents_MouseEvent_pageY($0)), Web_Raw_UIEvents_MouseEvent_screenX($0)), Web_Raw_UIEvents_MouseEvent_screenY($0)), Web_Raw_UIEvents_MouseEvent_altKey($0)), Web_Raw_UIEvents_MouseEvent_ctrlKey($0)), Web_Raw_UIEvents_MouseEvent_metaKey($0)), Web_Raw_UIEvents_MouseEvent_shiftKey($0));
}

/* Web.MVC.Event.keyInfo : KeyboardEvent -> JSIO KeyInfo */
function Web_MVC_Event_keyInfo($0) {
 return Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $2e => $2f => $30 => $31 => $32 => $33 => $34 => $35 => ({a1: $2e, a2: $2f, a3: $30, a4: $31, a5: $32, a6: $33, a7: $34, a8: $35})), Web_Raw_UIEvents_KeyboardEvent_key($0)), Web_Raw_UIEvents_KeyboardEvent_code($0)), Web_Raw_UIEvents_KeyboardEvent_location($0)), Web_Raw_UIEvents_KeyboardEvent_isComposing($0)), Web_Raw_UIEvents_KeyboardEvent_altKey($0)), Web_Raw_UIEvents_KeyboardEvent_ctrlKey($0)), Web_Raw_UIEvents_KeyboardEvent_metaKey($0)), Web_Raw_UIEvents_KeyboardEvent_shiftKey($0));
}

/* Web.MVC.Event.files : Event -> JSIO (List File) */
function Web_MVC_Event_files($0) {
 const $f = fs => {
  const $1e = l => {
   let $23;
   switch(l) {
    case 0: {
     $23 = {h: 0};
     break;
    }
    default: $23 = Prelude_Types_List_mapAppend({h: 0}, $28 => Web_MVC_Event_prim__item(fs, $28), Prelude_Types_rangeFromTo_Range_x24a({a1: {a1: csegen_159(), a2: $33 => $34 => Prelude_Num_div_Integral_Bits32($33, $34), a3: $39 => $3a => Prelude_Num_mod_Integral_Bits32($39, $3a)}, a2: {a1: csegen_155(), a2: csegen_161()}}, 0, _sub32u(l, 1)));
   }
   return Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $23);
  };
  return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $1a => Web_MVC_Event_prim__length(fs, $1a)), $1e);
 };
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $b => Web_MVC_Event_prim__files($0, $b)), $f);
}

/* Web.MVC.Event.elemScrollInfo : Element -> JSIO ScrollInfo */
function Web_MVC_Event_elemScrollInfo($0) {
 return Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $15 => $16 => $17 => ({a1: $15, a2: $16, a3: $17})), JS_Attribute_get($0, $1f => Web_Raw_Dom_Element_scrollTop($1f))), Web_Raw_Dom_Element_scrollHeight($0)), Web_Raw_Dom_Element_clientHeight($0));
}

/* Web.MVC.Event.changeInfo : Event -> JSIO InputInfo */
function Web_MVC_Event_changeInfo($0) {
 return Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_x3cx2ax3e_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $15 => $16 => $17 => ({a1: $15, a2: $16, a3: $17})), Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $21 => Web_MVC_Event_prim__input($0, $21))), Web_MVC_Event_files($0)), Control_Monad_Error_Either_map_Functor_x28x28EitherTx20x24ex29x20x24mx29(csegen_645(), $2d => Prelude_EqOrd_x3dx3d_Eq_Bits8(1, $2d), Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $37 => Web_MVC_Event_prim__checked($0, $37))));
}

/* Web.Raw.UIEvents.MouseEvent.shiftKey : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Bool */
function Web_Raw_UIEvents_MouseEvent_shiftKey($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'MouseEvent.shiftKey', $8 => Web_Internal_UIEventsPrim_MouseEvent_prim__shiftKey($0, $8));
}

/* Web.Raw.UIEvents.KeyboardEvent.shiftKey : KeyboardEvent -> JSIO Bool */
function Web_Raw_UIEvents_KeyboardEvent_shiftKey($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'KeyboardEvent.shiftKey', $8 => Web_Internal_UIEventsPrim_KeyboardEvent_prim__shiftKey($0, $8));
}

/* Web.Raw.UIEvents.MouseEvent.screenY : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_UIEvents_MouseEvent_screenY($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__screenY($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.screenX : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_UIEvents_MouseEvent_screenX($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__screenX($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.pageY : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_UIEvents_MouseEvent_pageY($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__pageY($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.pageX : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_UIEvents_MouseEvent_pageX($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__pageX($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.offsetY : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_UIEvents_MouseEvent_offsetY($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__offsetY($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.offsetX : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_UIEvents_MouseEvent_offsetX($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__offsetX($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.metaKey : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Bool */
function Web_Raw_UIEvents_MouseEvent_metaKey($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'MouseEvent.metaKey', $8 => Web_Internal_UIEventsPrim_MouseEvent_prim__metaKey($0, $8));
}

/* Web.Raw.UIEvents.KeyboardEvent.metaKey : KeyboardEvent -> JSIO Bool */
function Web_Raw_UIEvents_KeyboardEvent_metaKey($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'KeyboardEvent.metaKey', $8 => Web_Internal_UIEventsPrim_KeyboardEvent_prim__metaKey($0, $8));
}

/* Web.Raw.UIEvents.KeyboardEvent.location : KeyboardEvent -> JSIO Bits32 */
function Web_Raw_UIEvents_KeyboardEvent_location($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_KeyboardEvent_prim__location($0, $6));
}

/* Web.Raw.UIEvents.KeyboardEvent.key : KeyboardEvent -> JSIO String */
function Web_Raw_UIEvents_KeyboardEvent_key($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_KeyboardEvent_prim__key($0, $6));
}

/* Web.Raw.UIEvents.KeyboardEvent.isComposing : KeyboardEvent -> JSIO Bool */
function Web_Raw_UIEvents_KeyboardEvent_isComposing($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'KeyboardEvent.isComposing', $8 => Web_Internal_UIEventsPrim_KeyboardEvent_prim__isComposing($0, $8));
}

/* Web.Raw.UIEvents.WheelEvent.deltaZ : WheelEvent -> JSIO Double */
function Web_Raw_UIEvents_WheelEvent_deltaZ($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_WheelEvent_prim__deltaZ($0, $6));
}

/* Web.Raw.UIEvents.WheelEvent.deltaY : WheelEvent -> JSIO Double */
function Web_Raw_UIEvents_WheelEvent_deltaY($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_WheelEvent_prim__deltaY($0, $6));
}

/* Web.Raw.UIEvents.WheelEvent.deltaX : WheelEvent -> JSIO Double */
function Web_Raw_UIEvents_WheelEvent_deltaX($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_WheelEvent_prim__deltaX($0, $6));
}

/* Web.Raw.UIEvents.WheelEvent.deltaMode : WheelEvent -> JSIO Bits32 */
function Web_Raw_UIEvents_WheelEvent_deltaMode($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_WheelEvent_prim__deltaMode($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.ctrlKey : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Bool */
function Web_Raw_UIEvents_MouseEvent_ctrlKey($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'MouseEvent.ctrlKey', $8 => Web_Internal_UIEventsPrim_MouseEvent_prim__ctrlKey($0, $8));
}

/* Web.Raw.UIEvents.KeyboardEvent.ctrlKey : KeyboardEvent -> JSIO Bool */
function Web_Raw_UIEvents_KeyboardEvent_ctrlKey($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'KeyboardEvent.ctrlKey', $8 => Web_Internal_UIEventsPrim_KeyboardEvent_prim__ctrlKey($0, $8));
}

/* Web.Raw.UIEvents.KeyboardEvent.code : KeyboardEvent -> JSIO String */
function Web_Raw_UIEvents_KeyboardEvent_code($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_KeyboardEvent_prim__code($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.clientY : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_UIEvents_MouseEvent_clientY($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__clientY($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.clientX : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Double */
function Web_Raw_UIEvents_MouseEvent_clientX($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__clientX($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.buttons : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Bits16 */
function Web_Raw_UIEvents_MouseEvent_buttons($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__buttons($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.button : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Int16 */
function Web_Raw_UIEvents_MouseEvent_button($0) {
 return Control_Monad_Error_Either_liftIO_HasIO_x28x28EitherTx20x24ex29x20x24mx29(csegen_111()(), $6 => Web_Internal_UIEventsPrim_MouseEvent_prim__button($0, $6));
}

/* Web.Raw.UIEvents.MouseEvent.altKey : {auto 0 conArg : JSType t1} -> {auto 0 _ : Elem MouseEvent (Types t1)} ->
t1 -> JSIO Bool */
function Web_Raw_UIEvents_MouseEvent_altKey($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'MouseEvent.altKey', $8 => Web_Internal_UIEventsPrim_MouseEvent_prim__altKey($0, $8));
}

/* Web.Raw.UIEvents.KeyboardEvent.altKey : KeyboardEvent -> JSIO Bool */
function Web_Raw_UIEvents_KeyboardEvent_altKey($0) {
 return JS_Marshall_tryJS($3 => JS_Boolean_fromFFI_FromFFI_Bool_Boolean($3), () => 'KeyboardEvent.altKey', $8 => Web_Internal_UIEventsPrim_KeyboardEvent_prim__altKey($0, $8));
}

/* Data.Queue.enqueue : Queue a -> a -> Queue a */
function Data_Queue_enqueue($0, $1) {
 return {a1: $0.a1, a2: {a1: $0.a2, a2: $1}};
}

/* Data.Queue.dequeue : Queue a -> Maybe (a, Queue a) */
function Data_Queue_dequeue($0) {
 switch($0.a1.h) {
  case undefined: /* cons */ return {a1: {a1: $0.a1.a1, a2: {a1: $0.a1.a2, a2: $0.a2}}};
  case 0: /* nil */ {
   const $8 = Prelude_Types_SnocList_x3cx3ex3e($0.a2, {h: 0});
   switch($8.h) {
    case undefined: /* cons */ return {a1: {a1: $8.a1, a2: {a1: $8.a2, a2: {h: 0}}}};
    case 0: /* nil */ return {h: 0};
   }
  }
 }
}

/* Data.IORef.newIORef : HasIO io => a -> io (IORef a) */
function Data_IORef_newIORef($0, $1) {
 return $0.a1.a2(undefined)(undefined)($0.a2(undefined)($10 => ({value:$1})))(m => $0.a1.a1.a2(undefined)(m));
}

/* Data.IORef.modifyIORef : HasIO io => IORef a -> (a -> a) -> io () */
function Data_IORef_modifyIORef($0, $1, $2) {
 return $0.a1.a2(undefined)(undefined)($0.a2(undefined)($11 => ($1.value)))(val => $0.a2(undefined)($1b => ($1.value=$2(val))));
}

/* EmKit.Wire.JSON.Simple.toJsonExecutePayload : ToJSON cmd => ExecutePayload cmd -> JSON */
function EmKit_Wire_JSON_Simple_toJsonExecutePayload($0, $1) {
 return {h: 6 /* JObject */, a1: {a1: {a1: 'expectedVersion', a2: {h: 1 /* JInteger */, a1: $1.a1}}, a2: {a1: {a1: 'command', a2: $0($1.a2)}, a2: {h: 0}}}};
}

/* EmKit.Wire.JSON.Simple.fromJsonStreamEvent : FromJSON ev => Parser JSON (StreamEvent ev) */
function EmKit_Wire_JSON_Simple_fromJsonStreamEvent($0, $1) {
 const $7 = $8 => {
  const $9 = JSON_Simple_FromJSON_explicitParseField($c => JSON_Simple_FromJSON_fromJSON_FromJSON_Nat($c), $8, 'version');
  switch($9.h) {
   case 1: /* Right */ {
    const $11 = JSON_Simple_FromJSON_explicitParseField($0, $8, 'event');
    switch($11.h) {
     case 1: /* Right */ return {h: 1 /* Right */, a1: {a1: $9.a1, a2: $11.a1}};
     case 0: /* Left */ return {h: 0 /* Left */, a1: $11.a1};
    }
   }
   case 0: /* Left */ return {h: 0 /* Left */, a1: $9.a1};
  }
 };
 return JSON_Simple_FromJSON_withValue('Object', csegen_626(), () => 'StreamEvent', $7, $1);
}

/* EmKit.Wire.JSON.Simple.fromJsonResyncPayload : FromJSON ev => Parser JSON (ResyncPayload ev) */
function EmKit_Wire_JSON_Simple_fromJsonResyncPayload($0, $1) {
 const $7 = $8 => {
  const $9 = JSON_Simple_FromJSON_explicitParseField($c => JSON_Simple_FromJSON_fromJSON_FromJSON_Nat($c), $8, 'version');
  switch($9.h) {
   case 1: /* Right */ {
    const $11 = JSON_Simple_FromJSON_explicitParseField($14 => JSON_Simple_FromJSON_fromJSON_FromJSON_x28Listx20x24ax29($0, $14), $8, 'events');
    switch($11.h) {
     case 1: /* Right */ return {h: 1 /* Right */, a1: {a1: $9.a1, a2: $11.a1}};
     case 0: /* Left */ return {h: 0 /* Left */, a1: $11.a1};
    }
   }
   case 0: /* Left */ return {h: 0 /* Left */, a1: $9.a1};
  }
 };
 return JSON_Simple_FromJSON_withValue('Object', csegen_626(), () => 'ResyncPayload', $7, $1);
}

/* EmKit.Frontend.Stream.subscribeStream : (stream -> String -> String) -> stream -> String -> (String -> msg) -> Cmd msg */
function EmKit_Frontend_Stream_subscribeStream($0, $1, $2, $3, $4) {
 return EmKit_Frontend_SSE_subscribe($0($1)($2), $3, $4);
}

/* EmKit.Frontend.SSE.subscribe : String -> (String -> msg) -> Cmd msg */
function EmKit_Frontend_SSE_subscribe($0, $1, $2) {
 return EmKit_Frontend_SSE_prim__subscribeSSE($0, msg => $2($1(msg)));
}

/* EmKit.Frontend.SSE.requestClientId : (String -> msg) -> Cmd msg */
function EmKit_Frontend_SSE_requestClientId($0, $1) {
 return Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), Control_Monad_Error_Either_x3ex3ex3d_Monad_x28x28EitherTx20x24ex29x20x24mx29(csegen_45()(), EmKit_Frontend_SSE_prim__clientId(), cid => Control_Monad_Error_Either_pure_Applicative_x28x28EitherTx20x24ex29x20x24mx29(csegen_36()(), $0(cid))), $1);
}

/* EmKit.Frontend.Execute.postExecuteSingle : ToJSON commandT =>
(stream -> String) -> (Either HTTPError () -> msg) -> stream -> Nat -> commandT -> Cmd msg */
function EmKit_Frontend_Execute_postExecuteSingle($0, $1, $2, $3, $4, $5, $6) {
 return Web_MVC_Http_request(1, {h: 0}, $1($3), {h: 2 /* JSONBody */, a1: $f => EmKit_Wire_JSON_Simple_toJsonExecutePayload($0, $f), a2: {a1: $4, a2: $5}}, {h: 2 /* ExpectAny */, a1: $2}, {h: 0}, $6);
}

/* EmKit.Frontend.Execute.getResync : FromJSON (ResyncPayload ev) =>
(stream -> String) -> (stream -> Either HTTPError (ResyncPayload ev) -> msg) -> stream -> Cmd msg */
function EmKit_Frontend_Execute_getResync($0, $1, $2, $3, $4) {
 return Web_MVC_Http_request(0, {h: 0}, $1($3), {h: 0 /* Empty */}, {h: 0 /* ExpectJSON */, a1: $0, a2: $2($3)}, {h: 0}, $4);
}

/* Domain.JSON.Simple.toJsonCommand : Command -> JSON */
function Domain_JSON_Simple_toJsonCommand($0) {
 switch($0.h) {
  case 0: /* Create */ return JSON_Simple_ToJSON_taggedObject('tag', 'contents', 'Create', {h: 4 /* JString */, a1: $0.a1});
  case 1: /* Increment */ return {h: 4 /* JString */, a1: 'Increment'};
  case 2: /* Decrement */ return {h: 4 /* JString */, a1: 'Decrement'};
 }
}

/* Domain.JSON.Simple.fromJsonCounterEvent : Parser JSON CounterEvent */
function Domain_JSON_Simple_fromJsonCounterEvent($0) {
 const $2 = $3 => {
  const $9 = x => {
   switch(x) {
    case 'Incremented': return {h: 1 /* Right */, a1: {h: 1 /* Incremented */}};
    case 'Decremented': return {h: 1 /* Right */, a1: {h: 2 /* Decremented */}};
    default: return {h: 0 /* Left */, a1: {a1: {h: 0}, a2: ('Unexpected constructor tag for CounterEvent: '+Prelude_Show_show_Show_String(x))}};
   }
  };
  return JSON_Simple_FromJSON_withValue('String', csegen_627(), () => 'CounterEvent', $9, $3);
 };
 const $15 = $16 => {
  const $1b = x => {
   switch(x.a1) {
    case 'Created': {
     const $1e = JSON_Simple_FromJSON_withValue('String', csegen_627(), () => 'String', $25 => ({h: 1 /* Right */, a1: $25}), x.a2);
     switch($1e.h) {
      case 0: /* Left */ return {h: 0 /* Left */, a1: {a1: {a1: {h: 0 /* Key */, a1: 'Created'}, a2: $1e.a1.a1}, a2: $1e.a1.a2}};
      case 1: /* Right */ return {h: 1 /* Right */, a1: {h: 0 /* Created */, a1: $1e.a1}};
     }
    }
    default: return {h: 0 /* Left */, a1: {a1: {h: 0}, a2: ('Unexpected constructor tag for CounterEvent: '+Prelude_Show_show_Show_String(x.a1))}};
   }
  };
  return JSON_Simple_FromJSON_fromTaggedObject(() => 'CounterEvent', 'tag', 'contents', $1b, $16);
 };
 return JSON_Simple_FromJSON_x3cx7cx3e($2, $15, $0);
}

/* Domain.4798:2267:step */
function Domain_n__4798_2267_step($0, $1, $2, $3, $4) {
 const $5 = Prelude_Types_List_tailRecAppend($4.a3, {a1: $1, a2: {h: 0}});
 const $c = Domain_stepModel($4.a2, $1);
 return {a1: $3, a2: $c, a3: $5};
}

/* Domain.initial */
const Domain_initial_Projection_CounterEvent_CounterModel = __lazy(function () {
 return {a1: 0, a2: '(unnamed)', a3: 0n, a4: ''};
});

/* Domain.availableScreenActions */
function Domain_availableScreenActions_ScreenActions_Screen_CounterBundle_Action_Intent($0, $1) {
 switch($0.a1) {
  case 1: return {a1: 1, a2: {a1: 2, a2: {h: 0}}};
  case 0: return {a1: 0, a2: {h: 0}};
 }
}

/* Domain.stepModel : CounterModel -> CounterEvent -> CounterModel */
function Domain_stepModel($0, $1) {
 switch($1.h) {
  case 0: /* Created */ return {a1: 1, a2: $1.a1, a3: 0n, a4: ''};
  case 1: /* Incremented */ {
   const $7 = ($0.a3+1n);
   return {a1: 1, a2: $0.a2, a3: $7, a4: Domain_romanDigit($7)};
  }
  case 2: /* Decremented */ {
   const $12 = Domain_decNat($0.a3);
   return {a1: 1, a2: $0.a2, a3: $12, a4: Domain_romanDigit($12)};
  }
 }
}

/* Domain.romanDigit : Nat -> String */
function Domain_romanDigit($0) {
 switch($0) {
  case 0n: return '';
  default: {
   const $2 = ($0-1n);
   switch($2) {
    case 0n: return 'I';
    default: {
     const $6 = ($2-1n);
     switch($6) {
      case 0n: return 'II';
      default: {
       const $a = ($6-1n);
       switch($a) {
        case 0n: return 'III';
        default: {
         const $e = ($a-1n);
         switch($e) {
          case 0n: return 'IV';
          default: {
           const $12 = ($e-1n);
           switch($12) {
            case 0n: return 'V';
            default: {
             const $16 = ($12-1n);
             switch($16) {
              case 0n: return 'VI';
              default: {
               const $1a = ($16-1n);
               switch($1a) {
                case 0n: return 'VII';
                default: {
                 const $1e = ($1a-1n);
                 switch($1e) {
                  case 0n: return 'VIII';
                  default: {
                   const $22 = ($1e-1n);
                   switch($22) {
                    case 0n: return 'IX';
                    default: return 'X';
                   }
                  }
                 }
                }
               }
              }
             }
            }
           }
          }
         }
        }
       }
      }
     }
    }
   }
  }
 }
}

/* Domain.renderAction : Action -> String */
function Domain_renderAction($0) {
 switch($0) {
  case 0: return 'Create counter';
  case 1: return 'Increment';
  case 2: return 'Decrement';
 }
}

/* Domain.emptyDetail : CounterDetail */
const Domain_emptyDetail = __lazy(function () {
 return {a1: 0n, a2: Domain_initial_Projection_CounterEvent_CounterModel(), a3: {h: 0}};
});

/* Domain.detailFromEvents : Nat -> List CounterEvent -> CounterDetail */
function Domain_detailFromEvents($0, $1) {
 return {a1: $0, a2: EmKit_Sourcing_Projection_project($6 => ({h: 'Prelude.Basics.List', a1: $6}), {a1: $a => ({h: 'Prelude.Basics.List', a1: $a}), a2: e => ({h: 0}), a3: e => $e => $f => Prelude_Types_List_tailRecAppend($e, $f), a4: e => s => $14 => $15 => $16 => Prelude_Types_foldl_Foldable_List($14, $15, $16), a5: e => a => b => c => Data_List_appendAssociative(a, b, c), a6: e => right => undefined, a7: e => left => Data_List_appendNilRightNeutral(left), a8: e => s => start => step => undefined, a9: e => s => start => step => x => y => undefined}, {h: 'Domain.CounterEvent'}, {h: 'Domain.CounterModel'}, {a1: {h: 'Domain.CounterEvent'}, a2: {h: 'Domain.CounterModel'}, a3: Domain_initial_Projection_CounterEvent_CounterModel(), a4: $2e => $2f => Domain_stepModel($2e, $2f)}, $1), a3: $1};
}

/* Domain.decNat : Nat -> Nat */
function Domain_decNat($0) {
 switch($0) {
  case 0n: return 0n;
  default: return ($0-1n);
 }
}

/* Domain.availableActionsForModel : CounterModel -> List Action */
function Domain_availableActionsForModel($0) {
 return Domain_availableScreenActions_ScreenActions_Screen_CounterBundle_Action_Intent($0, undefined);
}

/* Domain.applyDetailEvent : Nat -> CounterEvent -> CounterDetail -> Either String CounterDetail */
function Domain_applyDetailEvent($0, $1, $2) {
 const $3 = EmKit_Stream_Version_applyVersionedUpdate(csegen_631(), 'counter-main', $2.a1, $0, $c => $d => Domain_n__4798_2267_step($2, $1, $0, $c, $d), $2);
 switch($3.h) {
  case 0: /* Left */ return {h: 0 /* Left */, a1: EmKit_Stream_Version_formatAdvanceError($18 => $18, $3.a1)};
  case 1: /* Right */ {
   switch($3.a1.h) {
    case 0: /* IgnoredStale */ return {h: 1 /* Right */, a1: $3.a1.a1};
    case 1: /* Applied */ return {h: 1 /* Right */, a1: $3.a1.a1};
   }
  }
 }
}

/* EmKit.Stream.Version.upsertStreamVersion : Eq stream => stream -> Nat -> List (stream, Nat) -> List (stream, Nat) */
function EmKit_Stream_Version_upsertStreamVersion($0, $1, $2, $3) {
 switch($3.h) {
  case 0: /* nil */ return {a1: {a1: $1, a2: $2}, a2: {h: 0}};
  case undefined: /* cons */ {
   switch($0.a1($3.a1.a1)($1)) {
    case 1: return {a1: {a1: $1, a2: $2}, a2: $3.a2};
    case 0: return {a1: {a1: $3.a1.a1, a2: $3.a1.a2}, a2: EmKit_Stream_Version_upsertStreamVersion($0, $1, $2, $3.a2)};
   }
  }
 }
}

/* EmKit.Stream.Version.formatAdvanceError : (stream -> String) -> StreamVersionAdvanceError stream -> String */
function EmKit_Stream_Version_formatAdvanceError($0, $1) {
 return ('Live stream version gap on '+($0($1.a1)+(': expected v'+(Prelude_Show_show_Show_Nat($1.a2)+(', got v'+(Prelude_Show_show_Show_Nat($1.a3)+'.'))))));
}

/* EmKit.Stream.Version.applyVersionedUpdate : Eq stream =>
stream -> Nat -> Nat -> (Nat -> state -> state) -> state -> Either (StreamVersionAdvanceError stream) (VersionedUpdate state) */
function EmKit_Stream_Version_applyVersionedUpdate($0, $1, $2, $3, $4, $5) {
 const $6 = EmKit_Stream_Version_advanceStreamVersion($0, $1, $3, {a1: {a1: $1, a2: $2}, a2: {h: 0}});
 switch($6.h) {
  case 0: /* Left */ return {h: 0 /* Left */, a1: $6.a1};
  case 1: /* Right */ {
   switch($6.a1.h) {
    case 0: /* nothing */ return {h: 1 /* Right */, a1: {h: 0 /* IgnoredStale */, a1: $5}};
    case undefined: /* just */ return {h: 1 /* Right */, a1: {h: 1 /* Applied */, a1: $4($3)($5)}};
   }
  }
 }
}

/* EmKit.Stream.Version.advanceStreamVersion : Eq stream => stream -> Nat -> List (stream,
Nat) -> Either (StreamVersionAdvanceError stream) (StreamVersionAdvance stream) */
function EmKit_Stream_Version_advanceStreamVersion($0, $1, $2, $3) {
 const $4 = EmKit_Stream_Version_streamKnownVersion($0, $1, $3);
 switch(Prelude_Types_x3cx3d_Ord_Nat($2, $4)) {
  case 1: return {h: 1 /* Right */, a1: {h: 0}};
  case 0: {
   const $e = ($4+1n);
   switch((($2===$e)?1:0)) {
    case 1: return {h: 1 /* Right */, a1: {a1: EmKit_Stream_Version_upsertStreamVersion($0, $1, $2, $3)}};
    case 0: return {h: 0 /* Left */, a1: {a1: $1, a2: $e, a3: $2}};
   }
  }
 }
}

/* EmKit.Sourcing.Projection.projectFrom : History h => Projection event model => model -> h event -> model */
function EmKit_Sourcing_Projection_projectFrom($0, $1, $2, $3, $4, $5, $6) {
 return $1.a4(undefined)(undefined)($4.a4)($5)($6);
}

/* EmKit.Sourcing.Projection.project : History h => Projection event model => h event -> model */
function EmKit_Sourcing_Projection_project($0, $1, $2, $3, $4, $5) {
 return EmKit_Sourcing_Projection_projectFrom($0, $1, $2, $3, $4, $4.a3, $5);
}


try{__mainExpression_0()}catch(e){if(e instanceof IdrisError){console.log('ERROR: ' + e.message)}else{throw e} }
