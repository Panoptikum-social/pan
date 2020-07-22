(function webpackUniversalModuleDefinition(root, factory) {
	if (typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if (typeof define === 'function' && define.amd)
		define([], factory);
	else if (typeof exports === 'object')
		exports["tinyToast"] = factory();
	else
		root["tinyToast"] = factory();
})(this, function () {
	return (function (modules) {
		var installedModules = {};

		function __webpack_require__(moduleId) {
			if (installedModules[moduleId])
				return installedModules[moduleId].exports;

			var module = installedModules[moduleId] = {
				exports: {},
				id: moduleId,
				loaded: false
			};

			modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
			module.loaded = true;
			return module.exports;
		}
		__webpack_require__.m = modules;
		__webpack_require__.c = installedModules;
		__webpack_require__.p = "";
		return __webpack_require__(0);
	})
		([
			function (module, exports) {
				'use strict'
				var tinyToast

				function createCssStyleSheet() {
					const style = document.createElement('style')
					document.head.appendChild(style)
					return style.sheet
				}

				function createDom(messageType) {
					if (tinyToast) return tinyToast

					tinyToast = document.createElement('p')
					tinyToast.classList.add('tinyToast-' + messageType)
					document.body.appendChild(tinyToast)
					return tinyToast
				}

				function closeMessage() {
					if (tinyToast) {
						document.body.removeChild(tinyToast)
						tinyToast = null
					}
				}

				function maybeDefer(fn, timeoutMs) {
					if (timeoutMs) {
						setTimeout(fn, timeoutMs)
					} else {
						fn()
					}
				}

				function hide(timeoutMs) {
					maybeDefer(closeMessage, timeoutMs)
				}

				var tinyToastApi = {
					show: function show(text, messageType) {
						createDom(messageType).innerHTML = text
						return tinyToastApi
					},
					hide: hide
				}

				module.exports = tinyToastApi
			}
		])
})
