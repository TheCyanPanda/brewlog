{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's own (deprecated) service worker is not
// used. The PWA service worker is web/sw.js, registered from index.html.
_flutter.loader.load();
