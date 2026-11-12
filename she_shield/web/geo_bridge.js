(function () {
  let watchId = null;

  function formatError(err) {
    if (!err) return "Location request failed.";
    switch (err.code) {
      case 1:
        return "Location permission denied. Please enable browser location access.";
      case 2:
        return "Location position unavailable. Ensure GPS or network positioning is enabled.";
      case 3:
        return "Location request timed out. Move to an area with better signal and retry.";
      default:
        return err.message || "Geolocation error occurred.";
    }
  }

  function serializePosition(pos) {
    const c = pos.coords || {};
    return {
      ok: true,
      latitude: Number(c.latitude),
      longitude: Number(c.longitude),
      accuracy: c.accuracy != null && Number.isFinite(c.accuracy) ? Number(c.accuracy) : 0.0,
      speed: c.speed != null && Number.isFinite(c.speed) ? Number(c.speed) : 0.0,
      heading: c.heading != null && Number.isFinite(c.heading) ? Number(c.heading) : 0.0,
      timestamp: new Date(pos.timestamp || Date.now()).toISOString(),
    };
  }

  window.SheShieldGeoBridge = {
    isSupported: function () {
      return !!(typeof navigator !== "undefined" && navigator.geolocation);
    },

    checkPermission: async function () {
      try {
        if (!navigator.geolocation) return "unsupported";
        if (navigator.permissions && navigator.permissions.query) {
          const st = await navigator.permissions.query({ name: "geolocation" });
          return st && st.state ? st.state : "prompt";
        }
        return "prompt";
      } catch (_) {
        return "prompt";
      }
    },

    getCurrentPosition: function () {
      return new Promise((resolve) => {
        if (typeof navigator === "undefined" || !navigator.geolocation) {
          resolve(
            JSON.stringify({
              ok: false,
              code: "UNSUPPORTED",
              error: "Browser Geolocation API is not supported in this browser.",
            })
          );
          return;
        }
        navigator.geolocation.getCurrentPosition(
          (pos) => resolve(JSON.stringify(serializePosition(pos))),
          (err) =>
            resolve(
              JSON.stringify({
                ok: false,
                code: err && err.code === 1 ? "PERMISSION_DENIED" : "UNAVAILABLE",
                error: formatError(err),
              })
            ),
          {
            enableHighAccuracy: true,
            timeout: 12000,
            maximumAge: 3000,
          }
        );
      });
    },

    startWatch: function (onPosition, onError) {
      if (typeof navigator === "undefined" || !navigator.geolocation) {
        if (typeof onError === "function") {
          onError("Browser Geolocation API is not supported.");
        }
        return false;
      }
      if (watchId !== null) {
        navigator.geolocation.clearWatch(watchId);
        watchId = null;
      }
      watchId = navigator.geolocation.watchPosition(
        (pos) => {
          if (typeof onPosition === "function") {
            onPosition(JSON.stringify(serializePosition(pos)));
          }
        },
        (err) => {
          if (typeof onError === "function") {
            onError(formatError(err));
          }
        },
        {
          enableHighAccuracy: true,
          timeout: 15000,
          maximumAge: 2500,
        }
      );
      return true;
    },

    stopWatch: function () {
      if (watchId !== null && typeof navigator !== "undefined" && navigator.geolocation) {
        navigator.geolocation.clearWatch(watchId);
      }
      watchId = null;
    },
  };
})();
