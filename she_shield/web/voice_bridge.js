// SHE SHIELD Browser Audio & Voice Bridge
// Implements real Web Speech API continuous detection, MediaRecorder capture,
// SubtleCrypto SHA-256 hashing, authenticated Blob playback/download, and IndexedDB offline vault.

window.SheShieldVoiceBridge = (() => {
  let recognition = null;
  let keepListening = false;
  let listenStream = null;
  let levelTimer = null;
  let audioCtx = null;

  let mediaRecorder = null;
  let recordStream = null;
  let recordChunks = [];
  let recordStartMs = 0;
  let lastRecordedBytes = null;
  let lastRecordedMime = 'audio/webm';
  let onSystemStopCb = null;

  let activeAudioEl = null;
  let activeObjectUrl = null;
  let playbackCb = null;

  function toHex(buffer) {
    return Array.from(new Uint8Array(buffer))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('');
  }

  async function sha256Hex(uint8) {
    if (window.crypto && window.crypto.subtle) {
      const digest = await window.crypto.subtle.digest('SHA-256', uint8.buffer.slice(uint8.byteOffset, uint8.byteOffset + uint8.byteLength));
      return toHex(digest);
    }
    return '';
  }

  function stopTracks(stream) {
    if (!stream) return;
    try {
      stream.getTracks().forEach((t) => t.stop());
    } catch (_) {}
  }

  function clearLevelMonitor() {
    if (levelTimer) {
      clearInterval(levelTimer);
      levelTimer = null;
    }
    if (audioCtx) {
      try { audioCtx.close(); } catch (_) {}
      audioCtx = null;
    }
  }

  function startLevelMonitor(stream, onLevel) {
    clearLevelMonitor();
    try {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC || !onLevel) return;
      audioCtx = new AC();
      const source = audioCtx.createMediaStreamSource(stream);
      const analyser = audioCtx.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);
      const buf = new Uint8Array(analyser.frequencyBinCount);
      levelTimer = setInterval(() => {
        try {
          analyser.getByteFrequencyData(buf);
          let sum = 0;
          for (let i = 0; i < buf.length; i++) sum += buf[i];
          const avg = sum / buf.length;
          onLevel(Math.min(10, (avg / 255) * 14));
        } catch (_) {}
      }, 180);
    } catch (_) {}
  }

  async function checkMicPermission() {
    try {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        return false;
      }
      if (navigator.permissions && navigator.permissions.query) {
        const res = await navigator.permissions.query({ name: 'microphone' });
        return res.state === 'granted';
      }
    } catch (_) {}
    return false;
  }

  async function requestMicPermission() {
    try {
      if (!window.isSecureContext || !navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        return JSON.stringify({
          granted: false,
          error: 'Browser microphone access requires http://localhost:3000 (or HTTPS). Plain LAN IP HTTP is blocked by browser security.'
        });
      }
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      stopTracks(stream);
      return JSON.stringify({ granted: true });
    } catch (err) {
      return JSON.stringify({ granted: false, error: err && err.message ? err.message : 'Microphone permission denied' });
    }
  }

  async function startListening(langTag, onResult, onLevel, onStatus, onError) {
    stopListening();
    const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRec) {
      if (onStatus) onStatus('speech_api_unavailable');
      if (onError) onError('Web Speech Recognition API is not supported in this browser.');
      return false;
    }

    try {
      listenStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      startLevelMonitor(listenStream, onLevel);
    } catch (err) {
      if (onError) onError(err && err.message ? err.message : 'Microphone permission denied');
      return false;
    }

    keepListening = true;

    const launchRecognizer = () => {
      if (!keepListening) return;
      try {
        recognition = new SpeechRec();
        recognition.lang = langTag || 'en-US';
        recognition.continuous = true;
        recognition.interimResults = true;
        recognition.maxAlternatives = 3;

        recognition.onstart = () => {
          if (onStatus) onStatus('listening');
        };

        recognition.onresult = (event) => {
          let fullTranscript = '';
          for (let i = event.resultIndex; i < event.results.length; i++) {
            fullTranscript += event.results[i][0].transcript + ' ';
          }
          const clean = fullTranscript.trim();
          if (clean && onResult) {
            onResult(clean);
          }
        };

        recognition.onerror = (event) => {
          const code = event && event.error ? event.error : 'unknown';
          if (code === 'not-allowed' || code === 'service-not-allowed') {
            keepListening = false;
            if (onError) onError('Microphone / speech permission denied: ' + code);
          } else if (code !== 'no-speech' && code !== 'aborted') {
            if (onStatus) onStatus('retrying (' + code + ')');
          }
        };

        recognition.onend = () => {
          if (keepListening) {
            setTimeout(() => {
              if (keepListening) launchRecognizer();
            }, 350);
          } else {
            if (onStatus) onStatus('stopped');
          }
        };

        recognition.start();
      } catch (e) {
        if (onError) onError(String(e));
      }
    };

    launchRecognizer();
    return true;
  }

  function stopListening() {
    keepListening = false;
    if (recognition) {
      try {
        recognition.onend = null;
        recognition.stop();
      } catch (_) {}
      recognition = null;
    }
    clearLevelMonitor();
    stopTracks(listenStream);
    listenStream = null;
  }

  function pickRecorderMime() {
    const candidates = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/mp4',
      'audio/ogg;codecs=opus',
    ];
    if (typeof MediaRecorder === 'undefined') return '';
    for (const m of candidates) {
      if (MediaRecorder.isTypeSupported && MediaRecorder.isTypeSupported(m)) {
        return m;
      }
    }
    return '';
  }

  async function startRecording(onSystemStop, onLevel) {
    stopListening();
    if (mediaRecorder && mediaRecorder.state === 'recording') {
      return JSON.stringify({ ok: false, error: 'Recording already active' });
    }
    if (typeof MediaRecorder === 'undefined') {
      return JSON.stringify({ ok: false, error: 'MediaRecorder is not supported in this browser.' });
    }

    try {
      recordStream = await navigator.mediaDevices.getUserMedia({ audio: true });
      recordChunks = [];
      lastRecordedBytes = null;
      onSystemStopCb = onSystemStop;

      const tracks = recordStream.getAudioTracks();
      if (tracks.length > 0) {
        tracks[0].onended = () => {
          if (mediaRecorder && mediaRecorder.state === 'recording' && onSystemStopCb) {
            onSystemStopCb('microphone_disconnected');
          }
        };
      }

      startLevelMonitor(recordStream, onLevel);

      const chosenMime = pickRecorderMime();
      mediaRecorder = chosenMime
        ? new MediaRecorder(recordStream, { mimeType: chosenMime })
        : new MediaRecorder(recordStream);

      lastRecordedMime = (mediaRecorder.mimeType || chosenMime || 'audio/webm').split(';')[0].trim();

      mediaRecorder.ondataavailable = (ev) => {
        if (ev.data && ev.data.size > 0) {
          recordChunks.push(ev.data);
        }
      };

      recordStartMs = Date.now();
      mediaRecorder.start(500);

      return JSON.stringify({
        ok: true,
        mimeType: lastRecordedMime,
        startedAtMs: recordStartMs,
      });
    } catch (err) {
      clearLevelMonitor();
      stopTracks(recordStream);
      recordStream = null;
      return JSON.stringify({
        ok: false,
        error: err && err.message ? err.message : 'Unable to start audio recording',
      });
    }
  }

  function validatePlayableBlob(blob) {
    return new Promise((resolve) => {
      try {
        const tempUrl = URL.createObjectURL(blob);
        const audio = new Audio();
        audio.preload = 'metadata';
        let settled = false;
        const done = (playable, measuredSec) => {
          if (settled) return;
          settled = true;
          try { URL.revokeObjectURL(tempUrl); } catch (_) {}
          resolve({ playable, measuredSec });
        };
        audio.onloadedmetadata = () => {
          const d = Number.isFinite(audio.duration) ? Math.round(audio.duration) : 0;
          done(true, d);
        };
        audio.onerror = () => done(false, 0);
        setTimeout(() => done(blob.size > 0, 0), 1500);
        audio.src = tempUrl;
      } catch (_) {
        resolve({ playable: blob.size > 0, measuredSec: 0 });
      }
    });
  }

  function stopRecording() {
    return new Promise((resolve) => {
      if (!mediaRecorder) {
        resolve(JSON.stringify({ ok: false, error: 'No active recording' }));
        return;
      }

      const mr = mediaRecorder;
      const elapsedSeconds = Math.max(1, Math.round((Date.now() - recordStartMs) / 1000));

      const finalize = async () => {
        clearLevelMonitor();
        stopTracks(recordStream);
        recordStream = null;
        mediaRecorder = null;

        try {
          const blob = new Blob(recordChunks, { type: lastRecordedMime });
          recordChunks = [];
          if (!blob || blob.size < 64) {
            resolve(JSON.stringify({ ok: false, error: 'Recorded audio file is empty.' }));
            return;
          }

          const check = await validatePlayableBlob(blob);
          if (!check.playable) {
            resolve(JSON.stringify({ ok: false, error: 'Audio container validation failed (unplayable).' }));
            return;
          }

          const ab = await blob.arrayBuffer();
          lastRecordedBytes = new Uint8Array(ab);
          const digest = await sha256Hex(lastRecordedBytes);
          const duration = check.measuredSec > 0 ? check.measuredSec : elapsedSeconds;

          resolve(JSON.stringify({
            ok: true,
            mimeType: lastRecordedMime,
            fileSize: lastRecordedBytes.length,
            durationSeconds: duration,
            sha256: digest,
          }));
        } catch (err) {
          resolve(JSON.stringify({ ok: false, error: err && err.message ? err.message : 'Finalize failed' }));
        }
      };

      if (mr.state === 'inactive') {
        finalize();
      } else {
        mr.onstop = finalize;
        try {
          mr.stop();
        } catch (e) {
          finalize();
        }
      }
    });
  }

  function getLastRecordedBytes() {
    return lastRecordedBytes;
  }

  function stopPlayback() {
    if (activeAudioEl) {
      try {
        activeAudioEl.pause();
        activeAudioEl.onended = null;
        activeAudioEl.ontimeupdate = null;
      } catch (_) {}
      activeAudioEl = null;
    }
    if (activeObjectUrl) {
      try { URL.revokeObjectURL(activeObjectUrl); } catch (_) {}
      activeObjectUrl = null;
    }
  }

  async function playAuthAudio(streamUrl, token, onTimeUpdate, onEnded, onError) {
    stopPlayback();
    playbackCb = { onTimeUpdate, onEnded, onError };
    try {
      const resp = await fetch(streamUrl, {
        method: 'GET',
        headers: token ? { Authorization: 'Bearer ' + token } : {},
      });
      if (!resp.ok) {
        let errText = 'HTTP ' + resp.status;
        try {
          const j = await resp.json();
          if (j && j.error) errText = j.error;
        } catch (_) {}
        if (onError) onError(errText);
        return false;
      }
      const blob = await resp.blob();
      activeObjectUrl = URL.createObjectURL(blob);
      activeAudioEl = new Audio(activeObjectUrl);

      activeAudioEl.ontimeupdate = () => {
        if (!activeAudioEl || !playbackCb || !playbackCb.onTimeUpdate) return;
        const cur = Number.isFinite(activeAudioEl.currentTime) ? activeAudioEl.currentTime : 0;
        const dur = Number.isFinite(activeAudioEl.duration) ? activeAudioEl.duration : 0;
        playbackCb.onTimeUpdate(cur, dur);
      };
      activeAudioEl.onended = () => {
        if (playbackCb && playbackCb.onEnded) playbackCb.onEnded();
      };
      activeAudioEl.onerror = () => {
        if (playbackCb && playbackCb.onError) playbackCb.onError('Audio playback error');
      };

      await activeAudioEl.play();
      return true;
    } catch (err) {
      if (onError) onError(err && err.message ? err.message : 'Playback failed');
      return false;
    }
  }

  function pausePlayback() {
    if (activeAudioEl) {
      try { activeAudioEl.pause(); } catch (_) {}
    }
  }

  async function resumePlayback() {
    if (activeAudioEl) {
      try {
        await activeAudioEl.play();
        return true;
      } catch (_) {}
    }
    return false;
  }

  async function downloadAuthAudio(downloadUrl, token, filename) {
    try {
      const resp = await fetch(downloadUrl, {
        method: 'GET',
        headers: token ? { Authorization: 'Bearer ' + token } : {},
      });
      if (!resp.ok) {
        return JSON.stringify({ ok: false, error: 'Download failed (HTTP ' + resp.status + ')' });
      }
      const blob = await resp.blob();
      const objUrl = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = objUrl;
      a.download = filename || 'evidence_audio.webm';
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(objUrl), 2000);
      return JSON.stringify({ ok: true });
    } catch (err) {
      return JSON.stringify({ ok: false, error: err && err.message ? err.message : 'Download error' });
    }
  }

  // IndexedDB offline vault queue so recordings survive offline failures & page reloads
  function openOfflineDb() {
    return new Promise((resolve, reject) => {
      const req = indexedDB.open('she_shield_offline_vault_db', 1);
      req.onupgradeneeded = (e) => {
        const db = e.target.result;
        if (!db.objectStoreNames.contains('pending_audio')) {
          db.createObjectStore('pending_audio', { keyPath: 'id' });
        }
      };
      req.onsuccess = (e) => resolve(e.target.result);
      req.onerror = (e) => reject(e.target.error);
    });
  }

  async function offlineSave(metaJson, uint8Bytes) {
    try {
      const db = await openOfflineDb();
      const meta = JSON.parse(metaJson);
      const record = {
        ...meta,
        bytes: uint8Bytes ? uint8Bytes.buffer.slice(uint8Bytes.byteOffset, uint8Bytes.byteOffset + uint8Bytes.byteLength) : null,
      };
      await new Promise((resolve, reject) => {
        const tx = db.transaction('pending_audio', 'readwrite');
        tx.objectStore('pending_audio').put(record);
        tx.oncomplete = () => resolve();
        tx.onerror = (e) => reject(e.target.error);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  async function offlineList(userId) {
    try {
      const db = await openOfflineDb();
      const items = await new Promise((resolve, reject) => {
        const tx = db.transaction('pending_audio', 'readonly');
        const req = tx.objectStore('pending_audio').getAll();
        req.onsuccess = () => resolve(req.result || []);
        req.onerror = (e) => reject(e.target.error);
      });
      const filtered = items
        .filter((item) => !userId || item.userId === userId)
        .map(({ bytes, ...meta }) => meta);
      return JSON.stringify(filtered);
    } catch (_) {
      return '[]';
    }
  }

  async function offlineGetBytes(id) {
    try {
      const db = await openOfflineDb();
      const rec = await new Promise((resolve, reject) => {
        const tx = db.transaction('pending_audio', 'readonly');
        const req = tx.objectStore('pending_audio').get(id);
        req.onsuccess = () => resolve(req.result);
        req.onerror = (e) => reject(e.target.error);
      });
      if (rec && rec.bytes) {
        return new Uint8Array(rec.bytes);
      }
    } catch (_) {}
    return null;
  }

  async function offlineDelete(id) {
    try {
      const db = await openOfflineDb();
      await new Promise((resolve, reject) => {
        const tx = db.transaction('pending_audio', 'readwrite');
        tx.objectStore('pending_audio').delete(id);
        tx.oncomplete = () => resolve();
        tx.onerror = (e) => reject(e.target.error);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  return {
    checkMicPermission,
    requestMicPermission,
    startListening,
    stopListening,
    startRecording,
    stopRecording,
    getLastRecordedBytes,
    playAuthAudio,
    pausePlayback,
    resumePlayback,
    stopPlayback,
    downloadAuthAudio,
    offlineSave,
    offlineList,
    offlineGetBytes,
    offlineDelete,
  };
})();
