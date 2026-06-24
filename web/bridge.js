// Supabase bridge for Far Keep (Godot web export). GDScript talks to this via JavaScriptBridge.
// Identity is a client-generated UUID persisted in localStorage (project has anonymous auth
// disabled + email confirmation required, so this is the per-device persistent identity).
// URL + publishable anon key are PUBLIC client credentials by design.
(function () {
  var SB_URL = "https://xhhmxabftbyxrirvvihn.supabase.co";
  var SB_KEY = "sb_publishable_NZHoIxqqpSvVBP8MrLHCYA_gmg1AbN-";
  var LB_TABLE = "usr_nmexs7bytxq2_farkeep_leaderboard";
  var client = null;

  function getClient() {
    if (client) return client;
    if (!window.supabase || !window.supabase.createClient) return null;
    client = window.supabase.createClient(SB_URL, SB_KEY, { auth: { persistSession: false } });
    return client;
  }
  function uid() {
    var k = "farkeep_uid", v = null;
    try { v = localStorage.getItem(k); } catch (e) {}
    if (!v) {
      v = (window.crypto && crypto.randomUUID) ? crypto.randomUUID()
        : "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
            var r = (Math.random() * 16) | 0; return (c === "x" ? r : (r & 0x3) | 0x8).toString(16); });
      try { localStorage.setItem(k, v); } catch (e) {}
    }
    return v;
  }
  function getName() { try { return localStorage.getItem("farkeep_name") || ""; } catch (e) { return ""; } }
  function setName(n) { try { localStorage.setItem("farkeep_name", n || ""); } catch (e) {} }
  function done(cb, payload) { try { if (cb) cb(JSON.stringify(payload)); } catch (e) {} }

  window.farkeep = {
    getUserId: function () { return uid(); },
    getName: getName,
    setName: setName,
    load: function (cb) {
      var c = getClient();
      if (!c) { done(cb, { ok: false }); return; }
      c.rpc("farkeep_load", { p_user_id: uid() })
        .then(function (r) { done(cb, { ok: !r.error, save: r.data || null }); })
        .catch(function () { done(cb, { ok: false }); });
    },
    save: function (name, px, py, pz, yaw, invJson, gatesJson, elapsed, reached, cb) {
      var c = getClient();
      if (!c) { done(cb, { ok: false }); return; }
      var inv = {}, gates = [];
      try { inv = JSON.parse(invJson); } catch (e) {}
      try { gates = JSON.parse(gatesJson); } catch (e) {}
      c.rpc("farkeep_upsert_save", {
        p_user_id: uid(), p_name: name, p_px: px, p_py: py, p_pz: pz, p_yaw: yaw,
        p_inv: inv, p_gates: gates, p_elapsed: elapsed, p_reached: !!reached
      }).then(function (r) { done(cb, { ok: !r.error }); }).catch(function () { done(cb, { ok: false }); });
    },
    submitScore: function (name, timeSec, cb) {
      var c = getClient();
      if (!c) { done(cb, { ok: false }); return; }
      c.rpc("farkeep_submit_score", { p_user_id: uid(), p_name: name, p_time: timeSec })
        .then(function (r) { done(cb, { ok: !r.error }); }).catch(function () { done(cb, { ok: false }); });
    },
    leaderboard: function (cb) {
      var c = getClient();
      if (!c) { done(cb, { ok: false, rows: [] }); return; }
      c.from(LB_TABLE).select("display_name,time_seconds").order("time_seconds", { ascending: true }).limit(20)
        .then(function (r) { done(cb, { ok: !r.error, rows: r.data || [] }); })
        .catch(function () { done(cb, { ok: false, rows: [] }); });
    }
  };
})();
