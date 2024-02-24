/**
 * @license
 * Copyright 2015 The Emscripten Authors
 * SPDX-License-Identifier: MIT
 */

// Pthread Web Worker startup routine:
// This is the entry point file that is loaded first by each Web Worker
// that executes pthreads on the Emscripten application.

'use strict';

var Module = {};

// Thread-local:

function assert(condition, text) {
  if (!condition) abort('Assertion failed: ' + text);
}

function threadPrintErr() {
  var text = Array.prototype.slice.call(arguments).join(' ');
  console.error(text);
}
function threadAlert() {
  var text = Array.prototype.slice.call(arguments).join(' ');
  postMessage({cmd: 'alert', text: text, threadId: Module['_pthread_self']()});
}
// We don't need out() for now, but may need to add it if we want to use it
// here. Or, if this code all moves into the main JS, that problem will go
// away. (For now, adding it here increases code size for no benefit.)
var out = () => { throw 'out() is not defined in worker.js.'; }
var err = threadPrintErr;
self.alert = threadAlert;

Module['instantiateWasm'] = (info, receiveInstance) => {
  // Instantiate from the module posted from the main thread.
  // We can just use sync instantiation in the worker.
  var instance = new WebAssembly.Instance(Module['wasmModule'], info);
  // TODO: Due to Closure regression https://github.com/google/closure-compiler/issues/3193,
  // the above line no longer optimizes out down to the following line.
  // When the regression is fixed, we can remove this if/else.
  receiveInstance(instance);
  // We don't need the module anymore; new threads will be spawned from the main thread.
  Module['wasmModule'] = null;
  return instance.exports;
}

self.onmessage = (e) => {
  try {
    if (e.data.cmd === 'load') { // Preload command that is called once per worker to parse and load the Emscripten code.

      // Module and memory were sent from main thread
      Module['wasmModule'] = e.data.wasmModule;

      Module['wasmMemory'] = e.data.wasmMemory;

      Module['buffer'] = Module['wasmMemory'].buffer;

      Module['ENVIRONMENT_IS_PTHREAD'] = true;

      if (typeof e.data.urlOrBlob == 'string') {
        importScripts(e.data.urlOrBlob);
      } else {
        var objectUrl = URL.createObjectURL(e.data.urlOrBlob);
        importScripts(objectUrl);
        URL.revokeObjectURL(objectUrl);
      }
      Godot(Module).then(function (instance) {
        Module = instance;
      });
    } else if (e.data.cmd === 'run') {
      // This worker was idle, and now should start executing its pthread entry
      // point.
      // performance.now() is specced to return a wallclock time in msecs since
      // that Web Worker/main thread launched. However for pthreads this can
      // cause subtle problems in emscripten_get_now() as this essentially
      // would measure time from pthread_create(), meaning that the clocks
      // between each threads would be wildly out of sync. Therefore sync all
      // pthreads to the clock on the main browser thread, so that different
      // threads see a somewhat coherent clock across each of them
      // (+/- 0.1msecs in testing).
      Module['__performance_now_clock_drift'] = performance.now() - e.data.time;

      // Pass the thread address inside the asm.js scope to store it for fast access that avoids the need for a FFI out.
      Module['__emscripten_thread_init'](e.data.threadInfoStruct, /*isMainBrowserThread=*/0, /*isMainRuntimeThread=*/0, /*canBlock=*/1);

      assert(e.data.threadInfoStruct);
      // Also call inside JS module to set up the stack frame for this pthread in JS module scope
      Module['establishStackSpace']();
      Module['PThread'].receiveObjectTransfer(e.data);
      Module['PThread'].threadInit();

      try {
        // pthread entry points are always of signature 'void *ThreadMain(void *arg)'
        // Native codebases sometimes spawn threads with other thread entry point signatures,
        // such as void ThreadMain(void *arg), void *ThreadMain(), or void ThreadMain().
        // That is not acceptable per C/C++ specification, but x86 compiler ABI extensions
        // enable that to work. If you find the following line to crash, either change the signature
        // to "proper" void *ThreadMain(void *arg) form, or try linking with the Emscripten linker
        // flag -s EMULATE_FUNCTION_POINTER_CASTS=1 to add in emulation for this x86 ABI extension.
        var result = Module['invokeEntryPoint'](e.data.start_routine, e.data.arg);

        Module['checkStackCookie']();
        if (Module['keepRuntimeAlive']()) {
          Module['PThread'].setExitStatus(result);
        } else {
          Module['__emscripten_thread_exit'](result);
        }
      } catch(ex) {
        if (ex != 'unwind') {
          // ExitStatus not present in MINIMAL_RUNTIME
          if (ex instanceof Module['ExitStatus']) {
            if (Module['keepRuntimeAlive']()) {
              err('Pthread 0x' + Module['_pthread_self']().toString(16) + ' called exit(), staying alive due to noExitRuntime.');
            } else {
              err('Pthread 0x' + Module['_pthread_self']().toString(16) + ' called exit(), calling _emscripten_thread_exit.');
              Module['__emscripten_thread_exit'](ex.status);
            }
          }
          else
          {
            // The pthread "crashed".  Do not call `_emscripten_thread_exit` (which
            // would make this thread joinable.  Instead, re-throw the exception
            // and let the top level handler propagate it back to the main thread.
            throw ex;
          }
        } else {
          // else e == 'unwind', and we should fall through here and keep the pthread alive for asynchronous events.
          err('Pthread 0x' + Module['_pthread_self']().toString(16) + ' completed its main entry point with an `unwind`, keeping the worker alive for asynchronous operation.');
        }
      }
    } else if (e.data.cmd === 'cancel') { // Main thread is asking for a pthread_cancel() on this thread.
      if (Module['_pthread_self']()) {
        Module['__emscripten_thread_exit'](-1/*PTHREAD_CANCELED*/);
      }
    } else if (e.data.target === 'setimmediate') {
      // no-op
    } else if (e.data.cmd === 'processThreadQueue') {
      if (Module['_pthread_self']()) { // If this thread is actually running?
        Module['_emscripten_current_thread_process_queued_calls']();
      }
    } else if (e.data.cmd === 'processProxyingQueue') {
      if (Module['_pthread_self']()) { // If this thread is actually running?
        Module['_emscripten_proxy_execute_queue'](e.data.queue);
      }
    } else {
      err('worker.js received unknown command ' + e.data.cmd);
      err(e.data);
    }
  } catch(ex) {
    err('worker.js onmessage() captured an uncaught exception: ' + ex);
    if (ex && ex.stack) err(ex.stack);
    if (Module['__emscripten_thread_crashed']) {
      Module['__emscripten_thread_crashed']();
    }
    throw ex;
  }
};


