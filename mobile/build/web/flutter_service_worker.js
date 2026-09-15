'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "582726640775f343f1d403b1ad31dd27",
"assets/AssetManifest.bin.json": "f3f7076947b84bd4871e699dbbc8329e",
"assets/AssetManifest.json": "09103838b3ad19f63f6631b8dd84c3af",
"assets/assets/images/kaza.mp4": "f77025b60dca1c8d95f2b3aa8a29a752",
"assets/assets/images/kaza_app_icon.png": "e1223b460e1f7d7304cf355011c7ddaa",
"assets/assets/images/kaza_app_icon_1024.png": "d1aeaf8751231bc6789eece1e9986ea1",
"assets/assets/images/kaza_logo.gif": "c0f6550ed0710c67d5431b931fa5a4b5",
"assets/assets/images/kaza_logo_final.png": "85996cb130ea0319adfbca72cce840cb",
"assets/assets/images/kaza_logo_final_reencoded.png": "9542549df96519ff459c36eafdbba45c",
"assets/assets/images/kaza_logo_negative_navy.png": "71643e0e34d7414f8dec8e75178cc92e",
"assets/assets/images/kaza_logo_primary.png": "cab23184a2f8c553126afb8936f89b17",
"assets/assets/images/kaza_logo_tagline.png": "57b63e7726f2dc26bbf9c8487e84e023",
"assets/assets/images/kaza_logo_tagline_hd.png": "502f6fad23b5244743acaaaeb0464e90",
"assets/assets/images/kaza_symbol.png": "00ffb91c62fc34e807382ac908eccaa1",
"assets/assets/images/logo.png": "1111e6a9880c3cdfbee3db4e9975ea6f",
"assets/assets/images/WhatsApp%2520Image%25202026-08-01%2520at%252012.15.39.jpeg": "ccfe838491ef970d70828e13ce989fe0",
"assets/assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Lockup_Negative_Navy.svg": "07181c8a464967dbf20503f2fc23dcf0",
"assets/assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Lockup_Primary.svg": "377169fad78436d855af932254e81ce6",
"assets/assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Lockup_With_Tagline.svg": "f17ed2f7ed04dc865a62f01657ad7c44",
"assets/assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Symbol_Master.svg": "f35978deb0c24277e6538dffdfa41045",
"assets/assets/KAZA_Wordmark_Lockup_1.0/01_MASTER_VECTOR/KAZA_Wordmark_Master.svg": "35760d3d4739dec81e5b630fcfe74ffb",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Primary_1024px.png": "d8770f08c1e26fbc9b6fb705dd52cfc1",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Primary_128px.png": "4075b27bbdd76808295b1490e0d33d29",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Primary_2048px.png": "d0098e62909b38c8baf34a8c8956dab3",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Primary_256px.png": "db9a33224a00cd3d3b5363118457f9ed",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Primary_512px.png": "cab23184a2f8c553126afb8936f89b17",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Tagline_1024px.png": "cdd3338a4024b6417588bae37fd55b1b",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Tagline_128px.png": "ff9126d382ba1705d21dd6f08b9db944",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Tagline_2048px.png": "502f6fad23b5244743acaaaeb0464e90",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Tagline_256px.png": "2d8cd620eb8d873c4f4685acf25a865e",
"assets/assets/KAZA_Wordmark_Lockup_1.0/02_PNG_TRANSPARENT/KAZA_Tagline_512px.png": "57b63e7726f2dc26bbf9c8487e84e023",
"assets/assets/KAZA_Wordmark_Lockup_1.0/04_APP_ASSETS/KAZA_Symbol_1024px.png": "408bd3af23efd80da55e64412f197a81",
"assets/assets/KAZA_Wordmark_Lockup_1.0/04_APP_ASSETS/KAZA_Symbol_128px.png": "893ae846edf647b1e457bd0b656d97e2",
"assets/assets/KAZA_Wordmark_Lockup_1.0/04_APP_ASSETS/KAZA_Symbol_24px.png": "3fe904cacad0cf53ed2130b66aa9a4ab",
"assets/assets/KAZA_Wordmark_Lockup_1.0/04_APP_ASSETS/KAZA_Symbol_256px.png": "00ffb91c62fc34e807382ac908eccaa1",
"assets/assets/KAZA_Wordmark_Lockup_1.0/04_APP_ASSETS/KAZA_Symbol_32px.png": "d668c94e72d78c7ddce01aae415d97e9",
"assets/assets/KAZA_Wordmark_Lockup_1.0/04_APP_ASSETS/KAZA_Symbol_48px.png": "6a527c97610bf47b0fbc303b3f0e90a2",
"assets/assets/KAZA_Wordmark_Lockup_1.0/04_APP_ASSETS/KAZA_Symbol_512px.png": "1e863bd01110922819553cc7e1742dac",
"assets/assets/KAZA_Wordmark_Lockup_1.0/04_APP_ASSETS/KAZA_Symbol_64px.png": "f97e140863ab87a71b6f135d9645520c",
"assets/assets/pins/3XS.png": "d3115c8c6f59f401774a2d0ac8914231",
"assets/assets/pins/pin_casa.png": "157c44f979b55c4cd4a78366dfcc0780",
"assets/assets/pins/pin_departamento.png": "8164efb34e255fa59bd33fab03788728",
"assets/assets/pins/pin_oficina.png": "95ea4a3c11230248ecbf7d087dba91a7",
"assets/assets/pins/pin_terreno.png": "231b935f4724783ea8629bb943027823",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "2fc1deacec1dfe341367509d46868bb8",
"assets/NOTICES": "78770d9adcceed9f5641dab0f47242b5",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"flutter_bootstrap.js": "93e7d68cb009b9ccd543e6bb81ec5bbf",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "f59e32d024d9aa293128e10e9a30a343",
"/": "f59e32d024d9aa293128e10e9a30a343",
"main.dart.js": "7c5da45736e4c35cee53ef5951a0593f",
"manifest.json": "6818dc0048f086a6849c17ab04b5b189",
"version.json": "9ed43ffa08b5c3b81f0154dc4943c58e"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
